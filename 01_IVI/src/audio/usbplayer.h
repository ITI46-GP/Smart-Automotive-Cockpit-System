#ifndef USBPLAYER_H
#define USBPLAYER_H

#include "audiosourcebase.h"
#include <QMediaPlayer>
#include <QAudioOutput>
#include <QVideoSink>

class UsbPlayer : public AudioSourceBase
{
    Q_OBJECT

public:
    explicit UsbPlayer(QObject *parent = nullptr);
    ~UsbPlayer();

    bool isVideo() const;
    void setVideoSink(QVideoSink* sink);

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

signals:
    void isVideoChanged();

private:
    void scanUsb();
    void playTrack(int index);
    void setIsVideo(bool value);

    QMediaPlayer *m_player;
    QString m_usbPath;
    QStringList m_files;
    int m_index;
    bool m_isVideo;
};

#endif