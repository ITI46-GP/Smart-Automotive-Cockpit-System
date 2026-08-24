// Copyright (C) 2026 Hyper-Nova Cockpit
// SPDX-License-Identifier: GPL-3.0-only

#include <QCoreApplication>
#include <QDebug>
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickWindow>
#include <QSurfaceFormat>
#include <QStringList>

#include <QMetaObject>
#include <cstdint>
#include <cstdlib>
#include <utility>

#include "MapFrameBackend/MapFrameImageProvider.hpp"
#include "MapFrameBackend/MapFrameModel.hpp"
#include "MapFrameBackend/MapFrameServer.hpp"

#include "MediaBackend/ClusterMediaModel.hpp"
#include "MediaBackend/HnmcMediaServer.hpp"

#include "NavigationBackend/ClusterNavigationModel.hpp"
#include "NavigationBackend/HnclNavigationServer.hpp"

int main(int argc, char *argv[])
{
    /*
     * Frame-rate cap. A swap interval of N makes the buffer swap block for N
     * vblanks, so a 60 Hz display renders at 60/N fps.
     *
     * Display 4 has no physical panel attached -- the only consumer is the
     * 640x360 RTP stream, which runs at 30 fps, as does the RPi pipeline
     * receiving it. Rendering every vblank therefore produces one frame in
     * two that the DPU capture discards before anyone sees it. Measured on
     * the board: the cluster costs ~90% of a core at 60 fps and ~48% at 30.
     *
     * Parsed straight from argv rather than app.arguments() because the
     * default surface format has to be set before the first window exists,
     * and that happens inside QGuiApplication on some platforms.
     */
    {
        int interval = 1;
        for (int i = 1; i + 1 < argc; ++i) {
            if (qstrcmp(argv[i], "--swap-interval") == 0) {
                interval = atoi(argv[i + 1]);
                if (interval < 1)
                    interval = 1;
            }
        }
        if (interval != 1) {
            QSurfaceFormat fmt = QSurfaceFormat::defaultFormat();
            fmt.setSwapInterval(interval);
            QSurfaceFormat::setDefaultFormat(fmt);
            qInfo("swap-interval=%d requested", interval);
        }
    }

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
     * Completely independent from HNVG / TCP 6100.
     */
    hypernova::cluster::ClusterNavigationModel navigationModel;

    auto *mapFrameImageProvider =
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
                        const hypernova::cluster::hncl::NavigationState &state) {

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
                            [&mapFrameModel] {
                                mapFrameModel.clear();
                            },
                            Qt::QueuedConnection);

                    qInfo()
                            << "HNCL NAVIGATION_CLEAR";
                }
            });

    /*
     * Independent Android MapLibre JPEG mirror.
     *
     * HNMF transport:
     *
     *   Android Navigation = TCP client
     *   QNX Digital Cluster = TCP server
     *   TCP port = 6201
     */
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
                    qInfo()
                            << "HNMF Android map-frame connection:"
                            << (connected
                                    ? "READY"
                                    : "DISCONNECTED");
                }
            });

    /*
     * Android -> QNX Digital Cluster media-state backend.
     *
     * Dedicated HNMC transport:
     *
     *   Android HyperNova Media = TCP client
     *   QNX Digital Cluster     = TCP server
     *   TCP port                = 6300
     *
     * HNMC is independent from:
     *
     *   HNVG 6100
     *   HNCL 6200
     *   HNMF 6201
     */
    hypernova::cluster::ClusterMediaModel mediaModel;

    hypernova::cluster::HnmcMediaServer mediaServer(
            6300,
            {
                [&mediaModel](bool connected) {
                    mediaModel.postConnectionState(
                            connected);

                    qInfo()
                            << "HNMC Android media connection:"
                            << (connected
                                    ? "READY"
                                    : "DISCONNECTED");
                },

                [&mediaModel](
                        const hypernova::cluster::hnmc::MediaState &state) {

                    mediaModel.postMediaState(
                            state);

                    qInfo()
                            << "HNMC MEDIA_STATE"
                            << "hasMedia=" << state.hasMedia
                            << "playing=" << state.playing
                            << "positionMs="
                            << static_cast<qulonglong>(
                                    state.positionMs)
                            << "durationMs="
                            << static_cast<qulonglong>(
                                    state.durationMs)
                            << "title="
                            << QString::fromUtf8(
                                    state.title.data(),
                                    static_cast<qsizetype>(
                                            state.title.size()))
                            << "artist="
                            << QString::fromUtf8(
                                    state.artist.data(),
                                    static_cast<qsizetype>(
                                            state.artist.size()));
                },

                [&mediaModel]() {
                    mediaModel.postMediaClear();

                    qInfo()
                            << "HNMC MEDIA_CLEAR";
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
        qWarning()
                << "HNMF: failed to listen on TCP 6201";
    } else {
        qInfo()
                << "HNMF: Digital Cluster frame server listening on TCP"
                << mapFrameServer.boundPort();
    }

    if (!mediaServer.start()) {
        qWarning()
                << "HNMC: failed to listen on TCP 6300";
    } else {
        qInfo()
                << "HNMC: Digital Cluster media server listening on TCP"
                << mediaServer.boundPort();
    }

    QQmlApplicationEngine engine;

    engine.addImageProvider(
            QStringLiteral("hnmf"),
            mapFrameImageProvider);

    engine.rootContext()->setContextProperty(
            QStringLiteral("clusterNavigation"),
            &navigationModel);

    engine.rootContext()->setContextProperty(
            QStringLiteral("mapFrames"),
            &mapFrameModel);

    /*
     * Media QML binding is intentionally separate from the old
     * VehicleData.musicController mock implementation.
     *
     * Next step:
     *
     * MusicView.qml -> clusterMedia
     */
    engine.rootContext()->setContextProperty(
            QStringLiteral("clusterMedia"),
            &mediaModel);

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

    mediaServer.stop();
    mapFrameServer.stop();
    navigationServer.stop();

    return result;
}
