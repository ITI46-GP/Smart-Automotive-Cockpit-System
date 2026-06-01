#include "hvaccontroller.h"
#include <QtMath>

HvacController::HvacController(QObject *parent)
    : QObject(parent)
{
}

double HvacController::driverTemp() const  { return m_driverTemp; }
double HvacController::passengerTemp() const { return m_passengerTemp; }
int    HvacController::fanSpeed() const      { return m_fanSpeed; }
bool   HvacController::acOn() const          { return m_acOn; }
int    HvacController::fanMode() const       { return m_fanMode; }
bool   HvacController::driverPowerOn() const { return m_driverPowerOn; }
bool   HvacController::passengerPowerOn() const { return m_passengerPowerOn; }

void HvacController::setDriverTemp(double t) {
    t = qBound(16.0, t, 30.0);
    if (!qFuzzyCompare(m_driverTemp, t)) {
        m_driverTemp = t;
        emit driverTempChanged();
    }
}
void HvacController::setPassengerTemp(double t) {
    t = qBound(16.0, t, 30.0);
    if (!qFuzzyCompare(m_passengerTemp, t)) {
        m_passengerTemp = t;
        emit passengerTempChanged();
    }
}
void HvacController::setFanSpeed(int s) {
    s = qBound(0, s, 5);
    if (m_fanSpeed != s) {
        m_fanSpeed = s;
        emit fanSpeedChanged();
    }
}
void HvacController::setAcOn(bool on) {
    if (m_acOn != on) {
        m_acOn = on;
        emit acOnChanged();
    }
}
void HvacController::setFanMode(int m) {
    m = qBound(0, m, 3);
    if (m_fanMode != m) {
        m_fanMode = m;
        emit fanModeChanged();
    }
}
void HvacController::setDriverPowerOn(bool on) {
    if (m_driverPowerOn != on) {
        m_driverPowerOn = on;
        emit driverPowerOnChanged();
    }
}
void HvacController::setPassengerPowerOn(bool on) {
    if (m_passengerPowerOn != on) {
        m_passengerPowerOn = on;
        emit passengerPowerOnChanged();
    }
}

void HvacController::increaseDriverTemp()     { setDriverTemp(m_driverTemp + 0.5); }
void HvacController::decreaseDriverTemp()     { setDriverTemp(m_driverTemp - 0.5); }
void HvacController::increasePassengerTemp()  { setPassengerTemp(m_passengerTemp + 0.5); }
void HvacController::decreasePassengerTemp()  { setPassengerTemp(m_passengerTemp - 0.5); }
void HvacController::increaseFanSpeed()       { setFanSpeed(m_fanSpeed + 1); }
void HvacController::decreaseFanSpeed()       { setFanSpeed(m_fanSpeed - 1); }
void HvacController::toggleAc()               { setAcOn(!m_acOn); }
void HvacController::toggleDriverPower()      { setDriverPowerOn(!m_driverPowerOn); }
void HvacController::togglePassengerPower()   { setPassengerPowerOn(!m_passengerPowerOn); }
void HvacController::setFanModeIndex(int idx) { setFanMode(idx); }