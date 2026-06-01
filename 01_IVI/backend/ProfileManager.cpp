#include "ProfileManager.h"

#include <QSettings>
#include <utility>

namespace {
constexpr int kMinTemp = 16;
constexpr int kMaxTemp = 30;
constexpr int kDefaultTemp = 20;
constexpr int kMinVolume = 0;
constexpr int kMaxVolume = 100;
constexpr int kMinAmbient = 0;
constexpr int kMaxAmbient = 100;

QString normalizedProfileName(const QString &name)
{
    return name.trimmed();
}

QString matchedOption(const QString &value, const QStringList &allowed, const QString &fallback)
{
    const QString trimmedValue = value.trimmed();
    for (const QString &option : allowed) {
        if (option.compare(trimmedValue, Qt::CaseInsensitive) == 0) {
            return option;
        }
    }

    return fallback;
}
}

ProfileManager::ProfileManager(QObject *parent)
    : QObject(parent)
{
    addDefaultProfiles();
    load();
}

QString ProfileManager::activeProfileName() const
{
    return m_activeProfileName;
}

QString ProfileManager::activeProfileRole() const
{
    const Profile *profile = activeProfile();
    return profile ? profile->role : QString();
}

QString ProfileManager::activeDriveMode() const
{
    const Profile *profile = activeProfile();
    return profile ? profile->driveMode : "Comfort";
}

QString ProfileManager::activeSeatPreset() const
{
    const Profile *profile = activeProfile();
    return profile ? profile->seatPreset : "Normal";
}

int ProfileManager::activeDriverTemp() const
{
    const Profile *profile = activeProfile();
    return profile ? profile->driverTemp : kDefaultTemp;
}

int ProfileManager::activePassengerTemp() const
{
    const Profile *profile = activeProfile();
    return profile ? profile->passengerTemp : kDefaultTemp;
}

int ProfileManager::activeVolume() const
{
    const Profile *profile = activeProfile();
    return profile ? profile->volume : 52;
}

QString ProfileManager::activeMediaSource() const
{
    const Profile *profile = activeProfile();
    return profile ? profile->mediaSource : "Bluetooth";
}

QString ProfileManager::activeMediaPreset() const
{
    const Profile *profile = activeProfile();
    return profile ? profile->mediaPreset : "Night Drive";
}

bool ProfileManager::activeDarkMode() const
{
    const Profile *profile = activeProfile();
    return profile ? profile->darkMode : true;
}

int ProfileManager::activeAmbientLevel() const
{
    const Profile *profile = activeProfile();
    return profile ? profile->ambientLevel : 64;
}

QString ProfileManager::activeLastDestination() const
{
    const Profile *profile = activeProfile();
    return profile ? profile->lastDestination : QString();
}

bool ProfileManager::activeVoiceEnabled() const
{
    const Profile *profile = activeProfile();
    return profile ? profile->voiceEnabled : true;
}

QStringList ProfileManager::profileNames() const
{
    return m_profileOrder;
}

bool ProfileManager::switchProfile(const QString &name)
{
    const QString normalizedName = normalizedProfileName(name);
    if (!m_profiles.contains(normalizedName)) {
        return false;
    }

    if (m_activeProfileName == normalizedName) {
        return true;
    }

    m_activeProfileName = normalizedName;
    emitActiveProfileChanged();
    save();
    return true;
}

bool ProfileManager::createProfile(const QString &name)
{
    const QString normalizedName = normalizedProfileName(name);
    if (normalizedName.isEmpty() || m_profiles.contains(normalizedName)) {
        return false;
    }

    Profile profile;
    profile.name = normalizedName;
    profile.role = "Custom profile";
    if (const Profile *current = activeProfile()) {
        profile.driveMode = current->driveMode;
        profile.seatPreset = current->seatPreset;
        profile.driverTemp = current->driverTemp;
        profile.passengerTemp = current->passengerTemp;
        profile.volume = current->volume;
        profile.mediaSource = current->mediaSource;
        profile.mediaPreset = current->mediaPreset;
        profile.darkMode = current->darkMode;
        profile.ambientLevel = current->ambientLevel;
        profile.lastDestination = current->lastDestination;
        profile.voiceEnabled = current->voiceEnabled;
    }

    m_profiles.insert(profile.name, profile);
    m_profileOrder.append(profile.name);
    emit profilesChanged();
    save();
    return true;
}

