// Copyright (C) 2026 Hyper-Nova Cockpit
// SPDX-License-Identifier: GPL-3.0-only

#include <QCoreApplication>
#include <QDebug>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickWindow>
#include <QStringList>

#include "NavigationBackend/ClusterNavigationModel.hpp"
#include "NavigationBackend/HnclNavigationServer.hpp"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    // S7 experiment: glyph render path.
    if (app.arguments().contains(QStringLiteral("--native-text"))) {
        QQuickWindow::setTextRenderType(
                QQuickWindow::NativeTextRendering);
    }

    /*
     * Android -> QNX Digital Cluster navigation backend.
     *
     * Dedicated HNCL transport:
     *
     *   Android VehicleGateway = TCP client
     *   QNX Digital Cluster    = TCP server
     *   TCP port               = 6200
     *
     * This is completely independent from HNVG / TCP 6100.
     */
    hypernova::cluster::ClusterNavigationModel navigationModel;

    hypernova::cluster::HnclNavigationServer navigationServer(
            6200,
            {
                [&navigationModel](bool connected) {
                    navigationModel.postConnectionState(
                            connected);

                    qInfo()
                            << "HNCL Android connection:"
                            << (connected
                                    ? "READY"
                                    : "DISCONNECTED");
                },

                [&navigationModel](
                        const hypernova::cluster::hncl::NavigationState& state) {
                    navigationModel.postNavigationState(
                            state);

                    qInfo()
                            << "HNCL NAVIGATION_STATE"
                            << "active=" << state.active
                            << "remainingDistance="
                            << state.remainingDistanceMeters
                            << "destination="
                            << QString::fromStdString(
                                    state.destination);
                },

                [&navigationModel]() {
                    navigationModel.postNavigationClear();

                    qInfo()
                            << "HNCL NAVIGATION_CLEAR";
                }
            });

    if (!navigationServer.start()) {
        qWarning()
                << "HNCL: failed to listen on TCP 6200";
    } else {
        qInfo()
                << "HNCL: Digital Cluster server listening on TCP"
                << navigationServer.boundPort();
    }

    QQmlApplicationEngine engine;

    /*
     * Prepared for the next integration step.
     *
     * QML will later use:
     *
     *   clusterNavigation.connected
     *   clusterNavigation.navigationActive
     *   clusterNavigation.effectiveView
     *   clusterNavigation.destination
     *   clusterNavigation.selectView(...)
     */
    engine.rootContext()->setContextProperty(
            QStringLiteral("clusterNavigation"),
            &navigationModel);

    QObject::connect(
            &engine,
            &QQmlApplicationEngine::objectCreationFailed,
            &app,
            [] {
                QCoreApplication::exit(-1);
            },
            Qt::QueuedConnection);

    engine.loadFromModule(
            "QnxCluster",
            "Main");

    const int result =
            app.exec();

    navigationServer.stop();

    return result;
}
