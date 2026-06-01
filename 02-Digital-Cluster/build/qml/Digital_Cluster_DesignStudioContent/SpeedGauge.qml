import QtQuick
import Gauge
import Digital_Cluster_DesignStudio
import QtQuick.Studio.DesignEffects

Item {
    id: speedGaugeRoot
    x: -22
    y: 98
    width: 450
    height: 450
    scale: 0.65

    // ── PUBLIC API ────────────────────────────────────
    property real   speedValue:   digitalCluster.simSpeed
    property real   maxSpeed:     240
    property real   redlineSpeed: 210
    property real   fuelPercent:  100
    property int    speedLimit:   90

    property bool   enableSmoothing: true

    // Background gauge area
    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: "#0A0A1B"
        opacity: 0.3
    }

    // Tick marks
    GaugeTickMarks {
        anchors.fill: parent
        value:    speedGaugeRoot.speedValue
        maxValue: speedGaugeRoot.maxSpeed

        bigStep:    30.0
        mediumStep: 10.0
        smallStep:  5.0
    }

    // Redline zone (red ticks above 210)
    GaugeRedlineZone {
        anchors.fill: parent
        redlineStart: speedGaugeRoot.redlineSpeed
        maxValue:     speedGaugeRoot.maxSpeed

        bigStep:    30.0
        mediumStep: 10.0
        smallStep:  5.0
    }

    // Labels
    GaugeLabels {
        anchors.fill: parent
        value:     speedGaugeRoot.speedValue
        maxValue:  speedGaugeRoot.maxSpeed
        labelStep: 30.0
    }

    // Active arc
    GaugeActiveArc {
        anchors.fill: parent
        value:    speedGaugeRoot.speedValue
        maxValue: speedGaugeRoot.maxSpeed
        enableSmoothing: speedGaugeRoot.enableSmoothing
    }

    // Inner disc (center)
    GaugeInnerDisc {
        anchors.centerIn: parent
        width:  300
        height: 300
        discRadius: 110
        discColor: "#111111"
        borderColor: Theme.colorAccentPrimary
        borderWidth: 2
        borderOpacity: 0.05
    }

    GaugeSpeedNumber {
        anchors.centerIn: parent
        width:  300
        height: 300
        value:    speedGaugeRoot.speedValue
        maxValue: speedGaugeRoot.maxSpeed
        unitText: "KM/H"
    }

    // Speed limit badge — positioned above the speed number
    GaugeSpeedLimitBadge {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: 170   // adjust based on your layout

        speedLimit:   speedGaugeRoot.speedLimit
        currentSpeed: speedGaugeRoot.speedValue    // for violation detection
        badgeSize: 60
    }

    GaugeNeedle {
        id: needle
        anchors.fill: parent
        value:    speedGaugeRoot.speedValue
        maxValue: speedGaugeRoot.maxSpeed
        enableSmoothing: speedGaugeRoot.enableSmoothing
    }

}
