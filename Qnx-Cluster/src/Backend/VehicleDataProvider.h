// Ported from 02-Digital-Cluster/Backend/vehicledataprovider.h.
//
// Registration differs from the reference on purpose. The reference used
// `qmlRegisterSingletonInstance` from main.cpp. This project already has a
// PROVEN working pattern for exactly this problem (see src/Theme.h's long
// comment): a real C++ QML_SINGLETON, registered automatically by
// qt_add_qml_module via QML_NAMED_ELEMENT/QML_SINGLETON — the QML-authored
// `pragma Singleton` route was tried twice on Theme and silently resolved
// to `undefined` both times. Theme is default-constructible so the macro
// alone was enough; VehicleDataProvider needs a telemetry.json path, so it
// additionally needs the static `create()` factory Qt's singleton
// mechanism calls when there's no default constructor.
#pragma once

#include <QObject>
#include <QString>
#include <QTimer>
#include <qqml.h>

#include "SpeedProvider.h"
#include "RpmProvider.h"
#include "GearProvider.h"
#include "BottomBar/BottomBarDataProvider.h"
#include "ContentArea/ContactsModel.h"
#include "ContentArea/MusicController.h"
#include "SteeringWheelController.h"

class QQmlEngine;
class QJSEngine;

class VehicleDataProvider : public QObject
{
    Q_OBJECT
    QML_NAMED_ELEMENT(VehicleData)
    QML_SINGLETON

    Q_PROPERTY(SpeedProvider* speedProvider READ speedProvider CONSTANT)
    Q_PROPERTY(RpmProvider* rpmProvider READ rpmProvider CONSTANT)
    Q_PROPERTY(GearProvider* gearProvider READ gearProvider CONSTANT)
    Q_PROPERTY(BottomBarDataProvider* bottomBar READ bottomBar CONSTANT)
    Q_PROPERTY(ContactsModel* contactsModel READ contactsModel CONSTANT)
    Q_PROPERTY(MusicController* musicController READ musicController CONSTANT)
    Q_PROPERTY(SteeringWheelController* steeringWheel READ steeringWheel CONSTANT)

public:
    explicit VehicleDataProvider(const QString &telemetryPath, QObject *parent = nullptr);

    SpeedProvider* speedProvider() const;
    RpmProvider* rpmProvider() const;
    GearProvider* gearProvider() const;
    BottomBarDataProvider* bottomBar() const;
    ContactsModel* contactsModel() const;
    MusicController* musicController() const;
    SteeringWheelController* steeringWheel() const;

    // Called once by the QML engine to construct the singleton. Owns the
    // one place the telemetry path is hardcoded, matching the reference's
    // main.cpp (`new VehicleDataProvider("telemetry.json", &app)`).
    static VehicleDataProvider *create(QQmlEngine *qmlEngine, QJSEngine *jsEngine);

private:
    SpeedProvider* speedProvider_;
    RpmProvider* rpmProvider_;
    GearProvider* gearProvider_;
    BottomBarDataProvider* bottomBar_;
    ContactsModel* contactsModel_;
    MusicController* musicController_;
    SteeringWheelController* steeringWheel_;

    QTimer* timer_;
    QString telemetryPath_;

public slots:
    void updateData();
};
