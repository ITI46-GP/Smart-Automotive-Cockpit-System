#pragma once

#include <QImage>
#include <QMutex>
#include <QQuickImageProvider>

namespace hypernova::cluster {

class MapFrameImageProvider final : public QQuickImageProvider {
public:
    MapFrameImageProvider();

    void setImage(const QImage& image);
    QImage requestImage(
            const QString& id,
            QSize* size,
            const QSize& requestedSize) override;

private:
    mutable QMutex mutex_;
    QImage latestImage_;
};

} // namespace hypernova::cluster
