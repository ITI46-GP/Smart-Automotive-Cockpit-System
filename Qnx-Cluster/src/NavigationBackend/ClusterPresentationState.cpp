#include "ClusterPresentationState.hpp"

namespace hypernova::cluster {

void ClusterPresentationState::setConnected(
        bool connected)
{
    connected_ = connected;
}

void ClusterPresentationState::selectView(
        ClusterView view)
{
    const auto viewId =
            static_cast<std::uint8_t>(view);

    if (!isValidViewId(viewId)) {
        throw std::invalid_argument(
                "invalid Digital Cluster view");
    }

    selectedView_ = view;
}

void ClusterPresentationState::selectViewId(
        std::uint8_t viewId)
{
    if (!isValidViewId(viewId)) {
        throw std::invalid_argument(
                "invalid Digital Cluster view id");
    }

    selectedView_ =
            static_cast<ClusterView>(viewId);
}

void ClusterPresentationState::applyNavigationState(
        const hncl::NavigationState& state)
{
    navigationState_ = state;
    hasNavigationState_ = true;
    navigationActive_ = state.active;
}

void ClusterPresentationState::clearNavigation()
{
    navigationState_ =
            hncl::NavigationState{};

    hasNavigationState_ = false;
    navigationActive_ = false;
}

bool ClusterPresentationState::connected() const
{
    return connected_;
}

bool ClusterPresentationState::navigationActive() const
{
    return navigationActive_;
}

bool ClusterPresentationState::hasNavigationState() const
{
    return hasNavigationState_;
}

ClusterView ClusterPresentationState::selectedView() const
{
    return selectedView_;
}

ClusterView ClusterPresentationState::effectiveView() const
{
    /*
     * Active turn-by-turn navigation owns the center display.
     *
     * selectedView_ is intentionally preserved so when navigation finishes
     * the cluster returns to the driver's most recent selection.
     */
    if (navigationActive_) {
        return ClusterView::Navigation;
    }

    return selectedView_;
}

const hncl::NavigationState&
ClusterPresentationState::navigationState() const
{
    return navigationState_;
}

bool ClusterPresentationState::isValidViewId(
        std::uint8_t viewId)
{
    return viewId
            <= static_cast<std::uint8_t>(
                    ClusterView::Settings);
}

} // namespace hypernova::cluster
