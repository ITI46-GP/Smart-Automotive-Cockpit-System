#ifndef SETTINGSMANAGER_H
#define SETTINGSMANAGER_H

#include <QObject>

class SettingsManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool wifiOn READ wifiOn WRITE setWifiOn NOTIFY wifiOnChanged)
    Q_PROPERTY(bool bluetoothOn READ bluetoothOn WRITE setBluetoothOn NOTIFY bluetoothOnChanged)
    Q_PROPERTY(bool darkMode READ darkMode WRITE setDarkMode NOTIFY darkModeChanged)
    Q_PROPERTY(bool autoBrightness READ autoBrightness WRITE setAutoBrightness NOTIFY autoBrightnessChanged)
    Q_PROPERTY(bool privacyMode READ privacyMode WRITE setPrivacyMode NOTIFY privacyModeChanged)
    Q_PROPERTY(int brightness READ brightness WRITE setBrightness NOTIFY brightnessChanged)
    Q_PROPERTY(int systemVolume READ systemVolume WRITE setSystemVolume NOTIFY systemVolumeChanged)

public:
    explicit SettingsManager(QObject *parent = nullptr);

    bool wifiOn() const;
    bool bluetoothOn() const;
    bool darkMode() const;
    bool autoBrightness() const;
    bool privacyMode() const;
    int brightness() const;
    int systemVolume() const;

    Q_INVOKABLE void toggleWifi();
    Q_INVOKABLE void toggleBluetooth();
    Q_INVOKABLE void toggleDarkMode();
    Q_INVOKABLE void toggleAutoBrightness();
    Q_INVOKABLE void togglePrivacyMode();
    Q_INVOKABLE void increaseBrightness();
    Q_INVOKABLE void decreaseBrightness();
    Q_INVOKABLE void increaseSystemVolume();
    Q_INVOKABLE void decreaseSystemVolume();

public slots:
    void setWifiOn(bool on);
    void setBluetoothOn(bool on);
    void setDarkMode(bool on);
    void setAutoBrightness(bool on);
    void setPrivacyMode(bool on);
    void setBrightness(int brightness);
    void setSystemVolume(int volume);

signals:
    void wifiOnChanged();
    void bluetoothOnChanged();
    void darkModeChanged();
    void autoBrightnessChanged();
    void privacyModeChanged();
    void brightnessChanged();
    void systemVolumeChanged();

private:
    void load();
    void save() const;

    bool m_wifiOn = false;
    bool m_bluetoothOn = true;
    bool m_darkMode = true;
    bool m_autoBrightness = false;
    bool m_privacyMode = false;
    int m_brightness = 52;
    int m_systemVolume = 52;
};

#endif // SETTINGSMANAGER_H
