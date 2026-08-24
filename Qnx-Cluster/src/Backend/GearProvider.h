// Ported verbatim from 02-Digital-Cluster/Backend/GearProvider.h.
#pragma once

#include <QObject>
#include <QString>

class GearProvider : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString gearValue READ gearValue NOTIFY gearValueChanged FINAL)

public:
    explicit GearProvider(QObject *parent = nullptr);

    QString gearValue() const;
    void setGearValue(const QString &gear);

signals:
    void gearValueChanged();

private:
    QString gearValue_ = "P";
};
