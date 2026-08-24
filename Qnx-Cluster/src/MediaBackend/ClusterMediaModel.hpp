#pragma once

#include "HnmcProtocol.hpp"

#include <QObject>
#include <QString>

namespace hypernova::cluster {

/*
 * Qt/QML presentation model for Android media state.
 *
 * HnmcMediaServer runs on its own worker thread.
 * All updates entering through post*() are marshalled safely
 * onto the Qt main thread before changing Q_PROPERTY state.
 */
class ClusterMediaModel final : public QObject
{
    Q_OBJECT

    Q_PROPERTY(
            bool connected
            READ connected
            NOTIFY stateChanged)

    Q_PROPERTY(
            bool hasMedia
            READ hasMedia
            NOTIFY stateChanged)

    Q_PROPERTY(
            bool playing
            READ playing
            NOTIFY stateChanged)

    Q_PROPERTY(
            qulonglong positionMs
            READ positionMs
            NOTIFY stateChanged)

    Q_PROPERTY(
            qulonglong durationMs
            READ durationMs
            NOTIFY stateChanged)

    Q_PROPERTY(
            QString mediaId
            READ mediaId
            NOTIFY stateChanged)

    Q_PROPERTY(
            QString title
            READ title
            NOTIFY stateChanged)

    Q_PROPERTY(
            QString artist
            READ artist
            NOTIFY stateChanged)

    Q_PROPERTY(
            QString album
            READ album
            NOTIFY stateChanged)

public:
    explicit ClusterMediaModel(
            QObject *parent = nullptr);

    bool connected() const;
    bool hasMedia() const;
    bool playing() const;

    qulonglong positionMs() const;
    qulonglong durationMs() const;

    QString mediaId() const;
    QString title() const;
    QString artist() const;
    QString album() const;

    /*
     * Thread-safe entry points used by HnmcMediaServer callbacks.
     */
    void postConnectionState(
            bool connected);

    void postMediaState(
            hnmc::MediaState state);

    void postMediaClear();

signals:
    void stateChanged();

private:
    void applyConnectionState(
            bool connected);

    void applyMediaState(
            const hnmc::MediaState &state);

    void applyMediaClear();

    void clearMediaState();

    static QString decodeUtf8(
            const std::string &value);

    bool connected_ = false;
    bool hasMedia_ = false;
    bool playing_ = false;

    qulonglong positionMs_ = 0;
    qulonglong durationMs_ = 0;

    QString mediaId_;
    QString title_;
    QString artist_;
    QString album_;
};

} // namespace hypernova::cluster
