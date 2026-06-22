#include "GearProvider.h"

GearProvider::GearProvider(QObject *parent)
    : QObject(parent)
{
}

QString GearProvider::gearValue() const
{
    return gearValue_;
}

void GearProvider::setGearValue(const QString &gear)
{
    if (gearValue_ != gear) {
        gearValue_ = gear;
        emit gearValueChanged();
    }
}
