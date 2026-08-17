#include "../ClusterNavigationModel.hpp"

#include <QCoreApplication>
#include <QEventLoop>

#include <chrono>
#include <cmath>
#include <iostream>
#include <stdexcept>
#include <string>
#include <thread>

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

        QCoreApplication::processEvents(
                QEventLoop::AllEvents,
                20);

        if (predicate()) {
            return true;
        }

        std::this_thread::sleep_for(
                std::chrono::milliseconds(5));
    }

    QCoreApplication::processEvents(
            QEventLoop::AllEvents,
            20);

    return predicate();
}

NavigationState activeNavigation()
{
    NavigationState state;

    state.active = true;
    state.maneuver =
            kManeuverTurnRight;

    state.speedLimitKph =
            kUnknownSpeedLimit;

    /*
     * Android bridge currently uses uint32 max as the
     * unavailable sentinel.
     */
    state.distanceToManeuverMeters =
            0xFFFF'FFFFU;

    state.remainingDistanceMeters =
            12'345;

    state.remainingTimeSeconds =
            720;

    state.etaEpochSeconds =
            1'800'000'000ULL;

    state.latitudeE7 =
            300'712'345;

    state.longitudeE7 =
            310'176'543;

    state.headingCentiDegrees =
            9'550;

    state.streetName =
            "Sheikh Zayed Road";

    state.destination =
            "Smart Village";

    return state;
}

} // namespace

int main(
        int argc,
        char* argv[])
{
    QCoreApplication application(
            argc,
            argv);

    try {
        ClusterNavigationModel model;

        expect(
                model.selectedView()
                        == 0,
                "default selected view is Car");

        expect(
                model.effectiveView()
                        == 0,
                "default effective view is Car");

        /*
         * Existing physical/QML Navigation icon.
         */
        model.selectView(1);

        expect(
                model.selectedView()
                        == 1,
                "manual icon selects Navigation");

        expect(
                model.effectiveView()
                        == 1,
                "manual icon opens Map");

        model.selectView(0);

        expect(
                model.effectiveView()
                        == 0,
                "manual Car selection");

        /*
         * Simulate HNCL worker thread delivering active navigation.
         */
        std::thread navigationThread(
                [&model]() {
                    model.postNavigationState(
                            activeNavigation());
                });

        navigationThread.join();

        expect(
                waitUntil(
                        [&model]() {
                            return model.navigationActive();
                        }),
                "queued navigation reaches Qt thread");

        expect(
                model.effectiveView()
                        == 1,
                "active Navigation forces Map");

        expect(
                model.destination()
                        == QStringLiteral(
                                "Smart Village"),
                "destination property");

        expect(
                model.streetName()
                        == QStringLiteral(
                                "Sheikh Zayed Road"),
                "street property");

        expect(
                model.distanceToManeuverMeters()
                        == -1,
                "unknown uint32 sentinel");

        expect(
                model.remainingDistanceMeters()
                        == 12'345,
                "remaining distance property");

        expect(
                model.remainingTimeSeconds()
                        == 720,
                "remaining time property");

        expect(
                model.speedLimitKph()
                        == -1,
                "unknown speed limit");

        expect(
                std::abs(
                        model.latitude()
                        - 30.0712345)
                        < 0.00000001,
                "latitude property");

        expect(
                std::abs(
                        model.longitude()
                        - 31.0176543)
                        < 0.00000001,
                "longitude property");

        expect(
                std::abs(
                        model.headingDegrees()
                        - 95.5)
                        < 0.001,
                "heading property");

        /*
         * Selection while route is active is remembered,
         * but Navigation keeps control of center display.
         */
        model.selectView(3);

        expect(
                model.selectedView()
                        == 3,
                "Music selection remembered");

        expect(
                model.effectiveView()
                        == 1,
                "active route still forces Map");

        /*
         * Simulate route ending from network worker.
         */
        std::thread clearThread(
                [&model]() {
                    model.postNavigationClear();
                });

        clearThread.join();

        expect(
                waitUntil(
                        [&model]() {
                            return !model.navigationActive();
                        }),
                "navigation clear reaches Qt thread");

        expect(
                model.effectiveView()
                        == 3,
                "route end restores Music");

        /*
         * This models the future:
         *
         * NOVA AI
         *   -> Android VIEW_SELECT
         *   -> HNCL
         *   -> postSelectView(1)
         */
        std::thread aiThread(
                [&model]() {
                    model.postSelectView(1);
                });

        aiThread.join();

        expect(
                waitUntil(
                        [&model]() {
                            return model.selectedView()
                                    == 1;
                        }),
                "remote view selection reaches Qt thread");

        expect(
                model.effectiveView()
                        == 1,
                "AI remote selection opens Map");

        /*
         * Connection status also originates from server thread.
         */
        std::thread connectionThread(
                [&model]() {
                    model.postConnectionState(true);
                });

        connectionThread.join();

        expect(
                waitUntil(
                        [&model]() {
                            return model.connected();
                        }),
                "connection status reaches Qt thread");

        std::cout
                << "PASS: Qt ClusterNavigationModel tests"
                << std::endl;

        std::cout
                << "PASS: QML manual Navigation -> Map"
                << std::endl;

        std::cout
                << "PASS: HNCL navigation -> Qt queued update"
                << std::endl;

        std::cout
                << "PASS: active Navigation -> Map"
                << std::endl;

        std::cout
                << "PASS: navigation data Q_PROPERTY mapping"
                << std::endl;

        std::cout
                << "PASS: route end restores selected view"
                << std::endl;

        std::cout
                << "PASS: future AI/remote view -> Map"
                << std::endl;

        return 0;

    } catch (const std::exception& error) {

        std::cerr
                << error.what()
                << std::endl;

        return 1;
    }
}
