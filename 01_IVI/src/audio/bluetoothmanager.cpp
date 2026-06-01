#include "bluetoothmanager.h"

#include <QDBusConnection>
#include <QDBusInterface>
#include <QDBusMessage>
#include <QDBusArgument>
#include <QDBusVariant>
#include <QTimer>

BluetoothManager::BluetoothManager(QObject *parent)
    : QObject(parent)
{
    findAdapter();
}

bool BluetoothManager::scanning() const
{
    return m_scanning;
}

QVariantList BluetoothManager::devices() const
{
    return m_devices;
}

void BluetoothManager::findAdapter()
{
    QDBusMessage msg = QDBusMessage::createMethodCall(
        "org.bluez",
        "/",
        "org.freedesktop.DBus.ObjectManager",
        "GetManagedObjects"
        );

    QDBusMessage reply =
        QDBusConnection::systemBus().call(msg);

    if (reply.type() == QDBusMessage::ErrorMessage)
        return;

    const QDBusArgument &arg =
        reply.arguments().at(0).value<QDBusArgument>();

    arg.beginMap();

    while (!arg.atEnd()) {

        QString path;
        QVariantMap interfaces;

        arg.beginMapEntry();

        arg >> path >> interfaces;

        arg.endMapEntry();

        if (interfaces.contains("org.bluez.Adapter1")) {

            m_adapterPath = path;

            break;
        }
    }

    arg.endMap();
}

void BluetoothManager::startScan()
{
    if (m_adapterPath.isEmpty())
        return;

    QDBusInterface adapter(
        "org.bluez",
        m_adapterPath,
        "org.bluez.Adapter1",
        QDBusConnection::systemBus()
        );

    adapter.call("StartDiscovery");

    m_scanning = true;

    emit scanningChanged();

    QTimer::singleShot(4000, this, [this]() {

        loadDevices();

        m_scanning = false;

        emit scanningChanged();
    });
}

void BluetoothManager::stopScan()
{
    if (m_adapterPath.isEmpty())
        return;

    QDBusInterface adapter(
        "org.bluez",
        m_adapterPath,
        "org.bluez.Adapter1",
        QDBusConnection::systemBus()
        );

    adapter.call("StopDiscovery");

    m_scanning = false;

    emit scanningChanged();
}

void BluetoothManager::loadDevices()
{
    m_devices.clear();

    QDBusMessage msg = QDBusMessage::createMethodCall(
        "org.bluez",
        "/",
        "org.freedesktop.DBus.ObjectManager",
        "GetManagedObjects"
        );

    QDBusMessage reply =
        QDBusConnection::systemBus().call(msg);

    if (reply.type() == QDBusMessage::ErrorMessage)
        return;

    const QDBusArgument &arg =
        reply.arguments().at(0).value<QDBusArgument>();

    arg.beginMap();

    while (!arg.atEnd()) {

        QString path;
        QVariantMap interfaces;

        arg.beginMapEntry();

        arg >> path >> interfaces;

        arg.endMapEntry();

        if (interfaces.contains("org.bluez.Device1")) {

            QDBusInterface device(
                "org.bluez",
                path,
                "org.bluez.Device1",
                QDBusConnection::systemBus()
                );

            QString name =
                device.property("Name").toString();

            QString address =
                device.property("Address").toString();

            bool connected =
                device.property("Connected").toBool();

            bool paired =
                device.property("Paired").toBool();

            QVariantMap info;

            info["name"] =
                name.isEmpty()
                    ? address
                    : name;

            info["address"] = address;

            info["path"] = path;

            info["connected"] = connected;

            info["paired"] = paired;

            m_devices.append(info);
        }
    }

    arg.endMap();

    emit devicesChanged();
}

void BluetoothManager::pairDevice(const QString &path)
{
    QDBusInterface device(
        "org.bluez",
        path,
        "org.bluez.Device1",
        QDBusConnection::systemBus()
        );

    device.call("Pair");

    QTimer::singleShot(2000, this, [this]() {

        loadDevices();
    });
}

void BluetoothManager::connectDevice(const QString &path)
{
    QDBusInterface device(
        "org.bluez",
        path,
        "org.bluez.Device1",
        QDBusConnection::systemBus()
        );

    device.call("Connect");

    QTimer::singleShot(2000, this, [this]() {

        loadDevices();
    });
}

void BluetoothManager::disconnectDevice(const QString &path)
{
    QDBusInterface device(
        "org.bluez",
        path,
        "org.bluez.Device1",
        QDBusConnection::systemBus()
        );

    device.call("Disconnect");

    QTimer::singleShot(1000, this, [this]() {

        loadDevices();
    });
}