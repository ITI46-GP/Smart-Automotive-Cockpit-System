#pragma once

#include "HnclProtocol.hpp"

#include <atomic>
#include <cstdint>
#include <functional>
#include <thread>

namespace hypernova::cluster {

class HnclNavigationServer final {
public:
    struct Listener {
        std::function<void(bool)> onClientConnectionChanged;
        std::function<void(const hncl::NavigationState&)> onNavigationState;
        std::function<void()> onNavigationClear;
    };

    explicit HnclNavigationServer(
            std::uint16_t port = 6200,
            Listener listener = {});

    ~HnclNavigationServer();

    HnclNavigationServer(const HnclNavigationServer&) = delete;
    HnclNavigationServer& operator=(const HnclNavigationServer&) = delete;

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
            const std::vector<std::uint8_t>& payload = {});

    static bool sendAll(
            int fd,
            const std::uint8_t* data,
            std::size_t size);

    void notifyClientState(bool connected);
    void notifyNavigationState(
            const hncl::NavigationState& state);
    void notifyNavigationClear();

    std::uint16_t requestedPort_;
    Listener listener_;

    std::atomic<bool> running_{false};
    std::atomic<std::uint16_t> boundPort_{0};
    std::atomic<int> listenFd_{-1};
    std::atomic<int> clientFd_{-1};

    std::thread worker_;
};

} // namespace hypernova::cluster
