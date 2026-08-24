#include "SpeedProvider.h"

SpeedProvider::SpeedProvider(QObject *parent)
    : QObject{parent}
{
}

uint32_t SpeedProvider::speedValue() const
{
    return speedValue_;
}

void SpeedProvider::setSpeedValue(uint32_t speed)
{
    if (speed < MIN_SPEED || speed > MAX_SPEED) {
        return;
    }

    if (speed != speedValue_) {
        speedValue_ = speed;
        emit speedValueChanged();
    }
}
