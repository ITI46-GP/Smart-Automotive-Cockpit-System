#pragma once

#include "ClusterPresentationState.hpp"

#include <QObject>
#include <QString>

namespace hypernova::cluster {

/**
 * Qt/QML presentation model for Digital Cluster navigation.
 *
 * Responsibilities:
 *
 *   - Expose HNCL navigation data as Q_PROPERTY values.
 *   - Expose selected/effective cluster view to QML.
 *   - Accept manual QML icon selection.
 *   - Accept future remote/AI view selection.
 *   - Marshal HNCL socket-thread updates safely onto the Qt UI thread.
 *
 * Transport parsing remains outside this class.
 */
class ClusterNavigationModel final : public QObject {
    Q_OBJECT

    Q_PROPERTY(
            bool connected
            READ connected
            NOTIFY stateChanged)

    Q_PROPERTY(
            bool navigationActive
            READ navigationActive
            NOTIFY stateChanged)

    Q_PROPERTY(
            bool hasNavigationState
            READ hasNavigationState
            NOTIFY stateChanged)

    Q_PROPERTY(
            int selectedView
            READ selectedView
            NOTIFY stateChanged)

    Q_PROPERTY(
            int effectiveView
            READ effectiveView
            NOTIFY stateChanged)

    Q_PROPERTY(
            int maneuver
            READ maneuver
            NOTIFY stateChanged)

    Q_PROPERTY(
            int speedLimitKph
            READ speedLimitKph
            NOTIFY stateChanged)

    Q_PROPERTY(
            qint64 distanceToManeuverMeters
            READ distanceToManeuverMeters
            NOTIFY stateChanged)

    Q_PROPERTY(
            qint64 remainingDistanceMeters
            READ remainingDistanceMeters
            NOTIFY stateChanged)

    Q_PROPERTY(
            qint64 remainingTimeSeconds
            READ remainingTimeSeconds
            NOTIFY stateChanged)

    Q_PROPERTY(
            qulonglong etaEpochSeconds
            READ etaEpochSeconds
            NOTIFY stateChanged)

    Q_PROPERTY(
            double latitude
            READ latitude
            NOTIFY stateChanged)

    Q_PROPERTY(
            double longitude
            READ longitude
            NOTIFY stateChanged)

    Q_PROPERTY(
            double headingDegrees
            READ headingDegrees
            NOTIFY stateChanged)

    Q_PROPERTY(
            QString streetName
            READ streetName
            NOTIFY stateChanged)

    Q_PROPERTY(
            QString destination
            READ destination
            NOTIFY stateChanged)

public:
    explicit ClusterNavigationModel(
            QObject* parent = nullptr);

    bool connected() const;

    bool navigationActive() const;
    bool hasNavigationState() const;

    int selectedView() const;
    int effectiveView() const;

    int maneuver() const;
    int speedLimitKph() const;

    qint64 distanceToManeuverMeters() const;
    qint64 remainingDistanceMeters() const;
    qint64 remainingTimeSeconds() const;

    qulonglong etaEpochSeconds() const;

    double latitude() const;
    double longitude() const;
    double headingDegrees() const;

    QString streetName() const;
    QString destination() const;

    /**
     * Called directly from QML.
     *
     * Existing cluster mapping:
     *
     *   0 = Car
     *   1 = Navigation
     *   2 = Contacts
     *   3 = Music
     *   4 = Fuel
     *   5 = Settings
     */
    Q_INVOKABLE void selectView(int viewId);

    /**
     * Thread-safe APIs intended for HNCL callbacks.
     */
    void postConnectionState(bool connected);

    void postNavigationState(
            hncl::NavigationState state);

    void postNavigationClear();

    /**
     * Prepared for future Android/NOVA remote view selection.
     *
     * Example:
     *   "Open map on cluster"
     *       -> VIEW_SELECT Navigation
     *       -> postSelectView(1)
     */
    void postSelectView(int viewId);

signals:
    void stateChanged();

private:
    void applyConnectionState(bool connected);

    void applyNavigationState(
            const hncl::NavigationState& state);

    void applyNavigationClear();

    void applySelectView(int viewId);

    const hncl::NavigationState&
    navigationState() const;

    static qint64 decodeOptionalUint32(
            std::uint32_t value);

    ClusterPresentationState state_;
};

} // namespace hypernova::cluster
