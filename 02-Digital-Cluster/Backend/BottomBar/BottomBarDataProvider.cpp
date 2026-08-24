#include "BottomBarDataProvider.h"

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
