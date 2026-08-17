#include "../HnclProtocol.hpp"

#include <cmath>
#include <cstdint>
#include <iostream>
#include <stdexcept>
#include <string>
#include <vector>

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
    expect(
            value.size() <= 0xFFFFU,
            "test string must fit uint16");

    appendU16(
            output,
            static_cast<std::uint16_t>(value.size()));

    output.insert(
            output.end(),
            value.begin(),
            value.end());
}

std::vector<std::uint8_t> makeNavigationPayload()
{
    std::vector<std::uint8_t> payload;

    payload.push_back(1); // active
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

    appendU16(
            payload,
            9'550);

    appendText(
            payload,
            "Sheikh Zayed Road");

    appendText(
            payload,
            "Smart Village");

    return payload;
}

void testFragmentedFrame()
{
    const auto frameBytes =
            encodeFrame(
                    kTypeNavigationState,
                    42,
                    makeNavigationPayload());

    Frame frame;
    std::size_t consumed = 0;

    const DecodeStatus status =
            tryDecode(
                    frameBytes.data(),
                    kHeaderSize + 1,
                    frame,
                    consumed);

    expect(
            status == DecodeStatus::NeedMore,
            "fragmented frame must wait");

    expect(
            consumed == 0,
            "fragmented frame must consume zero bytes");
}

void testMergedFrames()
{
    const auto first =
            encodeFrame(
                    kTypePing,
                    100);

    const auto second =
            encodeFrame(
                    kTypeNavigationClear,
                    200);

    std::vector<std::uint8_t> merged = first;

    merged.insert(
            merged.end(),
            second.begin(),
            second.end());

    Frame frame;
    std::size_t consumed = 0;

    expect(
            tryDecode(
                    merged.data(),
                    merged.size(),
                    frame,
                    consumed)
                    == DecodeStatus::Complete,
            "first merged frame must decode");

    expect(
            frame.type == kTypePing,
            "first merged frame type");

    expect(
            frame.correlationId == 100,
            "first merged correlation");

    expect(
            consumed == first.size(),
            "decoder must consume exactly one frame");

    Frame secondFrame;
    std::size_t secondConsumed = 0;

    expect(
            tryDecode(
                    merged.data() + consumed,
                    merged.size() - consumed,
                    secondFrame,
                    secondConsumed)
                    == DecodeStatus::Complete,
            "second merged frame must decode");

    expect(
            secondFrame.type
                    == kTypeNavigationClear,
            "second merged frame type");

    expect(
            secondFrame.correlationId == 200,
            "second merged correlation");
}

void testNavigationState()
{
    const auto payload =
            makeNavigationPayload();

    const NavigationState state =
            decodeNavigationStatePayload(payload);

    expect(
            state.active,
            "navigation must be active");

    expect(
            state.maneuver
                    == kManeuverTurnRight,
            "maneuver must decode");

    expect(
            state.speedLimitKph
                    == kUnknownSpeedLimit,
            "unknown speed limit sentinel");

    expect(
            !state.hasKnownSpeedLimit(),
            "unknown speed limit helper");

    expect(
            state.distanceToManeuverMeters
                    == 250,
            "distance to maneuver");

    expect(
            state.remainingDistanceMeters
                    == 12'345,
            "remaining distance");

    expect(
            state.remainingTimeSeconds
                    == 720,
            "remaining time");

    expect(
            state.etaEpochSeconds
                    == 1'800'000'000ULL,
            "ETA epoch");

    expect(
            state.latitudeE7
                    == 300'712'345,
            "latitude E7");

    expect(
            state.longitudeE7
                    == 310'176'543,
            "longitude E7");

    expect(
            std::abs(
                    state.latitudeDegrees()
                    - 30.0712345)
                    < 0.00000001,
            "latitude degrees");

    expect(
            std::abs(
                    state.longitudeDegrees()
                    - 31.0176543)
                    < 0.00000001,
            "longitude degrees");

    expect(
            std::abs(
                    state.headingDegrees()
                    - 95.5)
                    < 0.001,
            "heading");

    expect(
            state.streetName
                    == "Sheikh Zayed Road",
            "street name");

    expect(
            state.destination
                    == "Smart Village",
            "destination");
}

void testHelloHandshake()
{
    const std::vector<std::uint8_t> hello = {
            0x00,
            0x01,
            0x00,
            0x00,
            0x00,
            0x01
    };

    const HelloInfo info =
            decodeHelloPayload(hello);

    expect(
            info.version == kVersion,
            "HELLO protocol version");

    expect(
            (info.capabilities
                    & kNavigationCapability)
                    != 0,
            "HELLO navigation capability");

    const auto ackPayload =
            helloAckPayload();

    expect(
            ackPayload == hello,
            "HELLO_ACK payload must mirror v1 navigation capability");

    const auto ackFrame =
            encodeFrame(
                    kTypeHelloAck,
                    0,
                    ackPayload);

    Frame decoded;
    std::size_t consumed = 0;

    expect(
            tryDecode(
                    ackFrame.data(),
                    ackFrame.size(),
                    decoded,
                    consumed)
                    == DecodeStatus::Complete,
            "HELLO_ACK frame must decode");

    expect(
            decoded.type == kTypeHelloAck,
            "HELLO_ACK type");

    expect(
            decoded.payload.size() == 6,
            "HELLO_ACK payload length");
}

void testInvalidMagic()
{
    auto frame =
            encodeFrame(
                    kTypePing,
                    0);

    frame[0] = 0x00;

    Frame decoded;
    std::size_t consumed = 0;

    bool threw = false;

    try {
        static_cast<void>(
                tryDecode(
                        frame.data(),
                        frame.size(),
                        decoded,
                        consumed));
    } catch (const ProtocolError&) {
        threw = true;
    }

    expect(
            threw,
            "bad magic must throw ProtocolError");
}

void testClearFrame()
{
    const auto encoded =
            encodeFrame(
                    kTypeNavigationClear,
                    0);

    Frame decoded;
    std::size_t consumed = 0;

    expect(
            tryDecode(
                    encoded.data(),
                    encoded.size(),
                    decoded,
                    consumed)
                    == DecodeStatus::Complete,
            "NAVIGATION_CLEAR must decode");

    expect(
            decoded.type
                    == kTypeNavigationClear,
            "NAVIGATION_CLEAR type");

    expect(
            decoded.payload.empty(),
            "NAVIGATION_CLEAR must have no payload");
}

} // namespace

int main()
{
    try {
        testFragmentedFrame();
        testMergedFrames();
        testNavigationState();
        testHelloHandshake();
        testInvalidMagic();
        testClearFrame();

        std::cout
                << "PASS: HNCL v1 protocol tests"
                << std::endl;

        std::cout
                << "PASS: frame fragmentation"
                << std::endl;

        std::cout
                << "PASS: merged frame parsing"
                << std::endl;

        std::cout
                << "PASS: HELLO / HELLO_ACK"
                << std::endl;

        std::cout
                << "PASS: NAVIGATION_STATE payload"
                << std::endl;

        std::cout
                << "PASS: NAVIGATION_CLEAR"
                << std::endl;

        return 0;

    } catch (const std::exception& error) {

        std::cerr
                << error.what()
                << std::endl;

        return 1;
    }
}
