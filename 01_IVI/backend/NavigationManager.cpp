#include "NavigationManager.h"

#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QSettings>
#include <QUrl>
#include <QUrlQuery>
#include <QtGlobal>

#include <algorithm>
#include <cmath>

namespace {
constexpr double kFallbackLatitude = 30.0444;
constexpr double kFallbackLongitude = 31.2357;
constexpr double kUnknownDestinationLatitude = 30.0610;
constexpr double kUnknownDestinationLongitude = 31.2150;
constexpr double kEarthRadiusKm = 6371.0;
constexpr double kPi = 3.14159265358979323846;
constexpr double kRouteReloadThresholdKm = 0.15;

double degreesToRadians(double degrees)
{
    return degrees * kPi / 180.0;
}

QString normalizedName(const QString &value)
{
    return value.trimmed().toLower().simplified();
}

QVariantMap routePoint(double latitude, double longitude)
{
    QVariantMap point;
    point.insert(QStringLiteral("latitude"), latitude);
    point.insert(QStringLiteral("longitude"), longitude);
    return point;
}
} // namespace

NavigationManager::NavigationManager(QObject *parent)
    : QObject(parent)
    , m_orsApiKey(qEnvironmentVariable("ORS_API_KEY").trimmed())
{
    load();
}

QString NavigationManager::destination() const
{
    return m_destination;
}

bool NavigationManager::routeActive() const
{
    return m_routeActive;
}

int NavigationManager::etaMinutes() const
{
    return m_etaMinutes;
}

double NavigationManager::distanceKm() const
{
    return m_distanceKm;
}

double NavigationManager::currentLatitude() const
{
    return m_currentLatitude;
}

double NavigationManager::currentLongitude() const
{
    return m_currentLongitude;
}

double NavigationManager::destinationLatitude() const
{
    return m_destinationLatitude;
}

double NavigationManager::destinationLongitude() const
{
    return m_destinationLongitude;
}

bool NavigationManager::currentLocationValid() const
{
    return m_currentLocationValid;
}

bool NavigationManager::routeLoading() const
{
    return m_routeLoading;
}

QString NavigationManager::routeError() const
{
    return m_routeError;
}

QVariantList NavigationManager::routePath() const
{
    return m_routePath;
}

void NavigationManager::setRouteDestination(const QString &destination)
{
    const QString normalizedDestination = destination.trimmed().simplified();

    if (normalizedDestination.isEmpty()) {
        clearRoute();
        return;
    }

    const QString oldDestination = m_destination;
    m_destination = normalizedDestination;

    if (m_destination != oldDestination) {
        emit destinationChanged();
    }

    clearRouteMetrics();
    setRouteActiveValue(false);
    setRouteLoadingValue(false);
    setRoutePathValue({});
    setRouteErrorValue({});

    const RouteInfo knownDestination = routeInfoForDestination(normalizedDestination);

    if (knownDestination.found) {
        updateDestinationCoordinate(knownDestination.latitude, knownDestination.longitude);
        loadRoute();
    } else {
        geocodeDestination(normalizedDestination);
    }

    save();
}

void NavigationManager::clearRoute()
{
    const bool destinationChangedValue = !m_destination.isEmpty();
    const bool routeActiveChangedValue = m_routeActive;
    const bool etaChangedValue = m_etaMinutes != 0;
    const bool distanceChangedValue = !qFuzzyIsNull(m_distanceKm);

    ++m_requestSerial;

    m_destination.clear();
    m_routeActive = false;
    m_etaMinutes = 0;
    m_distanceKm = 0.0;
    m_hasLastRouteStart = false;

    setRouteLoadingValue(false);
    setRouteErrorValue({});
    setRoutePathValue({});

    if (destinationChangedValue) {
        emit destinationChanged();
    }

    if (routeActiveChangedValue) {
        emit routeActiveChanged();
    }

    if (etaChangedValue) {
        emit etaMinutesChanged();
    }

    if (distanceChangedValue) {
        emit distanceKmChanged();
    }

    save();
}

void NavigationManager::setQuickDestination(const QString &name)
{
    setRouteDestination(name);
}

