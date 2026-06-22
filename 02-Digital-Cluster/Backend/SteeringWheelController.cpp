#include "SteeringWheelController.h"

SteeringWheelController::SteeringWheelController(QObject *parent)
    : QObject(parent)
{
    m_socket = new QUdpSocket(this);
    m_socket->bind(QHostAddress::LocalHost, 8888);

    connect(m_socket, &QUdpSocket::readyRead, this, &SteeringWheelController::processPendingDatagrams);
}

void SteeringWheelController::processPendingDatagrams()
{
    while (m_socket->hasPendingDatagrams()) {
        QNetworkDatagram datagram = m_socket->receiveDatagram();
        QString cmd = QString::fromUtf8(datagram.data()).trimmed();

        if (cmd == "BTN_UP") {
            emit upPressed();
        } else if (cmd == "BTN_DOWN") {
            emit downPressed();
        } else if (cmd == "BTN_LEFT") {
            emit leftPressed();
        } else if (cmd == "BTN_RIGHT") {
            emit rightPressed();
        } else if (cmd == "BTN_OK") {
            emit okPressed();
        }
    }
}
