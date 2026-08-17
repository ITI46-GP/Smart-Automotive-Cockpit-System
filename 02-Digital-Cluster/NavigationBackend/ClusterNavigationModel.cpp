#include "ClusterNavigationModel.hpp"

#include <QMetaObject>
#include <QThread>
#include <QDebug>

#include <utility>

namespace hypernova::cluster {
namespace {

constexpr std::uint32_t kUnknownUint32 =
        0xFFFF'FFFFU;

} // namespace

ClusterNavigationModel::ClusterNavigationModel(
        QObject* parent)
    : QObject(parent)
{
}

bool ClusterNavigationModel::connected() const
{
    return state_.connected();
}

bool ClusterNavigationModel::navigationActive() const
{
    return state_.navigationActive();
}

bool ClusterNavigationModel::hasNavigationState() const
{
    return state_.hasNavigationState();
}

int ClusterNavigationModel::selectedView() const
{
    return static_cast<int>(
            state_.selectedView());
}

int ClusterNavigationModel::effectiveView() const
{
    return static_cast<int>(
            state_.effectiveView());
}

int ClusterNavigationModel::maneuver() const
{
    if (!hasNavigationState()) {
        return static_cast<int>(
                hncl::kManeuverUnknown);
    }

    return static_cast<int>(
            navigationState().maneuver);
}

int ClusterNavigationModel::speedLimitKph() const
{
    if (!hasNavigationState()) {
        return -1;
    }

    const std::uint16_t value =
            navigationState().speedLimitKph;

    if (value == hncl::kUnknownSpeedLimit) {
        return -1;
    }

    return static_cast<int>(value);
}

qint64
ClusterNavigationModel::distanceToManeuverMeters() const
{
    if (!hasNavigationState()) {
        return -1;
    }

    return decodeOptionalUint32(
            navigationState()
                    .distanceToManeuverMeters);
}

qint64
ClusterNavigationModel::remainingDistanceMeters() const
{
    if (!hasNavigationState()) {
        return -1;
    }

    return decodeOptionalUint32(
            navigationState()
                    .remainingDistanceMeters);
}

qint64
ClusterNavigationModel::remainingTimeSeconds() const
{
    if (!hasNavigationState()) {
        return -1;
    }

    return decodeOptionalUint32(
            navigationState()
                    .remainingTimeSeconds);
}

qulonglong
ClusterNavigationModel::etaEpochSeconds() const
{
    if (!hasNavigationState()) {
        return 0;
    }

    return static_cast<qulonglong>(
            navigationState()
                    .etaEpochSeconds);
}

double ClusterNavigationModel::latitude() const
{
    if (!hasNavigationState()) {
        return 0.0;
    }

    return navigationState()
            .latitudeDegrees();
}

double ClusterNavigationModel::longitude() const
{
    if (!hasNavigationState()) {
        return 0.0;
    }

    return navigationState()
            .longitudeDegrees();
}

double ClusterNavigationModel::headingDegrees() const
{
    if (!hasNavigationState()) {
        return 0.0;
    }

    return navigationState()
            .headingDegrees();
}

QString ClusterNavigationModel::streetName() const
{
    if (!hasNavigationState()) {
        return {};
    }

    return QString::fromUtf8(
            navigationState()
                    .streetName.c_str(),
            static_cast<qsizetype>(
                    navigationState()
                            .streetName.size()));
}

QString ClusterNavigationModel::destination() const
{
    if (!hasNavigationState()) {
        return {};
    }

    return QString::fromUtf8(
            navigationState()
                    .destination.c_str(),
            static_cast<qsizetype>(
                    navigationState()
                            .destination.size()));
}

void ClusterNavigationModel::selectView(
        int viewId)
{
    /*
     * QML calls this on the main thread.
     * Keep the implementation defensive anyway.
     */
    if (QThread::currentThread()
            == thread()) {
        applySelectView(viewId);
        return;
    }

    postSelectView(viewId);
}

void ClusterNavigationModel::postConnectionState(
        bool connected)
{
    if (QThread::currentThread()
            == thread()) {
        applyConnectionState(connected);
        return;
    }

    QMetaObject::invokeMethod(
            this,
            [this, connected]() {
                applyConnectionState(
                        connected);
            },
            Qt::QueuedConnection);
}

void ClusterNavigationModel::postNavigationState(
        hncl::NavigationState state)
{
    if (QThread::currentThread()
            == thread()) {
        applyNavigationState(state);
        return;
    }

    QMetaObject::invokeMethod(
            this,
            [
                this,
                state = std::move(state)
            ]() {
                applyNavigationState(state);
            },
            Qt::QueuedConnection);
}

void ClusterNavigationModel::postNavigationClear()
{
    if (QThread::currentThread()
            == thread()) {
        applyNavigationClear();
        return;
    }

    QMetaObject::invokeMethod(
            this,
            [this]() {
                applyNavigationClear();
            },
            Qt::QueuedConnection);
}

void ClusterNavigationModel::postSelectView(
        int viewId)
{
    if (QThread::currentThread()
            == thread()) {
        applySelectView(viewId);
        return;
    }

    QMetaObject::invokeMethod(
            this,
            [this, viewId]() {
                applySelectView(viewId);
            },
            Qt::QueuedConnection);
}

void ClusterNavigationModel::applyConnectionState(
        bool connected)
{
    if (state_.connected() == connected) {
        return;
    }

    state_.setConnected(connected);

    emit stateChanged();
}

void ClusterNavigationModel::applyNavigationState(
        const hncl::NavigationState& state)
{
    state_.applyNavigationState(state);

    emit stateChanged();
}

void ClusterNavigationModel::applyNavigationClear()
{
    if (!state_.hasNavigationState()
            && !state_.navigationActive()) {
        return;
    }

    state_.clearNavigation();

    emit stateChanged();
}

void ClusterNavigationModel::applySelectView(
        int viewId)
{
    if (viewId < 0
            || viewId > static_cast<int>(
                    ClusterView::Settings)) {

        qWarning()
                << "Ignoring invalid Digital Cluster view:"
                << viewId;

        return;
    }

    const auto requested =
            static_cast<ClusterView>(
                    viewId);

    if (state_.selectedView()
            == requested) {
        return;
    }

    state_.selectView(requested);

    emit stateChanged();
}

const hncl::NavigationState&
ClusterNavigationModel::navigationState() const
{
    return state_.navigationState();
}

qint64
ClusterNavigationModel::decodeOptionalUint32(
        std::uint32_t value)
{
    if (value == kUnknownUint32) {
        return -1;
    }

    return static_cast<qint64>(value);
}

} // namespace hypernova::cluster
