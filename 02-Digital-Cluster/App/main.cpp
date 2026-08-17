// Copyright (C) 2024 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

#include <QApplication>
#include <QDebug>
#include <QQmlApplicationEngine>
#include <QQmlContext>

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
