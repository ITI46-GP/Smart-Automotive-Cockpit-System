cmake_minimum_required(VERSION 3.21)

project(QnxClusterApp LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_INCLUDE_CURRENT_DIR ON)

if(NOT CMAKE_BUILD_TYPE)
    set(CMAKE_BUILD_TYPE Release)
endif()

find_package(Qt6 6.8 REQUIRED COMPONENTS Core Gui Qml Quick Network)

qt_standard_project_setup(REQUIRES 6.8)

qt_add_executable(QnxClusterApp
    src/main.cpp
    resources.qrc
)

qt_add_qml_module(QnxClusterApp
    URI QnxCluster
    VERSION 1.0
    QML_FILES
    qml/Main.qml
    qml/ContentArea/BazelFrame.qml
    qml/ContentArea/TopBar.qml
    qml/ContentArea/TopBarButton.qml
    qml/ContentArea/Car.qml
    qml/ContentArea/Road.qml
    qml/ContentArea/SplashScreen.qml
    qml/Gauge/GaugeActiveArc.qml
    qml/Gauge/GaugeSpeedNumber.qml
    qml/Gauge/GaugeLabels.qml
    qml/Gauge/GaugeTickMarks.qml
    qml/Gauge/GaugeTickMarksShape.qml
    qml/Gauge/GaugeRedlineZone.qml
    qml/Gauge/GaugeGearBadge.qml
    qml/Gauge/GaugeModeBadge.qml
    qml/Gauge/GaugeSpeedLimitBadge.qml
    qml/BottomLayer/BottomLayer.qml
    qml/BottomLayer/CenterInfo.qml
    qml/BottomLayer/InfoBlock.qml
    qml/BottomLayer/FuelIndicator.qml
    qml/BottomLayer/TempIndicator.qml
    qml/BottomLayer/SegmentedGauge.qml
    qml/ContentArea/MapView.qml
    qml/ContentArea/ContactsView.qml
    qml/ContentArea/ContactItem.qml
    qml/ContentArea/MusicView.qml
    qml/ContentArea/FuelView.qml
    qml/ContentArea/FuelStatItem.qml
    qml/ContentArea/SettingsView.qml
    qml/ContentArea/SettingItem.qml
    SOURCES
    src/Theme.h
    src/Backend/SpeedProvider.h
    src/Backend/SpeedProvider.cpp
    src/Backend/RpmProvider.h
    src/Backend/RpmProvider.cpp
    src/Backend/GearProvider.h
    src/Backend/GearProvider.cpp
    src/Backend/VehicleDataProvider.h
    src/Backend/VehicleDataProvider.cpp
    src/Backend/SteeringWheelController.h
    src/Backend/SteeringWheelController.cpp
    src/Backend/BottomBar/FuelProvider.h
    src/Backend/BottomBar/FuelProvider.cpp
    src/Backend/BottomBar/EngineTempProvider.h
    src/Backend/BottomBar/EngineTempProvider.cpp
    src/Backend/BottomBar/EnvTempProvider.h
    src/Backend/BottomBar/EnvTempProvider.cpp
    src/Backend/BottomBar/TotalKmsProvider.h
    src/Backend/BottomBar/TotalKmsProvider.cpp
    src/Backend/BottomBar/TimeProvider.h
    src/Backend/BottomBar/TimeProvider.cpp
    src/Backend/BottomBar/BottomBarDataProvider.h
    src/Backend/BottomBar/BottomBarDataProvider.cpp
    src/Backend/ContentArea/ContactsModel.h
    src/Backend/ContentArea/ContactsModel.cpp
    src/Backend/ContentArea/MusicController.h
    src/Backend/ContentArea/MusicController.cpp
)

# The generated qmltyperegistrations.cpp does `#include <Theme.h>` (bare
# filename via angle brackets, resolved through the compiler's include
# search path — not a relative path). qt_add_qml_module's SOURCES entries
# don't automatically add their own directory to the target's include
# path the way normal sources under CMAKE_INCLUDE_CURRENT_DIR do, so
# without this, that #include silently fails to find src/Theme.h and
# every type it declares (Theme) is "not declared in this scope" in that
# one generated file, even though Theme.h itself compiles fine everywhere
# else and moc/qmltyperegistrar both correctly found and processed it.
# Same trap applies to VehicleDataProvider.h (the other QML_SINGLETON,
# see its header comment) — it lives one directory deeper, so `src` alone
# doesn't cover it; `src/Backend` is added for the same reason.
target_include_directories(QnxClusterApp PRIVATE src src/Backend)

target_link_libraries(QnxClusterApp PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
    Qt6::Network
)

include(GNUInstallDirs)
install(TARGETS QnxClusterApp
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
