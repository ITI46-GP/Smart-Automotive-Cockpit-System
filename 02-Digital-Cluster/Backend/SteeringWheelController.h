#ifndef STEERINGWHEELCONTROLLER_H
#define STEERINGWHEELCONTROLLER_H

#include <QObject>
#include <QUdpSocket>
#include <QNetworkDatagram>

class SteeringWheelController : public QObject
{
    Q_OBJECT
public:
    explicit SteeringWheelController(QObject *parent = nullptr);

signals:
    void upPressed();
    void downPressed();
    void leftPressed();
    void rightPressed();
    void okPressed();

private slots:
    void processPendingDatagrams();

private:
    QUdpSocket *m_socket;
};

#endif // STEERINGWHEELCONTROLLER_H
