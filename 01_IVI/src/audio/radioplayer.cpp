#include "radioplayer.h"
#include <QUrl>

RadioPlayer::RadioPlayer(QObject *parent) : AudioSourceBase(parent)
    , m_index(0)
{
    m_player = new QMediaPlayer(this);

    m_urls << "http://stream.radiojar.com/8s5u5tpdtwzuv"
           << "http://live.mp3quran.net:8002/";

    connect(m_player, &QMediaPlayer::positionChanged,
            this, [this](qint64 pos){ setPositionInternal(pos); });

    connect(m_player, &QMediaPlayer::durationChanged,
            this, [this](qint64 dur){ setDurationInternal(dur); });

    connect(m_player, &QMediaPlayer::playbackStateChanged,
            this, [this](){
                setPlaying(m_player->playbackState() == QMediaPlayer::PlayingState);
            });
}

RadioPlayer::~RadioPlayer()
{
}

void RadioPlayer::activate()
{
    setSongTitle("Live Radio Stream");
    m_player->setSource(QUrl(m_urls.at(m_index)));
    m_player->play();
}

void RadioPlayer::deactivate()
{
    m_player->stop();
}

void RadioPlayer::play()
{
    m_player->play();
}

void RadioPlayer::pause()
{
    m_player->pause();
}

void RadioPlayer::stop()
{
    m_player->stop();
}

void RadioPlayer::next()
{
    m_index = (m_index + 1) % m_urls.size();
    activate();
}

void RadioPlayer::prev()
{
    m_index = (m_index - 1 + m_urls.size()) % m_urls.size();
    activate();
}

void RadioPlayer::togglePlayPause()
{
    if (m_player->playbackState() == QMediaPlayer::PlayingState)
        m_player->pause();
    else
        m_player->play();
}

void RadioPlayer::seek(qint64 pos)
{
    Q_UNUSED(pos)
}

void RadioPlayer::setVolume(float level)
{
    if (m_player->audioOutput())
        m_player->audioOutput()->setVolume(level);
}

void RadioPlayer::setMuted(bool muted)
{
    if (m_player->audioOutput())
        m_player->audioOutput()->setMuted(muted);
}

void RadioPlayer::setAudioOutput(QAudioOutput *output)
{
    m_player->setAudioOutput(output);
}