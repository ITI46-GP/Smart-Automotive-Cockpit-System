cmake_minimum_required(VERSION 3.16)

project(GP_IVI VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Quick Multimedia QuickEffects Bluetooth DBus QuickControls2)
qt_standard_project_setup(REQUIRES 6.8)

qt_add_executable(appGP_IVI
    main.cpp
)

target_include_directories(appGP_IVI PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/src/audio
    ${CMAKE_CURRENT_SOURCE_DIR}/src/weather
    ${CMAKE_CURRENT_SOURCE_DIR}/src/climate
    ${CMAKE_CURRENT_SOURCE_DIR}/backend
)

if(TARGET Qt6::Multimedia AND TARGET Qt6::DBus)
    set(AUDIO_SOURCES
        src/audio/audioplayer.cpp
        src/audio/audioplayer.h
        src/audio/audiosourcebase.cpp
        src/audio/audiosourcebase.h
        src/audio/radioplayer.cpp
        src/audio/radioplayer.h
        src/audio/usbplayer.cpp
        src/audio/usbplayer.h
        src/audio/btplayer.cpp
        src/audio/btplayer.h
        src/audio/bluetoothmanager.cpp
        src/audio/bluetoothmanager.h
    )
    target_compile_definitions(appGP_IVI PRIVATE GP_IVI_USE_QT_MULTIMEDIA_AUDIO)
else()
    set(AUDIO_SOURCES
        src/audio/AudioCompatManager.cpp
        src/audio/AudioCompatManager.h
    )
    message(STATUS "Qt Multimedia/DBus audio stack is unavailable in this kit; using AudioCompatManager.")
endif()

qt_add_qml_module(appGP_IVI
    URI GP_IVI
    QML_FILES
        Main.qml
        SplashScreen.qml
        pages/DashboardPage.qml
        pages/ProfilePage.qml
        pages/LightsPage.qml
        pages/SettingsPage.qml
        pages/MapPage.qml
        pages/AssistantPage.qml
        pages/MediaPage.qml
        pages/WeatherPage.qml
        pages/ClimatePage.qml

        components/TopStatusBar.qml
        components/SideMenu.qml
        components/VehicleOverviewCard.qml
        components/RightPanel.qml
        components/BottomNavBar.qml
        components/OnScreenKeyboard.qml
        components/BluetoothSheet.qml
        components/RadioView.qml
        components/UsbView.qml

    RESOURCES
        assets/images/iti_logo.png
        assets/images/tesla.png
        assets/images/iti.png
        assets/images/car_climate.png
        assets/icons/2285924901582793664-128.png
        assets/icons/car_home.svg
        assets/icons/ai_assistant.svg
        assets/icons/climate_fan.svg
        assets/icons/settings_gear.svg
        assets/icons/weather.png
        assets/icons/light.png
        assets/icons/Bluetooth.png
        assets/icons/radio.png
        assets/icons/usb.png
        assets/icons/prev.png
        assets/icons/pause.png
        assets/icons/play.png
        assets/icons/next.png
        assets/icons/mute.png
        assets/icons/volume.png
        assets/icons/vent.png
        assets/icons/vent_blow.png
        assets/icons/windscreen-air.png

    SOURCES
        ${AUDIO_SOURCES}
        src/weather/WeatherAPI.h         
        src/weather/WeatherAPI.cpp
        src/climate/hvaccontroller.h             
        src/climate/hvaccontroller.cpp
        backend/AssistantManager.cpp
        backend/AssistantManager.h
        backend/LightsController.cpp
        backend/LightsController.h
        backend/NavigationManager.cpp
        backend/NavigationManager.h
        backend/ProfileManager.cpp
        backend/ProfileManager.h
        backend/SettingsManager.cpp
        backend/SettingsManager.h
)

set_target_properties(appGP_IVI PROPERTIES
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(appGP_IVI
    PRIVATE
        Qt6::Core
        Qt6::Quick
        Qt6::Network
        Qt6::Bluetooth
)

if(TARGET Qt6::QuickControls2)
    target_link_libraries(appGP_IVI PRIVATE Qt6::QuickControls2)
endif()

if(TARGET Qt6::QuickEffects)
    target_link_libraries(appGP_IVI PRIVATE Qt6::QuickEffects)
endif()

if(TARGET Qt6::Multimedia AND TARGET Qt6::DBus)
    target_link_libraries(appGP_IVI PRIVATE
        Qt6::Multimedia
        Qt6::DBus
    )
endif()

if(TARGET Qt6::Positioning)
    target_link_libraries(appGP_IVI PRIVATE Qt6::Positioning)
else()
    message(WARNING "QtPositioning is not installed in this Qt kit; MapPage will show GPS FALLBACK until a location is provided.")
endif()

if(TARGET Qt6::Location)
    target_link_libraries(appGP_IVI PRIVATE Qt6::Location)
else()
    message(WARNING "QtLocation is not installed in this Qt kit; MapPage will use its clean QML fallback surface.")
endif()

include(GNUInstallDirs)
install(TARGETS appGP_IVI
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)