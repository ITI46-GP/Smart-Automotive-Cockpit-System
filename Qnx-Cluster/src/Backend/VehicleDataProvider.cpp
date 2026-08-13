#include "VehicleDataProvider.h"

#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QQmlEngine>

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
    connect(timer_, &QTimer::timeout, this, &VehicleDataProvider::updateData);
    timer_->start(50);
}

VehicleDataProvider *VehicleDataProvider::create(QQmlEngine *qmlEngine, QJSEngine *jsEngine)
{
    Q_UNUSED(qmlEngine)
    Q_UNUSED(jsEngine)
    // 2026-08-13: was a bare relative "telemetry.json", matching the
    // reference. On this board that resolves against the app's cwd, which
    // over this project's ssh launch harness is /home/qnxuser -- confirmed
    // NOT writable (`touch` there fails with ENOENT despite `ls` succeeding
    // on the directory itself; likely a read-only-mounted base image path).
    // /tmp is the only location proven writable all session (it's where
    // every TrialCluster* binary, log, and the /tmp/ivi/*.txt bottom-bar
    // files already live) -- made absolute and consistent with those
    // instead of leaving telemetry.json as the one file nothing could ever
    // actually write to.
    // No QObject parent: the QML engine takes ownership of a QML_SINGLETON
    // instance created this way.
    return new VehicleDataProvider(QStringLiteral("/tmp/telemetry.json"));
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

    bottomBar_->updateData();
}

SpeedProvider* VehicleDataProvider::speedProvider() const { return speedProvider_; }
RpmProvider* VehicleDataProvider::rpmProvider() const { return rpmProvider_; }
GearProvider* VehicleDataProvider::gearProvider() const { return gearProvider_; }
BottomBarDataProvider* VehicleDataProvider::bottomBar() const { return bottomBar_; }
ContactsModel* VehicleDataProvider::contactsModel() const { return contactsModel_; }
MusicController* VehicleDataProvider::musicController() const { return musicController_; }
SteeringWheelController* VehicleDataProvider::steeringWheel() const { return steeringWheel_; }
