import QtQuick
import "../components"

Item {
    id: dashboardRoot
    width: 1024
    height: 600

    signal profileRequested()
    signal lightsRequested()
    signal settingsRequested()
    signal mapRequested()
    signal assistantRequested()
    signal mediaRequested()
    signal weatherRequested()
    signal climateRequested()

    readonly property real margin: Math.max(14, Math.min(18, width * 0.016))
    readonly property real gap: Math.max(12, Math.min(16, width * 0.014))
    readonly property real topBarHeight: Math.max(38, Math.min(42, height * 0.067))
    readonly property real bottomBarHeight: Math.max(66, Math.min(74, height * 0.116))
    readonly property real contentTop: topBarHeight + margin
    readonly property real contentBottom: height - margin - bottomBarHeight - gap
    readonly property real contentHeight: contentBottom - contentTop
    readonly property real sideWidth: Math.max(230, Math.min(248, width * 0.232))
    readonly property real centerWidth: Math.max(360, Math.min(390, width * 0.373))
    readonly property real rightWidth: Math.max(250, Math.min(280, width * 0.269))
    readonly property real contentGroupWidth: sideWidth + centerWidth + rightWidth + gap * 2
    readonly property real contentLeft: Math.max(margin, (width - contentGroupWidth) / 2)

    Rectangle {
        anchors.fill: parent
        color: "#07000E"
    }

    Rectangle {
        anchors.fill: parent
        opacity: 0.55

        gradient: Gradient {
            GradientStop { position: 0.0; color: "#1C162B" }
            GradientStop { position: 0.45; color: "#0A0A1B" }
            GradientStop { position: 1.0; color: "#07000E" }
        }
    }
    TopStatusBar {
        id: topStatusBar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: dashboardRoot.topBarHeight
        cabinMode: settingsManager.privacyMode ? "PRIVATE" : "EASY ENTRY"
        network: settingsManager.wifiOn ? "Wi-Fi" : "LTE"
    }

    SideMenu {
        id: sideMenu
        x: dashboardRoot.contentLeft
        y: dashboardRoot.contentTop
        width: dashboardRoot.sideWidth
        height: dashboardRoot.contentHeight
        profileName: profileManager.activeProfileName

        profileSummary: profileManager.activeDriveMode + " · " + profileManager.activeSeatPreset + " · " + HvacBackend.driverTemp + "°"        
        
        assistantSummary: !assistantManager.voiceEnabled
                          ? "Voice off · chat available"
                          : (assistantManager.listening ? "Listening now · assistant online" : "Voice ready · assistant online")
        lightsSubtitle: (lightsController.headlightsOn ? "Headlights on" : "Headlights off") + " · ambient " + lightsController.ambientLevel + "%"
        settingsSubtitle: settingsManager.darkMode ? "Dark mode · system" : "Light mode · system"

        onProfileClicked: dashboardRoot.profileRequested()
        onAssistantClicked: dashboardRoot.assistantRequested()
        onLightsClicked: dashboardRoot.lightsRequested()
        onClimateClicked: dashboardRoot.climateRequested()
        onSettingsClicked: dashboardRoot.settingsRequested()
    }

    VehicleOverviewCard {
        id: vehicleCard
        x: sideMenu.x + sideMenu.width + dashboardRoot.gap
        y: dashboardRoot.contentTop
        width: dashboardRoot.centerWidth
        height: dashboardRoot.contentHeight
        driveMode: profileManager.activeDriveMode
        lightState: lightsController.autoLightsOn ? "Auto" : (lightsController.headlightsOn ? "On" : "Off")
        systemState: profileManager.activeSeatPreset

    }

    RightPanel {
        id: rightPanel
        x: vehicleCard.x + vehicleCard.width + dashboardRoot.gap
        y: dashboardRoot.contentTop
        width: dashboardRoot.rightWidth
        height: dashboardRoot.contentHeight
        routeActive: navigationManager.routeActive
        routeLoading: navigationManager.routeLoading
        routeError: navigationManager.routeError
        currentLocationValid: navigationManager.currentLocationValid
        destination: navigationManager.destination
        etaText: navigationManager.routeActive ? navigationManager.etaMinutes + " min" : "--"
        distanceText: navigationManager.routeActive ? navigationManager.distanceKm.toFixed(1) + " km" : "--"
        routePath: navigationManager.routePath
        songTitle: profileManager.activeMediaPreset
        songArtist: profileManager.activeMediaSource
        songAlbum: profileManager.activeDriveMode

        onMediaClicked: dashboardRoot.mediaRequested()
        onMapClicked: dashboardRoot.mapRequested()
    }

    BottomNavBar {
        id: bottomNav
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: dashboardRoot.margin
        anchors.rightMargin: dashboardRoot.margin
        anchors.bottomMargin: dashboardRoot.margin
        height: dashboardRoot.bottomBarHeight
        driverTemp: HvacBackend.driverTemp
        passengerTemp: HvacBackend.passengerTemp
        volume: profileManager.activeVolume

        onSettingsClicked: dashboardRoot.settingsRequested()
        onHomeClicked: console.log("Home clicked")
        onClimateClicked: dashboardRoot.climateRequested()
        onMediaClicked: dashboardRoot.mediaRequested()
        onWeatherClicked: dashboardRoot.weatherRequested()
        onAppsClicked: console.log("Apps clicked")
        onAssistantClicked: dashboardRoot.assistantRequested()

        onDriverTempUp: HvacBackend.setDriverTemp(HvacBackend.driverTemp + 1)
        onDriverTempDown: HvacBackend.setDriverTemp(HvacBackend.driverTemp - 1)
        onPassengerTempUp: HvacBackend.setPassengerTemp(HvacBackend.passengerTemp + 1)
        onPassengerTempDown: HvacBackend.setPassengerTemp(HvacBackend.passengerTemp - 1)
        onVolumeUp: profileManager.setActiveVolume(profileManager.activeVolume + 5)
        onVolumeDown: profileManager.setActiveVolume(profileManager.activeVolume - 5)
    }

}
