#pragma once

#include <cstddef>
#include <cstdint>
#include <stdexcept>
#include <string>
#include <vector>

namespace hypernova::cluster::hncl {

constexpr std::uint32_t kMagic = 0x484E434C; // "HNCL"
constexpr std::uint8_t kVersion = 1;

constexpr std::size_t kHeaderSize = 16;
constexpr std::size_t kMaxPayload = 4096;
constexpr std::size_t kMaxTextBytes = 1024;

constexpr std::uint32_t kNavigationCapability = 0x00000001;

constexpr std::uint8_t kTypeHello = 0x01;
constexpr std::uint8_t kTypePing = 0x02;

constexpr std::uint8_t kTypeNavigationState = 0x10;
constexpr std::uint8_t kTypeNavigationClear = 0x11;

constexpr std::uint8_t kTypeHelloAck = 0x81;
constexpr std::uint8_t kTypePong = 0x82;

constexpr std::uint8_t kManeuverUnknown = 0;
constexpr std::uint8_t kManeuverStraight = 1;
constexpr std::uint8_t kManeuverTurnLeft = 2;
constexpr std::uint8_t kManeuverTurnRight = 3;
constexpr std::uint8_t kManeuverSlightLeft = 4;
constexpr std::uint8_t kManeuverSlightRight = 5;
constexpr std::uint8_t kManeuverSharpLeft = 6;
constexpr std::uint8_t kManeuverSharpRight = 7;
constexpr std::uint8_t kManeuverUturn = 8;
constexpr std::uint8_t kManeuverRoundabout = 9;
constexpr std::uint8_t kManeuverArrive = 10;

constexpr std::uint16_t kUnknownSpeedLimit = 0xFFFF;
constexpr std::size_t kFixedNavigationPayloadSize = 38;

class ProtocolError final : public std::runtime_error {
public:
    explicit ProtocolError(const std::string& message)
        : std::runtime_error(message)
    {
    }
};

struct Frame {
    std::uint8_t type = 0;
    std::uint32_t correlationId = 0;
    std::vector<std::uint8_t> payload;
};

enum class DecodeStatus {
    NeedMore,
    Complete
};

struct HelloInfo {
    std::uint16_t version = 0;
    std::uint32_t capabilities = 0;
};

struct NavigationState {
    bool active = false;
    std::uint8_t maneuver = kManeuverUnknown;
    std::uint16_t speedLimitKph = kUnknownSpeedLimit;

    std::uint32_t distanceToManeuverMeters = 0;
    std::uint32_t remainingDistanceMeters = 0;
    std::uint32_t remainingTimeSeconds = 0;

    std::uint64_t etaEpochSeconds = 0;

    std::int32_t latitudeE7 = 0;
    std::int32_t longitudeE7 = 0;

    std::uint16_t headingCentiDegrees = 0;

    std::string streetName;
    std::string destination;

    double latitudeDegrees() const
    {
        return static_cast<double>(latitudeE7) / 10'000'000.0;
    }

    double longitudeDegrees() const
    {
        return static_cast<double>(longitudeE7) / 10'000'000.0;
    }

    double headingDegrees() const
    {
        return static_cast<double>(headingCentiDegrees) / 100.0;
    }

    bool hasKnownSpeedLimit() const
    {
        return speedLimitKph != kUnknownSpeedLimit;
    }
};

std::vector<std::uint8_t> encodeFrame(
        std::uint8_t type,
        std::uint32_t correlationId,
        const std::vector<std::uint8_t>& payload = {});

DecodeStatus tryDecode(
        const std::uint8_t* data,
        std::size_t length,
        Frame& frame,
        std::size_t& consumed);

HelloInfo decodeHelloPayload(
        const std::vector<std::uint8_t>& payload);

std::vector<std::uint8_t> helloAckPayload();

NavigationState decodeNavigationStatePayload(
        const std::vector<std::uint8_t>& payload);

} // namespace hypernova::cluster::hncl
