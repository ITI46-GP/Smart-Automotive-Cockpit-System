// Ported verbatim from 02-Digital-Cluster/Backend/BottomBar/FuelProvider.h.
#pragma once

#include <QObject>
#include <string>

class FuelProvider : public QObject
{
    Q_OBJECT
    Q_PROPERTY(qreal fuelValue READ fuelValue NOTIFY fuelValueChanged FINAL)

public:
    explicit FuelProvider(std::string path, QObject *parent = nullptr);
    qreal fuelValue() const;
    bool getValueFromFile();

private:
    qreal fuelValue_ = 80.0;
    std::string filePath_;

signals:
    void fuelValueChanged();
};
