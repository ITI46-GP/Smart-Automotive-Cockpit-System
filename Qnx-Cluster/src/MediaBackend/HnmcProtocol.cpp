#include "HnmcProtocol.hpp"

#include <algorithm>
#include <limits>

namespace hypernova::cluster::hnmc {
namespace {

std::uint16_t readU16(
        const std::uint8_t *data)
{
    return static_cast<std::uint16_t>(
            (static_cast<std::uint16_t>(data[0]) << 8)
            | static_cast<std::uint16_t>(data[1]));
}

std::uint32_t readU32(
        const std::uint8_t *data)
{
    return
            (static_cast<std::uint32_t>(data[0]) << 24)
            | (static_cast<std::uint32_t>(data[1]) << 16)
            | (static_cast<std::uint32_t>(data[2]) << 8)
            | static_cast<std::uint32_t>(data[3]);
}

std::uint64_t readU64(
        const std::uint8_t *data)
{
    std::uint64_t value = 0;

    for (int i = 0; i < 8; ++i) {
        value =
                (value << 8)
                | static_cast<std::uint64_t>(data[i]);
    }

    return value;
}

void appendU16(
        std::vector<std::uint8_t> &out,
        std::uint16_t value)
{
    out.push_back(
            static_cast<std::uint8_t>(
                    (value >> 8) & 0xFF));

    out.push_back(
            static_cast<std::uint8_t>(
                    value & 0xFF));
}

void appendU32(
        std::vector<std::uint8_t> &out,
        std::uint32_t value)
{
    out.push_back(
            static_cast<std::uint8_t>(
                    (value >> 24) & 0xFF));

    out.push_back(
            static_cast<std::uint8_t>(
                    (value >> 16) & 0xFF));

    out.push_back(
            static_cast<std::uint8_t>(
                    (value >> 8) & 0xFF));

    out.push_back(
            static_cast<std::uint8_t>(
                    value & 0xFF));
}

void requireTextLength(
        std::uint16_t length,
        const char *fieldName)
{
    if (length > kMaxTextBytes) {
        throw ProtocolError(
                std::string(fieldName)
                + " exceeds HNMC text limit");
    }
}

std::string readText(
        const std::vector<std::uint8_t> &payload,
        std::size_t &offset,
        std::size_t size,
        const char *fieldName)
{
    if (size > kMaxTextBytes) {
        throw ProtocolError(
                std::string(fieldName)
                + " exceeds HNMC text limit");
    }

    if (offset > payload.size()
            || size > payload.size() - offset) {
        throw ProtocolError(
                std::string(fieldName)
                + " is truncated");
    }

    std::string value(
            reinterpret_cast<const char *>(
                    payload.data() + offset),
            size);

    offset += size;

    return value;
}

} // namespace

std::vector<std::uint8_t> encodeFrame(
        std::uint8_t type,
        std::uint32_t correlationId,
        const std::vector<std::uint8_t> &payload)
{
    if (payload.size() > kMaxPayload) {
        throw ProtocolError(
                "HNMC payload exceeds maximum size");
    }

    if (payload.size()
            > std::numeric_limits<std::uint32_t>::max()) {
        throw ProtocolError(
                "HNMC payload cannot be represented");
    }

    std::vector<std::uint8_t> encoded;
    encoded.reserve(
            kHeaderSize + payload.size());

    appendU32(encoded, kMagic);

    encoded.push_back(kVersion);
    encoded.push_back(type);

    // Reserved / flags field.
    appendU16(encoded, 0);

    appendU32(
            encoded,
            static_cast<std::uint32_t>(
                    payload.size()));

    appendU32(
            encoded,
            correlationId);

    encoded.insert(
            encoded.end(),
            payload.begin(),
            payload.end());

    return encoded;
}

DecodeStatus tryDecode(
        const std::uint8_t *data,
        std::size_t length,
        Frame &frame,
        std::size_t &consumed)
{
    consumed = 0;

    if (length < kHeaderSize) {
        return DecodeStatus::NeedMore;
    }

    const std::uint32_t magic =
            readU32(data);

    if (magic != kMagic) {
        throw ProtocolError(
                "invalid HNMC magic");
    }

    const std::uint8_t version =
            data[4];

    if (version != kVersion) {
        throw ProtocolError(
                "unsupported HNMC frame version");
    }

    const std::uint8_t type =
            data[5];

    const std::uint16_t reserved =
            readU16(data + 6);

    if (reserved != 0) {
        throw ProtocolError(
                "HNMC reserved header field must be zero");
    }

    const std::uint32_t payloadLength =
            readU32(data + 8);

    if (payloadLength > kMaxPayload) {
        throw ProtocolError(
                "HNMC payload exceeds maximum size");
    }

    const std::size_t frameSize =
            kHeaderSize
            + static_cast<std::size_t>(
                    payloadLength);

    if (length < frameSize) {
        return DecodeStatus::NeedMore;
    }

    frame.type = type;
    frame.correlationId =
            readU32(data + 12);

    frame.payload.assign(
            data + kHeaderSize,
            data + frameSize);

    consumed = frameSize;

    return DecodeStatus::Complete;
}

HelloInfo decodeHelloPayload(
        const std::vector<std::uint8_t> &payload)
{
    constexpr std::size_t kHelloPayloadSize = 8;

    if (payload.size()
            != kHelloPayloadSize) {
        throw ProtocolError(
                "invalid HNMC HELLO payload size");
    }

    HelloInfo hello;

    hello.version =
            readU16(payload.data());

    const std::uint16_t reserved =
            readU16(payload.data() + 2);

    if (reserved != 0) {
        throw ProtocolError(
                "HNMC HELLO reserved field must be zero");
    }

    hello.capabilities =
            readU32(payload.data() + 4);

    return hello;
}

std::vector<std::uint8_t> helloAckPayload()
{
    std::vector<std::uint8_t> payload;
    payload.reserve(8);

    appendU16(
            payload,
            static_cast<std::uint16_t>(
                    kVersion));

    appendU16(payload, 0);

    appendU32(
            payload,
            kMediaStateCapability
                    | kArtworkCapability);

    return payload;
}

MediaState decodeMediaStatePayload(
        const std::vector<std::uint8_t> &payload)
{
    /*
     * MEDIA_STATE payload, big-endian:
     *
     * byte  0     flags
     * bytes 1..3  reserved
     * bytes 4..11 positionMs
     * bytes 12..19 durationMs
     * bytes 20..21 mediaId length
     * bytes 22..23 title length
     * bytes 24..25 artist length
     * bytes 26..27 album length
     * bytes 28..   UTF-8 strings in that order
     */
    constexpr std::size_t kFixedSize = 28;

    if (payload.size() < kFixedSize) {
        throw ProtocolError(
                "HNMC MEDIA_STATE payload is truncated");
    }

    const std::uint8_t flags =
            payload[0];

    if ((flags
            & static_cast<std::uint8_t>(
                    ~(kMediaFlagHasMedia
                      | kMediaFlagPlaying)))
            != 0) {
        throw ProtocolError(
                "HNMC MEDIA_STATE contains unknown flags");
    }

    if (payload[1] != 0
            || payload[2] != 0
            || payload[3] != 0) {
        throw ProtocolError(
                "HNMC MEDIA_STATE reserved bytes must be zero");
    }

    const std::uint16_t mediaIdLength =
            readU16(payload.data() + 20);

    const std::uint16_t titleLength =
            readU16(payload.data() + 22);

    const std::uint16_t artistLength =
            readU16(payload.data() + 24);

    const std::uint16_t albumLength =
            readU16(payload.data() + 26);

    requireTextLength(
            mediaIdLength,
            "mediaId");

    requireTextLength(
            titleLength,
            "title");

    requireTextLength(
            artistLength,
            "artist");

    requireTextLength(
            albumLength,
            "album");

    const std::size_t textBytes =
            static_cast<std::size_t>(
                    mediaIdLength)
            + static_cast<std::size_t>(
                    titleLength)
            + static_cast<std::size_t>(
                    artistLength)
            + static_cast<std::size_t>(
                    albumLength);

    if (payload.size()
            != kFixedSize + textBytes) {
        throw ProtocolError(
                "HNMC MEDIA_STATE payload length mismatch");
    }

    MediaState state;

    state.hasMedia =
            (flags
                    & kMediaFlagHasMedia)
            != 0;

    state.playing =
            (flags
                    & kMediaFlagPlaying)
            != 0;

    state.positionMs =
            readU64(
                    payload.data() + 4);

    state.durationMs =
            readU64(
                    payload.data() + 12);

    std::size_t offset =
            kFixedSize;

    state.mediaId =
            readText(
                    payload,
                    offset,
                    mediaIdLength,
                    "mediaId");

    state.title =
            readText(
                    payload,
                    offset,
                    titleLength,
                    "title");

    state.artist =
            readText(
                    payload,
                    offset,
                    artistLength,
                    "artist");

    state.album =
            readText(
                    payload,
                    offset,
                    albumLength,
                    "album");

    if (!state.hasMedia) {
        state.playing = false;
        state.positionMs = 0;
        state.durationMs = 0;
        state.mediaId.clear();
        state.title.clear();
        state.artist.clear();
        state.album.clear();
    }

    if (state.durationMs > 0
            && state.positionMs
                    > state.durationMs) {
        state.positionMs =
                state.durationMs;
    }

    return state;
}

} // namespace hypernova::cluster::hnmc
