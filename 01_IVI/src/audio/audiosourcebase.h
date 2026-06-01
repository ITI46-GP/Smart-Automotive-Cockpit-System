#ifndef AUDIOSOURCEBASE_H
#define AUDIOSOURCEBASE_H


#include <QObject>
#include <QMediaPlayer>
#include <QAudioOutput>

class AudioSourceBase : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QString songTitle READ songTitle NOTIFY songTitleChanged)
    Q_PROPERTY(bool playing READ isplaying  NOTIFY playingChanged)
    Q_PROPERTY(qint64 position READ position NOTIFY positionChanged)
    Q_PROPERTY(qint64 duration READ duration NOTIFY durationChanged)


public:
    explicit AudioSourceBase(QObject *parent = nullptr);
    virtual ~AudioSourceBase();


    QString songTitle() const;
    bool    isplaying() const;
    qint64  position() const;
    qint64  duration() const;

    virtual void activate() = 0;
    virtual void deactivate() = 0;
    virtual void play() = 0;
    virtual void pause() = 0;
    virtual void stop() = 0;
    virtual void next() = 0;
    virtual void prev() = 0;
    virtual void togglePlayPause() = 0;
    virtual void seek(qint64 pos) = 0;  // slider
    virtual void setVolume(float level) = 0;
    virtual void setMuted(bool muted) = 0;
    virtual void setAudioOutput(QAudioOutput *output) = 0;

signals:
    void songTitleChanged();
    void playingChanged();
    void positionChanged();
    void durationChanged();


protected:
    void setSongTitle(const QString &title);
    void setPlaying(bool playing);
    void setPositionInternal(qint64 pos);
    void setDurationInternal(qint64 dur);

    QMediaPlayer *m_player = nullptr;
    QString m_songTitle;
    bool    m_playing = false;
    qint64  m_position = 0;
    qint64  m_duration = 0;
};

#endif // AUDIOSOURCEBASE_H