void NavigationManager::setCurrentLocation(double latitude, double longitude)
{
    if (!isValidCoordinate(latitude, longitude)) {
        return;
    }

    const bool latitudeChangedValue = !qFuzzyCompare(m_currentLatitude + 1.0, latitude + 1.0);
    const bool longitudeChangedValue = !qFuzzyCompare(m_currentLongitude + 1.0, longitude + 1.0);
    const bool validityChangedValue = !m_currentLocationValid;

    const double previousLatitude = m_currentLatitude;
    const double previousLongitude = m_currentLongitude;

    m_currentLatitude = latitude;
    m_currentLongitude = longitude;
    m_currentLocationValid = true;

    if (latitudeChangedValue) {
        emit currentLatitudeChanged();
    }

    if (longitudeChangedValue) {
        emit currentLongitudeChanged();
    }

    if (validityChangedValue) {
        emit currentLocationValidChanged();
    }

    if (!m_destination.isEmpty() && (latitudeChangedValue || longitudeChangedValue)) {
        const double movementKm = distanceBetween(previousLatitude, previousLongitude, latitude, longitude);

        if (!m_hasLastRouteStart || movementKm >= kRouteReloadThresholdKm) {
            loadRoute();
        }
    }

    save();
}

void NavigationManager::setDestinationCoordinate(double latitude, double longitude)
{
    if (updateDestinationCoordinate(latitude, longitude) && !m_destination.isEmpty()) {
        loadRoute();
        save();
    }
}

void NavigationManager::loadRoute()
{
    if (m_destination.isEmpty()) {
        clearRoute();
        return;
    }

    if (!isValidCoordinate(m_currentLatitude, m_currentLongitude)
        || !isValidCoordinate(m_destinationLatitude, m_destinationLongitude)) {
        ++m_requestSerial;
        failRoute(QStringLiteral("Invalid route coordinates"));
        return;
    }

    if (m_orsApiKey.isEmpty()) {
        beginOsrmRouteRequest();
        return;
    }

    beginRouteRequest();
}

void NavigationManager::geocodeDestination(const QString &destination)
{
    const QString normalizedDestination = destination.trimmed().simplified();

    if (normalizedDestination.isEmpty()) {
        clearRoute();
        return;
    }

    if (m_orsApiKey.isEmpty()) {
        const RouteInfo fallback = routeInfoForDestination(normalizedDestination);

        if (fallback.found) {
            updateDestinationCoordinate(fallback.latitude, fallback.longitude);
            loadRoute();
        } else {
            failRoute(QStringLiteral("Unknown destination and missing ORS_API_KEY"));
        }

        return;
    }

    const int requestSerial = ++m_requestSerial;

    setRouteLoadingValue(true);
    setRouteErrorValue({});
    setRouteActiveValue(false);
    setRoutePathValue({});

    QUrl url(QStringLiteral("https://api.openrouteservice.org/geocode/search"));

    QUrlQuery query;
    query.addQueryItem(QStringLiteral("api_key"), m_orsApiKey);
    query.addQueryItem(QStringLiteral("text"), normalizedDestination + QStringLiteral(", Egypt"));
    query.addQueryItem(QStringLiteral("boundary.country"), QStringLiteral("EG"));
    query.addQueryItem(QStringLiteral("size"), QStringLiteral("1"));
    url.setQuery(query);

    QNetworkRequest request(url);
    request.setRawHeader("Accept", "application/json");
    request.setRawHeader("User-Agent", "GP_IVI_Navigation");

    QNetworkReply *reply = m_networkManager.get(request);

    connect(reply, &QNetworkReply::finished, this, [this, reply, requestSerial, normalizedDestination]() {
        handleGeocodeReply(reply, requestSerial, normalizedDestination);
    });
}

