#ifndef SPEEDPROVIDER_H
#define SPEEDPROVIDER_H

#include <QObject>
#include <string>

#define MAX_SPEED 240
#define MIN_SPEED 0

class SpeedProvider : public QObject
{
    Q_OBJECT

    Q_PROPERTY(uint32_t speedValue READ speedValue NOTIFY speedValueChanged FINAL)
public:
    explicit SpeedProvider(QObject *parent = nullptr);
    uint32_t speedValue() const;
    void setSpeedValue(uint32_t speed);

private:
    uint32_t speedValue_ = 0;

signals:
    void speedValueChanged();
};

#endif // SPEEDPROVIDER_H
