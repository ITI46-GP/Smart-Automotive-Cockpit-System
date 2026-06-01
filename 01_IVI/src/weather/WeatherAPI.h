#ifndef WEATHERAPI_H
#define WEATHERAPI_H

#include <QObject>
#include <QString>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QVariantList>

class WeatherAPI : public QObject {
    // Enable Qt meta-object features (signals, slots, properties)
    Q_OBJECT

    // Current city name property exposed to QML
    Q_PROPERTY(QString cityName READ getCityName NOTIFY weatherDataReady)
    // Current weather description property
    Q_PROPERTY(QString weather READ getWeather NOTIFY weatherDataReady)
    Q_PROPERTY(int humidity READ getHumidity NOTIFY weatherDataReady)
    Q_PROPERTY(double temperature READ getTemperature NOTIFY weatherDataReady)
    // Weather icon code property
    Q_PROPERTY(QString icon READ getIcon NOTIFY weatherDataReady)
    Q_PROPERTY(double windSpeed READ getWindSpeed NOTIFY weatherDataReady)
    // 5-day forecast list exposed to QML
    Q_PROPERTY(QVariantList forecast READ getForecast NOTIFY forecastReady)

private:

    // Handles all network requests to the weather API
    QNetworkAccessManager* manager;
    // API key used for OpenWeather requests
    QString apiKey = "a535d6f8909944fbab017f765c2d80b1";
    // Stores the currently selected city
    QString currentCity;
    // Stores current request type (weather or forecast)
    QString currentRequestType;
    // Stores city name from API response
    QString city_name;
    // Stores weather description (e.g. clear sky)
    QString weather;
    // Stores forecast data list for upcoming days
    int humidity = 0;
    double temperature = 0.0;
    QString icon;
    double windSpeed = 0.0;
    QVariantList forecastList;

public:
    // Constructor for WeatherAPI class
    explicit WeatherAPI(QObject* parent = nullptr);
    // Fetch current weather data for a city
    Q_INVOKABLE void fetchWeather(QString cityName);
    // Fetch forecast data for a city
    Q_INVOKABLE void fetchForecast(QString cityName);
    // Return current city name
    QString getCityName();
    // Return current weather description
    QString getWeather();
    // Return humidity value
    int getHumidity();
    // Return current temperature
    double getTemperature();
    // Return weather icon code
    QString getIcon();
    // Return wind speed value
    double getWindSpeed();
    // Return forecast list
    QVariantList getForecast();

private slots:

    // Handle finished network replies
    void handleNetworkReply(QNetworkReply* reply);
    // Parse current weather response
    void onWeatherDataReceived(QNetworkReply* reply);
    // Parse forecast response
    void onForecastReceived(QNetworkReply* reply);

signals:

    // Emitted when weather data is updated
    void weatherDataReady();
    // Emitted when forecast data is updated
    void forecastReady();
    // Emitted when an error occurs
    void errorOccurred(QString message);
};

#endif
