#include "MapFrameServer.hpp"

#include <arpa/inet.h>
#include <cerrno>
#include <chrono>
#include <cstring>
#include <exception>
#include <iostream>
#include <netinet/in.h>
#include <netinet/tcp.h>
#include <optional>
#include <poll.h>
#include <stdexcept>
#include <sys/socket.h>
#include <unistd.h>
#include <vector>

namespace hypernova::cluster {
namespace {

constexpr std::uint32_t kMagic = 0x484E4D46U; // HNMF
constexpr std::uint16_t kVersion = 1U;
constexpr std::uint16_t kHeaderSize = 32U;
constexpr std::uint8_t kEncodingJpeg = 1U;
constexpr std::size_t kMaxPayloadBytes = 1024U * 1024U;
constexpr std::size_t kMaxBufferedBytes =
        2U * (kHeaderSize + kMaxPayloadBytes);
constexpr int kPollTimeoutMs = 200;
constexpr std::size_t kReceiveChunkSize = 16U * 1024U;

struct Header {
    std::uint32_t sequence;
    std::uint64_t captureTimestampMs;
    std::uint16_t width;
    std::uint16_t height;
    std::uint32_t payloadLength;
};

struct CompleteFrame {
    Header header;
    std::vector<std::uint8_t> jpeg;
};

void closeSocket(int fd)
{
    if (fd >= 0) {
        ::close(fd);
    }
}

std::string socketError(const char* operation)
{
    return std::string(operation) + ": " + std::strerror(errno);
}

std::uint16_t readU16(const std::uint8_t* bytes)
{
    return static_cast<std::uint16_t>(bytes[0]) << 8U
            | static_cast<std::uint16_t>(bytes[1]);
}

std::uint32_t readU32(const std::uint8_t* bytes)
{
    return static_cast<std::uint32_t>(bytes[0]) << 24U
            | static_cast<std::uint32_t>(bytes[1]) << 16U
            | static_cast<std::uint32_t>(bytes[2]) << 8U
            | static_cast<std::uint32_t>(bytes[3]);
}

std::uint64_t readU64(const std::uint8_t* bytes)
{
    std::uint64_t value = 0;
    for (std::size_t index = 0; index < 8U; ++index) {
        value = (value << 8U) | bytes[index];
    }
    return value;
}

bool parseHeader(const std::vector<std::uint8_t>& buffer, Header& header)
{
    if (buffer.size() < kHeaderSize) {
        return false;
    }

    const std::uint8_t* bytes = buffer.data();
    const std::uint32_t magic = readU32(bytes);
    const std::uint16_t version = readU16(bytes + 4U);
    const std::uint16_t headerSize = readU16(bytes + 6U);
    const std::uint8_t encoding = bytes[24U];
    const std::uint8_t flags = bytes[25U];
    const std::uint16_t reserved = readU16(bytes + 30U);

    header.sequence = readU32(bytes + 8U);
    header.captureTimestampMs = readU64(bytes + 12U);
    header.width = readU16(bytes + 20U);
    header.height = readU16(bytes + 22U);
    header.payloadLength = readU32(bytes + 26U);

    if (magic != kMagic
            || version != kVersion
            || headerSize != kHeaderSize
            || encoding != kEncodingJpeg
            || flags != 0U
            || reserved != 0U) {
        throw std::runtime_error("invalid HNMF frame header");
    }

    if (header.width == 0U
            || header.height == 0U
            || header.width > 1920U
            || header.height > 1080U
            || header.payloadLength == 0U
            || header.payloadLength > kMaxPayloadBytes) {
        throw std::runtime_error("invalid HNMF dimensions or payload length");
    }
    return true;
}

} // namespace

MapFrameServer::MapFrameServer(std::uint16_t port, Listener listener)
    : requestedPort_(port),
      listener_(std::move(listener))
{
}

MapFrameServer::~MapFrameServer()
{
    stop();
}

bool MapFrameServer::start()
{
    bool expected = false;
    if (!running_.compare_exchange_strong(expected, true)) {
        return true;
    }

    const int fd = ::socket(AF_INET, SOCK_STREAM, 0);
    if (fd < 0) {
        std::cerr << "HNMF: " << socketError("socket") << std::endl;
        running_.store(false);
        return false;
    }

    int enabled = 1;
    if (::setsockopt(
                fd, SOL_SOCKET, SO_REUSEADDR, &enabled, sizeof(enabled)) < 0) {
        std::cerr << "HNMF: " << socketError("setsockopt(SO_REUSEADDR)")
                  << std::endl;
        closeSocket(fd);
        running_.store(false);
        return false;
    }

    sockaddr_in address{};
    address.sin_family = AF_INET;
    address.sin_addr.s_addr = htonl(INADDR_ANY);
    address.sin_port = htons(requestedPort_);
    if (::bind(fd, reinterpret_cast<sockaddr*>(&address), sizeof(address)) < 0
            || ::listen(fd, 1) < 0) {
        std::cerr << "HNMF: " << socketError("bind/listen") << std::endl;
        closeSocket(fd);
        running_.store(false);
        return false;
    }

    sockaddr_in actualAddress{};
    socklen_t actualLength = sizeof(actualAddress);
    if (::getsockname(
                fd,
                reinterpret_cast<sockaddr*>(&actualAddress),
                &actualLength) < 0) {
        std::cerr << "HNMF: " << socketError("getsockname") << std::endl;
        closeSocket(fd);
        running_.store(false);
        return false;
    }

    listenFd_.store(fd);
    boundPort_.store(ntohs(actualAddress.sin_port));
    try {
        worker_ = std::thread(&MapFrameServer::workerMain, this);
    } catch (...) {
        closeSocket(listenFd_.exchange(-1));
        boundPort_.store(0);
        running_.store(false);
        throw;
    }

    std::cout << "HNMF: listening on 0.0.0.0:" << boundPort_.load()
              << std::endl;
    return true;
}

void MapFrameServer::stop()
{
    running_.store(false);
    if (worker_.joinable()) {
        worker_.join();
    }
    closeSocket(listenFd_.exchange(-1));
    clientFd_.store(-1);
    boundPort_.store(0);
}

bool MapFrameServer::isRunning() const { return running_.load(); }
std::uint16_t MapFrameServer::boundPort() const { return boundPort_.load(); }

void MapFrameServer::workerMain()
{
    const int serverFd = listenFd_.load();
    while (running_.load()) {
        pollfd descriptor{};
        descriptor.fd = serverFd;
        descriptor.events = POLLIN;
        const int result = ::poll(&descriptor, 1, kPollTimeoutMs);
        if (result < 0) {
            if (errno == EINTR) continue;
            std::cerr << "HNMF: " << socketError("poll(listen)") << std::endl;
            break;
        }
        if (result == 0) continue;
        if ((descriptor.revents & (POLLERR | POLLNVAL)) != 0) break;
        if ((descriptor.revents & POLLIN) == 0) continue;

        sockaddr_in peer{};
        socklen_t peerLength = sizeof(peer);
        const int accepted = ::accept(
                serverFd,
                reinterpret_cast<sockaddr*>(&peer),
                &peerLength);
        if (accepted < 0) {
            if (errno != EINTR && running_.load()) {
                std::cerr << "HNMF: " << socketError("accept") << std::endl;
            }
            continue;
        }
        int enabled = 1;
        static_cast<void>(::setsockopt(
                accepted, IPPROTO_TCP, TCP_NODELAY, &enabled, sizeof(enabled)));
        clientFd_.store(accepted);

        char peerAddress[INET_ADDRSTRLEN] = {};
        const char* addressText = ::inet_ntop(
                AF_INET, &peer.sin_addr, peerAddress, sizeof(peerAddress));
        std::cout << "HNMF: Android map-frame client connected from "
                  << (addressText == nullptr ? "unknown" : addressText)
                  << ":" << ntohs(peer.sin_port) << std::endl;
        notifyClientState(true);
        try {
            runClient(accepted);
        } catch (const std::exception& error) {
            std::cerr << "HNMF: client session error: " << error.what()
                      << std::endl;
        }
        closeSocket(accepted);
        clientFd_.store(-1);
        notifyClientState(false);
    }
    closeSocket(listenFd_.exchange(-1));
    running_.store(false);
}

void MapFrameServer::runClient(int clientFd)
{
    std::vector<std::uint8_t> receiveBuffer;
    receiveBuffer.reserve(kMaxBufferedBytes);
    std::optional<CompleteFrame> newestCompleteFrame;
    std::uint32_t decodedFrames = 0;

    while (running_.load()) {
        pollfd descriptor{};
        descriptor.fd = clientFd;
        descriptor.events = POLLIN;
        const int result = ::poll(&descriptor, 1, kPollTimeoutMs);
        if (result < 0) {
            if (errno == EINTR) continue;
            throw std::runtime_error(socketError("poll(client)"));
        }
        if (result == 0) continue;
        if ((descriptor.revents & (POLLERR | POLLNVAL | POLLHUP)) != 0) break;
        if ((descriptor.revents & POLLIN) == 0) continue;

        std::uint8_t chunk[kReceiveChunkSize];
        const ssize_t received = ::recv(clientFd, chunk, sizeof(chunk), 0);
        if (received == 0) break;
        if (received < 0) {
            if (errno == EINTR) continue;
            throw std::runtime_error(socketError("recv"));
        }
        receiveBuffer.insert(
                receiveBuffer.end(),
                chunk,
                chunk + static_cast<std::size_t>(received));
        if (receiveBuffer.size() > kMaxBufferedBytes) {
            throw std::runtime_error("HNMF receive buffer limit exceeded");
        }

        while (true) {
            Header header{};
            if (!parseHeader(receiveBuffer, header)) break;
            const std::size_t frameSize =
                    kHeaderSize + static_cast<std::size_t>(header.payloadLength);
            if (receiveBuffer.size() < frameSize) break;

            CompleteFrame completed;
            completed.header = header;
            completed.jpeg.assign(
                    receiveBuffer.begin()
                            + static_cast<std::ptrdiff_t>(kHeaderSize),
                    receiveBuffer.begin()
                            + static_cast<std::ptrdiff_t>(frameSize));
            receiveBuffer.erase(
                    receiveBuffer.begin(),
                    receiveBuffer.begin()
                            + static_cast<std::ptrdiff_t>(frameSize));
            // Replace, never queue: only newest complete JPEG is decoded.
            newestCompleteFrame = std::move(completed);
        }
        if (!newestCompleteFrame.has_value()) continue;

        CompleteFrame frame = std::move(*newestCompleteFrame);
        newestCompleteFrame.reset();
        const auto decodeStartedAt = std::chrono::steady_clock::now();
        const QByteArray payload(
                reinterpret_cast<const char*>(frame.jpeg.data()),
                static_cast<int>(frame.jpeg.size()));
        QImage image = QImage::fromData(payload, "JPEG");
        const auto decodeMillis = std::chrono::duration_cast<
                std::chrono::milliseconds>(
                std::chrono::steady_clock::now() - decodeStartedAt).count();
        if (image.isNull()
                || image.width() != frame.header.width
                || image.height() != frame.header.height) {
            std::cerr << "HNMF: rejected corrupt JPEG frame" << std::endl;
            continue;
        }
        ++decodedFrames;
        if ((decodedFrames % 50U) == 0U) {
            std::cout << "HNMF decode=" << decodeMillis << "ms sequence="
                      << frame.header.sequence << " size="
                      << frame.jpeg.size() << "B" << std::endl;
        }
        notifyFrame(
                std::move(image),
                frame.header.sequence,
                frame.header.captureTimestampMs);
    }
}

void MapFrameServer::notifyClientState(bool connected)
{
    if (listener_.onClientConnectionChanged) {
        listener_.onClientConnectionChanged(connected);
    }
}

void MapFrameServer::notifyFrame(
        QImage image,
        std::uint32_t sequence,
        std::uint64_t captureTimestampMs)
{
    if (listener_.onFrame) {
        listener_.onFrame(std::move(image), sequence, captureTimestampMs);
    }
}

} // namespace hypernova::cluster
