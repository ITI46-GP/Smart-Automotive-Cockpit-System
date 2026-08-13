#include "BottomBarDataProvider.h"

// Paths verbatim from the reference (Backend/BottomBar/BottomBarDataProvider.
// cpp) — an external process is expected to write these on both the desktop
// kit and the QNX target; /tmp exists and is writable on both (this project
// already uses /tmp for deploy/measure on the board). Each provider keeps a
// sensible hardcoded default (see its header) if the file is missing, so a
// clean board with nothing writing these yet still shows something plausible
// rather than 0.
BottomBarDataProvider::BottomBarDataProvider(QObject *parent)
    : QObject{parent}
{
    fuelProvider_ = new FuelProvider("/tmp/ivi/fuel.txt", this);
    engineTempProvider_ = new EngineTempProvider("/tmp/ivi/engine_temp.txt", this);
    envTempProvider_ = new EnvTempProvider("/tmp/ivi/env_temp.txt", this);
    totalKmsProvider_ = new TotalKmsProvider("/tmp/ivi/total_kms.txt", this);
    timeProvider_ = new TimeProvider(this);
}

FuelProvider* BottomBarDataProvider::fuelProvider() const { return fuelProvider_; }
EngineTempProvider* BottomBarDataProvider::engineTempProvider() const { return engineTempProvider_; }
EnvTempProvider* BottomBarDataProvider::envTempProvider() const { return envTempProvider_; }
TotalKmsProvider* BottomBarDataProvider::totalKmsProvider() const { return totalKmsProvider_; }
TimeProvider* BottomBarDataProvider::timeProvider() const { return timeProvider_; }

void BottomBarDataProvider::updateData()
{
    fuelProvider_->getValueFromFile();
    engineTempProvider_->getValueFromFile();
    envTempProvider_->getValueFromFile();
    totalKmsProvider_->getValueFromFile();
    timeProvider_->updateTime();
}
