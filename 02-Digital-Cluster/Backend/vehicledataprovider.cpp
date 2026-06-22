#include "vehicledataprovider.h"

VehicleDataProvider::VehicleDataProvider(std::string speedPath , std::string rpmPath, QObject *parent)
    : QObject{parent}
{
    speedProvider_ = new SpeedProvider(speedPath,this);
    rpmProvider_ = new RpmProvider(rpmPath,this);
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
    speedProvider_ ->getValueFromFile();
    rpmProvider_ -> getValueFromFile();
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
