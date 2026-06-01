#ifndef HVACCONTROLLER_H
#define HVACCONTROLLER_H

#include <QObject>

class HvacController : public QObject
{
    Q_OBJECT
    Q_PROPERTY(double driverTemp READ driverTemp WRITE setDriverTemp NOTIFY driverTempChanged)
    Q_PROPERTY(double passengerTemp READ passengerTemp WRITE setPassengerTemp NOTIFY passengerTempChanged)
    Q_PROPERTY(int fanSpeed READ fanSpeed WRITE setFanSpeed NOTIFY fanSpeedChanged)
    Q_PROPERTY(bool acOn READ acOn WRITE setAcOn NOTIFY acOnChanged)
    Q_PROPERTY(int fanMode READ fanMode WRITE setFanMode NOTIFY fanModeChanged)
    Q_PROPERTY(bool driverPowerOn READ driverPowerOn WRITE setDriverPowerOn NOTIFY driverPowerOnChanged)
    Q_PROPERTY(bool passengerPowerOn READ passengerPowerOn WRITE setPassengerPowerOn NOTIFY passengerPowerOnChanged)

public:
    explicit HvacController(QObject *parent = nullptr);

    double driverTemp() const;
    double passengerTemp() const;
    int fanSpeed() const;
    bool acOn() const;
    int fanMode() const;
    bool driverPowerOn() const;
    bool passengerPowerOn() const;

public slots:
    void setDriverTemp(double t);
    void setPassengerTemp(double t);
    void setFanSpeed(int s);
    void setAcOn(bool on);
    void setFanMode(int m);
    void setDriverPowerOn(bool on);
    void setPassengerPowerOn(bool on);

    void increaseDriverTemp();
    void decreaseDriverTemp();
    void increasePassengerTemp();
    void decreasePassengerTemp();
    void increaseFanSpeed();
    void decreaseFanSpeed();
    void toggleAc();
    void toggleDriverPower();
    void togglePassengerPower();
    void setFanModeIndex(int idx);

signals:
    void driverTempChanged();
    void passengerTempChanged();
    void fanSpeedChanged();
    void acOnChanged();
    void fanModeChanged();
    void driverPowerOnChanged();
    void passengerPowerOnChanged();

private:
    double m_driverTemp = 23.0;
    double m_passengerTemp = 23.0;
    int m_fanSpeed = 3;
    bool m_acOn = true;
    int m_fanMode = 0;
    bool m_driverPowerOn = true;
    bool m_passengerPowerOn = false;
};

#endif