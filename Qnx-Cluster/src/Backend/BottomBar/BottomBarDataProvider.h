// Ported verbatim from 02-Digital-Cluster/Backend/BottomBar/BottomBarDataProvider.h.
#pragma once

#include <QObject>
#include "FuelProvider.h"
#include "EngineTempProvider.h"
#include "EnvTempProvider.h"
#include "TotalKmsProvider.h"
#include "TimeProvider.h"

class BottomBarDataProvider : public QObject
{
    Q_OBJECT
    Q_PROPERTY(FuelProvider* fuelProvider READ fuelProvider CONSTANT)
    Q_PROPERTY(EngineTempProvider* engineTempProvider READ engineTempProvider CONSTANT)
    Q_PROPERTY(EnvTempProvider* envTempProvider READ envTempProvider CONSTANT)
    Q_PROPERTY(TotalKmsProvider* totalKmsProvider READ totalKmsProvider CONSTANT)
    Q_PROPERTY(TimeProvider* timeProvider READ timeProvider CONSTANT)

public:
    explicit BottomBarDataProvider(QObject *parent = nullptr);

    FuelProvider* fuelProvider() const;
    EngineTempProvider* engineTempProvider() const;
    EnvTempProvider* envTempProvider() const;
    TotalKmsProvider* totalKmsProvider() const;
    TimeProvider* timeProvider() const;

    void updateData();

private:
    FuelProvider* fuelProvider_;
    EngineTempProvider* engineTempProvider_;
    EnvTempProvider* envTempProvider_;
    TotalKmsProvider* totalKmsProvider_;
    TimeProvider* timeProvider_;
};
