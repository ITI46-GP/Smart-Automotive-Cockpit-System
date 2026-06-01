#include "WeatherAPI.h"
#include <QNetworkRequest>
#include <QUrl>
// Used to parse and create JSON documents
#include <QJsonDocument>
// Used to work with JSON objects { }
#include <QJsonObject>
// Used to work with JSON arrays [ ]
#include <QJsonArray>
#include <QDebug>
#include <QDateTime>

WeatherAPI::WeatherAPI(QObject* parent) : QObject(parent) {
    manager = new QNetworkAccessManager(this);

    // Connect network replies to response handler
    connect(manager, &QNetworkAccessManager::finished, this, &WeatherAPI::handleNetworkReply);
}

void WeatherAPI::fetchWeather(QString cityName) {
    currentCity = cityName;
    currentRequestType = "weather";
    // Build weather API request URL
    QString url = "https://api.openweathermap.org/data/2.5/weather?q=" + cityName + "&appid=" + apiKey + "&units=metric";

    QUrl qurl(url);
    QNetworkRequest request(qurl);
    manager->get(request);
}

void WeatherAPI::fetchForecast(QString cityName) {
    currentRequestType = "forecast";

    QString url = "https://api.openweathermap.org/data/2.5/forecast?q=" + cityName + "&appid=" + apiKey + "&units=metric";

    QUrl qurl(url);
    QNetworkRequest request(qurl);
    manager->get(request);
}

void WeatherAPI::handleNetworkReply(QNetworkReply* reply) {
    if (reply->error()) {
        qDebug() << "Error:" << reply->errorString();
        emit errorOccurred(reply->errorString());
        // Safely delete reply object later
        reply->deleteLater();
        return;
    }

    if (currentRequestType == "weather") {
        onWeatherDataReceived(reply);
    } else if (currentRequestType == "forecast") {
        onForecastReceived(reply);
    }
}

void WeatherAPI::onWeatherDataReceived(QNetworkReply* reply) {
    // Read all response data from the network reply
    QByteArray data = reply->readAll();
    // Convert raw JSON text into a JSON document
    QJsonDocument doc = QJsonDocument::fromJson(data);
    // Extract the root JSON object from the document
    QJsonObject json = doc.object();

    // {
    // "name":"Cairo",
    // "main":{
    //     "temp":31,
    //     "humidity":40
    //     },
    // }

    city_name = json.value("name").toString();

    QJsonObject main = json.value("main").toObject();
    temperature = main.value("temp").toDouble();
    humidity = main.value("humidity").toInt();

    // "wind":{
    //    "speed":5.2
    // }

    QJsonObject wind = json.value("wind").toObject();
    windSpeed = wind.value("speed").toDouble();

    // "weather":[
    //    {
    //       "description":"clear sky",
    //       "icon":"01d"
    //    }
    // ]

    QJsonArray weatherArray = json.value("weather").toArray();
    QJsonObject weatherObj = weatherArray.at(0).toObject();
    weather = weatherObj.value("description").toString();
    icon = weatherObj.value("icon").toString();

    qDebug() << "Weather loaded:" << city_name << temperature << weather;

    // Notify QML/UI that weather data is updated
    emit weatherDataReady();
    reply->deleteLater();

    // Fetch forecast after weather
    fetchForecast(currentCity);
}

void WeatherAPI::onForecastReceived(QNetworkReply* reply) {
    QByteArray data = reply->readAll();
    QJsonDocument doc = QJsonDocument::fromJson(data);
    QJsonObject json = doc.object();
    
    // Clear old forecast data before adding new data
    forecastList.clear();
    // Get forecast list array from JSON response
    QJsonArray list = json.value("list").toArray();
    // Store last processed date to avoid duplicate days                                    
    QString lastDate = "";

    for (int i = 0; i < list.size(); i++) {
        // Get current forecast object from array
        QJsonObject item = list.at(i).toObject();

        QString dateTime = item.value("dt_txt").toString();
        QString date = dateTime.split(" ").at(0);

        if (date != lastDate) {
            lastDate = date;

            QJsonObject main = item.value("main").toObject();
            QJsonArray weatherArray = item.value("weather").toArray();
            QJsonObject weatherObj = weatherArray.at(0).toObject();
            // Create map to store one forecast day data
            QVariantMap dayForecast;
            dayForecast["date"] = date;
            dayForecast["temp"] = main.value("temp").toDouble();
            dayForecast["icon"] = weatherObj.value("icon").toString();
            dayForecast["weather"] = weatherObj.value("description").toString();

            QDateTime dt = QDateTime::fromString(dateTime, "yyyy-MM-dd hh:mm:ss");
            dayForecast["dayName"] = dt.toString("ddd");
            // Add forecast day to forecast list
            forecastList.append(dayForecast);

            qDebug() << "Forecast day:" << dayForecast["dayName"] << dayForecast["temp"];
        }

        if (forecastList.size() >= 5) break;
    }

    qDebug() << "Forecast loaded, days:" << forecastList.size();

    emit forecastReady();
    reply->deleteLater();
}

QString WeatherAPI::getCityName() { return city_name; }
QString WeatherAPI::getWeather() { return weather; }
int WeatherAPI::getHumidity() { return humidity; }
double WeatherAPI::getTemperature() { return temperature; }
QString WeatherAPI::getIcon() { return icon; }
double WeatherAPI::getWindSpeed() { return windSpeed; }
QVariantList WeatherAPI::getForecast() { return forecastList; }
