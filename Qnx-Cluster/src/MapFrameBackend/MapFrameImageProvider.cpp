#include "MapFrameImageProvider.hpp"

#include <QMutexLocker>

namespace hypernova::cluster {

MapFrameImageProvider::MapFrameImageProvider()
    : QQuickImageProvider(QQuickImageProvider::Image)
{
}

void MapFrameImageProvider::setImage(const QImage& image)
{
    QMutexLocker locker(&mutex_);
    latestImage_ = image;
}

QImage MapFrameImageProvider::requestImage(
        const QString&,
        QSize* size,
        const QSize& requestedSize)
{
    QImage image;
    {
        QMutexLocker locker(&mutex_);
        image = latestImage_;
    }
    if (size != nullptr) {
        *size = image.size();
    }
    if (!image.isNull()
            && requestedSize.isValid()
            && requestedSize != image.size()) {
        image = image.scaled(
                requestedSize,
                Qt::IgnoreAspectRatio,
                Qt::SmoothTransformation);
    }
    return image;
}

} // namespace hypernova::cluster
