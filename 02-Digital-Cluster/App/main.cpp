// Copyright (C) 2024 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

#include <QApplication>
#include <QDebug>
#include <QQmlApplicationEngine>
#include <QQmlContext>

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
#include "../Backend/GearProvider.h"

#include "autogen/environment.h"

#include "ClusterNavigationModel.hpp"
#include "HnclNavigationServer.hpp"

int main(int argc, char *argv[])
{
    set_qt_environment();

    QApplication app(argc, argv);

    /*
     * Keep the model alive for the entire lifetime of the QML engine.
     *
     * It is deliberately constructed before the HNCL server so the server
     * is stopped/destructed before the model during application shutdown.
     */
    hypernova::cluster::ClusterNavigationModel navigationModel;

    /*
     * Dedicated Android -> Digital Cluster navigation transport.
     *
     * This is independent from the existing Android HNVG / TCP 6100
     * vehicle + climate path.
     */
    hypernova::cluster::HnclNavigationServer navigationServer(
            6200,
            {
                [&navigationModel](bool connected) {
                    navigationModel.postConnectionState(
                            connected);
                },

                [&navigationModel](
                        const hypernova::cluster::hncl::NavigationState& state) {
                    navigationModel.postNavigationState(
                            state);
                },

                [&navigationModel]() {
                    navigationModel.postNavigationClear();
                }
            });

    if (!navigationServer.start()) {
        /*
         * The cluster UI must still start even if the Android navigation
         * transport cannot bind. This preserves the existing cluster
         * experience instead of making navigation networking a hard
         * dependency for the complete application.
         */
        qWarning()
                << "HNCL navigation server failed to start on TCP 6200";
    }

    QQmlApplicationEngine engine;

    /*
     * Backend data providers.
     *
     * Restored during the Digital_Cluster_dev merge: this branch's main.cpp
     * had grown the HNCL navigation transport but lost these registrations,
     * while Digital_Cluster_dev had the registrations but no navigation.
     * Screen01.qml on the merged tree references both clusterNavigation and
     * VehicleData.steeringWheel, so both have to be present.
     */
    VehicleDataProvider *backend = new VehicleDataProvider("telemetry.json", &app);
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
    qmlRegisterUncreatableType<GearProvider>("Backend", 1, 0, "GearProvider", "Cannot create GearProvider in QML");

    /*
     * Single backend object exposed to QML.
     *
     * QML usage:
     *
     *   clusterNavigation.connected
     *   clusterNavigation.navigationActive
     *   clusterNavigation.effectiveView
     *   clusterNavigation.destination
     *   clusterNavigation.remainingDistanceMeters
     *   clusterNavigation.selectView(1)
     */
    engine.rootContext()->setContextProperty(
            QStringLiteral("clusterNavigation"),
            &navigationModel);

    const QUrl url(mainQmlFile);

    QObject::connect(
            &engine,
            &QQmlApplicationEngine::objectCreated,
            &app,
            [url](QObject *obj, const QUrl &objUrl) {
                if (!obj && url == objUrl) {
                    QCoreApplication::exit(-1);
                }
            },
            Qt::QueuedConnection);

    engine.addImportPath(
            QCoreApplication::applicationDirPath()
            + "/qml");

    engine.addImportPath(":/");

    engine.load(url);

    if (engine.rootObjects().isEmpty()) {
        navigationServer.stop();
        return -1;
    }

    const int result = app.exec();

    navigationServer.stop();

    return result;
}
