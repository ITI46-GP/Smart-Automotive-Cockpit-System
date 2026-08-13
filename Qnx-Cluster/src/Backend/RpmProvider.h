// Ported verbatim from 02-Digital-Cluster/Backend/Rpmprovider.h.
#pragma once

#include <QObject>

#define MIN_RPM 0
#define MAX_RPM 8.0

class RpmProvider : public QObject
{
    Q_OBJECT
    Q_PROPERTY(qreal rpmValue READ rpmValue NOTIFY rpmValueChanged FINAL)

public:
    explicit RpmProvider(QObject *parent = nullptr);
    qreal rpmValue() const;
    void setRpmValue(qreal rpm);

private:
    qreal rpmValue_ = 0;

signals:
    void rpmValueChanged();
};
