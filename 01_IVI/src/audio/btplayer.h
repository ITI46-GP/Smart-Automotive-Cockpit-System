#ifndef BTPLAYER_H
#define BTPLAYER_H

#include "audiosourcebase.h"
#include "bluetoothmanager.h"

#include <QDBusConnection>
#include <QTimer>
#include <QVariantList>

class BtPlayer : public AudioSourceBase
{
    Q_OBJECT

    Q_PROPERTY(
        bool btSearching
            READ isBtSearching
                NOTIFY btSearchingChanged
        )

    Q_PROPERTY(
        QString btStatus
            READ btStatus
                NOTIFY btStatusChanged
        )

    Q_PROPERTY(
        QString deviceName
            READ deviceName
                NOTIFY deviceNameChanged
        )

    Q_PROPERTY(
        QVariantList availableDevices
            READ availableDevices
                NOTIFY availableDevicesChanged
        )

public:
    explicit BtPlayer(QObject *parent = nullptr);

    ~BtPlayer();

    bool isBtSearching() const;

    QString btStatus() const;

    QString deviceName() const;

    QVariantList availableDevices() const;

    void activate() override;

    void deactivate() override;

    void play() override;

    void pause() override;

    void stop() override;

    void next() override;

    void prev() override;

    void togglePlayPause() override;

    void seek(qint64 pos) override;

    void setVolume(float level) override;

    void setMuted(bool muted) override;

    void setAudioOutput(QAudioOutput *output) override;

    Q_INVOKABLE void startDiscovery();

    Q_INVOKABLE void connectToDevice(
        const QString &path
        );

    Q_INVOKABLE void disconnectBt();

signals:
    void btSearchingChanged();

    void btStatusChanged();

    void deviceNameChanged();

    void availableDevicesChanged();

private slots:
    void poll();

private:
    void sendAvrcp(const QString &cmd);

    QVariantMap getProperties(
        const QString &path,
        const QString &iface
        );

    void updateSongTitle();

    void setBtStatus(
        const QString &status
        );

private:
    BluetoothManager *m_btManager = nullptr;

    QDBusConnection m_bus;

    QTimer *m_pollTimer = nullptr;

    QString m_btStatus = "Idle";

    QString m_deviceName;

    QString m_devicePath;

    QString m_playerPath;

    QString m_playerStatus;

    bool m_connected = false;
};

#endif