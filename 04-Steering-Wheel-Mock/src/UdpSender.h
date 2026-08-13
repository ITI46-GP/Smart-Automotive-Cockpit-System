#ifndef UDPSENDER_H
#define UDPSENDER_H

#include <QObject>
#include <QHostAddress>
#include <QUdpSocket>

class UdpSender : public QObject
{
    Q_OBJECT
public:
    explicit UdpSender(QObject *parent = nullptr);

    Q_INVOKABLE void sendCommand(const QString &command);

private:
    QUdpSocket *m_socket;
    QHostAddress m_host;
    quint16 m_port;
};

#endif // UDPSENDER_H
