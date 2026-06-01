#ifndef BLUETOOTHMANAGER_H
#define BLUETOOTHMANAGER_H

#include <QObject>
#include <QVariantList>

class BluetoothManager : public QObject
{
    Q_OBJECT

    Q_PROPERTY(bool scanning READ scanning NOTIFY scanningChanged)
    Q_PROPERTY(QVariantList devices READ devices NOTIFY devicesChanged)

public:
    explicit BluetoothManager(QObject *parent = nullptr);

    bool scanning() const;
    QVariantList devices() const;

    Q_INVOKABLE void startScan();
    Q_INVOKABLE void stopScan();

    Q_INVOKABLE void pairDevice(const QString &path);
    Q_INVOKABLE void connectDevice(const QString &path);
    Q_INVOKABLE void disconnectDevice(const QString &path);

signals:
    void scanningChanged();
    void devicesChanged();

private:
    QString m_adapterPath;
    QVariantList m_devices;
    bool m_scanning = false;

    void findAdapter();
    void loadDevices();
};

#endif // BLUETOOTHMANAGER_H