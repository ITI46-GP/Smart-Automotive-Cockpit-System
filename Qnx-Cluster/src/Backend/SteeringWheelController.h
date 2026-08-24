// Ported verbatim from 02-Digital-Cluster/Backend/SteeringWheelController.h.
// Needs Qt6::Network (QUdpSocket/QNetworkDatagram) -- see CMakeLists.txt.
#pragma once

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
    void l3Pressed();
    void r3Pressed();
    void bindFailed(const QString &reason);

private slots:
    void processPendingDatagrams();

private:
    QUdpSocket *m_socket;
};
