import QtQuick
import Digital_Cluster_DesignStudio

/*
 * ╔═══════════════════════════════════════════════════════════════╗
 * ║  GAUGE GEAR BADGE (P / R / N / D selector)                    ║
 * ║                                                               ║
 * ║  Displays all gear positions in a row, with the currently     ║
 * ║  selected gear highlighted (bright color) and others dim.     ║
 * ║                                                               ║
 * ║  Standard automatic transmission positions:                   ║
 * ║    P = Park                                                   ║
 * ║    R = Reverse (red highlight when selected)                  ║
 * ║    N = Neutral                                                ║
 * ║    D = Drive                                                  ║
 * ║                                                               ║
 * ╚═══════════════════════════════════════════════════════════════╝
 */
Item {
    id: gearRoot

    // ════════════════════════════════════════════════════
    //  PUBLIC API
    // ════════════════════════════════════════════════════

    // Current gear (P, R, N, or D)
    property string currentGear: "P"

    // Spacing between letters
    property real letterSpacing: 12

    // Typography
    property string fontFamily: Theme.fontPrimary
    property int    fontSize:   22
    property int    fontWeight: Theme.fontWeightBold

    // Colors
    property color colorActive:   Theme.colorTextPrimary    // selected gear
    property color colorPassive:  Theme.colorTextMuted      // other gears
    property color colorReverse:  Theme.colorDanger         // R when active (special)

    // List of available gears (in display order)
    property var gears: ["P", "R", "N", "D"]


    // ════════════════════════════════════════════════════
    //  AUTO-SIZE
    // ════════════════════════════════════════════════════
    implicitWidth:  gearRow.implicitWidth
    implicitHeight: gearRow.implicitHeight


    // ════════════════════════════════════════════════════
    //  GEAR LETTERS ROW
    // ════════════════════════════════════════════════════
    Row {
        id: gearRow
        anchors.centerIn: parent
        spacing: gearRoot.letterSpacing

        Repeater {
            model: gearRoot.gears

            delegate: Text {
                // Is this letter the currently selected gear?
                property bool isActive: modelData === gearRoot.currentGear

                text: modelData

                // Color logic:
                //   - Reverse when active → RED
                //   - Active otherwise   → primary text color
                //   - Passive            → muted
                color: {
                    if (isActive && modelData === "R") return gearRoot.colorReverse
                    if (isActive) return gearRoot.colorActive
                    return gearRoot.colorPassive
                }

                // Smooth color transitions when shifting gears
                Behavior on color {
                    ColorAnimation { duration: Theme.durationNormal }
                }

                // Active gear is slightly bigger for emphasis
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
