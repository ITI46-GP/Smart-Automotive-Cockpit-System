// Ported from 02-Digital-Cluster/Backend/ContentArea/MusicController.h,
// verbatim except the mock cover URLs (see .cpp) — the original used
// relative file:// paths into the reference project's own asset folder,
// which don't resolve from this rebuild. Now qrc:/art/... aliases.
#pragma once

#include <QObject>
#include <QString>
#include <QTimer>

class MusicController : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString trackTitle READ trackTitle NOTIFY trackTitleChanged FINAL)
    Q_PROPERTY(QString trackArtist READ trackArtist NOTIFY trackArtistChanged FINAL)
    Q_PROPERTY(QString coverArtUrl READ coverArtUrl NOTIFY coverArtUrlChanged FINAL)
    Q_PROPERTY(QString prevCoverArtUrl READ prevCoverArtUrl NOTIFY prevCoverArtUrlChanged FINAL)
    Q_PROPERTY(QString nextCoverArtUrl READ nextCoverArtUrl NOTIFY nextCoverArtUrlChanged FINAL)
    Q_PROPERTY(int currentTimeSec READ currentTimeSec NOTIFY currentTimeSecChanged FINAL)
    Q_PROPERTY(int totalTimeSec READ totalTimeSec NOTIFY totalTimeSecChanged FINAL)
    Q_PROPERTY(bool isPlaying READ isPlaying NOTIFY isPlayingChanged FINAL)

public:
    explicit MusicController(QObject *parent = nullptr);

    QString trackTitle() const;
    QString trackArtist() const;
    QString coverArtUrl() const;
    QString prevCoverArtUrl() const;
    QString nextCoverArtUrl() const;
    int currentTimeSec() const;
    int totalTimeSec() const;
    bool isPlaying() const;

    Q_INVOKABLE void playPause();
    Q_INVOKABLE void nextTrack();
    Q_INVOKABLE void previousTrack();

    void setTrackTitle(const QString &title);
    void setTrackArtist(const QString &artist);
    void setCoverArtUrl(const QString &url);
    void setPrevCoverArtUrl(const QString &url);
    void setNextCoverArtUrl(const QString &url);
    void setCurrentTimeSec(int timeSec);
    void setTotalTimeSec(int timeSec);
    void setIsPlaying(bool playing);

private slots:
    void updatePlaybackTime();

private:
    void loadMockTrack(int index);

    QString m_trackTitle;
    QString m_trackArtist;
    QString m_coverArtUrl;
    QString m_prevCoverArtUrl;
    QString m_nextCoverArtUrl;
    int m_currentTimeSec = 0;
    int m_totalTimeSec = 0;
    bool m_isPlaying = false;

    QTimer *m_playbackTimer;
    int m_currentMockIndex = 0;

signals:
    void trackTitleChanged();
    void trackArtistChanged();
    void coverArtUrlChanged();
    void prevCoverArtUrlChanged();
    void nextCoverArtUrlChanged();
    void currentTimeSecChanged();
    void totalTimeSecChanged();
    void isPlayingChanged();
};
