import QtQuick
import QtQuick.Layouts
import QnxCluster

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
    // Absolute qrc paths via resources.qrc, never a relative "../assets/..."
    // reference — from inside a compiled QML module that resolved to the wrong
    // directory in S1 and produced a silent-until-runtime "Cannot open".
    property url  fuelIconSource: "qrc:/icons/fuel_icon_unselected.png"

    // Temperature
    property real motorTempC:  90
    property url  tempIconSource: "qrc:/icons/engineTemp.png"

    // Center info
    property string outsideTempText: "14 °C"
    property string odometerText:    "33560.5 km"
    property string clockText:       "10:32 PM"

    // ── S7 isolation switches ───────────────────────
    // S7 measured the whole bar at 7 ms of render thread. These split that
    // between its two candidate costs — the 60 segmented-bar Rectangles and
    // the ~14 Text items — so the fix targets whichever actually pays.
    // Both default true; they are diagnostics, not features.
    property bool showBars:   true
    property bool showCenter: true
    property bool flatBars:   false
    // S9 (2026-08-12): render regression traced past Road to an unclosed S7/
    // S7.5 gap. PLAN.md flagged "batches track font size, not item count" as
    // an untested hypothesis for the bottom bar's cost -- this flag tests it.
    property bool flatFontSize: false

    // ── LAYOUT ──────────────────────────────────────
    implicitHeight: 70

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin:  100
        anchors.rightMargin: 100
        spacing: 0

        // Left: fuel
        FuelIndicator {
            showBar: bottomRoot.showBars
            flatBar: bottomRoot.flatBars
            flatFontSize: bottomRoot.flatFontSize
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
            visible: bottomRoot.showCenter
            Layout.alignment: Qt.AlignVCenter
            tempText:  bottomRoot.outsideTempText
            totalText: bottomRoot.odometerText
            timeText:  bottomRoot.clockText
            flatFontSize: bottomRoot.flatFontSize
        }

        // Spacer
        Item { Layout.fillWidth: true }

        // Right: motor temp
        TempIndicator {
            showBar: bottomRoot.showBars
            flatBar: bottomRoot.flatBars
            flatFontSize: bottomRoot.flatFontSize
            Layout.preferredWidth: 220
            Layout.alignment: Qt.AlignVCenter
            motorTempC: bottomRoot.motorTempC
            iconSource: bottomRoot.tempIconSource
        }
    }
}
