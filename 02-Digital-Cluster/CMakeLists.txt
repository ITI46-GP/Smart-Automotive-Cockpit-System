cmake_minimum_required(VERSION 3.21.1)

option(LINK_INSIGHT "Link Qt Insight Tracker library" ON)
option(BUILD_QDS_COMPONENTS "Build design studio components" ON)

project(Digital_Cluster_DesignStudioApp LANGUAGES CXX)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}" "${CMAKE_CURRENT_SOURCE_DIR}/cmake")

set(CMAKE_AUTOMOC ON)
set(CMAKE_INCLUDE_CURRENT_DIR ON)
set(QT_QML_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/qml)
set(QML_IMPORT_PATH ${QT_QML_OUTPUT_DIRECTORY}
    CACHE STRING "Import paths for Qt Creator's code model"
    FORCE
)

find_package(Qt6 6.8 REQUIRED COMPONENTS Core Gui Widgets Qml Quick Network)
qt_standard_project_setup()


qt_add_executable(${CMAKE_PROJECT_NAME}
    App/main.cpp
    Backend/Speedprovider.h Backend/Speedprovider.cpp
    Backend/Rpmprovider.h Backend/Rpmprovider.cpp
    Backend/GearProvider.h Backend/GearProvider.cpp
    Backend/vehicledataprovider.h Backend/vehicledataprovider.cpp
    Backend/BottomBar/FuelProvider.h Backend/BottomBar/FuelProvider.cpp
    Backend/BottomBar/EngineTempProvider.h Backend/BottomBar/EngineTempProvider.cpp
    Backend/BottomBar/EnvTempProvider.h Backend/BottomBar/EnvTempProvider.cpp
    Backend/BottomBar/TotalKmsProvider.h Backend/BottomBar/TotalKmsProvider.cpp
    Backend/BottomBar/TimeProvider.h Backend/BottomBar/TimeProvider.cpp
    Backend/BottomBar/BottomBarDataProvider.h Backend/BottomBar/BottomBarDataProvider.cpp
    Backend/ContentArea/ContactsModel.h Backend/ContentArea/ContactsModel.cpp
    Backend/ContentArea/MusicController.h Backend/ContentArea/MusicController.cpp
    Backend/SteeringWheelController.h Backend/SteeringWheelController.cpp)
qt_add_resources(${CMAKE_PROJECT_NAME} "configuration"
    PREFIX "/"
    FILES
        qtquickcontrols2.conf)

include(qds)

if (BUILD_QDS_COMPONENTS)
    include(qmlcomponents OPTIONAL)
endif()

if (LINK_INSIGHT)
    include(insight OPTIONAL)
endif ()

include(GNUInstallDirs)
install(TARGETS ${CMAKE_PROJECT_NAME}
  BUNDLE DESTINATION .
  LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
  RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

target_link_libraries(${CMAKE_PROJECT_NAME} PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Widgets
    Qt6::Qml
    Qt6::Quick
    Qt6::Network
)