bool ProfileManager::deleteProfile(const QString &name)
{
    const QString normalizedName = normalizedProfileName(name);
    if (!m_profiles.contains(normalizedName) || m_profiles.size() <= 1) {
        return false;
    }

    const bool deletingActiveProfile = m_activeProfileName == normalizedName;
    m_profiles.remove(normalizedName);
    m_profileOrder.removeAll(normalizedName);

    if (deletingActiveProfile) {
        m_activeProfileName = m_profileOrder.value(0);
        emitActiveProfileChanged();
    }

    emit profilesChanged();
    save();
    return true;
}

QString ProfileManager::profileRole(const QString &name) const
{
    const QString normalizedName = normalizedProfileName(name);
    const auto it = m_profiles.constFind(normalizedName);
    return it == m_profiles.constEnd() ? QString() : it->role;
}

void ProfileManager::setActiveDriveMode(const QString &driveMode)
{
    Profile *profile = activeProfile();
    if (!profile) {
        return;
    }

    const QString normalized = normalizedDriveMode(driveMode);
    if (profile->driveMode == normalized) {
        return;
    }

    profile->driveMode = normalized;
    emit activeDriveModeChanged();
    save();
}

void ProfileManager::setActiveSeatPreset(const QString &seatPreset)
{
    Profile *profile = activeProfile();
    if (!profile) {
        return;
    }

    const QString normalized = normalizedSeatPreset(seatPreset);
    if (profile->seatPreset == normalized) {
        return;
    }

    profile->seatPreset = normalized;
    emit activeSeatPresetChanged();
    save();
}

void ProfileManager::setActiveDriverTemp(int temp)
{
    Profile *profile = activeProfile();
    if (!profile) {
        return;
    }

    const int clamped = clampedTemp(temp);
    if (profile->driverTemp == clamped) {
        return;
    }

    profile->driverTemp = clamped;
    emit activeDriverTempChanged();
    save();
}

void ProfileManager::setActivePassengerTemp(int temp)
{
    Profile *profile = activeProfile();
    if (!profile) {
        return;
    }

    const int clamped = clampedTemp(temp);
    if (profile->passengerTemp == clamped) {
        return;
    }

    profile->passengerTemp = clamped;
    emit activePassengerTempChanged();
    save();
}

void ProfileManager::setActiveVolume(int volume)
{
    Profile *profile = activeProfile();
    if (!profile) {
        return;
    }

    const int clamped = qBound(kMinVolume, volume, kMaxVolume);
    if (profile->volume == clamped) {
        return;
    }

    profile->volume = clamped;
    emit activeVolumeChanged();
    save();
}

void ProfileManager::setActiveMediaSource(const QString &mediaSource)
{
    Profile *profile = activeProfile();
    if (!profile) {
        return;
    }

    const QString normalized = normalizedMediaSource(mediaSource);
    if (profile->mediaSource == normalized) {
        return;
    }

    profile->mediaSource = normalized;
    emit activeMediaSourceChanged();
    save();
}

void ProfileManager::setActiveMediaPreset(const QString &mediaPreset)
{
    Profile *profile = activeProfile();
    if (!profile) {
        return;
    }

    const QString normalized = normalizedMediaPreset(mediaPreset);
    if (profile->mediaPreset == normalized) {
        return;
    }

    profile->mediaPreset = normalized;
    emit activeMediaPresetChanged();
    save();
}

void ProfileManager::setActiveDarkMode(bool darkMode)
{
    Profile *profile = activeProfile();
    if (!profile || profile->darkMode == darkMode) {
        return;
    }

    profile->darkMode = darkMode;
    emit activeDarkModeChanged();
    save();
}

void ProfileManager::setActiveAmbientLevel(int level)
{
    Profile *profile = activeProfile();
    if (!profile) {
        return;
    }

    const int clamped = qBound(kMinAmbient, level, kMaxAmbient);
    if (profile->ambientLevel == clamped) {
        return;
    }

    profile->ambientLevel = clamped;
    emit activeAmbientLevelChanged();
    save();
}

void ProfileManager::setActiveVoiceEnabled(bool enabled)
{
    Profile *profile = activeProfile();
    if (!profile || profile->voiceEnabled == enabled) {
        return;
    }

    profile->voiceEnabled = enabled;
    emit activeVoiceEnabledChanged();
    save();
}

