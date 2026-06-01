#include "AudioCompatManager.h"

#include <QVariantMap>
#include <QtGlobal>

AudioCompatManager::AudioCompatManager(QObject *parent)
    : QObject(parent)
{
    m_positionTimer.setInterval(1000);
    connect(&m_positionTimer, &QTimer::timeout, this, [this]() {
        if (!m_playing || m_duration <= 0) {
            return;
        }

        const qint64 nextPosition = m_position + m_positionTimer.interval();
        setPosition(nextPosition >= m_duration ? 0 : nextPosition);
    });
}

bool AudioCompatManager::playing() const { return m_playing; }
qint64 AudioCompatManager::position() const { return m_position; }
qint64 AudioCompatManager::duration() const { return m_duration; }
float AudioCompatManager::volume() const { return m_volume; }
QString AudioCompatManager::currentSource() const { return m_currentSource; }
QString AudioCompatManager::currentSongTitle() const { return m_currentSongTitle; }
bool AudioCompatManager::muted() const { return m_muted; }
bool AudioCompatManager::btSearching() const { return m_btSearching; }
QString AudioCompatManager::btStatus() const { return m_btStatus; }
QVariantList AudioCompatManager::availableDevices() const { return m_availableDevices; }
bool AudioCompatManager::isVideo() const { return m_isVideo; }

void AudioCompatManager::setSource(int type)
{
    const QString source = type == 1 ? QStringLiteral("USB")
                         : type == 2 ? QStringLiteral("Bluetooth")
                                     : QStringLiteral("Radio");

    if (m_currentSource != source) {
        m_currentSource = source;
        m_position = 0;
        emit sourceChanged();
        emit positionChanged();
    }

    m_duration = m_currentSource == QStringLiteral("Bluetooth") ? 0 : 180000;
    emit durationChanged();

    if (m_isVideo) {
        m_isVideo = false;
        emit isVideoChanged();
    }

    updateSongTitle();
    setPlaying(true);
}

void AudioCompatManager::next()
{
    ++m_trackIndex;
    setPosition(0);
    updateSongTitle();
}

void AudioCompatManager::prev()
{
    m_trackIndex = qMax(0, m_trackIndex - 1);
    setPosition(0);
    updateSongTitle();
}

void AudioCompatManager::togglePlayPause()
{
    if (m_currentSource.isEmpty()) {
        setSource(0);
        return;
    }

    setPlaying(!m_playing);
}

void AudioCompatManager::disconnectBt()
{
    setBtStatus(QStringLiteral("Disconnected"));
    setPlaying(false);
}

void AudioCompatManager::startDiscovery()
{
    setBtSearching(true);
    setBtStatus(QStringLiteral("Searching..."));

    QTimer::singleShot(1200, this, [this]() {
        QVariantMap device;
        device.insert(QStringLiteral("name"), QStringLiteral("Demo Phone"));
        device.insert(QStringLiteral("address"), QStringLiteral("00:00:00:00:00:00"));
        device.insert(QStringLiteral("path"), QStringLiteral("/compat/demo-phone"));
        device.insert(QStringLiteral("connected"), false);
        device.insert(QStringLiteral("paired"), false);

        m_availableDevices = {device};
        emit availableDevicesChanged();

        setBtSearching(false);
        setBtStatus(QStringLiteral("Compatibility Mode"));
    });
}

void AudioCompatManager::connectToDevice(const QString &path)
{
    Q_UNUSED(path)
    setSource(2);
    setBtStatus(QStringLiteral("Connected"));
}

void AudioCompatManager::bindVideoOutput(QObject *videoOutput)
{
    Q_UNUSED(videoOutput)
}

void AudioCompatManager::stop()
{
    setPlaying(false);
    setPosition(0);
}

void AudioCompatManager::setVolume(float level)
{
    const float bounded = qBound(0.0f, level, 1.0f);
    if (qFuzzyCompare(m_volume, bounded)) {
        return;
    }

    m_volume = bounded;
    emit volumeChanged();
}

void AudioCompatManager::setMuted(bool mute)
{
    if (m_muted == mute) {
        return;
    }

    m_muted = mute;
    emit mutedChanged();
}

void AudioCompatManager::setPosition(qint64 pos)
{
    const qint64 bounded = qBound<qint64>(0, pos, m_duration);
    if (m_position == bounded) {
        return;
    }

    m_position = bounded;
    emit positionChanged();
}

void AudioCompatManager::setPlaying(bool playing)
{
    if (m_playing == playing) {
        return;
    }

    m_playing = playing;
    if (m_playing) {
        m_positionTimer.start();
    } else {
        m_positionTimer.stop();
    }

    emit playingChanged();
}

void AudioCompatManager::setBtSearching(bool searching)
{
    if (m_btSearching == searching) {
        return;
    }

    m_btSearching = searching;
    emit btSearchingChanged();
}

void AudioCompatManager::setBtStatus(const QString &status)
{
    if (m_btStatus == status) {
        return;
    }

    m_btStatus = status;
    emit btStatusChanged();
}

void AudioCompatManager::updateSongTitle()
{
    QString title;
    bool videoStatus = false; 

    if (m_currentSource == QStringLiteral("USB")) {
        int trackNum = (m_trackIndex % 5) + 1;
        title = QStringLiteral("USB Track %1").arg(trackNum);
        
        // Simulating that Track 2 is a Video file
        if (trackNum == 2) {
            videoStatus = true;
        }
    } else if (m_currentSource == QStringLiteral("Bluetooth")) {
        title = QStringLiteral("Bluetooth Audio");
    } else if (m_currentSource == QStringLiteral("Radio")) {
        title = QStringLiteral("Live Radio Stream");
    } else {
        title = QStringLiteral("No Media");
    }

    if (m_currentSongTitle != title) {
        m_currentSongTitle = title;
        emit songTitleChanged();
    }

    if (m_isVideo != videoStatus) {
        m_isVideo = videoStatus;
        emit isVideoChanged();
    }
}
