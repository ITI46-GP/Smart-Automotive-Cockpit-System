#include "btplayer.h"

#include <QDBusMessage>
#include <QDBusArgument>
#include <QDBusVariant>
#include <QDBusObjectPath>
#include <QDBusInterface>
#include <QDBusReply>
#include <QProcess>
#include <QDebug>

static const QString BLUEZ_SVC  = QStringLiteral("org.bluez");
static const QString BLUEZ_DEV  = QStringLiteral("org.bluez.Device1");
static const QString BLUEZ_PLAY = QStringLiteral("org.bluez.MediaPlayer1");
static const QString DBUS_OM    = QStringLiteral("org.freedesktop.DBus.ObjectManager");
static const QString DBUS_PROP  = QStringLiteral("org.freedesktop.DBus.Properties");

BtPlayer::BtPlayer(QObject *parent)
    : AudioSourceBase(parent)
    , m_bus(QDBusConnection::systemBus())
{
    m_btManager = new BluetoothManager(this);

    connect(
        m_btManager,
        &BluetoothManager::devicesChanged,
        this,
        &BtPlayer::availableDevicesChanged
        );

    connect(
        m_btManager,
        &BluetoothManager::scanningChanged,
        this,
        &BtPlayer::btSearchingChanged
        );

    m_pollTimer = new QTimer(this);

    m_pollTimer->setInterval(1000);

    connect(
        m_pollTimer,
        &QTimer::timeout,
        this,
        &BtPlayer::poll
        );

    setPlaying(false);

    setPositionInternal(0);

    setDurationInternal(0);
}

BtPlayer::~BtPlayer()
{
    pause();

    if (!m_devicePath.isEmpty()) {

        QDBusInterface device(
            BLUEZ_SVC,
            m_devicePath,
            BLUEZ_DEV,
            m_bus
            );

        device.call("Disconnect");
    }
}

bool BtPlayer::isBtSearching() const
{
    return m_btManager->scanning();
}

QString BtPlayer::btStatus() const
{
    return m_btStatus;
}

QString BtPlayer::deviceName() const
{
    return m_deviceName;
}

QVariantList BtPlayer::availableDevices() const
{
    return m_btManager->devices();
}

void BtPlayer::activate()
{
    if (!m_bus.isConnected()) {

        setSongTitle("D-Bus Error");

        setBtStatus("Error");

        return;
    }

    m_pollTimer->start();

    poll();
}

void BtPlayer::deactivate()
{
    pause();

    if (m_pollTimer)
        m_pollTimer->stop();
}

void BtPlayer::play()
{
    sendAvrcp("Play");
    m_playerStatus = "playing";
    setPlaying(true);
    QTimer::singleShot(500, this, &BtPlayer::poll);
}

void BtPlayer::pause()
{
    sendAvrcp("Pause");
    m_playerStatus = "paused";
    setPlaying(false);
    QTimer::singleShot(500, this, &BtPlayer::poll);
}

void BtPlayer::stop()
{
    sendAvrcp("Pause");
    m_playerStatus = "stopped";
    setPlaying(false);
    QTimer::singleShot(500, this, &BtPlayer::poll);
}

void BtPlayer::next()
{
    sendAvrcp("Next");
    QTimer::singleShot(800, this, &BtPlayer::poll);
}

void BtPlayer::prev()
{
    sendAvrcp("Previous");
    QTimer::singleShot(800, this, &BtPlayer::poll);
}

void BtPlayer::togglePlayPause()
{
    if (isplaying())
        pause();
    else
        play();
}

void BtPlayer::seek(qint64 pos)
{
    Q_UNUSED(pos)
}

void BtPlayer::setVolume(float level)
{
    int volume =
        static_cast<int>(level * 100.0f);

    QProcess::startDetached(
        "pactl",
        {
            "set-sink-volume",
            "@DEFAULT_SINK@",
            QString("%1%").arg(volume)
        }
        );
}

void BtPlayer::setMuted(bool muted)
{
    QProcess::startDetached(
        "pactl",
        {
            "set-sink-mute",
            "@DEFAULT_SINK@",
            muted ? "1" : "0"
        }
        );
}

