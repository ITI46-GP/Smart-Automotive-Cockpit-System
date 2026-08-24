#include "MapFrameModel.hpp"

#include "MapFrameImageProvider.hpp"

#include <QDebug>
#include <QMetaObject>

namespace hypernova::cluster {

MapFrameModel::MapFrameModel(
        MapFrameImageProvider* provider,
        QObject* parent)
    : QObject(parent),
      provider_(provider)
{
}

bool MapFrameModel::hasFrame() const { return hasFrame_; }
quint32 MapFrameModel::sequence() const { return sequence_; }

QString MapFrameModel::imageUrl() const
{
    return QStringLiteral("image://hnmf/latest?sequence=%1").arg(sequence_);
}

void MapFrameModel::postFrame(
        QImage image,
        std::uint32_t sequence,
        std::uint64_t captureTimestampMs)
{
    {
        const std::lock_guard<std::mutex> locker(mutex_);
        latestPending_ = PendingFrame{
                std::move(image), sequence, captureTimestampMs};
    }

    bool expected = false;
    if (publishQueued_.compare_exchange_strong(expected, true)) {
        QMetaObject::invokeMethod(
                this,
                [this] { publishLatest(); },
                Qt::QueuedConnection);
    }
}

void MapFrameModel::clear()
{
    {
        const std::lock_guard<std::mutex> locker(mutex_);
        latestPending_.reset();
    }
    hasFrame_ = false;
    sequence_ = 0;
    captureTimestampMs_ = 0;
    if (provider_ != nullptr) {
        provider_->setImage(QImage{});
    }
    emit frameChanged();
}

void MapFrameModel::publishLatest()
{
    std::optional<PendingFrame> pending;
    {
        const std::lock_guard<std::mutex> locker(mutex_);
        pending = std::move(latestPending_);
        latestPending_.reset();
    }

    if (pending.has_value() && provider_ != nullptr) {
        provider_->setImage(pending->image);
        hasFrame_ = true;
        sequence_ = pending->sequence;
        captureTimestampMs_ = pending->captureTimestampMs;
        ++publishedFrames_;
        if ((publishedFrames_ % 50U) == 0U) {
            qInfo() << "HNMF render update sequence=" << sequence_
                    << "captureTimestampMs=" << captureTimestampMs_
                    << "size=" << pending->image.size();
        }
        emit frameChanged();
    }

    publishQueued_.store(false);
    bool anotherFrameIsPending = false;
    {
        const std::lock_guard<std::mutex> locker(mutex_);
        anotherFrameIsPending = latestPending_.has_value();
    }
    if (anotherFrameIsPending) {
        bool expected = false;
        if (publishQueued_.compare_exchange_strong(expected, true)) {
            QMetaObject::invokeMethod(
                    this,
                    [this] { publishLatest(); },
                    Qt::QueuedConnection);
        }
    }
}

} // namespace hypernova::cluster
