find_package(Threads REQUIRED)

target_sources(${CMAKE_PROJECT_NAME} PRIVATE
    "main.cpp"

    "${CMAKE_CURRENT_SOURCE_DIR}/../NavigationBackend/HnclProtocol.cpp"
    "${CMAKE_CURRENT_SOURCE_DIR}/../NavigationBackend/HnclProtocol.hpp"

    "${CMAKE_CURRENT_SOURCE_DIR}/../NavigationBackend/HnclNavigationServer.cpp"
    "${CMAKE_CURRENT_SOURCE_DIR}/../NavigationBackend/HnclNavigationServer.hpp"

    "${CMAKE_CURRENT_SOURCE_DIR}/../NavigationBackend/ClusterPresentationState.cpp"
    "${CMAKE_CURRENT_SOURCE_DIR}/../NavigationBackend/ClusterPresentationState.hpp"

    "${CMAKE_CURRENT_SOURCE_DIR}/../NavigationBackend/ClusterNavigationModel.cpp"
    "${CMAKE_CURRENT_SOURCE_DIR}/../NavigationBackend/ClusterNavigationModel.hpp"
)

target_include_directories(${CMAKE_PROJECT_NAME} PRIVATE
    "${CMAKE_CURRENT_SOURCE_DIR}/../NavigationBackend"
)

target_link_libraries(${CMAKE_PROJECT_NAME} PRIVATE
    Qt${QT_VERSION_MAJOR}::Core
    Qt${QT_VERSION_MAJOR}::Gui
    Qt${QT_VERSION_MAJOR}::Widgets
    Qt${QT_VERSION_MAJOR}::Quick
    Qt${QT_VERSION_MAJOR}::Qml
    Threads::Threads
)
