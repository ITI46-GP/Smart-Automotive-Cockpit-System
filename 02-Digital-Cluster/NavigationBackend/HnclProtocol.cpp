#include "HnclProtocol.hpp"

#include <limits>

namespace hypernova::cluster::hncl {
namespace {

std::uint16_t readU16(const std::uint8_t* data)
{
    return static_cast<std::uint16_t>(
            (static_cast<std::uint16_t>(data[0]) << 8U)
            | static_cast<std::uint16_t>(data[1]));
}

std::uint32_t readU32(const std::uint8_t* data)
{
    return
            (static_cast<std::uint32_t>(data[0]) << 24U)
            | (static_cast<std::uint32_t>(data[1]) << 16U)
            | (static_cast<std::uint32_t>(data[2]) << 8U)
            | static_cast<std::uint32_t>(data[3]);
}

std::uint64_t readU64(const std::uint8_t* data)
{
    std::uint64_t value = 0;

    for (std::size_t index = 0; index < 8; ++index) {
        value =
                (value << 8U)
                | static_cast<std::uint64_t>(data[index]);
    }

    return value;
}

std::int32_t readI32(const std::uint8_t* data)
{
    return static_cast<std::int32_t>(readU32(data));
}

void appendU16(
        std::vector<std::uint8_t>& output,
        std::uint16_t value)
{
    output.push_back(
            static_cast<std::uint8_t>((value >> 8U) & 0xFFU));
    output.push_back(
            static_cast<std::uint8_t>(value & 0xFFU));
}

void appendU32(
        std::vector<std::uint8_t>& output,
        std::uint32_t value)
{
    output.push_back(
            static_cast<std::uint8_t>((value >> 24U) & 0xFFU));
    output.push_back(
            static_cast<std::uint8_t>((value >> 16U) & 0xFFU));
    output.push_back(
            static_cast<std::uint8_t>((value >> 8U) & 0xFFU));
    output.push_back(
            static_cast<std::uint8_t>(value & 0xFFU));
}

} // namespace

std::vector<std::uint8_t> encodeFrame(
        std::uint8_t type,
        std::uint32_t correlationId,
        const std::vector<std::uint8_t>& payload)
{
    if (payload.size() > kMaxPayload) {
        throw ProtocolError("payload exceeds HNCL limit");
    }

    std::vector<std::uint8_t> output;
    output.reserve(kHeaderSize + payload.size());

    appendU32(output, kMagic);

    output.push_back(kVersion);
    output.push_back(type);

    appendU16(output, 0); // flags
    appendU32(output, correlationId);

    appendU16(
            output,
            static_cast<std::uint16_t>(payload.size()));

    appendU16(output, 0); // reserved

    output.insert(
            output.end(),
            payload.begin(),
            payload.end());

    return output;
}

DecodeStatus tryDecode(
        const std::uint8_t* data,
        std::size_t length,
        Frame& frame,
        std::size_t& consumed)
{
    consumed = 0;

    if (length < kHeaderSize) {
        return DecodeStatus::NeedMore;
    }

    if (data == nullptr) {
        throw ProtocolError("null HNCL input buffer");
    }

    if (readU32(data) != kMagic) {
        throw ProtocolError("invalid HNCL magic");
    }

    const std::uint8_t version = data[4];
    const std::uint8_t type = data[5];
    const std::uint16_t flags = readU16(data + 6);
    const std::uint32_t correlationId = readU32(data + 8);
    const std::uint16_t payloadLength = readU16(data + 12);
    const std::uint16_t reserved = readU16(data + 14);

    if (version != kVersion) {
        throw ProtocolError("unsupported HNCL version");
    }

    if (flags != 0 || reserved != 0) {
        throw ProtocolError("non-zero HNCL reserved fields");
    }

    if (payloadLength > kMaxPayload) {
        throw ProtocolError("payload exceeds HNCL limit");
    }

    const std::size_t totalLength =
            kHeaderSize
            + static_cast<std::size_t>(payloadLength);

    if (length < totalLength) {
        return DecodeStatus::NeedMore;
    }

    frame.type = type;
    frame.correlationId = correlationId;

    frame.payload.assign(
            data + kHeaderSize,
            data + totalLength);

    consumed = totalLength;

    return DecodeStatus::Complete;
}

HelloInfo decodeHelloPayload(
        const std::vector<std::uint8_t>& payload)
{
    if (payload.size() != 6) {
        throw ProtocolError(
                "HELLO payload must contain exactly 6 bytes");
    }

    HelloInfo result;
    result.version = readU16(payload.data());
    result.capabilities = readU32(payload.data() + 2);

    return result;
}

std::vector<std::uint8_t> helloAckPayload()
{
    std::vector<std::uint8_t> payload;
    payload.reserve(6);

    appendU16(payload, kVersion);
    appendU32(payload, kNavigationCapability);

    return payload;
}

NavigationState decodeNavigationStatePayload(
        const std::vector<std::uint8_t>& payload)
{
    if (payload.size() < kFixedNavigationPayloadSize) {
        throw ProtocolError(
                "navigation payload shorter than HNCL fixed fields");
    }

    NavigationState state;

    std::size_t offset = 0;

    auto requireBytes =
            [&](std::size_t count) {
                if (count > payload.size() - offset) {
                    throw ProtocolError(
                            "truncated HNCL navigation payload");
                }
            };

    requireBytes(1);

    const std::uint8_t active = payload[offset++];

    if (active > 1) {
        throw ProtocolError(
                "navigation active field must be 0 or 1");
    }

    state.active = active != 0;

    requireBytes(1);
    state.maneuver = payload[offset++];

    requireBytes(2);
    state.speedLimitKph = readU16(payload.data() + offset);
    offset += 2;

    requireBytes(4);
    state.distanceToManeuverMeters =
            readU32(payload.data() + offset);
    offset += 4;

    requireBytes(4);
    state.remainingDistanceMeters =
            readU32(payload.data() + offset);
    offset += 4;

    requireBytes(4);
    state.remainingTimeSeconds =
            readU32(payload.data() + offset);
    offset += 4;

    requireBytes(8);
    state.etaEpochSeconds =
            readU64(payload.data() + offset);
    offset += 8;

    requireBytes(4);
    state.latitudeE7 =
            readI32(payload.data() + offset);
    offset += 4;

    requireBytes(4);
    state.longitudeE7 =
            readI32(payload.data() + offset);
    offset += 4;

    requireBytes(2);
    state.headingCentiDegrees =
            readU16(payload.data() + offset);
    offset += 2;

    if (state.headingCentiDegrees > 36000U) {
        throw ProtocolError(
                "navigation heading exceeds 360 degrees");
    }

    requireBytes(2);

    const std::uint16_t streetLength =
            readU16(payload.data() + offset);
    offset += 2;

    if (streetLength > kMaxTextBytes) {
        throw ProtocolError(
                "street name exceeds HNCL text limit");
    }

    requireBytes(
            static_cast<std::size_t>(streetLength) + 2U);

    state.streetName.assign(
            reinterpret_cast<const char*>(
                    payload.data() + offset),
            streetLength);

    offset += streetLength;

    const std::uint16_t destinationLength =
            readU16(payload.data() + offset);
    offset += 2;

    if (destinationLength > kMaxTextBytes) {
        throw ProtocolError(
                "destination exceeds HNCL text limit");
    }

    requireBytes(destinationLength);

    state.destination.assign(
            reinterpret_cast<const char*>(
                    payload.data() + offset),
            destinationLength);

    offset += destinationLength;

    if (offset != payload.size()) {
        throw ProtocolError(
                "unexpected trailing navigation payload bytes");
    }

    const double latitude =
            state.latitudeDegrees();

    const double longitude =
            state.longitudeDegrees();

    if (latitude < -90.0 || latitude > 90.0) {
        throw ProtocolError(
                "navigation latitude out of range");
    }

    if (longitude < -180.0 || longitude > 180.0) {
        throw ProtocolError(
                "navigation longitude out of range");
    }

    return state;
}

} // namespace hypernova::cluster::hncl
