import QtQuick
import Gauge
import Digital_Cluster_DesignStudio
import QtQuick.Studio.DesignEffects
import Backend 1.0

/*
 * RPM GAUGE COMPOSER
 *
 *   - Range 0–8 (×1000)
 *   - Redline starts at 6 (last 2000 RPM)
 *   - Big tick every 1, medium every 0.5, small every 0.1
 *   - Decimal RPM display (e.g., "3.5")
 *   - Drive mode badge below disc
 */
Item {
    id: rpmGaugeRoot

    width: 450
    height: 450
    scale: 0.65

    // ── PUBLIC API ────────────────────────────────────
    property real   rpmValue:    0       // 0–8 (×1000)
    property real   maxRpm:      8
    property real   redline:     6       // redline starts here
    property string driveMode:   "NORMAL"
    property string currentGear: VehicleData.gearProvider.gearValue
    property bool   enableSmoothing: true

    property int needleAnimationDuration: 500


    // Background gauge area
    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: "#0A0A1B"
        opacity: 0.3
    }

    // Tick marks (normal — covers ENTIRE range including redline area)
    GaugeTickMarks {
        anchors.fill: parent
        value:    rpmGaugeRoot.rpmValue
        maxValue: rpmGaugeRoot.maxRpm

        // RPM-specific steps (use real values!)
        bigStep:    1.0     // big tick + label every 1000 RPM
        mediumStep: 0.5     // medium every 500 RPM
        smallStep:  0.1     // small every 100 RPM
    }

    // Redline zone (red ticks 6 → 8) — OVERLAYS tick marks above
    GaugeRedlineZone {
        anchors.fill: parent
        redlineStart: rpmGaugeRoot.redline
        maxValue:     rpmGaugeRoot.maxRpm

        bigStep:    1.0
        mediumStep: 0.5
        smallStep:  0.1
    }

    // Number labels (0, 1, 2, 3, 4, 5, 6, 7, 8)
    GaugeLabels {
        anchors.fill: parent
        value:     rpmGaugeRoot.rpmValue
        maxValue:  rpmGaugeRoot.maxRpm
        labelStep: 1.0
    }

    // Active arc (no redline color shift — using halo opacity from earlier)
    GaugeActiveArc {
        anchors.fill: parent
        value:    rpmGaugeRoot.rpmValue
        maxValue: rpmGaugeRoot.maxRpm
        animationDuration: rpmGaugeRoot.needleAnimationDuration
        haloMidThreshold: 0.75
        enableSmoothing: rpmGaugeRoot.enableSmoothing

    }

    // Inner disc
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

    // RPM number — using decimal format
    GaugeSpeedNumber {
        anchors.centerIn: parent
        width:  300
        height: 300
        value:    rpmGaugeRoot.rpmValue
        maxValue: rpmGaugeRoot.maxRpm

        displayValue: rpmGaugeRoot.rpmValue.toFixed(1)
        unitText: "RPM ×1000"

        warnThreshold:   0.75   // amber at 6.0
        dangerThreshold: 0.90   // red at 7.2
    }

    // Gear badge (P/R/N/D) — above the RPM number
    GaugeGearBadge {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -80

        currentGear: rpmGaugeRoot.currentGear
    }

    // Mode badge — at the bottom outside disc
    GaugeModeBadge {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: 170

        mode: rpmGaugeRoot.driveMode
    }

    // Needle
    GaugeNeedle {
        id: needle
        anchors.fill: parent
        value:    rpmGaugeRoot.rpmValue
        maxValue: rpmGaugeRoot.maxRpm
        animationDuration: rpmGaugeRoot.needleAnimationDuration
        enableSmoothing: rpmGaugeRoot.enableSmoothing
    }
}
