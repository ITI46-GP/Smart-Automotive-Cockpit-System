#include "TimeProvider.h"
#include <QTime>

TimeProvider::TimeProvider(QObject *parent) : QObject{parent}
{
}

QString TimeProvider::timeValue() const
{
    return timeValue_;
}

void TimeProvider::updateTime()
{
    QString newTime = QTime::currentTime().toString("hh:mm AP");
    if (newTime != timeValue_) {
        timeValue_ = newTime;
        emit timeValueChanged();
    }
}
