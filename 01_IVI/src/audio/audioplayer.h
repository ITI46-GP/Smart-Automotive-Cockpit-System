#ifndef AUDIOPLAYER_H
#define AUDIOPLAYER_H

#include <QObject>
#include <QAudioOutput>
#include <QVideoSink>
#include "radioplayer.h"
#include "usbplayer.h"
#include "btplayer.h"

class AudioPlayer : public QObject
{
    Q_OBJECT

    Q_PROPERTY(bool         playing          READ getPlayingState   NOTIFY playingChanged)
    Q_PROPERTY(qint64       position         READ getPosition       WRITE  setPosition    NOTIFY positionChanged)
    Q_PROPERTY(qint64       duration         READ getDuration                             NOTIFY durationChanged)
    Q_PROPERTY(float        volume           READ getVolume         WRITE  setVolume      NOTIFY volumeChanged)
    Q_PROPERTY(QString      currentSource    READ currentSource                           NOTIFY sourceChanged)
    Q_PROPERTY(QString      currentSongTitle READ currentSongTitle                        NOTIFY songTitleChanged)
    Q_PROPERTY(bool         muted            READ getMuted          WRITE  setMuted       NOTIFY mutedChanged)
    Q_PROPERTY(bool         btSearching      READ isBtSearching                           NOTIFY btSearchingChanged)
    Q_PROPERTY(QString      btStatus         READ btStatus                                NOTIFY btStatusChanged)
    Q_PROPERTY(QVariantList availableDevices READ availableDevices                        NOTIFY availableDevicesChanged)
    Q_PROPERTY(bool         isVideo          READ isVideo                                 NOTIFY isVideoChanged)

public:
    explicit AudioPlayer(QObject *parent = nullptr);
    ~AudioPlayer();

    bool         getPlayingState()  const;
    qint64       getPosition()      const;
    qint64       getDuration()      const;
    float        getVolume()        const;
    QString      currentSource()    const;
    QString      currentSongTitle() const;
    bool         getMuted()         const;
    bool         isBtSearching()    const;
    QString      btStatus()         const;
    QVariantList availableDevices() const;
    bool         isVideo()          const;

    Q_INVOKABLE void setSource(int type);
    Q_INVOKABLE void next();
    Q_INVOKABLE void prev();
    Q_INVOKABLE void togglePlayPause();
    Q_INVOKABLE void disconnectBt();
    Q_INVOKABLE void startDiscovery();
    Q_INVOKABLE void connectToDevice(const QString &path);
    Q_INVOKABLE void bindVideoOutput(QObject* videoOutput);
    Q_INVOKABLE void stop();

public slots:
    void setVolume(float level);
    void setMuted(bool mute);
    void setPosition(qint64 pos);

signals:
    void playingChanged();
    void positionChanged();
    void durationChanged();
    void volumeChanged();
    void sourceChanged();
    void songTitleChanged();
    void mutedChanged();
    void btSearchingChanged();
    void btStatusChanged();
    void availableDevicesChanged();
    void isVideoChanged();

private:
    void connectSourceSignals(AudioSourceBase *source);
    void disconnectSourceSignals(AudioSourceBase *source);

    QAudioOutput    *m_audioOutput = nullptr;
    RadioPlayer     *m_radio       = nullptr;
    UsbPlayer       *m_usb         = nullptr;
    BtPlayer        *m_bt          = nullptr;
    AudioSourceBase *m_current     = nullptr;

    QString m_currentSourceName;
    float   m_volume = 0.5f;
    bool    m_muted  = false;
};

#endif
