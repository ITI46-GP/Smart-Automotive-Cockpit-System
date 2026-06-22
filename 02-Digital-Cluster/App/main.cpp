// Copyright (C) 2024 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

#include <QApplication>
#include <QQmlApplicationEngine>
#include "../Backend/vehicledataprovider.h"
#include "../Backend/BottomBar/BottomBarDataProvider.h"
#include "../Backend/BottomBar/FuelProvider.h"
#include "../Backend/BottomBar/EngineTempProvider.h"
#include "../Backend/BottomBar/EnvTempProvider.h"
#include "../Backend/BottomBar/TotalKmsProvider.h"
#include "../Backend/BottomBar/TimeProvider.h"
#include "../Backend/ContentArea/ContactsModel.h"
#include "../Backend/ContentArea/MusicController.h"
#include "../Backend/SteeringWheelController.h"

#include "autogen/environment.h"

int main(int argc, char *argv[])
{
    set_qt_environment();
    QApplication app(argc, argv);

    QQmlApplicationEngine engine;
    VehicleDataProvider *backend = new VehicleDataProvider("/tmp/ivi/speed.txt", "/tmp/ivi/rpm.txt", &app);
    qmlRegisterSingletonInstance("Backend", 1, 0, "VehicleData", backend);
    qmlRegisterUncreatableType<SpeedProvider>("Backend", 1, 0, "SpeedProvider", "Cannot create SpeedProvider in QML");
    qmlRegisterUncreatableType<RpmProvider>("Backend", 1, 0, "RpmProvider", "Cannot create RpmProvider in QML");
    qmlRegisterUncreatableType<BottomBarDataProvider>("Backend", 1, 0, "BottomBarDataProvider", "Cannot create BottomBarDataProvider in QML");
    qmlRegisterUncreatableType<FuelProvider>("Backend", 1, 0, "FuelProvider", "Cannot create FuelProvider in QML");
    qmlRegisterUncreatableType<EngineTempProvider>("Backend", 1, 0, "EngineTempProvider", "Cannot create EngineTempProvider in QML");
    qmlRegisterUncreatableType<EnvTempProvider>("Backend", 1, 0, "EnvTempProvider", "Cannot create EnvTempProvider in QML");
    qmlRegisterUncreatableType<TotalKmsProvider>("Backend", 1, 0, "TotalKmsProvider", "Cannot create TotalKmsProvider in QML");
    qmlRegisterUncreatableType<TimeProvider>("Backend", 1, 0, "TimeProvider", "Cannot create TimeProvider in QML");
    qmlRegisterUncreatableType<ContactsModel>("Backend", 1, 0, "ContactsModel", "Cannot create ContactsModel in QML");
    qmlRegisterUncreatableType<MusicController>("Backend", 1, 0, "MusicController", "Cannot create MusicController in QML");
    qmlRegisterUncreatableType<SteeringWheelController>("Backend", 1, 0, "SteeringWheelController", "Cannot create SteeringWheelController in QML");
    const QUrl url(mainQmlFile);
    QObject::connect(
                &engine, &QQmlApplicationEngine::objectCreated, &app,
                [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl)
            QCoreApplication::exit(-1);
    }, Qt::QueuedConnection);

    engine.addImportPath(QCoreApplication::applicationDirPath() + "/qml");
    engine.addImportPath(":/");
    engine.load(url);

    if (engine.rootObjects().isEmpty())
        return -1;

    return app.exec();
}
