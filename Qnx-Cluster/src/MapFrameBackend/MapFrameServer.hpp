#pragma once

#include <QImage>

#include <atomic>
#include <cstdint>
#include <functional>
#include <thread>

namespace hypernova::cluster {

class MapFrameServer final {
public:
    struct Listener {
        std::function<void(
                QImage,
                std::uint32_t sequence,
                std::uint64_t captureTimestampMs)> onFrame;
        std::function<void(bool)> onClientConnectionChanged;
    };

    explicit MapFrameServer(
            std::uint16_t port = 6201,
            Listener listener = {});
    ~MapFrameServer();

    MapFrameServer(const MapFrameServer&) = delete;
    MapFrameServer& operator=(const MapFrameServer&) = delete;

    bool start();
    void stop();
    bool isRunning() const;
    std::uint16_t boundPort() const;

private:
    void workerMain();
    void runClient(int clientFd);
    void notifyClientState(bool connected);
    void notifyFrame(
            QImage image,
            std::uint32_t sequence,
            std::uint64_t captureTimestampMs);

    std::uint16_t requestedPort_;
    Listener listener_;
    std::atomic_bool running_{false};
    std::atomic<std::uint16_t> boundPort_{0};
    std::atomic_int listenFd_{-1};
    std::atomic_int clientFd_{-1};
    std::thread worker_;
};

} // namespace hypernova::cluster
