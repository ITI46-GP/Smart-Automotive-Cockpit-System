// Ported from 02-Digital-Cluster/Gauge/GaugeGearBadge.qml. P/R/N/D row with
// the current gear highlighted (R in red when active). Pure Text, no
// Canvas/DesignEffect/assets — ports directly.
import QtQuick
import QnxCluster

Item {
    id: gearRoot

    property string currentGear: "P"
    property real letterSpacing: 12

    property string fontFamily: Theme.fontPrimary
    property int    fontSize:   22
    property int    fontWeight: Theme.fontWeightBold

    property color colorActive:  Theme.colorTextPrimary
    property color colorPassive: Theme.colorTextMuted
    property color colorReverse: Theme.colorDanger

    property var gears: ["P", "R", "N", "D"]

    implicitWidth:  gearRow.implicitWidth
    implicitHeight: gearRow.implicitHeight

    Row {
        id: gearRow
        anchors.centerIn: parent
        spacing: gearRoot.letterSpacing

        Repeater {
            model: gearRoot.gears

            delegate: Text {
                property bool isActive: modelData === gearRoot.currentGear

                text: modelData

                color: {
                    if (isActive && modelData === "R") return gearRoot.colorReverse
                    if (isActive) return gearRoot.colorActive
                    return gearRoot.colorPassive
                }
                Behavior on color {
                    ColorAnimation { duration: Theme.durationNormal }
                }

                font.family:    gearRoot.fontFamily
                font.pixelSize: isActive ? gearRoot.fontSize + 4 : gearRoot.fontSize
                font.weight:    isActive ? Theme.fontWeightBold : Theme.fontWeightMedium

                Behavior on font.pixelSize {
                    NumberAnimation { duration: Theme.durationFast }
                }
            }
        }
    }
}
