#ifndef PROFILEMANAGER_H
#define PROFILEMANAGER_H

#include <QObject>
#include <QHash>
#include <QString>
#include <QStringList>

class ProfileManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString activeProfileName READ activeProfileName NOTIFY activeProfileNameChanged)
    Q_PROPERTY(QString activeProfileRole READ activeProfileRole NOTIFY activeProfileRoleChanged)
    Q_PROPERTY(QString activeDriveMode READ activeDriveMode WRITE setActiveDriveMode NOTIFY activeDriveModeChanged)
    Q_PROPERTY(QString activeSeatPreset READ activeSeatPreset WRITE setActiveSeatPreset NOTIFY activeSeatPresetChanged)
    Q_PROPERTY(int activeDriverTemp READ activeDriverTemp WRITE setActiveDriverTemp NOTIFY activeDriverTempChanged)
    Q_PROPERTY(int activePassengerTemp READ activePassengerTemp WRITE setActivePassengerTemp NOTIFY activePassengerTempChanged)
    Q_PROPERTY(int activeVolume READ activeVolume WRITE setActiveVolume NOTIFY activeVolumeChanged)
    Q_PROPERTY(QString activeMediaSource READ activeMediaSource WRITE setActiveMediaSource NOTIFY activeMediaSourceChanged)
    Q_PROPERTY(QString activeMediaPreset READ activeMediaPreset WRITE setActiveMediaPreset NOTIFY activeMediaPresetChanged)
    Q_PROPERTY(bool activeDarkMode READ activeDarkMode WRITE setActiveDarkMode NOTIFY activeDarkModeChanged)
    Q_PROPERTY(int activeAmbientLevel READ activeAmbientLevel WRITE setActiveAmbientLevel NOTIFY activeAmbientLevelChanged)
    Q_PROPERTY(QString activeLastDestination READ activeLastDestination WRITE setActiveLastDestination NOTIFY activeLastDestinationChanged)
    Q_PROPERTY(bool activeVoiceEnabled READ activeVoiceEnabled WRITE setActiveVoiceEnabled NOTIFY activeVoiceEnabledChanged)
    Q_PROPERTY(QStringList profileNames READ profileNames NOTIFY profilesChanged)

public:
    explicit ProfileManager(QObject *parent = nullptr);

    QString activeProfileName() const;
    QString activeProfileRole() const;
    QString activeDriveMode() const;
    QString activeSeatPreset() const;
    int activeDriverTemp() const;
    int activePassengerTemp() const;
    int activeVolume() const;
    QString activeMediaSource() const;
    QString activeMediaPreset() const;
    bool activeDarkMode() const;
    int activeAmbientLevel() const;
    QString activeLastDestination() const;
    bool activeVoiceEnabled() const;
    QStringList profileNames() const;

    Q_INVOKABLE bool switchProfile(const QString &name);
    Q_INVOKABLE bool createProfile(const QString &name);
    Q_INVOKABLE bool deleteProfile(const QString &name);
    Q_INVOKABLE QString profileRole(const QString &name) const;

    Q_INVOKABLE void setActiveDriveMode(const QString &driveMode);
    Q_INVOKABLE void setActiveSeatPreset(const QString &seatPreset);
    Q_INVOKABLE void setActiveDriverTemp(int temp);
    Q_INVOKABLE void setActivePassengerTemp(int temp);
    Q_INVOKABLE void setActiveVolume(int volume);
    Q_INVOKABLE void setActiveMediaSource(const QString &mediaSource);
    Q_INVOKABLE void setActiveMediaPreset(const QString &mediaPreset);
    Q_INVOKABLE void setActiveDarkMode(bool darkMode);
    Q_INVOKABLE void setActiveAmbientLevel(int level);
    Q_INVOKABLE void setActiveVoiceEnabled(bool enabled);
    void setActiveLastDestination(const QString &destination);

signals:
    void activeProfileNameChanged();
    void activeProfileRoleChanged();
    void activeDriveModeChanged();
    void activeSeatPresetChanged();
    void activeDriverTempChanged();
    void activePassengerTempChanged();
    void activeVolumeChanged();
    void activeMediaSourceChanged();
    void activeMediaPresetChanged();
    void activeDarkModeChanged();
    void activeAmbientLevelChanged();
    void activeLastDestinationChanged();
    void activeVoiceEnabledChanged();
    void profilesChanged();

private:
    struct Profile
    {
        QString name;
        QString role;
        QString driveMode = "Comfort";
        QString seatPreset = "Normal";
        int driverTemp = 20;
        int passengerTemp = 20;
        int volume = 52;
        QString mediaSource = "Bluetooth";
        QString mediaPreset = "Night Drive";
        bool darkMode = true;
        int ambientLevel = 64;
        QString lastDestination;
        bool voiceEnabled = true;
    };

    Profile *activeProfile();
    const Profile *activeProfile() const;
    void addDefaultProfiles();
    void load();
    void save() const;
    void emitActiveProfileChanged();
    int clampedTemp(int temp) const;
    int loadedTempOrDefault(int temp) const;
    QString normalizedDriveMode(const QString &driveMode) const;
    QString normalizedSeatPreset(const QString &seatPreset) const;
    QString normalizedMediaSource(const QString &mediaSource) const;
    QString normalizedMediaPreset(const QString &mediaPreset) const;

    QHash<QString, Profile> m_profiles;
    QStringList m_profileOrder;
    QString m_activeProfileName;
};

#endif // PROFILEMANAGER_H