NavigationManager::RouteInfo NavigationManager::routeInfoForDestination(const QString &destination) const
{
    const QString normalized = normalizedName(destination);
    RouteInfo info;

    if (normalized == QStringLiteral("maadi")) {
        info = {true, 29.9602, 31.2569};
    } else if (normalized == QStringLiteral("helwan")) {
        info = {true, 29.8414, 31.3008};
    } else if (normalized == QStringLiteral("cairo")) {
        info = {true, 30.0444, 31.2357};
    } else if (normalized == QStringLiteral("nasr city")) {
        info = {true, 30.0566, 31.3301};
    } else if (normalized == QStringLiteral("new cairo")) {
        info = {true, 30.0074, 31.4913};
    } else if (normalized == QStringLiteral("iti campus") || normalized == QStringLiteral("iti")) {
        info = {true, 30.0725, 31.0211};
    } else if (normalized == QStringLiteral("smart village")) {
        info = {true, 30.0721, 31.0189};
    } else if (normalized == QStringLiteral("charging station")) {
        info = {true, 30.0622, 31.0401};
    } else if (normalized == QStringLiteral("cairo festival city")) {
        info = {true, 30.0286, 31.4078};
    } else if (normalized == QStringLiteral("home")) {
        info = {true, 30.0626, 31.2497};
    }

    return info;
}

double NavigationManager::distanceBetween(double startLatitude,
                                          double startLongitude,
                                          double endLatitude,
                                          double endLongitude) const
{
    const double startLatitudeRad = degreesToRadians(startLatitude);
    const double endLatitudeRad = degreesToRadians(endLatitude);
    const double latitudeDelta = degreesToRadians(endLatitude - startLatitude);
    const double longitudeDelta = degreesToRadians(endLongitude - startLongitude);

    const double a = std::sin(latitudeDelta / 2.0) * std::sin(latitudeDelta / 2.0)
                     + std::cos(startLatitudeRad) * std::cos(endLatitudeRad)
                           * std::sin(longitudeDelta / 2.0) * std::sin(longitudeDelta / 2.0);

    const double c = 2.0 * std::atan2(std::sqrt(a), std::sqrt(1.0 - a));

    return kEarthRadiusKm * c;
}

void NavigationManager::beginRouteRequest()
{
    const int requestSerial = ++m_requestSerial;

    m_lastRouteStartLatitude = m_currentLatitude;
    m_lastRouteStartLongitude = m_currentLongitude;
    m_hasLastRouteStart = true;

    setRouteLoadingValue(true);
    setRouteErrorValue({});
    setRouteActiveValue(false);
    setRoutePathValue({});

    QNetworkRequest request(QUrl(QStringLiteral("https://api.openrouteservice.org/v2/directions/driving-car/geojson")));
    request.setHeader(QNetworkRequest::ContentTypeHeader, QStringLiteral("application/json"));
    request.setRawHeader("Accept", "application/geo+json, application/json");
    request.setRawHeader("Authorization", m_orsApiKey.toUtf8());
    request.setRawHeader("User-Agent", "GP_IVI_Navigation");

    QJsonArray coordinates;
    coordinates.append(QJsonArray{m_currentLongitude, m_currentLatitude});
    coordinates.append(QJsonArray{m_destinationLongitude, m_destinationLatitude});

    QJsonObject payload;
    payload.insert(QStringLiteral("coordinates"), coordinates);
    payload.insert(QStringLiteral("instructions"), false);

    QNetworkReply *reply = m_networkManager.post(
        request,
        QJsonDocument(payload).toJson(QJsonDocument::Compact)
        );

    connect(reply, &QNetworkReply::finished, this, [this, reply, requestSerial]() {
        handleDirectionsReply(reply, requestSerial);
    });
}

void NavigationManager::beginOsrmRouteRequest()
{
    const int requestSerial = ++m_requestSerial;

    m_lastRouteStartLatitude = m_currentLatitude;
    m_lastRouteStartLongitude = m_currentLongitude;
    m_hasLastRouteStart = true;

    setRouteLoadingValue(true);
    setRouteErrorValue({});
    setRouteActiveValue(false);
    setRoutePathValue({});

    const QString urlText = QStringLiteral(
                                "https://router.project-osrm.org/route/v1/driving/%1,%2;%3,%4"
                                "?overview=full&geometries=geojson&steps=false"
                                )
                                .arg(m_currentLongitude, 0, 'f', 7)
                                .arg(m_currentLatitude, 0, 'f', 7)
                                .arg(m_destinationLongitude, 0, 'f', 7)
                                .arg(m_destinationLatitude, 0, 'f', 7);

    QUrl osrmUrl(urlText);
    QNetworkRequest request(osrmUrl);
    request.setRawHeader("Accept", "application/json");
    request.setRawHeader("User-Agent", "GP_IVI_Navigation");

    QNetworkReply *reply = m_networkManager.get(request);

    connect(reply, &QNetworkReply::finished, this, [this, reply, requestSerial]() {
        handleOsrmDirectionsReply(reply, requestSerial);
    });
}

