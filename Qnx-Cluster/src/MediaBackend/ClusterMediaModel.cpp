#include "ClusterMediaModel.hpp"

#include <QMetaObject>
#include <QThread>

#include <utility>

namespace hypernova::cluster {

ClusterMediaModel::ClusterMediaModel(
        QObject *parent)
    : QObject(parent)
{
}

bool ClusterMediaModel::connected() const
{
    return connected_;
}

bool ClusterMediaModel::hasMedia() const
{
    return hasMedia_;
}

bool ClusterMediaModel::playing() const
{
    return playing_;
}

qulonglong ClusterMediaModel::positionMs() const
{
    return positionMs_;
}

qulonglong ClusterMediaModel::durationMs() const
{
    return durationMs_;
}

QString ClusterMediaModel::mediaId() const
{
    return mediaId_;
}

QString ClusterMediaModel::title() const
{
    return title_;
}

QString ClusterMediaModel::artist() const
{
    return artist_;
}

QString ClusterMediaModel::album() const
{
    return album_;
}

void ClusterMediaModel::postConnectionState(
        bool connected)
{
    if (QThread::currentThread()
            == thread()) {

        applyConnectionState(
                connected);

        return;
    }

    QMetaObject::invokeMethod(
            this,
            [this, connected]() {
                applyConnectionState(
                        connected);
            },
            Qt::QueuedConnection);
}

void ClusterMediaModel::postMediaState(
        hnmc::MediaState state)
{
    if (QThread::currentThread()
            == thread()) {

        applyMediaState(
                state);

        return;
    }

    QMetaObject::invokeMethod(
            this,
            [
                this,
                state = std::move(state)
            ]() {
                applyMediaState(
                        state);
            },
            Qt::QueuedConnection);
}

void ClusterMediaModel::postMediaClear()
{
    if (QThread::currentThread()
            == thread()) {

        applyMediaClear();

        return;
    }

    QMetaObject::invokeMethod(
            this,
            [this]() {
                applyMediaClear();
            },
            Qt::QueuedConnection);
}

void ClusterMediaModel::applyConnectionState(
        bool connected)
{
    bool changed =
            connected_ != connected;

    connected_ =
            connected;

    /*
     * Never leave stale Android playback state visible
     * after the HNMC source disappears.
     */
    if (!connected_) {

        const bool hadState =
                hasMedia_
                || playing_
                || positionMs_ != 0
                || durationMs_ != 0
                || !mediaId_.isEmpty()
                || !title_.isEmpty()
                || !artist_.isEmpty()
                || !album_.isEmpty();

        if (hadState) {
            clearMediaState();
            changed = true;
        }
    }

    if (changed) {
        emit stateChanged();
    }
}

void ClusterMediaModel::applyMediaState(
        const hnmc::MediaState &state)
{
    const QString newMediaId =
            decodeUtf8(
                    state.mediaId);

    const QString newTitle =
            decodeUtf8(
                    state.title);

    const QString newArtist =
            decodeUtf8(
                    state.artist);

    const QString newAlbum =
            decodeUtf8(
                    state.album);

    const qulonglong newPosition =
            static_cast<qulonglong>(
                    state.positionMs);

    const qulonglong newDuration =
            static_cast<qulonglong>(
                    state.durationMs);

    const bool changed =
            hasMedia_ != state.hasMedia
            || playing_ != state.playing
            || positionMs_ != newPosition
            || durationMs_ != newDuration
            || mediaId_ != newMediaId
            || title_ != newTitle
            || artist_ != newArtist
            || album_ != newAlbum;

    if (!changed) {
        return;
    }

    hasMedia_ =
            state.hasMedia;

    playing_ =
            state.hasMedia
            && state.playing;

    positionMs_ =
            state.hasMedia
            ? newPosition
            : 0;

    durationMs_ =
            state.hasMedia
            ? newDuration
            : 0;

    if (state.hasMedia) {

        mediaId_ =
                newMediaId;

        title_ =
                newTitle;

        artist_ =
                newArtist;

        album_ =
                newAlbum;

    } else {

        mediaId_.clear();
        title_.clear();
        artist_.clear();
        album_.clear();
    }

    emit stateChanged();
}

void ClusterMediaModel::applyMediaClear()
{
    const bool hadState =
            hasMedia_
            || playing_
            || positionMs_ != 0
            || durationMs_ != 0
            || !mediaId_.isEmpty()
            || !title_.isEmpty()
            || !artist_.isEmpty()
            || !album_.isEmpty();

    if (!hadState) {
        return;
    }

    clearMediaState();

    emit stateChanged();
}

void ClusterMediaModel::clearMediaState()
{
    hasMedia_ = false;
    playing_ = false;

    positionMs_ = 0;
    durationMs_ = 0;

    mediaId_.clear();
    title_.clear();
    artist_.clear();
    album_.clear();
}

QString ClusterMediaModel::decodeUtf8(
        const std::string &value)
{
    return QString::fromUtf8(
            value.data(),
            static_cast<qsizetype>(
                    value.size()));
}

} // namespace hypernova::cluster