void ProfileManager::setActiveLastDestination(const QString &destination)
{
    Profile *profile = activeProfile();
    if (!profile) {
        return;
    }

    const QString normalizedDestination = destination.trimmed();
    if (profile->lastDestination == normalizedDestination) {
        return;
    }

    profile->lastDestination = normalizedDestination;
    emit activeLastDestinationChanged();
    save();
}

ProfileManager::Profile *ProfileManager::activeProfile()
{
    auto it = m_profiles.find(m_activeProfileName);
    return it == m_profiles.end() ? nullptr : &it.value();
}

const ProfileManager::Profile *ProfileManager::activeProfile() const
{
    auto it = m_profiles.constFind(m_activeProfileName);
    return it == m_profiles.constEnd() ? nullptr : &it.value();
}

void ProfileManager::addDefaultProfiles()
{
    m_profiles.clear();
    m_profileOrder.clear();

    QList<Profile> defaults;

    Profile abdelfattah;
    abdelfattah.name = "Abdelfattah";
    abdelfattah.role = "Primary Driver";
    abdelfattah.driveMode = "Comfort";
    abdelfattah.seatPreset = "Relax";
    abdelfattah.driverTemp = kDefaultTemp;
    abdelfattah.passengerTemp = kDefaultTemp;
    abdelfattah.volume = 52;
    abdelfattah.mediaSource = "Bluetooth";
    abdelfattah.mediaPreset = "Night Drive";
    abdelfattah.darkMode = true;
    abdelfattah.ambientLevel = 64;
    abdelfattah.voiceEnabled = true;
    defaults.append(abdelfattah);

    Profile guest;
    guest.name = "Guest";
    guest.role = "Temporary Profile";
    guest.driveMode = "Eco";
    guest.seatPreset = "Normal";
    guest.driverTemp = kDefaultTemp;
    guest.passengerTemp = kDefaultTemp;
    guest.volume = 35;
    guest.mediaSource = "Radio";
    guest.mediaPreset = "Favorites";
    guest.darkMode = true;
    guest.ambientLevel = 42;
    guest.voiceEnabled = true;
    defaults.append(guest);

    Profile family;
    family.name = "Family";
    family.role = "Shared Comfort Settings";
    family.driveMode = "Comfort";
    family.seatPreset = "Normal";
    family.driverTemp = kDefaultTemp;
    family.passengerTemp = kDefaultTemp;
    family.volume = 45;
    family.mediaSource = "USB";
    family.mediaPreset = "Quran";
    family.darkMode = true;
    family.ambientLevel = 58;
    family.lastDestination = "ITI Campus";
    family.voiceEnabled = true;
    defaults.append(family);

    for (const Profile &profile : std::as_const(defaults)) {
        m_profiles.insert(profile.name, profile);
        m_profileOrder.append(profile.name);
    }

    m_activeProfileName = "Abdelfattah";
}