void NavigationManager::handleGeocodeReply(QNetworkReply *reply,
                                           int requestSerial,
                                           const QString &destination)
{
    const QByteArray payload = reply->readAll();
    const QNetworkReply::NetworkError networkError = reply->error();
    const int statusCode = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
    reply->deleteLater();

    if (requestSerial != m_requestSerial) {
        return;
    }

    if (networkError != QNetworkReply::NoError) {
        failRoute(QStringLiteral("Geocode error %1").arg(statusCode));
        return;
    }

    QJsonParseError parseError;
    const QJsonDocument document = QJsonDocument::fromJson(payload, &parseError);

    const QJsonArray features = document.object().value(QStringLiteral("features")).toArray();

    if (parseError.error != QJsonParseError::NoError || features.isEmpty()) {
        failRoute(QStringLiteral("Destination not found"));
        return;
    }

    const QJsonObject geometry = features.first().toObject().value(QStringLiteral("geometry")).toObject();
    const QJsonArray coordinates = geometry.value(QStringLiteral("coordinates")).toArray();

    if (coordinates.size() < 2) {
        failRoute(QStringLiteral("Destination not found"));
        return;
    }

    const double longitude = coordinates.at(0).toDouble();
    const double latitude = coordinates.at(1).toDouble();

    if (!isValidCoordinate(latitude, longitude)) {
        failRoute(QStringLiteral("Destination not found"));
        return;
    }

    if (m_destination != destination) {
        m_destination = destination;
        emit destinationChanged();
    }

    updateDestinationCoordinate(latitude, longitude);
    loadRoute();
}

void NavigationManager::handleDirectionsReply(QNetworkReply *reply, int requestSerial)
{
    const QByteArray payload = reply->readAll();
    const QNetworkReply::NetworkError networkError = reply->error();
    reply->deleteLater();

    if (requestSerial != m_requestSerial) {
        return;
    }

    if (networkError != QNetworkReply::NoError) {
        beginOsrmRouteRequest();
        return;
    }

    QJsonParseError parseError;
    const QJsonDocument document = QJsonDocument::fromJson(payload, &parseError);

    if (parseError.error != QJsonParseError::NoError || !document.isObject()) {
        beginOsrmRouteRequest();
        return;
    }

    const QJsonArray features = document.object().value(QStringLiteral("features")).toArray();

    if (features.isEmpty()) {
        beginOsrmRouteRequest();
        return;
    }

    const QJsonObject feature = features.first().toObject();
    const QJsonObject geometry = feature.value(QStringLiteral("geometry")).toObject();
    const QJsonArray coordinates = geometry.value(QStringLiteral("coordinates")).toArray();

    QVariantList path;
    path.reserve(coordinates.size());

    for (const QJsonValue &coordinateValue : coordinates) {
        const QJsonArray coordinate = coordinateValue.toArray();

        if (coordinate.size() < 2) {
            continue;
        }

        const double longitude = coordinate.at(0).toDouble();
        const double latitude = coordinate.at(1).toDouble();

        if (isValidCoordinate(latitude, longitude)) {
            path.append(routePoint(latitude, longitude));
        }
    }

    if (path.size() < 2) {
        beginOsrmRouteRequest();
        return;
    }

    const QJsonObject properties = feature.value(QStringLiteral("properties")).toObject();
    const QJsonObject summary = properties.value(QStringLiteral("summary")).toObject();

    const double distanceMeters = summary.value(QStringLiteral("distance")).toDouble();
    const double durationSeconds = summary.value(QStringLiteral("duration")).toDouble();

    const int oldEtaMinutes = m_etaMinutes;
    const double oldDistanceKm = m_distanceKm;

    m_distanceKm = distanceMeters > 0.0
                       ? std::round((distanceMeters / 1000.0) * 10.0) / 10.0
                       : 0.0;

    m_etaMinutes = durationSeconds > 0.0
                       ? std::max(1, static_cast<int>(std::ceil(durationSeconds / 60.0)))
                       : 0;

    setRoutePathValue(path);
    setRouteActiveValue(true);
    setRouteLoadingValue(false);
    setRouteErrorValue({});

    if (m_etaMinutes != oldEtaMinutes) {
        emit etaMinutesChanged();
    }

    if (!qFuzzyCompare(m_distanceKm + 1.0, oldDistanceKm + 1.0)) {
        emit distanceKmChanged();
    }

    save();
}

