#include "HnclNavigationServer.hpp"

#include <arpa/inet.h>
#include <cerrno>
#include <chrono>
#include <cstring>
#include <iostream>
#include <netinet/in.h>
#include <netinet/tcp.h>
#include <poll.h>
#include <sys/socket.h>
#include <unistd.h>
#include <vector>

namespace hypernova::cluster {
namespace {

constexpr int kAcceptPollTimeoutMs = 200;
constexpr int kClientPollTimeoutMs = 200;

constexpr std::size_t kReceiveChunkSize = 4096;

/*
 * Allows at least two maximum-size HNCL frames to be received together.
 * Frames are parsed and removed immediately, so exceeding this indicates
 * malformed or abusive input.
 */
constexpr std::size_t kMaximumBufferedBytes =
        2U * (hncl::kHeaderSize + hncl::kMaxPayload);

void closeSocket(int fd)
{
    if (fd >= 0) {
        ::close(fd);
    }
}

std::string socketError(const char* operation)
{
    return std::string(operation)
            + ": "
            + std::strerror(errno);
}

} // namespace

HnclNavigationServer::HnclNavigationServer(
        std::uint16_t port,
        Listener listener)
    : requestedPort_(port),
      listener_(std::move(listener))
{
}

HnclNavigationServer::~HnclNavigationServer()
{
    stop();
}

bool HnclNavigationServer::start()
{
    bool expected = false;

    if (!running_.compare_exchange_strong(
            expected,
            true)) {
        return true;
    }

    const int fd =
            ::socket(
                    AF_INET,
                    SOCK_STREAM,
                    0);

    if (fd < 0) {
        std::cerr
                << "HNCL: "
                << socketError("socket")
                << std::endl;

        running_.store(false);
        return false;
    }

    int enabled = 1;

    if (::setsockopt(
            fd,
            SOL_SOCKET,
            SO_REUSEADDR,
            &enabled,
            sizeof(enabled)) < 0) {

        std::cerr
                << "HNCL: "
                << socketError("setsockopt(SO_REUSEADDR)")
                << std::endl;

        closeSocket(fd);
        running_.store(false);
        return false;
    }

    sockaddr_in address{};
    address.sin_family = AF_INET;
    address.sin_addr.s_addr = htonl(INADDR_ANY);
    address.sin_port = htons(requestedPort_);

    if (::bind(
            fd,
            reinterpret_cast<sockaddr*>(&address),
            sizeof(address)) < 0) {

        std::cerr
                << "HNCL: "
                << socketError("bind")
                << std::endl;

        closeSocket(fd);
        running_.store(false);
        return false;
    }

    if (::listen(fd, 1) < 0) {
        std::cerr
                << "HNCL: "
                << socketError("listen")
                << std::endl;

        closeSocket(fd);
        running_.store(false);
        return false;
    }

    sockaddr_in actualAddress{};
    socklen_t actualLength =
            sizeof(actualAddress);

    if (::getsockname(
            fd,
            reinterpret_cast<sockaddr*>(&actualAddress),
            &actualLength) < 0) {

        std::cerr
                << "HNCL: "
                << socketError("getsockname")
                << std::endl;

        closeSocket(fd);
        running_.store(false);
        return false;
    }

    listenFd_.store(fd);

    boundPort_.store(
            ntohs(actualAddress.sin_port));

    try {
        worker_ =
                std::thread(
                        &HnclNavigationServer::workerMain,
                        this);
    } catch (...) {
        listenFd_.store(-1);
        boundPort_.store(0);
        running_.store(false);
        closeSocket(fd);
        throw;
    }

    std::cout
            << "HNCL: listening on 0.0.0.0:"
            << boundPort_.load()
            << std::endl;

    return true;
}

void HnclNavigationServer::stop()
{
    running_.store(false);

    if (worker_.joinable()) {
        worker_.join();
    }

    boundPort_.store(0);
    clientFd_.store(-1);
    listenFd_.store(-1);
}

bool HnclNavigationServer::isRunning() const
{
    return running_.load();
}

std::uint16_t HnclNavigationServer::boundPort() const
{
    return boundPort_.load();
}

void HnclNavigationServer::workerMain()
{
    const int serverFd =
            listenFd_.load();

    while (running_.load()) {

        pollfd descriptor{};
        descriptor.fd = serverFd;
        descriptor.events = POLLIN;

        const int result =
                ::poll(
                        &descriptor,
                        1,
                        kAcceptPollTimeoutMs);

        if (result < 0) {
            if (errno == EINTR) {
                continue;
            }

            std::cerr
                    << "HNCL: "
                    << socketError("poll(listen)")
                    << std::endl;

            break;
        }

        if (result == 0) {
            continue;
        }

        if ((descriptor.revents
                & (POLLERR | POLLNVAL)) != 0) {
            std::cerr
                    << "HNCL: listening socket failed"
                    << std::endl;
            break;
        }

        if ((descriptor.revents & POLLIN) == 0) {
            continue;
        }

        sockaddr_in peer{};
        socklen_t peerLength =
                sizeof(peer);

        const int accepted =
                ::accept(
                        serverFd,
                        reinterpret_cast<sockaddr*>(&peer),
                        &peerLength);

        if (accepted < 0) {
            if (errno == EINTR) {
                continue;
            }

            if (running_.load()) {
                std::cerr
                        << "HNCL: "
                        << socketError("accept")
                        << std::endl;
            }

            continue;
        }

        int enabled = 1;

        static_cast<void>(
                ::setsockopt(
                        accepted,
                        IPPROTO_TCP,
                        TCP_NODELAY,
                        &enabled,
                        sizeof(enabled)));

        static_cast<void>(
                ::setsockopt(
                        accepted,
                        SOL_SOCKET,
                        SO_KEEPALIVE,
                        &enabled,
                        sizeof(enabled)));

        clientFd_.store(accepted);

        char peerAddress[INET_ADDRSTRLEN] = {};

        const char* addressText =
                ::inet_ntop(
                        AF_INET,
                        &peer.sin_addr,
                        peerAddress,
                        sizeof(peerAddress));

        std::cout
                << "HNCL: Android client connected from "
                << (addressText != nullptr
                        ? addressText
                        : "unknown")
                << ":"
                << ntohs(peer.sin_port)
                << std::endl;

        try {
            runClient(accepted);
        } catch (const hncl::ProtocolError& error) {
            std::cerr
                    << "HNCL: protocol error: "
                    << error.what()
                    << std::endl;
        } catch (const std::exception& error) {
            std::cerr
                    << "HNCL: client session error: "
                    << error.what()
                    << std::endl;
        }

        closeSocket(accepted);
        clientFd_.store(-1);
    }

    const int fd =
            listenFd_.exchange(-1);

    closeSocket(fd);

    running_.store(false);
}

void HnclNavigationServer::runClient(int clientFd)
{
    std::vector<std::uint8_t> receiveBuffer;
    receiveBuffer.reserve(kMaximumBufferedBytes);

    bool handshakeComplete = false;

    auto disconnectNotification =
            [&]() {
                if (handshakeComplete) {
                    handshakeComplete = false;
                    notifyClientState(false);
                }
            };

    try {
        while (running_.load()) {

            pollfd descriptor{};
            descriptor.fd = clientFd;
            descriptor.events = POLLIN;

            const int result =
                    ::poll(
                            &descriptor,
                            1,
                            kClientPollTimeoutMs);

            if (result < 0) {
                if (errno == EINTR) {
                    continue;
                }

                throw std::runtime_error(
                        socketError("poll(client)"));
            }

            if (result == 0) {
                continue;
            }

            if ((descriptor.revents
                    & (POLLERR | POLLNVAL)) != 0) {
                break;
            }

            if ((descriptor.revents & POLLIN) == 0) {
                if ((descriptor.revents & POLLHUP) != 0) {
                    break;
                }

                continue;
            }

            std::uint8_t chunk[kReceiveChunkSize];

            const ssize_t received =
                    ::recv(
                            clientFd,
                            chunk,
                            sizeof(chunk),
                            0);

            if (received == 0) {
                break;
            }

            if (received < 0) {
                if (errno == EINTR) {
                    continue;
                }

                throw std::runtime_error(
                        socketError("recv"));
            }

            receiveBuffer.insert(
                    receiveBuffer.end(),
                    chunk,
                    chunk
                            + static_cast<std::size_t>(
                                    received));

            std::size_t consumedTotal = 0;

            while (consumedTotal
                    < receiveBuffer.size()) {

                hncl::Frame frame;
                std::size_t consumed = 0;

                const hncl::DecodeStatus status =
                        hncl::tryDecode(
                                receiveBuffer.data()
                                        + consumedTotal,
                                receiveBuffer.size()
                                        - consumedTotal,
                                frame,
                                consumed);

                if (status
                        == hncl::DecodeStatus::NeedMore) {
                    break;
                }

                if (!handshakeComplete) {

                    if (frame.type
                            != hncl::kTypeHello) {
                        throw hncl::ProtocolError(
                                "HELLO required before other HNCL messages");
                    }

                    const hncl::HelloInfo hello =
                            hncl::decodeHelloPayload(
                                    frame.payload);

                    if (hello.version
                            != hncl::kVersion) {
                        throw hncl::ProtocolError(
                                "Android HNCL version mismatch");
                    }

                    if ((hello.capabilities
                            & hncl::kNavigationCapability)
                            == 0U) {
                        throw hncl::ProtocolError(
                                "Android does not advertise navigation capability");
                    }

                    if (!sendFrame(
                            clientFd,
                            hncl::kTypeHelloAck,
                            frame.correlationId,
                            hncl::helloAckPayload())) {
                        throw std::runtime_error(
                                "failed to send HELLO_ACK");
                    }

                    handshakeComplete = true;
                    notifyClientState(true);

                    std::cout
                            << "HNCL: session ready"
                            << std::endl;

                } else {

                    switch (frame.type) {

                    case hncl::kTypePing:
                        if (!frame.payload.empty()) {
                            throw hncl::ProtocolError(
                                    "PING payload must be empty");
                        }

                        if (!sendFrame(
                                clientFd,
                                hncl::kTypePong,
                                frame.correlationId)) {
                            throw std::runtime_error(
                                    "failed to send PONG");
                        }
                        break;

                    case hncl::kTypeNavigationState: {
                        const hncl::NavigationState state =
                                hncl::decodeNavigationStatePayload(
                                        frame.payload);

                        notifyNavigationState(state);
                        break;
                    }

                    case hncl::kTypeNavigationClear:
                        if (!frame.payload.empty()) {
                            throw hncl::ProtocolError(
                                    "NAVIGATION_CLEAR payload must be empty");
                        }

                        notifyNavigationClear();
                        break;

                    case hncl::kTypeHello:
                        throw hncl::ProtocolError(
                                "duplicate HELLO after handshake");

                    default:
                        throw hncl::ProtocolError(
                                "unexpected HNCL message type "
                                + std::to_string(frame.type));
                    }
                }

                consumedTotal += consumed;
            }

            if (consumedTotal > 0) {
                receiveBuffer.erase(
                        receiveBuffer.begin(),
                        receiveBuffer.begin()
                                + static_cast<std::ptrdiff_t>(
                                        consumedTotal));
            }

            if (receiveBuffer.size()
                    > kMaximumBufferedBytes) {
                throw hncl::ProtocolError(
                        "HNCL receive buffer exhausted");
            }
        }

        disconnectNotification();

    } catch (...) {
        disconnectNotification();
        throw;
    }
}

bool HnclNavigationServer::sendFrame(
        int fd,
        std::uint8_t type,
        std::uint32_t correlationId,
        const std::vector<std::uint8_t>& payload)
{
    const auto encoded =
            hncl::encodeFrame(
                    type,
                    correlationId,
                    payload);

    return sendAll(
            fd,
            encoded.data(),
            encoded.size());
}

bool HnclNavigationServer::sendAll(
        int fd,
        const std::uint8_t* data,
        std::size_t size)
{
    std::size_t sentTotal = 0;

    while (sentTotal < size) {

        int flags = 0;

#ifdef MSG_NOSIGNAL
        flags |= MSG_NOSIGNAL;
#endif

        const ssize_t sent =
                ::send(
                        fd,
                        data + sentTotal,
                        size - sentTotal,
                        flags);

        if (sent < 0) {
            if (errno == EINTR) {
                continue;
            }

            return false;
        }

        if (sent == 0) {
            return false;
        }

        sentTotal +=
                static_cast<std::size_t>(sent);
    }

    return true;
}

void HnclNavigationServer::notifyClientState(
        bool connected)
{
    if (!listener_.onClientConnectionChanged) {
        return;
    }

    try {
        listener_.onClientConnectionChanged(
                connected);
    } catch (const std::exception& error) {
        std::cerr
                << "HNCL: connection callback failed: "
                << error.what()
                << std::endl;
    } catch (...) {
        std::cerr
                << "HNCL: connection callback failed"
                << std::endl;
    }
}

void HnclNavigationServer::notifyNavigationState(
        const hncl::NavigationState& state)
{
    if (!listener_.onNavigationState) {
        return;
    }

    try {
        listener_.onNavigationState(state);
    } catch (const std::exception& error) {
        std::cerr
                << "HNCL: navigation callback failed: "
                << error.what()
                << std::endl;
    } catch (...) {
        std::cerr
                << "HNCL: navigation callback failed"
                << std::endl;
    }
}

void HnclNavigationServer::notifyNavigationClear()
{
    if (!listener_.onNavigationClear) {
        return;
    }

    try {
        listener_.onNavigationClear();
    } catch (const std::exception& error) {
        std::cerr
                << "HNCL: clear callback failed: "
                << error.what()
                << std::endl;
    } catch (...) {
        std::cerr
                << "HNCL: clear callback failed"
                << std::endl;
    }
}

} // namespace hypernova::cluster
