#include "SettingsManager.h"

#include <QSettings>

namespace {
constexpr int kMinBrightness = 10;
constexpr int kMaxBrightness = 100;
constexpr int kMinVolume = 0;
constexpr int kMaxVolume = 100;
constexpr int kStep = 5;
}

SettingsManager::SettingsManager(QObject *parent)
    : QObject(parent)
{
    load();
}

bool SettingsManager::wifiOn() const
{
    return m_wifiOn;
}

bool SettingsManager::bluetoothOn() const
{
    return m_bluetoothOn;
}

bool SettingsManager::darkMode() const
{
    return m_darkMode;
}

bool SettingsManager::autoBrightness() const
{
    return m_autoBrightness;
}

bool SettingsManager::privacyMode() const
{
    return m_privacyMode;
}

int SettingsManager::brightness() const
{
    return m_brightness;
}

int SettingsManager::systemVolume() const
{
    return m_systemVolume;
}

void SettingsManager::toggleWifi()
{
    setWifiOn(!m_wifiOn);
}

void SettingsManager::toggleBluetooth()
{
    setBluetoothOn(!m_bluetoothOn);
}

void SettingsManager::toggleDarkMode()
{
    setDarkMode(!m_darkMode);
}

void SettingsManager::toggleAutoBrightness()
{
    setAutoBrightness(!m_autoBrightness);
}

void SettingsManager::togglePrivacyMode()
{
    setPrivacyMode(!m_privacyMode);
}

void SettingsManager::increaseBrightness()
{
    setBrightness(m_brightness + kStep);
}

void SettingsManager::decreaseBrightness()
{
    setBrightness(m_brightness - kStep);
}

void SettingsManager::increaseSystemVolume()
{
    setSystemVolume(m_systemVolume + kStep);
}

void SettingsManager::decreaseSystemVolume()
{
    setSystemVolume(m_systemVolume - kStep);
}

void SettingsManager::setWifiOn(bool on)
{
    if (m_wifiOn == on) {
        return;
    }

    m_wifiOn = on;
    emit wifiOnChanged();
    save();
}

void SettingsManager::setBluetoothOn(bool on)
{
    if (m_bluetoothOn == on) {
        return;
    }

    m_bluetoothOn = on;
    emit bluetoothOnChanged();
    save();
}

void SettingsManager::setDarkMode(bool on)
{
    if (m_darkMode == on) {
        return;
    }

    m_darkMode = on;
    emit darkModeChanged();
    save();
}

void SettingsManager::setAutoBrightness(bool on)
{
    if (m_autoBrightness == on) {
        return;
    }

    m_autoBrightness = on;
    emit autoBrightnessChanged();
    save();
}

void SettingsManager::setPrivacyMode(bool on)
{
    if (m_privacyMode == on) {
        return;
    }

    m_privacyMode = on;
    emit privacyModeChanged();
    save();
}

void SettingsManager::setBrightness(int brightness)
{
    const int clamped = qBound(kMinBrightness, brightness, kMaxBrightness);
    if (m_brightness == clamped) {
        return;
    }

    m_brightness = clamped;
    emit brightnessChanged();
    save();
}

void SettingsManager::setSystemVolume(int volume)
{
    const int clamped = qBound(kMinVolume, volume, kMaxVolume);
    if (m_systemVolume == clamped) {
        return;
    }

    m_systemVolume = clamped;
    emit systemVolumeChanged();
    save();
}

void SettingsManager::load()
{
    QSettings settings;
    settings.beginGroup("SettingsManager");
    m_wifiOn = settings.value("wifiOn", m_wifiOn).toBool();
    m_bluetoothOn = settings.value("bluetoothOn", m_bluetoothOn).toBool();
    m_darkMode = settings.value("darkMode", m_darkMode).toBool();
    m_autoBrightness = settings.value("autoBrightness", m_autoBrightness).toBool();
    m_privacyMode = settings.value("privacyMode", m_privacyMode).toBool();
    m_brightness = qBound(kMinBrightness, settings.value("brightness", m_brightness).toInt(), kMaxBrightness);
    m_systemVolume = qBound(kMinVolume, settings.value("systemVolume", m_systemVolume).toInt(), kMaxVolume);
    settings.endGroup();
}

void SettingsManager::save() const
{
    QSettings settings;
    settings.beginGroup("SettingsManager");
    settings.setValue("wifiOn", m_wifiOn);
    settings.setValue("bluetoothOn", m_bluetoothOn);
    settings.setValue("darkMode", m_darkMode);
    settings.setValue("autoBrightness", m_autoBrightness);
    settings.setValue("privacyMode", m_privacyMode);
    settings.setValue("brightness", m_brightness);
    settings.setValue("systemVolume", m_systemVolume);
    settings.endGroup();
}
