#ifndef NAVIGATIONMANAGER_H
#define NAVIGATIONMANAGER_H

#include <QNetworkAccessManager>
#include <QObject>
#include <QString>
#include <QVariantList>

class QNetworkReply;

class NavigationManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString destination READ destination NOTIFY destinationChanged)
    Q_PROPERTY(bool routeActive READ routeActive NOTIFY routeActiveChanged)
    Q_PROPERTY(int etaMinutes READ etaMinutes NOTIFY etaMinutesChanged)
    Q_PROPERTY(double distanceKm READ distanceKm NOTIFY distanceKmChanged)
    Q_PROPERTY(double currentLatitude READ currentLatitude NOTIFY currentLatitudeChanged)
    Q_PROPERTY(double currentLongitude READ currentLongitude NOTIFY currentLongitudeChanged)
    Q_PROPERTY(double destinationLatitude READ destinationLatitude NOTIFY destinationLatitudeChanged)
    Q_PROPERTY(double destinationLongitude READ destinationLongitude NOTIFY destinationLongitudeChanged)
    Q_PROPERTY(bool currentLocationValid READ currentLocationValid NOTIFY currentLocationValidChanged)
    Q_PROPERTY(bool routeLoading READ routeLoading NOTIFY routeLoadingChanged)
    Q_PROPERTY(QString routeError READ routeError NOTIFY routeErrorChanged)
    Q_PROPERTY(QVariantList routePath READ routePath NOTIFY routePathChanged)

public:
    explicit NavigationManager(QObject *parent = nullptr);

    QString destination() const;
    bool routeActive() const;
    int etaMinutes() const;
    double distanceKm() const;
    double currentLatitude() const;
    double currentLongitude() const;
    double destinationLatitude() const;
    double destinationLongitude() const;
    bool currentLocationValid() const;
    bool routeLoading() const;
    QString routeError() const;
    QVariantList routePath() const;

    Q_INVOKABLE void setRouteDestination(const QString &destination);
    Q_INVOKABLE void clearRoute();
    Q_INVOKABLE void setQuickDestination(const QString &name);
    Q_INVOKABLE void setCurrentLocation(double latitude, double longitude);
    Q_INVOKABLE void setDestinationCoordinate(double latitude, double longitude);
    Q_INVOKABLE void loadRoute();
    Q_INVOKABLE void geocodeDestination(const QString &destination);

signals:
    void destinationChanged();
    void routeActiveChanged();
    void etaMinutesChanged();
    void distanceKmChanged();
    void currentLatitudeChanged();
    void currentLongitudeChanged();
    void destinationLatitudeChanged();
    void destinationLongitudeChanged();
    void currentLocationValidChanged();
    void routeLoadingChanged();
    void routeErrorChanged();
    void routePathChanged();

private:
    struct RouteInfo
    {
        bool found = false;
        double latitude = 0.0;
        double longitude = 0.0;
    };

    RouteInfo routeInfoForDestination(const QString &destination) const;
    double distanceBetween(double startLatitude, double startLongitude, double endLatitude, double endLongitude) const;

    void beginRouteRequest();
    void beginOsrmRouteRequest();

    void handleGeocodeReply(QNetworkReply *reply, int requestSerial, const QString &destination);
    void handleDirectionsReply(QNetworkReply *reply, int requestSerial);
    void handleOsrmDirectionsReply(QNetworkReply *reply, int requestSerial);

    void setRouteActiveValue(bool routeActive);
    void setRouteLoadingValue(bool routeLoading);
    void setRouteErrorValue(const QString &routeError);
    void setRoutePathValue(const QVariantList &routePath);
    void clearRouteMetrics();
    void failRoute(const QString &message);

    QString networkErrorMessage(QNetworkReply *reply, const QByteArray &payload) const;
    bool isValidCoordinate(double latitude, double longitude) const;
    bool updateDestinationCoordinate(double latitude, double longitude);
    void load();
    void save() const;

    QString m_destination;
    bool m_routeActive = false;
    int m_etaMinutes = 0;
    double m_distanceKm = 0.0;

    double m_currentLatitude = 30.0444;
    double m_currentLongitude = 31.2357;

    double m_destinationLatitude = 30.0610;
    double m_destinationLongitude = 31.2150;

    bool m_currentLocationValid = false;
    bool m_routeLoading = false;
    QString m_routeError;
    QVariantList m_routePath;

    QString m_orsApiKey;
    QNetworkAccessManager m_networkManager;
    int m_requestSerial = 0;

    double m_lastRouteStartLatitude = 0.0;
    double m_lastRouteStartLongitude = 0.0;
    bool m_hasLastRouteStart = false;
};

#endif // NAVIGATIONMANAGER_H
