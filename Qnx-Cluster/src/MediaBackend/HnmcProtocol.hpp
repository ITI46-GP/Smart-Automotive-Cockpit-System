#pragma once

#include <cstddef>
#include <cstdint>
#include <stdexcept>
#include <string>
#include <vector>

namespace hypernova::cluster::hnmc {

constexpr std::uint32_t kMagic = 0x484E4D43; // "HNMC"
constexpr std::uint8_t kVersion = 1;

constexpr std::size_t kHeaderSize = 16;
constexpr std::size_t kMaxPayload = 512U * 1024U;
constexpr std::size_t kMaxTextBytes = 2048;

constexpr std::uint32_t kMediaStateCapability = 0x00000001;
constexpr std::uint32_t kArtworkCapability    = 0x00000002;

constexpr std::uint8_t kTypeHello      = 0x01;
constexpr std::uint8_t kTypePing       = 0x02;

constexpr std::uint8_t kTypeMediaState = 0x10;
constexpr std::uint8_t kTypeMediaClear = 0x11;

constexpr std::uint8_t kTypeHelloAck   = 0x81;
constexpr std::uint8_t kTypePong       = 0x82;

constexpr std::uint8_t kMediaFlagHasMedia = 0x01;
constexpr std::uint8_t kMediaFlagPlaying  = 0x02;

class ProtocolError final : public std::runtime_error
{
public:
    explicit ProtocolError(const std::string &message)
        : std::runtime_error(message)
    {
    }
};

struct Frame
{
    std::uint8_t type = 0;
    std::uint32_t correlationId = 0;
    std::vector<std::uint8_t> payload;
};

enum class DecodeStatus
{
    NeedMore,
    Complete
};

struct HelloInfo
{
    std::uint16_t version = 0;
    std::uint32_t capabilities = 0;
};

struct MediaState
{
    bool hasMedia = false;
    bool playing = false;

    std::uint64_t positionMs = 0;
    std::uint64_t durationMs = 0;

    std::string mediaId;
    std::string title;
    std::string artist;
    std::string album;
};

std::vector<std::uint8_t> encodeFrame(
        std::uint8_t type,
        std::uint32_t correlationId,
        const std::vector<std::uint8_t> &payload = {});

DecodeStatus tryDecode(
        const std::uint8_t *data,
        std::size_t length,
        Frame &frame,
        std::size_t &consumed);

HelloInfo decodeHelloPayload(
        const std::vector<std::uint8_t> &payload);

std::vector<std::uint8_t> helloAckPayload();

MediaState decodeMediaStatePayload(
        const std::vector<std::uint8_t> &payload);

} // namespace hypernova::cluster::hnmc
