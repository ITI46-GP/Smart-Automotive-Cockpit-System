/*
This is a UI file (.ui.qml) that is intended to be edited in Qt Design Studio only.
*/
import QtQuick
import QtQuick.Controls
import Digital_Cluster_DesignStudio
import QtQuick.Studio.DesignEffects
import Digital_Cluster_DesignStudioContent.Content_Area
import QtQuick.Studio.Components 1.0
import Gauge
import BottomLayer
import QtQuick.Layouts

Rectangle {
    id: digitalCluster
    width: Constants.width
    height: Constants.height
    color: "#0a0b0b"
    clip: true

    // ── simulation state ──────────────────────────────
    property real simSpeed: 0
    property real simRpm: 0
    property real simFuel: 100
    property bool accelerating: true

    /*
     * The visible center view is now owned by the cluster backend.
     *
     * Normal:
     *   selectedView 0 -> Car
     *
     * Manual icon:
     *   clusterNavigation.selectView(index)
     *
     * Active route:
     *   effectiveView is forced to Navigation (1)
     *
     * Route end:
     *   effectiveView returns to the user's selected view.
     */
    readonly property int currentView: clusterNavigation.effectiveView

    property string simMode: {
        if (simRpm < 2) return "ECO"
        if (simRpm < 4) return "NORMAL"
        return "SPORT"
    }

    Timer {
        id: simTimer
        interval: 100
        running: false
        repeat: true
        onTriggered: {
            if (digitalCluster.accelerating) {
                digitalCluster.simSpeed = Math.min(240, digitalCluster.simSpeed + 1.5)
                digitalCluster.simRpm   = Math.min(8,   digitalCluster.simRpm   + 0.05)
                digitalCluster.simFuel  = Math.max(0,   digitalCluster.simFuel  - 1)
                if (digitalCluster.simSpeed >= 240)
                    digitalCluster.accelerating = false
            } else {
                digitalCluster.simSpeed = Math.max(0, digitalCluster.simSpeed - 2)
                digitalCluster.simRpm   = Math.max(0, digitalCluster.simRpm   - 0.07)
                if (digitalCluster.simSpeed <= 0)
                    digitalCluster.accelerating = true
            }
        }
    }

    // ── THE STARTUP CHOREOGRAPHY ──────────────────────
    SequentialAnimation {
        id: startupSequence

        // Phase 1: Pop out from the center
        ParallelAnimation {
            // Left Gauge (Speed)
            NumberAnimation { target: speedGauge; property: "scale"; from: 0.1; to: 0.7; duration: 1200; easing.type: Easing.OutBack }
            NumberAnimation { target: speedGauge; property: "x"; from: 432; to: 92; duration: 1200; easing.type: Easing.OutQuint }
            NumberAnimation { target: speedGauge; property: "opacity"; from: 0; to: 1; duration: 900 }

            // Right Gauge (RPM)
            NumberAnimation { target: rightGauge; property: "scale"; from: 0.1; to: 0.7; duration: 1200; easing.type: Easing.OutBack }
            NumberAnimation { target: rightGauge; property: "x"; from: 432; to: 772; duration: 1200; easing.type: Easing.OutQuint }
            NumberAnimation { target: rightGauge; property: "opacity"; from: 0; to: 1; duration: 900 }

            // Fade in the center content and bottom bar smoothly
            NumberAnimation { target: contentArea; property: "scale"; from: 0; to: 0.75; duration: 1200 ; easing.type: Easing.OutBack }
            NumberAnimation { target: contentArea; property: "opacity"; from: 0; to: 1; duration: 900 }

            NumberAnimation { target: topBar; property: "scale"; from: 0; to: 1; duration: 1200 ; easing.type: Easing.OutBack }
            NumberAnimation { target: topBar; property: "opacity"; from: 0; to: 1; duration: 900 }

            NumberAnimation { target: bottomBar; property: "scale"; from: 0; to: 1; duration: 1200 ; easing.type: Easing.OutBack }
            NumberAnimation { target: bottomBar; property: "opacity"; from: 0; to: 1; duration: 900 }
        }

        // Phase 2: The Needle Sweep
        SequentialAnimation {
            PropertyAction { target: speedGauge; property: "enableSmoothing"; value: false }
            PropertyAction { target: rightGauge; property: "enableSmoothing"; value: false }

            ParallelAnimation {
                // Speed Sweep (0 -> 240 -> 0)
                SequentialAnimation {
                    NumberAnimation { target: digitalCluster; property: "simSpeed"; from: 0; to: 240; duration: 1000; easing.type: Easing.InOutSine }
                    NumberAnimation { target: digitalCluster; property: "simSpeed"; from: 240; to: 0; duration: 1000; easing.type: Easing.InOutSine }
                }

                // RPM Sweep (0 -> 8 -> 0)
                SequentialAnimation {
                    NumberAnimation { target: digitalCluster; property: "simRpm"; from: 0; to: 8; duration: 1000; easing.type: Easing.InOutSine }
                    NumberAnimation { target: digitalCluster; property: "simRpm"; from: 8; to: 0; duration: 1000; easing.type: Easing.InOutSine }
                }
            }

            PropertyAction { target: speedGauge; property: "enableSmoothing"; value: true }
            PropertyAction { target: rightGauge; property: "enableSmoothing"; value: true }
        }

        // Phase 3: Hand off to the standard loop
        ScriptAction {
            script: {
                digitalCluster.accelerating = true
                simTimer.start()
            }
        }
    }

    // ── gauges ────────────────────────────────────────
    BazelFrame {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.leftMargin: 0
        anchors.rightMargin: 0
        anchors.topMargin: 0
        anchors.bottomMargin: 0
    }

    // ── center content area ───────────────────────────
    GroupItem {
        id: gaugeArea
        x: -148
        y: 75
        scale: 0.9

        Rectangle {
            id: frame
            x: 442
            y: -435
            width: 424
            height: 1320
            opacity: 1
            color: "#161616"
            radius: 212
            border.color: "#8080801a"
            border.width: 0
            rotation: -90
            scale: 0.75
        }

        Item {
            id: contentArea
            x: 420
            y: 13

            scale: 0
            opacity: 0

            width: 480
            height: 424

            CarView {
                y: -365
                visible: digitalCluster.currentView === 0
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: 0
                anchors.rightMargin: 0
                scale: 1.25
            }

            MapView {
                visible: digitalCluster.currentView === 1
                anchors.fill: parent
            }

            ContactsView {
                visible: digitalCluster.currentView === 2
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.leftMargin: 0
                anchors.rightMargin: 0
                anchors.topMargin: 0
                anchors.bottomMargin: 0
            }

            MusicView {
                visible: digitalCluster.currentView === 3
                anchors.fill: parent
            }

            FuelView {
                anchors.fill: parent
                visible: digitalCluster.currentView === 4
                fuelPercent: digitalCluster.simFuel
            }

            SettingsView {
                anchors.fill: parent
                visible: digitalCluster.currentView === 5
            }
        }

        SpeedGauge {
            id: speedGauge
            y: 0

            // for startupAnimation
            x: 432
            scale: 0.1
            opacity: 0
        }

        RPMGauge {
            id: rightGauge
            y: 0
            rpmValue: digitalCluster.simRpm.toFixed(1)
            driveMode: digitalCluster.simMode

            // for startupAnimation
            x: 432
            scale: 0.1
            opacity: 0
        }
    }

    TopBar {
        id: topBar
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 90
        anchors.horizontalCenterOffset: 0

        /*
         * Highlight the view that is actually visible.
         *
         * During active navigation this stays Navigation even if another
         * selection is remembered in the backend.
         */
        currentView: digitalCluster.currentView

        /*
         * Manual icon selection now goes through the same backend state
         * machine used by Android navigation and future NOVA commands.
         */
        onViewSelected: function(index) {
            clusterNavigation.selectView(index)
        }

        // for startupAnimation
        scale: 0
        opacity: 0
    }

    // ── bottom info bar ───────────────────────────────
    BottomLayer {
        id: bottomBar
        y: 470
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: 0
        anchors.rightMargin: 0
        anchors.bottomMargin: 60

        // for startupAnimation
        scale: 0
        opacity: 0

        height: 70

        fuelPercent: digitalCluster.simFuel
        rangeKm:     Math.round(digitalCluster.simFuel * 5.2)
        motorTempC:  90
        maxTempC:    120
        outsideTempText: "14 °C"
        odometerText:    "33560.5 km"
        clockText:       "10:32 PM"
    }

    // ── SPLASH SCREEN (Sits directly on top of everything) ──
    SplashScreen {
        id: splashSequence
        anchors.fill: parent
        z: 999

        onStartupComplete: {
            startupSequence.start()
        }
    }

    RowLayout {
        id: rowLayout
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 50

        Image {
            id: laneKeepingAssist
            Layout.preferredHeight: 36
            Layout.preferredWidth: 36
            Layout.alignment: Qt.AlignVCenter
            source: "assets/features_Icons/lane-keeping-assist.png"
            fillMode: Image.PreserveAspectFit
        }

        Image {
            id: tractionControl
            Layout.preferredHeight: 36
            Layout.preferredWidth: 36
            Layout.alignment: Qt.AlignVCenter
            source: "assets/features_Icons/traction-control.png"
            fillMode: Image.PreserveAspectFit
        }
    }
}
