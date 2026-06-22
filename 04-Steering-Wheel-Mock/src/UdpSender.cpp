#include "UdpSender.h"
#include <QNetworkDatagram>

UdpSender::UdpSender(QObject *parent) : QObject(parent)
{
    m_socket = new QUdpSocket(this);
}

void UdpSender::sendCommand(const QString &command)
{
    QByteArray datagram = command.toUtf8();
    // Broadcast on localhost to port 8888
    m_socket->writeDatagram(datagram, QHostAddress::LocalHost, 8888);
}
