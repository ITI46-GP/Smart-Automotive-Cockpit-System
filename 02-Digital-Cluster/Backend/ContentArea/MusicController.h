#ifndef MUSICCONTROLLER_H
#define MUSICCONTROLLER_H

#include <QObject>
#include <QString>
#include <QTimer>

/**
 * @brief MusicController bridges the QML Music UI with the external IVI media player.
 * 
 * This class exposes Q_PROPERTY bindings to the QML UI, ensuring the Digital Cluster
 * automatically updates when a track changes, pauses, or progresses.
 * 
 * In a production architecture over SOME/IP:
 * - Incoming IPC messages update these properties via the setter methods.
 * - Outgoing IPC messages are triggered when QML calls the Q_INVOKABLE methods (like playPause).
 */
class MusicController : public QObject
{
    Q_OBJECT
    // --- QML Exposed Properties ---
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

    // --- Property Getters ---
    QString trackTitle() const;
    QString trackArtist() const;
    QString coverArtUrl() const;
    QString prevCoverArtUrl() const;
    QString nextCoverArtUrl() const;
    int currentTimeSec() const;
    int totalTimeSec() const;
    bool isPlaying() const;

    // --- QML Invokable Methods ---
    // These methods are triggered by user interaction on the Digital Cluster UI.
    // They will eventually format and transmit SOME/IP messages to the IVI system.

    /** @brief Toggles the current playback state. Sends an IPC request to IVI. */
    Q_INVOKABLE void playPause();
    
    /** @brief Skips to the next track in the playlist. Sends an IPC request to IVI. */
    Q_INVOKABLE void nextTrack();
    
    /** @brief Returns to the previous track. Sends an IPC request to IVI. */
    Q_INVOKABLE void previousTrack();

    // --- Data Ingestion Setters ---
    // These methods act as the interface for the future CommonAPI/SOME/IP IPC layer.
    // The background IPC thread will call these when the IVI broadcasts media updates.

    /** @brief Updates the track title and signals QML. */
    void setTrackTitle(const QString &title);
    
    /** @brief Updates the artist name and signals QML. */
    void setTrackArtist(const QString &artist);
    
    /** @brief Updates the primary cover art URL and signals QML. */
    void setCoverArtUrl(const QString &url);
    
    /** @brief Updates the left-side preview cover art URL and signals QML. */
    void setPrevCoverArtUrl(const QString &url);
    
    /** @brief Updates the right-side preview cover art URL and signals QML. */
    void setNextCoverArtUrl(const QString &url);
    
    /** @brief Updates the current playback time in seconds and signals QML. */
    void setCurrentTimeSec(int timeSec);
    
    /** @brief Updates the total track duration in seconds and signals QML. */
    void setTotalTimeSec(int timeSec);
    
    /** @brief Updates the playing state boolean and signals QML. Controls the internal timer. */
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
    
    // Internal mock data management
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

#endif // MUSICCONTROLLER_H
