import QtQuick
import QtQuick.Layouts
import Digital_Cluster_DesignStudio

/*
 * ╔═══════════════════════════════════════════════════════════════╗
 * ║  BOTTOM LAYER — main composer                                 ║
 * ║                                                               ║
 * ║  Horizontal layout:                                           ║
 * ║    [ FUEL ]    [ INFO BLOCKS ]    [ TEMP ]                    ║
 * ║                                                               ║
 * ║  Each section is independently sized and styled.              ║
 * ╚═══════════════════════════════════════════════════════════════╝
 */
Item {
    id: bottomRoot

    // ── PUBLIC API (passed to children) ──────────────
    // Fuel
    property real fuelPercent: 100
    property int  rangeKm:     520
    property url  fuelIconSource: "../Digital_Cluster_DesignStudioContent/assets/fuel_icon_unselected.png"

    // Temperature
    property real motorTempC:  90
    property real maxTempC:    120
    property url  tempIconSource: "../Digital_Cluster_DesignStudioContent/assets/engineTemp.png"

    // Center info
    property string outsideTempText: "14 °C"
    property string odometerText:    "33560.5 km"
    property string clockText:       "10:32 PM"

    // ── LAYOUT ──────────────────────────────────────
    implicitHeight: 70

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin:  100
        anchors.rightMargin: 100
        spacing: 0

        // Left: fuel
        FuelIndicator {
            Layout.preferredWidth: 220
            Layout.alignment: Qt.AlignVCenter
            fuelPercent: bottomRoot.fuelPercent
            rangeKm:     bottomRoot.rangeKm
            iconSource:  bottomRoot.fuelIconSource
        }

        // Spacer (pushes center to middle)
        Item { Layout.fillWidth: true }

        // Center: info blocks
        CenterInfo {
            Layout.alignment: Qt.AlignVCenter
            tempText:  bottomRoot.outsideTempText
            totalText: bottomRoot.odometerText
            timeText:  bottomRoot.clockText
        }

        // Spacer
        Item { Layout.fillWidth: true }

        // Right: motor temp
        TempIndicator {
            Layout.preferredWidth: 220
            Layout.alignment: Qt.AlignVCenter
            motorTempC: bottomRoot.motorTempC
            maxTempC:   bottomRoot.maxTempC
            iconSource: bottomRoot.tempIconSource
        }
    }
}
