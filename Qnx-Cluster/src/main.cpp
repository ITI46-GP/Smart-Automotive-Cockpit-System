// Copyright (C) 2026 Hyper-Nova Cockpit
// SPDX-License-Identifier: GPL-3.0-only

#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQuickWindow>
#include <QStringList>

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    // ── S7 experiment: glyph render path ──────────────────────────────
    // Measured decomposition of S7's 14 ms render thread: ~36 Text items
    // account for 6 ms of it (gauge text 4 ms, bottom-bar text 2 ms) — more
    // than the 60 segmented-bar Rectangles at 3 ms. That fits the mechanism
    // S6 established on this board: it is fill/blend bound, and Qt's default
    // distance-field text draws every glyph as a blended quad whose
    // antialiased falloff region is larger than the glyph itself.
    //
    // NativeTextRendering rasterises glyphs to tight bitmaps instead.
    //
    // MEASURED, AND IT DOES NOT HELP: render p95 16 ms with native vs 15 ms
    // with the default distance-field path, frame period p99 25 vs 23 ms —
    // slightly WORSE, and no better on any metric. So the cost is not the
    // glyph rasterisation path; it is the number of blended glyph quads,
    // which is identical either way. Default left unchanged; the flag stays
    // only so this negative result is re-checkable rather than re-theorised.
    //
    // This must be set before any window exists, and Qt exposes it only as a
    // global — hence C++ here rather than a property in QML.
    if (app.arguments().contains(QStringLiteral("--native-text")))
        QQuickWindow::setTextRenderType(QQuickWindow::NativeTextRendering);

    QQmlApplicationEngine engine;
    QObject::connect(
        &engine, &QQmlApplicationEngine::objectCreationFailed,
        &app, [] { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);

    // Theme registers itself as a QML_SINGLETON (see src/Theme.h) via the
    // QML_NAMED_ELEMENT/QML_SINGLETON macros picked up by qt_add_qml_module
    // — no manual qmlRegisterSingletonInstance call needed here, and
    // nothing to load/instantiate by hand. Any QML file that does
    // `import QnxCluster` sees it as `Theme`.

    // Resolves through the QnxCluster module's type system, not a
    // hand-built qrc path, so it doesn't care whether qt_add_qml_module
    // preserved a qml/ subdirectory in the embedded resource path.
    engine.loadFromModule("QnxCluster", "Main");

    return app.exec();
}
