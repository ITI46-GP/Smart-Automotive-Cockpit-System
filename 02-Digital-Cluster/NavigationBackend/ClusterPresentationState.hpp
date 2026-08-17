#pragma once

#include "HnclProtocol.hpp"

#include <cstdint>
#include <stdexcept>

namespace hypernova::cluster {

enum class ClusterView : std::uint8_t {
    Car = 0,
    Navigation = 1,
    Contacts = 2,
    Music = 3,
    Fuel = 4,
    Settings = 5
};

/**
 * Pure presentation-state policy for the Digital Cluster.
 *
 * This class contains no Qt and no socket code.
 *
 * Rules:
 *
 *   - Default view is Car.
 *   - Manual icon selection changes selectedView.
 *   - AI/remote selection uses the same selectedView path.
 *   - Active navigation temporarily forces effectiveView to Navigation.
 *   - When navigation ends, effectiveView returns to selectedView.
 *
 * Keeping this policy independent from Qt makes it directly testable and
 * keeps network/QNX transport concerns out of the QML presentation layer.
 */
class ClusterPresentationState final {
public:
    ClusterPresentationState() = default;

    void setConnected(bool connected);

    void selectView(ClusterView view);
    void selectViewId(std::uint8_t viewId);

    void applyNavigationState(
            const hncl::NavigationState& state);

    void clearNavigation();

    bool connected() const;

    bool navigationActive() const;
    bool hasNavigationState() const;

    ClusterView selectedView() const;
    ClusterView effectiveView() const;

    const hncl::NavigationState& navigationState() const;

    static bool isValidViewId(std::uint8_t viewId);

private:
    bool connected_ = false;

    bool navigationActive_ = false;
    bool hasNavigationState_ = false;

    ClusterView selectedView_ =
            ClusterView::Car;

    hncl::NavigationState navigationState_;
};

} // namespace hypernova::cluster
