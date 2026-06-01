#include "audiosourcebase.h"

AudioSourceBase::AudioSourceBase(QObject *parent) : QObject(parent)
{
}

AudioSourceBase::~AudioSourceBase()
{
}

QString AudioSourceBase::songTitle() const
{
    return m_songTitle;
}

bool AudioSourceBase::isplaying() const
{
    return m_playing;
}

qint64 AudioSourceBase::position() const
{
    return m_position;
}

qint64 AudioSourceBase::duration() const
{
    return m_duration;
}

void AudioSourceBase::setSongTitle(const QString &title)
{
    if (m_songTitle != title) {
        m_songTitle = title;
        emit songTitleChanged();
    }
}

void AudioSourceBase::setPlaying(bool playing)
{
    if (m_playing != playing) {
        m_playing = playing;
        emit playingChanged();
    }
}

void AudioSourceBase::setPositionInternal(qint64 pos)
{
    if (m_position != pos) {
        m_position = pos;
        emit positionChanged();
    }
}

void AudioSourceBase::setDurationInternal(qint64 dur)
{
    if (m_duration != dur) {
        m_duration = dur;
        emit durationChanged();
    }
}