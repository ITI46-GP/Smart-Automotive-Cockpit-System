#ifndef VEHICLEDATAPROVIDER_H
#define VEHICLEDATAPROVIDER_H

#include <QObject>
#include "Speedprovider.h"
#include "Rpmprovider.h"
#include "BottomBar/BottomBarDataProvider.h"
#include "ContentArea/ContactsModel.h"
#include "ContentArea/MusicController.h"
#include "SteeringWheelController.h"

#include <string>
#include <QTimer>

class VehicleDataProvider : public QObject
{
    Q_OBJECT
    Q_PROPERTY(SpeedProvider* speedProvider READ speedProvider CONSTANT)
    Q_PROPERTY(RpmProvider* rpmProvider READ rpmProvider CONSTANT)
    Q_PROPERTY(BottomBarDataProvider* bottomBar READ bottomBar CONSTANT)
    Q_PROPERTY(ContactsModel* contactsModel READ contactsModel CONSTANT)
    Q_PROPERTY(MusicController* musicController READ musicController CONSTANT)
    Q_PROPERTY(SteeringWheelController* steeringWheel READ steeringWheel CONSTANT)
public:
    explicit VehicleDataProvider(std::string speedPath , std::string rpmPath, QObject *parent = nullptr);

    // Getters to satisfy the Q_PROPERTY macros
    SpeedProvider* speedProvider() const;
    RpmProvider* rpmProvider() const;
    BottomBarDataProvider* bottomBar() const;
    ContactsModel* contactsModel() const;
    MusicController* musicController() const;
    SteeringWheelController* steeringWheel() const;

private:
    SpeedProvider* speedProvider_;
    RpmProvider* rpmProvider_;
    BottomBarDataProvider* bottomBar_;
    ContactsModel* contactsModel_;
    MusicController* musicController_;
    SteeringWheelController* steeringWheel_;

    QTimer* timer_;

private slots:
    void updateData();

};

#endif // VEHICLEDATAPROVIDER_H