void NavigationManager::handleOsrmDirectionsReply(QNetworkReply *reply, int requestSerial)
{
    const QByteArray payload = reply->readAll();
    const QNetworkReply::NetworkError networkError = reply->error();
    const int statusCode = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
    reply->deleteLater();

    if (requestSerial != m_requestSerial) {
        return;
    }

    if (networkError != QNetworkReply::NoError) {
        failRoute(QStringLiteral("OSRM error %1").arg(statusCode));
        return;
    }

    QJsonParseError parseError;
    const QJsonDocument document = QJsonDocument::fromJson(payload, &parseError);

    if (parseError.error != QJsonParseError::NoError || !document.isObject()) {
        failRoute(QStringLiteral("OSRM response parse error"));
        return;
    }

    const QJsonObject rootObject = document.object();
    const QString code = rootObject.value(QStringLiteral("code")).toString();

    if (code != QStringLiteral("Ok")) {
        const QString message = rootObject.value(QStringLiteral("message")).toString().trimmed();
        failRoute(message.isEmpty() ? QStringLiteral("OSRM route failed") : message);
        return;
    }

    const QJsonArray routes = rootObject.value(QStringLiteral("routes")).toArray();

    if (routes.isEmpty()) {
        failRoute(QStringLiteral("OSRM route not found"));
        return;
    }

    const QJsonObject route = routes.first().toObject();
    const QJsonObject geometry = route.value(QStringLiteral("geometry")).toObject();
    const QJsonArray coordinates = geometry.value(QStringLiteral("coordinates")).toArray();

    QVariantList path;
    path.reserve(coordinates.size());

    for (const QJsonValue &coordinateValue : coordinates) {
        const QJsonArray coordinate = coordinateValue.toArray();

        if (coordinate.size() < 2) {
            continue;
        }

        const double longitude = coordinate.at(0).toDouble();
        const double latitude = coordinate.at(1).toDouble();

        if (isValidCoordinate(latitude, longitude)) {
            path.append(routePoint(latitude, longitude));
        }
    }

    if (path.size() < 2) {
        failRoute(QStringLiteral("OSRM route geometry unavailable"));
        return;
    }

    const int oldEtaMinutes = m_etaMinutes;
    const double oldDistanceKm = m_distanceKm;

    const double distanceMeters = route.value(QStringLiteral("distance")).toDouble();
    const double durationSeconds = route.value(QStringLiteral("duration")).toDouble();

    m_distanceKm = distanceMeters > 0.0
                       ? std::round((distanceMeters / 1000.0) * 10.0) / 10.0
                       : 0.0;

    m_etaMinutes = durationSeconds > 0.0
                       ? std::max(1, static_cast<int>(std::ceil(durationSeconds / 60.0)))
                       : 0;

    setRoutePathValue(path);
    setRouteActiveValue(true);
    setRouteLoadingValue(false);
    setRouteErrorValue({});

    if (m_etaMinutes != oldEtaMinutes) {
        emit etaMinutesChanged();
    }

    if (!qFuzzyCompare(m_distanceKm + 1.0, oldDistanceKm + 1.0)) {
        emit distanceKmChanged();
    }

    save();
}

void NavigationManager::setRouteActiveValue(bool routeActive)
{
    if (m_routeActive == routeActive) {
        return;
    }

    m_routeActive = routeActive;
    emit routeActiveChanged();
}

void NavigationManager::setRouteLoadingValue(bool routeLoading)
{
    if (m_routeLoading == routeLoading) {
        return;
    }

    m_routeLoading = routeLoading;
    emit routeLoadingChanged();
}

void NavigationManager::setRouteErrorValue(const QString &routeError)
{
    if (m_routeError == routeError) {
        return;
    }

    m_routeError = routeError;
    emit routeErrorChanged();
}

