// Copyright (C) 2026 Hyper-Nova Cockpit
// SPDX-License-Identifier: GPL-3.0-only

#include <QCoreApplication>
#include <QDebug>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickWindow>
#include <QStringList>

#include <QMetaObject>
#include <cstdint>
#include <utility>

#include "MapFrameBackend/MapFrameImageProvider.hpp"
#include "MapFrameBackend/MapFrameModel.hpp"
#include "MapFrameBackend/MapFrameServer.hpp"
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
    auto* mapFrameImageProvider =
            new hypernova::cluster::MapFrameImageProvider;
    hypernova::cluster::MapFrameModel mapFrameModel(
            mapFrameImageProvider);

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

                [&navigationModel, &mapFrameModel]() {
                    navigationModel.postNavigationClear();
                    QMetaObject::invokeMethod(
                            &mapFrameModel,
                            [&mapFrameModel] { mapFrameModel.clear(); },
                            Qt::QueuedConnection);

                    qInfo()
                            << "HNCL NAVIGATION_CLEAR";
                }
            });

    /* Independent Android MapLibre JPEG mirror; HNMF / TCP 6201 only. */
    hypernova::cluster::MapFrameServer mapFrameServer(
            6201,
            {
                [&mapFrameModel](
                        QImage image,
                        std::uint32_t sequence,
                        std::uint64_t captureTimestampMs) {
                    mapFrameModel.postFrame(
                            std::move(image),
                            sequence,
                            captureTimestampMs);
                },
                [](bool connected) {
                    qInfo() << "HNMF Android map-frame connection:"
                            << (connected ? "READY" : "DISCONNECTED");
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

    if (!mapFrameServer.start()) {
        qWarning() << "HNMF: failed to listen on TCP 6201";
    } else {
        qInfo() << "HNMF: Digital Cluster frame server listening on TCP"
                << mapFrameServer.boundPort();
    }

    QQmlApplicationEngine engine;

    engine.addImageProvider(
            QStringLiteral("hnmf"),
            mapFrameImageProvider);

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
    engine.rootContext()->setContextProperty(
            QStringLiteral("mapFrames"),
            &mapFrameModel);

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

    mapFrameServer.stop();
    navigationServer.stop();

    return result;
}
