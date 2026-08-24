#include "UdpSender.h"

#include <QDebug>
#include <QNetworkDatagram>

namespace {

// Where the cluster's SteeringWheelController is listening.
//
// This used to be hardcoded to QHostAddress::LocalHost, which meant the mock
// could only ever drive a cluster running on the same machine. In the real
// cockpit the cluster is on the QNX guest, so the target has to be settable
// without a rebuild:
//
//   HNC_CLUSTER_HOST=192.168.1.51 ./SteeringWheelMock
//
// Default stays loopback so existing local use is unchanged.
QHostAddress targetHost()
{
    const QString host = qEnvironmentVariable("HNC_CLUSTER_HOST");
    if (host.isEmpty())
        return QHostAddress(QHostAddress::LocalHost);

    QHostAddress addr(host);
    if (addr.isNull()) {
        qWarning() << "[WheelMock] HNC_CLUSTER_HOST is not a valid IP:" << host
                   << "- falling back to localhost.";
        return QHostAddress(QHostAddress::LocalHost);
    }
    return addr;
}

quint16 targetPort()
{
    bool ok = false;
    const quint16 port = qEnvironmentVariableIntValue("HNC_WHEEL_PORT", &ok);
    return (ok && port != 0) ? port : 8888;
}

} // namespace

UdpSender::UdpSender(QObject *parent)
    : QObject(parent), m_host(targetHost()), m_port(targetPort())
{
    m_socket = new QUdpSocket(this);
    qInfo() << "[WheelMock] sending BTN_* to" << m_host.toString() << ":" << m_port;
}

void UdpSender::sendCommand(const QString &command)
{
    const QByteArray datagram = command.toUtf8();
    if (m_socket->writeDatagram(datagram, m_host, m_port) == -1) {
        qWarning() << "[WheelMock] send failed:" << m_socket->errorString();
    }
}
