#include "../ClusterPresentationState.hpp"

#include <iostream>
#include <stdexcept>
#include <string>

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

NavigationState activeNavigation()
{
    NavigationState state;

    state.active = true;
    state.maneuver = kManeuverTurnRight;
    state.speedLimitKph = kUnknownSpeedLimit;

    state.distanceToManeuverMeters = 250;
    state.remainingDistanceMeters = 12'345;
    state.remainingTimeSeconds = 720;

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

void testDefaultCarView()
{
    ClusterPresentationState state;

    expect(
            state.selectedView()
                    == ClusterView::Car,
            "default selected view must be Car");

    expect(
            state.effectiveView()
                    == ClusterView::Car,
            "default effective view must be Car");

    expect(
            !state.navigationActive(),
            "navigation must initially be inactive");
}

void testManualNavigationIcon()
{
    ClusterPresentationState state;

    /*
     * Existing QML navigation icon is index 1.
     */
    state.selectViewId(1);

    expect(
            state.selectedView()
                    == ClusterView::Navigation,
            "manual navigation icon selects map");

    expect(
            state.effectiveView()
                    == ClusterView::Navigation,
            "manual navigation icon displays map");
}

void testManualOtherViews()
{
    ClusterPresentationState state;

    state.selectView(
            ClusterView::Contacts);

    expect(
            state.effectiveView()
                    == ClusterView::Contacts,
            "contacts view");

    state.selectView(
            ClusterView::Music);

    expect(
            state.effectiveView()
                    == ClusterView::Music,
            "music view");

    state.selectView(
            ClusterView::Fuel);

    expect(
            state.effectiveView()
                    == ClusterView::Fuel,
            "fuel view");

    state.selectView(
            ClusterView::Settings);

    expect(
            state.effectiveView()
                    == ClusterView::Settings,
            "settings view");
}

void testActiveNavigationForcesMap()
{
    ClusterPresentationState state;

    /*
     * Normal cluster state:
     * car is visible.
     */
    state.selectView(
            ClusterView::Car);

    expect(
            state.effectiveView()
                    == ClusterView::Car,
            "car visible before route starts");

    const NavigationState navigation =
            activeNavigation();

    state.applyNavigationState(
            navigation);

    expect(
            state.navigationActive(),
            "navigation active");

    expect(
            state.effectiveView()
                    == ClusterView::Navigation,
            "active navigation forces map");

    expect(
            state.selectedView()
                    == ClusterView::Car,
            "underlying user selection remains Car");

    expect(
            state.hasNavigationState(),
            "navigation presentation retained");

    expect(
            state.navigationState().destination
                    == "Smart Village",
            "navigation destination retained");
}

void testNavigationPriorityPreservesSelection()
{
    ClusterPresentationState state;

    state.selectView(
            ClusterView::Car);

    state.applyNavigationState(
            activeNavigation());

    /*
     * If another selection arrives while navigation is active,
     * remember it but keep Navigation on screen until the route ends.
     */
    state.selectView(
            ClusterView::Music);

    expect(
            state.selectedView()
                    == ClusterView::Music,
            "new selection remembered");

    expect(
            state.effectiveView()
                    == ClusterView::Navigation,
            "active route keeps map visible");

    state.clearNavigation();

    expect(
            !state.navigationActive(),
            "navigation cleared");

    expect(
            !state.hasNavigationState(),
            "navigation state cleared");

    expect(
            state.effectiveView()
                    == ClusterView::Music,
            "return to remembered view");
}

void testAiDirectOpenMap()
{
    ClusterPresentationState state;

    /*
     * This is the same action that a future Android HNCL VIEW_SELECT
     * command from NOVA AI will perform.
     */
    state.selectViewId(
            static_cast<std::uint8_t>(
                    ClusterView::Navigation));

    expect(
            state.selectedView()
                    == ClusterView::Navigation,
            "AI selects Navigation view");

    expect(
            state.effectiveView()
                    == ClusterView::Navigation,
            "AI opens map directly");
}

void testConnectionState()
{
    ClusterPresentationState state;

    expect(
            !state.connected(),
            "initially disconnected");

    state.setConnected(true);

    expect(
            state.connected(),
            "connected state");

    state.setConnected(false);

    expect(
            !state.connected(),
            "disconnected state");
}

void testInvalidViewRejected()
{
    ClusterPresentationState state;

    bool threw = false;

    try {
        state.selectViewId(6);
    } catch (const std::invalid_argument&) {
        threw = true;
    }

    expect(
            threw,
            "invalid cluster view must be rejected");
}

} // namespace

int main()
{
    try {
        testDefaultCarView();
        testManualNavigationIcon();
        testManualOtherViews();
        testActiveNavigationForcesMap();
        testNavigationPriorityPreservesSelection();
        testAiDirectOpenMap();
        testConnectionState();
        testInvalidViewRejected();

        std::cout
                << "PASS: Cluster presentation state tests"
                << std::endl;

        std::cout
                << "PASS: default Car view"
                << std::endl;

        std::cout
                << "PASS: manual Navigation icon -> Map"
                << std::endl;

        std::cout
                << "PASS: active Navigation -> Map"
                << std::endl;

        std::cout
                << "PASS: Navigation view priority"
                << std::endl;

        std::cout
                << "PASS: AI direct Map selection policy"
                << std::endl;

        std::cout
                << "PASS: route end restores selected view"
                << std::endl;

        return 0;

    } catch (const std::exception& error) {

        std::cerr
                << error.what()
                << std::endl;

        return 1;
    }
}
