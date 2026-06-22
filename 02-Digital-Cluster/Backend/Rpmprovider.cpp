#include "Rpmprovider.h"
#include <fstream>

RpmProvider::RpmProvider(QObject *parent)
    : QObject{parent}
{

}

qreal RpmProvider::rpmValue() const
{
    return rpmValue_;
}

void RpmProvider::setRpmValue(qreal rpm)
{
    // The JSON provides raw RPM (e.g., 2100), but gauge expects 0 to 8.0
    qreal normalizedRpm = rpm / 1000.0;

    if (normalizedRpm < MIN_RPM || normalizedRpm > MAX_RPM) {
        return;
    }

    if (normalizedRpm != rpmValue_) {
        rpmValue_ = normalizedRpm;
        emit rpmValueChanged();
    }
}
