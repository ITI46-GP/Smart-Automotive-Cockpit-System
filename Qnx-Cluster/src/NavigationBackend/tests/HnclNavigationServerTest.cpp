#include "../HnclNavigationServer.hpp"

#include <arpa/inet.h>
#include <atomic>
#include <chrono>
#include <cmath>
#include <cstdint>
#include <cstring>
#include <iostream>
#include <mutex>
#include <netinet/in.h>
#include <poll.h>
#include <stdexcept>
#include <string>
#include <sys/socket.h>
#include <thread>
#include <unistd.h>
#include <vector>

using namespace hypernova::cluster;
using namespace hypernova::cluster::hncl;

namespace {

void expect(
        bool condition,
        const std::string& message)
{
    if (!condition) {
        throw std::runtime_error(
                "TEST FAILED: " + message);
    }
}

void appendU16(
        std::vector<std::uint8_t>& output,
        std::uint16_t value)
{
    output.push_back(
            static_cast<std::uint8_t>(
                    (value >> 8U) & 0xFFU));

    output.push_back(
            static_cast<std::uint8_t>(
                    value & 0xFFU));
}

void appendU32(
        std::vector<std::uint8_t>& output,
        std::uint32_t value)
{
    output.push_back(
            static_cast<std::uint8_t>(
                    (value >> 24U) & 0xFFU));

    output.push_back(
            static_cast<std::uint8_t>(
                    (value >> 16U) & 0xFFU));

    output.push_back(
            static_cast<std::uint8_t>(
                    (value >> 8U) & 0xFFU));

    output.push_back(
            static_cast<std::uint8_t>(
                    value & 0xFFU));
}

void appendU64(
        std::vector<std::uint8_t>& output,
        std::uint64_t value)
{
    for (int shift = 56; shift >= 0; shift -= 8) {
        output.push_back(
                static_cast<std::uint8_t>(
                        (value
                                >> static_cast<unsigned>(shift))
                        & 0xFFU));
    }
}

void appendI32(
        std::vector<std::uint8_t>& output,
        std::int32_t value)
{
    appendU32(
            output,
            static_cast<std::uint32_t>(value));
}

void appendText(
        std::vector<std::uint8_t>& output,
        const std::string& value)
{
    appendU16(
            output,
            static_cast<std::uint16_t>(
                    value.size()));

    output.insert(
            output.end(),
            value.begin(),
            value.end());
}

std::vector<std::uint8_t> navigationPayload()
{
    std::vector<std::uint8_t> payload;

    payload.push_back(1);
    payload.push_back(kManeuverTurnRight);

    appendU16(
            payload,
            kUnknownSpeedLimit);

    appendU32(payload, 250);
    appendU32(payload, 12'345);
    appendU32(payload, 720);

    appendU64(
            payload,
            1'800'000'000ULL);

    appendI32(
            payload,
            300'712'345);

    appendI32(
            payload,
            310'176'543);

    appendU16(payload, 9'550);

    appendText(
            payload,
            "Sheikh Zayed Road");

    appendText(
            payload,
            "Smart Village");

    return payload;
}

bool sendAll(
        int fd,
        const std::uint8_t* data,
        std::size_t size)
{
    std::size_t total = 0;

    while (total < size) {
        const ssize_t result =
                ::send(
                        fd,
                        data + total,
                        size - total,
                        0);

        if (result <= 0) {
            return false;
        }

        total +=
                static_cast<std::size_t>(
                        result);
    }

    return true;
}

Frame receiveFrame(
        int fd)
{
    std::vector<std::uint8_t> buffer;

    const auto deadline =
            std::chrono::steady_clock::now()
            + std::chrono::seconds(2);

    while (std::chrono::steady_clock::now()
            < deadline) {

        Frame frame;
        std::size_t consumed = 0;

        if (!buffer.empty()) {
            const DecodeStatus status =
                    tryDecode(
                            buffer.data(),
                            buffer.size(),
                            frame,
                            consumed);

            if (status
                    == DecodeStatus::Complete) {
                return frame;
            }
        }

        pollfd descriptor{};
        descriptor.fd = fd;
        descriptor.events = POLLIN;

        const int pollResult =
                ::poll(
                        &descriptor,
                        1,
                        100);

        if (pollResult < 0) {
            throw std::runtime_error(
                    "client poll failed");
        }

        if (pollResult == 0) {
            continue;
        }

        std::uint8_t chunk[1024];

        const ssize_t count =
                ::recv(
                        fd,
                        chunk,
                        sizeof(chunk),
                        0);

        if (count <= 0) {
            throw std::runtime_error(
                    "server closed test connection");
        }

        buffer.insert(
                buffer.end(),
                chunk,
                chunk
                        + static_cast<std::size_t>(
                                count));
    }

    throw std::runtime_error(
            "timed out waiting for HNCL response");
}

template <typename Predicate>
bool waitUntil(
        Predicate predicate,
        std::chrono::milliseconds timeout =
                std::chrono::milliseconds(2000))
{
    const auto deadline =
            std::chrono::steady_clock::now()
            + timeout;

    while (std::chrono::steady_clock::now()
            < deadline) {

        if (predicate()) {
            return true;
        }

        std::this_thread::sleep_for(
                std::chrono::milliseconds(10));
    }

    return predicate();
}

} // namespace

int main()
{
    int clientFd = -1;

    try {
        std::atomic<int> connectionEvents{0};
        std::atomic<bool> connected{false};
        std::atomic<int> navigationEvents{0};
        std::atomic<int> clearEvents{0};

        std::mutex stateMutex;
        NavigationState lastState;

        HnclNavigationServer server(
                0,
                {
                    [&](bool value) {
                        connected.store(value);
                        connectionEvents.fetch_add(1);
                    },

                    [&](const NavigationState& state) {
                        {
                            std::lock_guard<std::mutex> lock(
                                    stateMutex);

                            lastState = state;
                        }

                        navigationEvents.fetch_add(1);
                    },

                    [&]() {
                        clearEvents.fetch_add(1);
                    }
                });

        expect(
                server.start(),
                "server must start");

        expect(
                server.boundPort() != 0,
                "ephemeral server port must resolve");

        clientFd =
                ::socket(
                        AF_INET,
                        SOCK_STREAM,
                        0);

        expect(
                clientFd >= 0,
                "client socket");

        sockaddr_in address{};
        address.sin_family = AF_INET;
        address.sin_port =
                htons(server.boundPort());

        expect(
                ::inet_pton(
                        AF_INET,
                        "127.0.0.1",
                        &address.sin_addr) == 1,
                "localhost address");

        expect(
                ::connect(
                        clientFd,
                        reinterpret_cast<sockaddr*>(
                                &address),
                        sizeof(address)) == 0,
                "connect to HNCL server");

        /*
         * Exact Android HNCL v1 HELLO frame:
         *
         * HNCL
         * version=1
         * type=HELLO
         * flags=0
         * correlation=0
         * payloadLength=6
         * reserved=0
         * protocolVersion=1
         * navigationCapability=1
         */
        const std::vector<std::uint8_t>
                androidHello = {
                    0x48, 0x4E, 0x43, 0x4C,
                    0x01,
                    0x01,
                    0x00, 0x00,
                    0x00, 0x00, 0x00, 0x00,
                    0x00, 0x06,
                    0x00, 0x00,
                    0x00, 0x01,
                    0x00, 0x00, 0x00, 0x01
                };

        expect(
                sendAll(
                        clientFd,
                        androidHello.data(),
                        androidHello.size()),
                "send Android HELLO");

        const Frame helloAck =
                receiveFrame(clientFd);

        expect(
                helloAck.type
                        == kTypeHelloAck,
                "server must send HELLO_ACK");

        expect(
                helloAck.payload
                        == helloAckPayload(),
                "HELLO_ACK capability payload");

        expect(
                waitUntil(
                        [&]() {
                            return connected.load();
                        }),
                "server connection-ready callback");

        const auto ping =
                encodeFrame(
                        kTypePing,
                        1234);

        expect(
                sendAll(
                        clientFd,
                        ping.data(),
                        ping.size()),
                "send PING");

        const Frame pong =
                receiveFrame(clientFd);

        expect(
                pong.type == kTypePong,
                "server must return PONG");

        expect(
                pong.correlationId == 1234,
                "PONG correlation");

        const auto navigation =
                encodeFrame(
                        kTypeNavigationState,
                        0,
                        navigationPayload());

        /*
         * Deliberately fragment one Android navigation frame across
         * multiple TCP writes.
         */
        expect(
                sendAll(
                        clientFd,
                        navigation.data(),
                        7),
                "send navigation fragment one");

        std::this_thread::sleep_for(
                std::chrono::milliseconds(30));

        expect(
                sendAll(
                        clientFd,
                        navigation.data() + 7,
                        navigation.size() - 7),
                "send navigation fragment two");

        expect(
                waitUntil(
                        [&]() {
                            return navigationEvents.load()
                                    == 1;
                        }),
                "navigation callback");

        {
            std::lock_guard<std::mutex> lock(
                    stateMutex);

            expect(
                    lastState.active,
                    "active state");

            expect(
                    lastState.maneuver
                            == kManeuverTurnRight,
                    "maneuver");

            expect(
                    lastState.remainingDistanceMeters
                            == 12'345,
                    "remaining distance");

            expect(
                    lastState.remainingTimeSeconds
                            == 720,
                    "remaining time");

            expect(
                    std::abs(
                            lastState.latitudeDegrees()
                            - 30.0712345)
                            < 0.00000001,
                    "latitude");

            expect(
                    std::abs(
                            lastState.longitudeDegrees()
                            - 31.0176543)
                            < 0.00000001,
                    "longitude");

            expect(
                    std::abs(
                            lastState.headingDegrees()
                            - 95.5)
                            < 0.001,
                    "heading");

            expect(
                    lastState.streetName
                            == "Sheikh Zayed Road",
                    "street");

            expect(
                    lastState.destination
                            == "Smart Village",
                    "destination");
        }

        const auto clear =
                encodeFrame(
                        kTypeNavigationClear,
                        0);

        expect(
                sendAll(
                        clientFd,
                        clear.data(),
                        clear.size()),
                "send NAVIGATION_CLEAR");

        expect(
                waitUntil(
                        [&]() {
                            return clearEvents.load()
                                    == 1;
                        }),
                "clear callback");

        ::shutdown(
                clientFd,
                SHUT_RDWR);

        ::close(clientFd);
        clientFd = -1;

        expect(
                waitUntil(
                        [&]() {
                            return !connected.load();
                        }),
                "disconnect callback");

        server.stop();

        expect(
                connectionEvents.load() >= 2,
                "connect and disconnect events");

        std::cout
                << "PASS: HNCL TCP server tests"
                << std::endl;

        std::cout
                << "PASS: Android HELLO -> HELLO_ACK"
                << std::endl;

        std::cout
                << "PASS: PING -> PONG"
                << std::endl;

        std::cout
                << "PASS: fragmented NAVIGATION_STATE"
                << std::endl;

        std::cout
                << "PASS: NAVIGATION_CLEAR"
                << std::endl;

        std::cout
                << "PASS: connection lifecycle"
                << std::endl;

        return 0;

    } catch (const std::exception& error) {

        if (clientFd >= 0) {
            ::close(clientFd);
        }

        std::cerr
                << error.what()
                << std::endl;

        return 1;
    }
}
