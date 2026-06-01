#include "LightsController.h"

#include <QSettings>

namespace {
constexpr int kMinAmbient = 0;
constexpr int kMaxAmbient = 100;
constexpr int kStep = 8;
}

LightsController::LightsController(QObject *parent)
    : QObject(parent)
{
    load();
}

bool LightsController::headlightsOn() const
{
    return m_headlightsOn;
}

bool LightsController::fogLightsOn() const
{
    return m_fogLightsOn;
}

bool LightsController::cabinAmbientOn() const
{
    return m_cabinAmbientOn;
}

bool LightsController::autoLightsOn() const
{
    return m_autoLightsOn;
}

int LightsController::ambientLevel() const
{
    return m_ambientLevel;
}

void LightsController::toggleHeadlights()
{
    setHeadlightsOn(!m_headlightsOn);
}

void LightsController::toggleFogLights()
{
    setFogLightsOn(!m_fogLightsOn);
}

void LightsController::toggleCabinAmbient()
{
    setCabinAmbientOn(!m_cabinAmbientOn);
}

void LightsController::toggleAutoLights()
{
    setAutoLightsOn(!m_autoLightsOn);
}

void LightsController::increaseAmbientLevel()
{
    setAmbientLevel(m_ambientLevel + kStep);
}

void LightsController::decreaseAmbientLevel()
{
    setAmbientLevel(m_ambientLevel - kStep);
}

void LightsController::setHeadlightsOn(bool on)
{
    if (m_headlightsOn == on) {
        return;
    }

    m_headlightsOn = on;
    emit headlightsOnChanged();
    save();
}

void LightsController::setFogLightsOn(bool on)
{
    if (m_fogLightsOn == on) {
        return;
    }

    m_fogLightsOn = on;
    emit fogLightsOnChanged();
    save();
}

void LightsController::setCabinAmbientOn(bool on)
{
    if (m_cabinAmbientOn == on) {
        return;
    }

    m_cabinAmbientOn = on;
    emit cabinAmbientOnChanged();
    save();
}

void LightsController::setAutoLightsOn(bool on)
{
    if (m_autoLightsOn == on) {
        return;
    }

    m_autoLightsOn = on;
    emit autoLightsOnChanged();
    save();
}

void LightsController::setAmbientLevel(int level)
{
    const int clamped = qBound(kMinAmbient, level, kMaxAmbient);
    if (m_ambientLevel == clamped) {
        return;
    }

    m_ambientLevel = clamped;
    emit ambientLevelChanged();
    save();
}

void LightsController::load()
{
    QSettings settings;
    settings.beginGroup("LightsController");
    m_headlightsOn = settings.value("headlightsOn", m_headlightsOn).toBool();
    m_fogLightsOn = settings.value("fogLightsOn", m_fogLightsOn).toBool();
    m_cabinAmbientOn = settings.value("cabinAmbientOn", m_cabinAmbientOn).toBool();
    m_autoLightsOn = settings.value("autoLightsOn", m_autoLightsOn).toBool();
    m_ambientLevel = qBound(kMinAmbient, settings.value("ambientLevel", m_ambientLevel).toInt(), kMaxAmbient);
    settings.endGroup();
}

void LightsController::save() const
{
    QSettings settings;
    settings.beginGroup("LightsController");
    settings.setValue("headlightsOn", m_headlightsOn);
    settings.setValue("fogLightsOn", m_fogLightsOn);
    settings.setValue("cabinAmbientOn", m_cabinAmbientOn);
    settings.setValue("autoLightsOn", m_autoLightsOn);
    settings.setValue("ambientLevel", m_ambientLevel);
    settings.endGroup();
}
