#pragma once

#include "HnmcProtocol.hpp"

#include <atomic>
#include <cstddef>
#include <cstdint>
#include <functional>
#include <thread>
#include <vector>

namespace hypernova::cluster {

class HnmcMediaServer final
{
public:
    struct Listener
    {
        std::function<void(bool)> onClientConnectionChanged;
        std::function<void(const hnmc::MediaState &)> onMediaState;
        std::function<void()> onMediaClear;
    };

    explicit HnmcMediaServer(
            std::uint16_t port = 6300,
            Listener listener = {});

    ~HnmcMediaServer();

    HnmcMediaServer(const HnmcMediaServer &) = delete;
    HnmcMediaServer &operator=(const HnmcMediaServer &) = delete;

    bool start();
    void stop();

    bool isRunning() const;
    std::uint16_t boundPort() const;

private:
    void workerMain();
    void runClient(int clientFd);

    bool sendFrame(
            int fd,
            std::uint8_t type,
            std::uint32_t correlationId,
            const std::vector<std::uint8_t> &payload = {});

    static bool sendAll(
            int fd,
            const std::uint8_t *data,
            std::size_t size);

    void notifyClientState(bool connected);

    void notifyMediaState(
            const hnmc::MediaState &state);

    void notifyMediaClear();

    std::uint16_t requestedPort_;
    Listener listener_;

    std::atomic<bool> running_{false};
    std::atomic<std::uint16_t> boundPort_{0};

    std::atomic<int> listenFd_{-1};
    std::atomic<int> clientFd_{-1};

    std::thread worker_;
};

} // namespace hypernova::cluster
