#include "usbplayer.h"
#include <QDir>
#include <QUrl>
#include <QDirIterator>
#include <QFileInfo>
#include <QFile>
#include <QTextStream>
#include <QDebug>

UsbPlayer::UsbPlayer(QObject *parent)
    : AudioSourceBase(parent)
    , m_player(new QMediaPlayer(this))
    , m_usbPath("")
    , m_index(0)
    , m_isVideo(false)
{
    connect(m_player, &QMediaPlayer::positionChanged,
            this, [this](qint64 pos){ setPositionInternal(pos); });

    connect(m_player, &QMediaPlayer::durationChanged,
            this, [this](qint64 dur){ setDurationInternal(dur); });

    connect(m_player, &QMediaPlayer::playbackStateChanged,
            this, [this](){
                setPlaying(m_player->playbackState() == QMediaPlayer::PlayingState);
            });
}

UsbPlayer::~UsbPlayer()
{
}

bool UsbPlayer::isVideo() const
{
    return m_isVideo;
}

void UsbPlayer::setVideoSink(QVideoSink* sink)
{
    m_player->setVideoSink(sink);
}

void UsbPlayer::activate()
{
    scanUsb();
    if (!m_files.isEmpty()) {
        m_index = 0;
        playTrack(m_index);
    } else {
        setSongTitle("No Media Found");
    }
}

void UsbPlayer::deactivate()
{
    m_player->stop();
    setIsVideo(false);
}

void UsbPlayer::play()
{
    m_player->play();
}

void UsbPlayer::pause()
{
    m_player->pause();
}

void UsbPlayer::stop()
{
    m_player->stop();
}

void UsbPlayer::next()
{
    if (!m_files.isEmpty()) {
        m_index = (m_index + 1) % m_files.size();
        playTrack(m_index);
    }
}

void UsbPlayer::prev()
{
    if (!m_files.isEmpty()) {
        m_index = (m_index - 1 + m_files.size()) % m_files.size();
        playTrack(m_index);
    }
}

void UsbPlayer::togglePlayPause()
{
    if (m_player->playbackState() == QMediaPlayer::PlayingState)
        m_player->pause();
    else
        m_player->play();
}

void UsbPlayer::seek(qint64 pos)
{
    m_player->setPosition(pos);
}

void UsbPlayer::setVolume(float level)
{
    if (m_player->audioOutput())
        m_player->audioOutput()->setVolume(level);
}

void UsbPlayer::setMuted(bool muted)
{
    if (m_player->audioOutput())
        m_player->audioOutput()->setMuted(muted);
}

void UsbPlayer::setAudioOutput(QAudioOutput *output)
{
    m_player->setAudioOutput(output);
}

void UsbPlayer::scanUsb()
{
    m_files.clear();
    QStringList candidates;

    QFile file("/proc/mounts");
    if (file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        QTextStream in(&file);
        while (!in.atEnd()) {
            QString line = in.readLine();
            if (line.contains("/media/") || line.contains("/run/media/") || line.contains("/mnt/")) {
                QString path = line.split(" ").at(1);
                candidates.append(path);
            }
        }
        file.close();
    }

    candidates.append("/media");
    candidates.append("/mnt");

    QStringList filters = {"*.mp3", "*.wav", "*.flac", "*.aac", "*.mp4", "*.mkv", "*.avi", "*.mov", "*.wmv",
                          "*.MP3", "*.WAV", "*.FLAC", "*.AAC", "*.MP4", "*.MKV", "*.AVI", "*.MOV", "*.WMV"};

    for (const QString &baseDir : candidates) {
        QDir dir(baseDir);
        if (!dir.exists()) continue;

        QDirIterator it(baseDir, filters, QDir::Files, QDirIterator::Subdirectories);
        while (it.hasNext()) {
            m_files.append(it.next());
        }

        if (!m_files.isEmpty()) {
            m_usbPath = baseDir;
            return;
        }
    }
}

void UsbPlayer::playTrack(int index)
{
    if (index < 0 || index >= m_files.size())
        return;

    m_index = index;
    QString fullPath = m_files.at(m_index);
    
    QFileInfo fileInfo(fullPath);
    QString ext = fileInfo.suffix().toLower();

    bool video = (ext == "mp4" || ext == "mkv" || ext == "avi" || ext == "mov" || ext == "wmv");
    setIsVideo(video);

    setSongTitle(fileInfo.baseName());
    
    m_player->setSource(QUrl::fromLocalFile(fullPath));
    m_player->play();
}

void UsbPlayer::setIsVideo(bool value)
{
    if (m_isVideo == value)
        return;
    m_isVideo = value;
    emit isVideoChanged();
}