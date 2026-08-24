#include "SteeringWheelController.h"

#include <QByteArray>
#include <QDebug>
#include <QHostAddress>
#include <QLoggingCategory>

namespace {

// Port the steering-wheel mock sends BTN_* datagrams to.
// Override with HNC_WHEEL_PORT if 8888 ever collides on the guest.
quint16 listenPort()
{
    bool ok = false;
    const quint16 port = qEnvironmentVariableIntValue("HNC_WHEEL_PORT", &ok);
    return (ok && port != 0) ? port : 8888;
}

} // namespace

SteeringWheelController::SteeringWheelController(QObject *parent)
    : QObject(parent)
{
    m_socket = new QUdpSocket(this);

    // Bind to ANY, not LocalHost.
    //
    // This was `bind(QHostAddress::LocalHost, 8888)`, which accepts datagrams
    // only from 127.0.0.1. That works when the sender and the cluster are the
    // same machine, but in the real cockpit the wheel's D-pad is on the LAPTOP
    // and the cluster runs on the QNX guest -- so every BTN_* datagram arrived
    // at the guest's external interface and was silently dropped. The menu
    // simply never responded and there was no error anywhere to explain why.
    //
    // ShareAddress + ReuseAddressHint so a crashed/restarted cluster can rebind
    // immediately instead of losing the port to TIME_WAIT until the guest is
    // rebooted -- on a demo bench, a port you cannot reclaim is a dead demo.
    const quint16 port = listenPort();
    const bool bound = m_socket->bind(QHostAddress::Any, port,
                                      QAbstractSocket::ShareAddress
                                          | QAbstractSocket::ReuseAddressHint);

    // The original ignored bind()'s return value entirely. A failed bind is
    // exactly the kind of fault that presents as "the buttons do nothing" and
    // costs an hour on the bench, so say so loudly instead of failing silently.
    if (!bound) {
        const QString reason = m_socket->errorString();
        qWarning() << "[SteeringWheel] FAILED to bind UDP" << port
                   << "-" << reason
                   << "- steering-wheel buttons will not respond.";
        emit bindFailed(QStringLiteral("Steering wheel UDP port %1 unavailable: %2")
                             .arg(port).arg(reason));
    } else {
        qInfo() << "[SteeringWheel] listening for BTN_* on UDP" << port;
    }

    connect(m_socket, &QUdpSocket::readyRead, this, &SteeringWheelController::processPendingDatagrams);
}

void SteeringWheelController::processPendingDatagrams()
{
    while (m_socket->hasPendingDatagrams()) {
        QNetworkDatagram datagram = m_socket->receiveDatagram();
        const QString cmd = QString::fromUtf8(datagram.data()).trimmed();

        if (cmd == QLatin1String("BTN_UP")) {
            emit upPressed();
        } else if (cmd == QLatin1String("BTN_DOWN")) {
            emit downPressed();
        } else if (cmd == QLatin1String("BTN_LEFT")) {
            emit leftPressed();
        } else if (cmd == QLatin1String("BTN_RIGHT")) {
            emit rightPressed();
        } else if (cmd == QLatin1String("BTN_OK")) {
            emit okPressed();
        } else if (cmd == QLatin1String("BTN_L3")) {
            emit l3Pressed();
        } else if (cmd == QLatin1String("BTN_R3")) {
            emit r3Pressed();
        }
        // Unknown commands are ignored on purpose: this socket is open to the
        // bench LAN, so anything else that lands on the port must not be able
        // to drive the UI.
    }
}
