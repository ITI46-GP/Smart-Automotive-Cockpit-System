#include "MusicController.h"

MusicController::MusicController(QObject *parent)
    : QObject{parent}
{
    m_playbackTimer = new QTimer(this);
    connect(m_playbackTimer, &QTimer::timeout, this, &MusicController::updatePlaybackTime);
    
    // Start with a mock track playing
    loadMockTrack(1); 
    setIsPlaying(true);
}

QString MusicController::trackTitle() const { return m_trackTitle; }
QString MusicController::trackArtist() const { return m_trackArtist; }
QString MusicController::coverArtUrl() const { return m_coverArtUrl; }
QString MusicController::prevCoverArtUrl() const { return m_prevCoverArtUrl; }
QString MusicController::nextCoverArtUrl() const { return m_nextCoverArtUrl; }
int MusicController::currentTimeSec() const { return m_currentTimeSec; }
int MusicController::totalTimeSec() const { return m_totalTimeSec; }
bool MusicController::isPlaying() const { return m_isPlaying; }

void MusicController::setTrackTitle(const QString &title)
{
    if (m_trackTitle == title) return;
    m_trackTitle = title;
    emit trackTitleChanged();
}

void MusicController::setTrackArtist(const QString &artist)
{
    if (m_trackArtist == artist) return;
    m_trackArtist = artist;
    emit trackArtistChanged();
}

void MusicController::setCoverArtUrl(const QString &url)
{
    if (m_coverArtUrl == url) return;
    m_coverArtUrl = url;
    emit coverArtUrlChanged();
}

void MusicController::setPrevCoverArtUrl(const QString &url)
{
    if (m_prevCoverArtUrl == url) return;
    m_prevCoverArtUrl = url;
    emit prevCoverArtUrlChanged();
}

void MusicController::setNextCoverArtUrl(const QString &url)
{
    if (m_nextCoverArtUrl == url) return;
    m_nextCoverArtUrl = url;
    emit nextCoverArtUrlChanged();
}

void MusicController::setCurrentTimeSec(int timeSec)
{
    if (m_currentTimeSec == timeSec) return;
    m_currentTimeSec = timeSec;
    emit currentTimeSecChanged();
}

void MusicController::setTotalTimeSec(int timeSec)
{
    if (m_totalTimeSec == timeSec) return;
    m_totalTimeSec = timeSec;
    emit totalTimeSecChanged();
}

void MusicController::setIsPlaying(bool playing)
{
    if (m_isPlaying == playing) return;
    m_isPlaying = playing;
    emit isPlayingChanged();
    
    if (m_isPlaying) {
        m_playbackTimer->start(1000);
    } else {
        m_playbackTimer->stop();
    }
}

void MusicController::playPause()
{
    setIsPlaying(!m_isPlaying);
    // In the future, this should also send an IPC message to the IVI to toggle playback
}

void MusicController::nextTrack()
{
    m_currentMockIndex = (m_currentMockIndex + 1) % 3;
    loadMockTrack(m_currentMockIndex);
    // Future: Send next track IPC command to IVI
}

void MusicController::previousTrack()
{
    m_currentMockIndex = (m_currentMockIndex - 1 + 3) % 3;
    loadMockTrack(m_currentMockIndex);
    // Future: Send previous track IPC command to IVI
}

void MusicController::updatePlaybackTime()
{
    if (m_currentTimeSec < m_totalTimeSec) {
        setCurrentTimeSec(m_currentTimeSec + 1);
    } else {
        nextTrack();
    }
}

void MusicController::loadMockTrack(int index)
{
    m_currentMockIndex = index;
    
    // Mock cover array for the prev/next calculation
    QString covers[3] = {
        "file://../../Digital_Cluster_DesignStudioContent/assets/starboy.jpeg",
        "file://../../Digital_Cluster_DesignStudioContent/assets/be_alright.jpeg",
        "file://../../Digital_Cluster_DesignStudioContent/assets/Imagine_Dragons_-_Shots.png"
    };

    setPrevCoverArtUrl(covers[(index - 1 + 3) % 3]);
    setNextCoverArtUrl(covers[(index + 1) % 3]);

    if (index == 0) {
        setTrackTitle("Starboy");
        setTrackArtist("The Weeknd");
        setCoverArtUrl(covers[0]);
        setTotalTimeSec(200); // 3:20
    } else if (index == 1) {
        setTrackTitle("Be Alright");
        setTrackArtist("Dean Lewis");
        setCoverArtUrl(covers[1]);
        setTotalTimeSec(230); // 3:50
    } else {
        setTrackTitle("Shots");
        setTrackArtist("Imagine Dragons");
        setCoverArtUrl(covers[2]);
        setTotalTimeSec(215); // 3:35
    }
    setCurrentTimeSec(0);
}