void NavigationManager::setRoutePathValue(const QVariantList &routePath)
{
    if (m_routePath == routePath) {
        return;
    }

    m_routePath = routePath;
    emit routePathChanged();
}

void NavigationManager::clearRouteMetrics()
{
    const int oldEtaMinutes = m_etaMinutes;
    const double oldDistanceKm = m_distanceKm;

    m_etaMinutes = 0;
    m_distanceKm = 0.0;

    if (m_etaMinutes != oldEtaMinutes) {
        emit etaMinutesChanged();
    }

    if (!qFuzzyCompare(m_distanceKm + 1.0, oldDistanceKm + 1.0)) {
        emit distanceKmChanged();
    }
}

void NavigationManager::failRoute(const QString &message)
{
    clearRouteMetrics();
    setRouteActiveValue(false);
    setRouteLoadingValue(false);
    setRouteErrorValue(message);
    setRoutePathValue({});
}

QString NavigationManager::networkErrorMessage(QNetworkReply *reply, const QByteArray &payload) const
{
    QJsonParseError parseError;
    const QJsonDocument document = QJsonDocument::fromJson(payload, &parseError);

    if (parseError.error == QJsonParseError::NoError && document.isObject()) {
        const QJsonObject object = document.object();
        const QJsonValue errorValue = object.value(QStringLiteral("error"));

        if (errorValue.isObject()) {
            const QString message = errorValue.toObject().value(QStringLiteral("message")).toString().trimmed();

            if (!message.isEmpty()) {
                return message;
            }
        } else if (errorValue.isString()) {
            const QString message = errorValue.toString().trimmed();

            if (!message.isEmpty()) {
                return message;
            }
        }
    }

    const int statusCode = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();

    if (statusCode > 0) {
        return QStringLiteral("Routing service error %1").arg(statusCode);
    }

    return reply->errorString().trimmed().isEmpty()
               ? QStringLiteral("Routing service unavailable")
               : reply->errorString().trimmed();
}

bool NavigationManager::isValidCoordinate(double latitude, double longitude) const
{
    return latitude >= -90.0
           && latitude <= 90.0
           && longitude >= -180.0
           && longitude <= 180.0;
}

bool NavigationManager::updateDestinationCoordinate(double latitude, double longitude)
{
    if (!isValidCoordinate(latitude, longitude)) {
        return false;
    }

    const bool latitudeChangedValue = !qFuzzyCompare(m_destinationLatitude + 1.0, latitude + 1.0);
    const bool longitudeChangedValue = !qFuzzyCompare(m_destinationLongitude + 1.0, longitude + 1.0);

    m_destinationLatitude = latitude;
    m_destinationLongitude = longitude;

    if (latitudeChangedValue) {
        emit destinationLatitudeChanged();
    }

    if (longitudeChangedValue) {
        emit destinationLongitudeChanged();
    }

    return latitudeChangedValue || longitudeChangedValue;
}

void NavigationManager::load()
{
    QSettings settings;
    settings.beginGroup("NavigationManager");

    m_destination = settings.value(QStringLiteral("destination")).toString();
    m_destinationLatitude = settings.value(QStringLiteral("destinationLatitude"), kUnknownDestinationLatitude).toDouble();
    m_destinationLongitude = settings.value(QStringLiteral("destinationLongitude"), kUnknownDestinationLongitude).toDouble();

    settings.endGroup();

    m_currentLatitude = kFallbackLatitude;
    m_currentLongitude = kFallbackLongitude;
    m_currentLocationValid = false;

    m_routeActive = false;
    m_routeLoading = false;
    m_routeError.clear();
    m_routePath.clear();
    m_etaMinutes = 0;
    m_distanceKm = 0.0;

    if (!isValidCoordinate(m_destinationLatitude, m_destinationLongitude)) {
        m_destinationLatitude = kUnknownDestinationLatitude;
        m_destinationLongitude = kUnknownDestinationLongitude;
    }
}

void NavigationManager::save() const
{
    QSettings settings;
    settings.beginGroup("NavigationManager");

    settings.setValue(QStringLiteral("destination"), m_destination);
    settings.setValue(QStringLiteral("destinationLatitude"), m_destinationLatitude);
    settings.setValue(QStringLiteral("destinationLongitude"), m_destinationLongitude);

    settings.endGroup();
}
