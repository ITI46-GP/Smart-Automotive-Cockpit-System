#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QtGlobal>

#include "backend/AssistantManager.h"
#include "backend/LightsController.h"
#include "backend/NavigationManager.h"
#include "backend/ProfileManager.h"
#include "backend/SettingsManager.h"
#include "src/climate/hvaccontroller.h"
#include "src/weather/WeatherAPI.h"
#include "src/audio/audioplayer.h"
#ifdef GP_IVI_USE_QT_MULTIMEDIA_AUDIO
#include "src/audio/audioplayer.h"
#else
#include "src/audio/AudioCompatManager.h"
#endif

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    QCoreApplication::setOrganizationName("GP");
    QCoreApplication::setApplicationName("GP_IVI");

    ProfileManager profileManager;
    SettingsManager settingsManager;
    LightsController lightsController;
    NavigationManager navigationManager;
    AssistantManager assistantManager(&profileManager, &navigationManager, &lightsController);
    WeatherAPI weatherApi;
    HvacController hvacBackend;
#ifdef GP_IVI_USE_QT_MULTIMEDIA_AUDIO
    AudioPlayer audioManager;
#else
    AudioCompatManager audioManager;
#endif

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("profileManager", &profileManager);
    engine.rootContext()->setContextProperty("settingsManager", &settingsManager);
    engine.rootContext()->setContextProperty("lightsController", &lightsController);
    engine.rootContext()->setContextProperty("navigationManager", &navigationManager);
    engine.rootContext()->setContextProperty("assistantManager", &assistantManager);
    engine.rootContext()->setContextProperty("weatherApi", &weatherApi);
    engine.rootContext()->setContextProperty("HvacBackend", &hvacBackend);
    engine.rootContext()->setContextProperty("audioManager", &audioManager);

    QObject::connect(&settingsManager, &SettingsManager::darkModeChanged, &profileManager, [&]() {
        profileManager.setActiveDarkMode(settingsManager.darkMode());
    });
    QObject::connect(&lightsController, &LightsController::ambientLevelChanged, &profileManager, [&]() {
        profileManager.setActiveAmbientLevel(lightsController.ambientLevel());
    });
    QObject::connect(&navigationManager, &NavigationManager::destinationChanged, &profileManager, [&]() {
        if (navigationManager.routeActive()) {
            profileManager.setActiveLastDestination(navigationManager.destination());
        }
    });
    QObject::connect(&assistantManager, &AssistantManager::voiceEnabledChanged, &profileManager, [&]() {
        profileManager.setActiveVoiceEnabled(assistantManager.voiceEnabled());
    });
    QObject::connect(&profileManager, &ProfileManager::activeDarkModeChanged, &settingsManager, [&]() {
        settingsManager.setDarkMode(profileManager.activeDarkMode());
    });
    QObject::connect(&profileManager, &ProfileManager::activeAmbientLevelChanged, &lightsController, [&]() {
        lightsController.setAmbientLevel(profileManager.activeAmbientLevel());
    });
    QObject::connect(&profileManager, &ProfileManager::activeVoiceEnabledChanged, &assistantManager, [&]() {
        assistantManager.setVoiceEnabled(profileManager.activeVoiceEnabled());
    });
    QObject::connect(&profileManager, &ProfileManager::activeLastDestinationChanged, &navigationManager, [&]() {
        const QString destination = profileManager.activeLastDestination().trimmed();
        if (!destination.isEmpty()) {
            navigationManager.setRouteDestination(destination);
        }
    });
    QObject::connect(&profileManager, &ProfileManager::activeDriverTempChanged, &hvacBackend, [&]() {
        hvacBackend.setDriverTemp(profileManager.activeDriverTemp()); 
    });

    QObject::connect(&profileManager, &ProfileManager::activePassengerTempChanged, &hvacBackend, [&]() {
        hvacBackend.setPassengerTemp(profileManager.activePassengerTemp());
    });

    QObject::connect(&audioManager, &AudioPlayer::songTitleChanged, &profileManager, [&]() {
        profileManager.setActiveMediaPreset(audioManager.currentSongTitle());
    });
    

    settingsManager.setDarkMode(profileManager.activeDarkMode());
    lightsController.setAmbientLevel(profileManager.activeAmbientLevel());
    assistantManager.setVoiceEnabled(profileManager.activeVoiceEnabled());
    if (!profileManager.activeLastDestination().trimmed().isEmpty()) {
        navigationManager.setRouteDestination(profileManager.activeLastDestination());
    }

    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.loadFromModule("GP_IVI", "Main");

    return app.exec();
}
