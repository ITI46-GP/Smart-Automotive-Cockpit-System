#pragma once

#include <QImage>
#include <QObject>
#include <QString>

#include <atomic>
#include <cstdint>
#include <mutex>
#include <optional>

namespace hypernova::cluster {

class MapFrameImageProvider;

class MapFrameModel final : public QObject {
    Q_OBJECT

    Q_PROPERTY(bool hasFrame READ hasFrame NOTIFY frameChanged)
    Q_PROPERTY(quint32 sequence READ sequence NOTIFY frameChanged)
    Q_PROPERTY(QString imageUrl READ imageUrl NOTIFY frameChanged)

public:
    explicit MapFrameModel(
            MapFrameImageProvider* provider,
            QObject* parent = nullptr);

    bool hasFrame() const;
    quint32 sequence() const;
    QString imageUrl() const;

    // Thread-safe: only the newest decoded image is retained for QML.
    void postFrame(
            QImage image,
            std::uint32_t sequence,
            std::uint64_t captureTimestampMs);

public slots:
    void clear();

signals:
    void frameChanged();

private:
    struct PendingFrame {
        QImage image;
        std::uint32_t sequence;
        std::uint64_t captureTimestampMs;
    };

    void publishLatest();

    MapFrameImageProvider* provider_;
    mutable std::mutex mutex_;
    std::optional<PendingFrame> latestPending_;
    std::atomic_bool publishQueued_{false};
    bool hasFrame_{false};
    quint32 sequence_{0};
    quint64 captureTimestampMs_{0};
    quint64 publishedFrames_{0};
};

} // namespace hypernova::cluster
