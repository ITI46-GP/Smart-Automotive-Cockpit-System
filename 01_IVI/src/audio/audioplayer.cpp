#include "audioplayer.h"
#include <QDebug>

AudioPlayer::AudioPlayer(QObject *parent) : QObject(parent)
{
    m_audioOutput = new QAudioOutput(this);
    m_audioOutput->setVolume(0.5f);

    m_radio = new RadioPlayer(this);
    m_usb   = new UsbPlayer(this);
    m_bt    = new BtPlayer(this);

    connect(m_bt, &BtPlayer::btSearchingChanged, this, &AudioPlayer::btSearchingChanged);
    connect(m_bt, &BtPlayer::btStatusChanged,this, &AudioPlayer::btStatusChanged);
    connect(m_bt, &BtPlayer::availableDevicesChanged,this, &AudioPlayer::availableDevicesChanged);
    
}

AudioPlayer::~AudioPlayer() {}

bool    AudioPlayer::getPlayingState()  const { return m_current ? m_current->isplaying() : false; }
qint64  AudioPlayer::getPosition()      const { return m_current ? m_current->position() : 0; }
qint64  AudioPlayer::getDuration()      const { return m_current ? m_current->duration() : 0; }
float   AudioPlayer::getVolume()        const { return m_volume; }
QString AudioPlayer::currentSource()    const { return m_currentSourceName; }
QString AudioPlayer::currentSongTitle() const { return m_current ? m_current->songTitle() : QStringLiteral("No Media"); }
bool    AudioPlayer::getMuted()         const { return m_muted; }
bool    AudioPlayer::isBtSearching()    const { return m_bt ? m_bt->isBtSearching() : false; }
QString AudioPlayer::btStatus()         const { return m_bt ? m_bt->btStatus() : QStringLiteral("Idle"); }
bool    AudioPlayer::isVideo()          const { return m_current == m_usb && m_usb ? m_usb->isVideo() : false; }

QVariantList AudioPlayer::availableDevices() const {
    return m_bt ? m_bt->availableDevices() : QVariantList{};
}

void AudioPlayer::startDiscovery() {
    if (m_bt) m_bt->startDiscovery();
}

void AudioPlayer::stop()
{
    if (m_current) m_current->stop();
}

void AudioPlayer::connectToDevice(const QString &path)
{
    if (m_bt)
        m_bt->connectToDevice(path);
}

void AudioPlayer::bindVideoOutput(QObject* videoOutput)
{
    if (!videoOutput || !m_usb)
        return;
    QVideoSink* sink = videoOutput->property("videoSink").value<QVideoSink*>();
    if (sink)
        m_usb->setVideoSink(sink);
}

void AudioPlayer::setSource(int type)
{
    if (m_current) {
        disconnectSourceSignals(m_current);
        m_current->deactivate();
        m_current->setAudioOutput(nullptr);
    }

    if (type == 1) {
        m_current = m_usb;
        m_currentSourceName = QStringLiteral("USB");
    } else if (type == 2) {
        m_current = m_bt;
        m_currentSourceName = QStringLiteral("Bluetooth");
    } else {
        m_current = m_radio;
        m_currentSourceName = QStringLiteral("Radio");
    }

    if (m_current) {
        m_current->setAudioOutput(m_audioOutput);
        m_current->setVolume(m_volume);
        m_current->setMuted(m_muted);
        connectSourceSignals(m_current);
        m_current->activate();
    }

    if (m_current == m_usb) {
        connect(m_usb, &UsbPlayer::isVideoChanged, this, &AudioPlayer::isVideoChanged, Qt::UniqueConnection);
    } else {
        disconnect(m_usb, &UsbPlayer::isVideoChanged, this, &AudioPlayer::isVideoChanged);
    }

    emit sourceChanged();
    emit songTitleChanged();
    emit playingChanged();
    emit positionChanged();
    emit durationChanged();
    emit btSearchingChanged();
    emit btStatusChanged();
    emit isVideoChanged();
}

void AudioPlayer::connectSourceSignals(AudioSourceBase *source)
{
    connect(source, &AudioSourceBase::songTitleChanged, this, &AudioPlayer::songTitleChanged);
    connect(source, &AudioSourceBase::playingChanged,   this, &AudioPlayer::playingChanged);
    connect(source, &AudioSourceBase::positionChanged,  this, &AudioPlayer::positionChanged);
    connect(source, &AudioSourceBase::durationChanged,  this, &AudioPlayer::durationChanged);
}

void AudioPlayer::disconnectSourceSignals(AudioSourceBase *source)
{
    disconnect(source, &AudioSourceBase::songTitleChanged, this, &AudioPlayer::songTitleChanged);
    disconnect(source, &AudioSourceBase::playingChanged,   this, &AudioPlayer::playingChanged);
    disconnect(source, &AudioSourceBase::positionChanged,  this, &AudioPlayer::positionChanged);
    disconnect(source, &AudioSourceBase::durationChanged,  this, &AudioPlayer::durationChanged);
}

void AudioPlayer::next()           { if (m_current) m_current->next(); }
void AudioPlayer::prev()           { if (m_current) m_current->prev(); }
void AudioPlayer::togglePlayPause(){ if (m_current) m_current->togglePlayPause(); }

void AudioPlayer::setVolume(float level)
{
    if (!qFuzzyCompare(m_volume, level)) {
        m_volume = level;
        m_audioOutput->setVolume(level);
        if (m_current) m_current->setVolume(level);
        emit volumeChanged();
    }
}

void AudioPlayer::setMuted(bool mute)
{
    if (m_muted != mute) {
        m_muted = mute;
        m_audioOutput->setMuted(mute);
        if (m_current) m_current->setMuted(mute);
        emit mutedChanged();
    }
}

void AudioPlayer::setPosition(qint64 pos)
{
    if (m_current) m_current->seek(pos);
}

void AudioPlayer::disconnectBt()
{
    m_bt->disconnectBt();
}