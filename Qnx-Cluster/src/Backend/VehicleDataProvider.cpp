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

QString VehicleDataProvider::resolveTelemetryPath()
{
    // Overridable at launch, so a path change never needs a rebuild again:
    //     HNC_TELEMETRY_PATH=/tmp/telemetry.json ./QnxClusterApp
    const QString override = qEnvironmentVariable("HNC_TELEMETRY_PATH");
    if (!override.isEmpty())
        return override;

    // ---------------------------------------------------------------------
    // Default = the intended end state: the SOME/IP client is launched with an
    // explicit output path of /tmp/telemetry.json and writes it atomically.
    // /tmp is consistent with everything else the cluster reads on this board
    // (/tmp/ivi/*.txt) and is proven writable; /home/qnxuser is not (touch
    // fails with ENOENT even though ls on the directory succeeds).
    //
    // INTERIM: until the updated client is installed in /opt, the shipped one
    // ignores both argv[1] and $CARLA_CLIENT_OUTPUT -- verified on the guest
    // 2026-08-13, its binary contains neither string -- and always writes its
    // built-in "received_firmware.bin" relative to cwd (/var, per
    // /opt/someip/run_client.sh). Until that is replaced, launch the cluster
    // with:
    //
    //     HNC_TELEMETRY_PATH=/var/received_firmware.bin ./QnxClusterApp
    //
    // The override exists precisely so this never needs another rebuild: the
    // path has already been wrong twice, and neither symlink nor hard link is
    // available as an escape hatch on this filesystem (both fail with
    // "Function not implemented").
    // ---------------------------------------------------------------------
    return QStringLiteral("/tmp/telemetry.json");
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
