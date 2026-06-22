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
    explicit SpeedProvider(std::string path , QObject *parent = nullptr);
    uint32_t speedValue() const;
    bool getValueFromFile();
private:

    uint32_t speedValue_ = 0;
    std::string filePath_ = "";


signals:
    void speedValueChanged();
};

#endif // SPEEDPROVIDER_H
