#ifndef UDPSENDER_H
#define UDPSENDER_H

#include <QObject>
#include <QUdpSocket>

class UdpSender : public QObject
{
    Q_OBJECT
public:
    explicit UdpSender(QObject *parent = nullptr);

    Q_INVOKABLE void sendCommand(const QString &command);

private:
    QUdpSocket *m_socket;
};

#endif // UDPSENDER_H
