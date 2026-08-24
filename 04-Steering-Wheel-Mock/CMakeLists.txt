cmake_minimum_required(VERSION 3.16)
project(SteeringWheelMock VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 6.5 REQUIRED COMPONENTS Core Gui Qml Quick Network)

qt_standard_project_setup()

qt_add_executable(SteeringWheelMock
    src/main.cpp
    src/UdpSender.h
    src/UdpSender.cpp
)

qt_add_qml_module(SteeringWheelMock
    URI SteeringWheel
    VERSION 1.0
    QML_FILES src/Main.qml
)

target_link_libraries(SteeringWheelMock
    PRIVATE Qt6::Core Qt6::Gui Qt6::Qml Qt6::Quick Qt6::Network
)
