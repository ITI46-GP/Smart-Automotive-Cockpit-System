#ifndef AUDIOCOMPATMANAGER_H
#define AUDIOCOMPATMANAGER_H

#include <QObject>
#include <QTimer>
#include <QVariantList>

class AudioCompatManager : public QObject
{
    Q_OBJECT

    Q_PROPERTY(bool playing READ playing NOTIFY playingChanged)
    Q_PROPERTY(qint64 position READ position WRITE setPosition NOTIFY positionChanged)
    Q_PROPERTY(qint64 duration READ duration NOTIFY durationChanged)
    Q_PROPERTY(float volume READ volume WRITE setVolume NOTIFY volumeChanged)
    Q_PROPERTY(QString currentSource READ currentSource NOTIFY sourceChanged)
    Q_PROPERTY(QString currentSongTitle READ currentSongTitle NOTIFY songTitleChanged)
    Q_PROPERTY(bool muted READ muted WRITE setMuted NOTIFY mutedChanged)
    Q_PROPERTY(bool btSearching READ btSearching NOTIFY btSearchingChanged)
    Q_PROPERTY(QString btStatus READ btStatus NOTIFY btStatusChanged)
    Q_PROPERTY(QVariantList availableDevices READ availableDevices NOTIFY availableDevicesChanged)
    Q_PROPERTY(bool isVideo READ isVideo NOTIFY isVideoChanged)

public:
    explicit AudioCompatManager(QObject *parent = nullptr);

    bool playing() const;
    qint64 position() const;
    qint64 duration() const;
    float volume() const;
    QString currentSource() const;
    QString currentSongTitle() const;
    bool muted() const;
    bool btSearching() const;
    QString btStatus() const;
    QVariantList availableDevices() const;
    bool isVideo() const;

    Q_INVOKABLE void setSource(int type);
    Q_INVOKABLE void next();
    Q_INVOKABLE void prev();
    Q_INVOKABLE void togglePlayPause();
    Q_INVOKABLE void disconnectBt();
    Q_INVOKABLE void startDiscovery();
    Q_INVOKABLE void connectToDevice(const QString &path);
    Q_INVOKABLE void bindVideoOutput(QObject *videoOutput);
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
    void setPlaying(bool playing);
    void setBtSearching(bool searching);
    void setBtStatus(const QString &status);
    void updateSongTitle();

    QTimer m_positionTimer;
    QVariantList m_availableDevices;
    QString m_currentSource;
    QString m_currentSongTitle = QStringLiteral("No Media");
    QString m_btStatus = QStringLiteral("Compatibility Mode");
    qint64 m_position = 0;
    qint64 m_duration = 180000;
    float m_volume = 0.5f;
    int m_trackIndex = 0;
    bool m_playing = false;
    bool m_muted = false;
    bool m_btSearching = false;
    bool m_isVideo = false;
};

#endif
