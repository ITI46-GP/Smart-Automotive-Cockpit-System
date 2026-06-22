#include "vehicledataprovider.h"
#include <QDebug>

VehicleDataProvider::VehicleDataProvider(const QString &telemetryPath, QObject *parent)
    : QObject{parent}, telemetryPath_(telemetryPath)
{
    speedProvider_ = new SpeedProvider(this);
    rpmProvider_ = new RpmProvider(this);
    gearProvider_ = new GearProvider(this);
    bottomBar_ = new BottomBarDataProvider(this);
    contactsModel_ = new ContactsModel(this);
    musicController_ = new MusicController(this);
    steeringWheel_ = new SteeringWheelController(this);
    timer_ = new QTimer(this);
    // Connect TimerCallBack
    connect(timer_, &QTimer::timeout, this,&VehicleDataProvider::updateData);
    // Start Timer with 50 ms
    timer_ -> start(50);
}

void VehicleDataProvider::updateData()
{
    QFile file(telemetryPath_);
    if (file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        QByteArray val = file.readAll();
        file.close();
        
        QJsonDocument doc = QJsonDocument::fromJson(val);
        if (!doc.isNull() && doc.isObject()) {
            QJsonObject obj = doc.object();
            
            if (obj.contains("speed_kph")) {
                speedProvider_->setSpeedValue(static_cast<uint32_t>(obj["speed_kph"].toDouble()));
            }
            if (obj.contains("rpm")) {
                rpmProvider_->setRpmValue(obj["rpm"].toDouble());
            }
            if (obj.contains("gear")) {
                gearProvider_->setGearValue(obj["gear"].toString());
            }
        }
    }

    bottomBar_ -> updateData();
}

SpeedProvider* VehicleDataProvider::speedProvider() const
{
    return speedProvider_;
}
RpmProvider* VehicleDataProvider::rpmProvider() const
{
    return rpmProvider_;
}

BottomBarDataProvider* VehicleDataProvider::bottomBar() const
{
    return bottomBar_;
}

ContactsModel* VehicleDataProvider::contactsModel() const
{
    return contactsModel_;
}

MusicController* VehicleDataProvider::musicController() const
{
    return musicController_;
}

SteeringWheelController* VehicleDataProvider::steeringWheel() const
{
    return steeringWheel_;
}

GearProvider* VehicleDataProvider::gearProvider() const
{
    return gearProvider_;
}
