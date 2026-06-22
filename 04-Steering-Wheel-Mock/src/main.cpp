#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include "UdpSender.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);

    UdpSender udpSender;

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("udpSender", &udpSender);
    const QUrl url(u"qrc:/SteeringWheel/src/Main.qml"_qs);
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed,
        &app, []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.load(url);

    return app.exec();
}