void BtPlayer::setAudioOutput(QAudioOutput *)
{
}

void BtPlayer::startDiscovery()
{
    m_btManager->startScan();
}

void BtPlayer::connectToDevice(const QString &path)
{
    m_btManager->connectDevice(path);

    setBtStatus("Connecting...");
}

void BtPlayer::disconnectBt()
{
    if (!m_devicePath.isEmpty()) {

        m_btManager->disconnectDevice(
            m_devicePath
            );
    }

    m_connected = false;

    m_playerPath.clear();

    setSongTitle("Disconnected");

    setBtStatus("Disconnected");
}

void BtPlayer::setBtStatus(const QString &status)
{
    if (m_btStatus != status) {

        m_btStatus = status;

        emit btStatusChanged();
    }
}

QVariantMap BtPlayer::getProperties(
    const QString &path,
    const QString &iface
    )
{
    QVariantMap result;

    QDBusMessage msg =
        QDBusMessage::createMethodCall(
            BLUEZ_SVC,
            path,
            DBUS_PROP,
            "GetAll"
            );

    msg << iface;

    QDBusMessage reply =
        m_bus.call(msg);

    if (reply.type() == QDBusMessage::ErrorMessage)
        return result;

    if (reply.arguments().isEmpty())
        return result;

    result =
        qdbus_cast<QVariantMap>(
            reply.arguments().first()
            );

    return result;
}

void BtPlayer::poll()
{
    if (!m_bus.isConnected())
        return;

    QDBusMessage msg =
        QDBusMessage::createMethodCall(
            BLUEZ_SVC,
            "/",
            DBUS_OM,
            "GetManagedObjects"
            );

    QDBusMessage reply =
        m_bus.call(msg);

    if (reply.type() == QDBusMessage::ErrorMessage)
        return;

    const QDBusArgument arg =
        reply.arguments().at(0).value<QDBusArgument>();

    QString foundPlayer;

    arg.beginMap();

    while (!arg.atEnd()) {

        QDBusObjectPath objPath;

        QVariantMap interfaces;

        arg.beginMapEntry();

        arg >> objPath >> interfaces;

        arg.endMapEntry();

        if (interfaces.contains(BLUEZ_PLAY)) {

            foundPlayer =
                objPath.path();

            break;
        }
    }

    arg.endMap();

    if (foundPlayer.isEmpty())
        return;

    m_playerPath = foundPlayer;

    QDBusInterface player(
        BLUEZ_SVC,
        m_playerPath,
        DBUS_PROP,
        m_bus
        );

    QDBusReply<QVariantMap> props =
        player.call(
            "GetAll",
            BLUEZ_PLAY
            );

    if (!props.isValid())
        return;

    QVariantMap playerProps =
        props.value();

    QString status =
        playerProps.value("Status").toString();

    m_playerStatus = status;

    setPlaying(
        status.toLower() == "playing"
        );

    QVariantMap track =
        qdbus_cast<QVariantMap>(
            playerProps.value("Track")
            );

    QString title =
        track.value("Title").toString();

    QString artist =
        track.value("Artist").toString();

    if (!title.isEmpty()) {

        if (!artist.isEmpty())
            setSongTitle(
                title + " - " + artist
                );
        else
            setSongTitle(title);
    }

    qint64 pos =
        playerProps.value("Position").toLongLong();

    qint64 dur =
        track.value("Duration").toLongLong();

    setPositionInternal(pos);

    setDurationInternal(dur);

    m_connected = true;

    setBtStatus("Connected");
}

void BtPlayer::updateSongTitle()
{
    poll();
}

void BtPlayer::sendAvrcp(const QString &cmd)
{
    if (m_playerPath.isEmpty())
        return;

    QDBusInterface player(
        BLUEZ_SVC,
        m_playerPath,
        BLUEZ_PLAY,
        m_bus
        );

    QDBusReply<void> reply =
        player.call(cmd);

    if (!reply.isValid()) {

        qDebug()
        << "AVRCP Error:"
        << reply.error().message();
    }
}