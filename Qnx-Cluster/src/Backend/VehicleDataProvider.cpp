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
    connect(steeringWheel_, &SteeringWheelController::bindFailed,
            this, &VehicleDataProvider::errorOccurred);
    timer_ = new QTimer(this);
    connect(timer_, &QTimer::timeout, this, &VehicleDataProvider::updateData);
    timer_->start(50);
}

QString VehicleDataProvider::resolveTelemetryPath()
{
    // Overridable at launch, so a path change never needs a rebuild again:
    //     HNC_TELEMETRY_PATH=/tmp/telemetry.json ./QnxClusterApp
    const QString override = qEnvironmentVariable("HNC_TELEMETRY_PATH");
    if (!override.isEmpty())
        return override;

    // ---------------------------------------------------------------------
    // Default = exactly where the SOME/IP client ALREADY on the guest writes.
    // Nothing in /opt is touched; the cluster is the only piece that changes.
    //
    // Verified on the guest 2026-08-13: /opt/someip/bin/SomeIPBlClient predates
    // output-path support -- its binary contains neither "CARLA_CLIENT_OUTPUT"
    // nor the argv[1] handling -- so it ignores both and always writes its
    // built-in "received_firmware.bin" relative to cwd.
    // /opt/someip/run_client.sh does `cd /var`, so the file lands here.
    //
    // Joining the two paths any other way is not possible on this board: the
    // filesystem implements neither symlink nor hard link (both fail with
    // "Function not implemented", tested on target).
    //
    // If the client is ever rebuilt with output-path support, no cluster
    // rebuild is needed -- just launch with:
    //     HNC_TELEMETRY_PATH=/tmp/telemetry.json ./QnxClusterApp
    // ---------------------------------------------------------------------
    return QStringLiteral("/var/received_firmware.bin");
}

VehicleDataProvider *VehicleDataProvider::create(QQmlEngine *qmlEngine, QJSEngine *jsEngine)
{
    Q_UNUSED(qmlEngine)
    Q_UNUSED(jsEngine)
    // No QObject parent: the QML engine takes ownership of a QML_SINGLETON
    // instance created this way.
    return new VehicleDataProvider(resolveTelemetryPath());
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

void VehicleDataProvider::raiseError(const QString &message)
{
    emit errorOccurred(message);
}