void ProfileManager::load()
{
    QSettings settings;
    settings.beginGroup("ProfileManager");

    const QHash<QString, Profile> defaultProfiles = m_profiles;
    bool needsSave = false;

    const int count = settings.beginReadArray("profiles");
    if (count > 0) {
        m_profiles.clear();
        m_profileOrder.clear();

        for (int i = 0; i < count; ++i) {
            settings.setArrayIndex(i);

            Profile profile;
            const QString profileName = normalizedProfileName(settings.value("name").toString());
            if (profileName.isEmpty() || m_profiles.contains(profileName)) {
                continue;
            }

            profile = defaultProfiles.value(profileName);
            profile.name = profileName;
            if (profile.role.isEmpty()) {
                profile.role = "Custom profile";
            }

            profile.role = settings.value("role", profile.role).toString();
            profile.driveMode = normalizedDriveMode(settings.value("driveMode", profile.driveMode).toString());
            profile.seatPreset = normalizedSeatPreset(settings.value("seatPreset", profile.seatPreset).toString());
            const int savedDriverTemp = settings.value("driverTemp", profile.driverTemp).toInt();
            const int savedPassengerTemp = settings.value("passengerTemp", profile.passengerTemp).toInt();
            profile.driverTemp = loadedTempOrDefault(savedDriverTemp);
            profile.passengerTemp = loadedTempOrDefault(savedPassengerTemp);
            needsSave = needsSave || profile.driverTemp != savedDriverTemp || profile.passengerTemp != savedPassengerTemp;
            profile.volume = qBound(kMinVolume, settings.value("volume", profile.volume).toInt(), kMaxVolume);
            profile.mediaSource = normalizedMediaSource(settings.value("mediaSource", profile.mediaSource).toString());
            profile.mediaPreset = normalizedMediaPreset(settings.value("mediaPreset", profile.mediaPreset).toString());
            profile.darkMode = settings.value("darkMode", profile.darkMode).toBool();
            profile.ambientLevel = qBound(kMinAmbient, settings.value("ambientLevel", profile.ambientLevel).toInt(), kMaxAmbient);
            profile.lastDestination = settings.value("lastDestination", profile.lastDestination).toString();
            profile.voiceEnabled = settings.value("voiceEnabled", profile.voiceEnabled).toBool();

            m_profiles.insert(profile.name, profile);
            m_profileOrder.append(profile.name);
        }
    }
    settings.endArray();

    if (m_profiles.isEmpty()) {
        addDefaultProfiles();
        needsSave = true;
    }

    const QString savedActiveProfile = normalizedProfileName(settings.value("activeProfileName", m_activeProfileName).toString());
    if (m_profiles.contains(savedActiveProfile)) {
        m_activeProfileName = savedActiveProfile;
    } else {
        m_activeProfileName = m_profileOrder.value(0);
        needsSave = true;
    }

    settings.endGroup();

    if (needsSave) {
        save();
    }
}

void ProfileManager::save() const
{
    QSettings settings;
    settings.beginGroup("ProfileManager");
    settings.setValue("activeProfileName", m_activeProfileName);

    settings.beginWriteArray("profiles", m_profileOrder.size());
    for (int i = 0; i < m_profileOrder.size(); ++i) {
        settings.setArrayIndex(i);
        const Profile profile = m_profiles.value(m_profileOrder.at(i));
        settings.setValue("name", profile.name);
        settings.setValue("role", profile.role);
        settings.setValue("driveMode", profile.driveMode);
        settings.setValue("seatPreset", profile.seatPreset);
        settings.setValue("driverTemp", profile.driverTemp);
        settings.setValue("passengerTemp", profile.passengerTemp);
        settings.setValue("volume", profile.volume);
        settings.setValue("mediaSource", profile.mediaSource);
        settings.setValue("mediaPreset", profile.mediaPreset);
        settings.setValue("darkMode", profile.darkMode);
        settings.setValue("ambientLevel", profile.ambientLevel);
        settings.setValue("lastDestination", profile.lastDestination);
        settings.setValue("voiceEnabled", profile.voiceEnabled);
    }
    settings.endArray();
    settings.endGroup();
}

void ProfileManager::emitActiveProfileChanged()
{
    emit activeProfileNameChanged();
    emit activeProfileRoleChanged();
    emit activeDriveModeChanged();
    emit activeSeatPresetChanged();
    emit activeDriverTempChanged();
    emit activePassengerTempChanged();
    emit activeVolumeChanged();
    emit activeMediaSourceChanged();
    emit activeMediaPresetChanged();
    emit activeDarkModeChanged();
    emit activeAmbientLevelChanged();
    emit activeLastDestinationChanged();
    emit activeVoiceEnabledChanged();
}

int ProfileManager::clampedTemp(int temp) const
{
    return qBound(kMinTemp, temp, kMaxTemp);
}

int ProfileManager::loadedTempOrDefault(int temp) const
{
    if (temp < kMinTemp || temp > kMaxTemp) {
        return kDefaultTemp;
    }

    return temp;
}

QString ProfileManager::normalizedDriveMode(const QString &driveMode) const
{
    return matchedOption(driveMode, {"Comfort", "Sport", "Eco"}, "Comfort");
}

QString ProfileManager::normalizedSeatPreset(const QString &seatPreset) const
{
    return matchedOption(seatPreset, {"Relax", "Normal", "Focus"}, "Normal");
}

QString ProfileManager::normalizedMediaSource(const QString &mediaSource) const
{
    return matchedOption(mediaSource, {"Radio", "USB", "Bluetooth"}, "Bluetooth");
}

QString ProfileManager::normalizedMediaPreset(const QString &mediaPreset) const
{
    return matchedOption(mediaPreset, {"Night Drive", "Quran", "Favorites"}, "Night Drive");
}
