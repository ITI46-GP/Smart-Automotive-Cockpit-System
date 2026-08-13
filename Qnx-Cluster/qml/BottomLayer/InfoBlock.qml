import QtQuick
import QtQuick.Layouts
import QnxCluster

/*
 * INFO BLOCK — small reusable label + value pair
 *
 * Used 3× in the center section:
 *   - TEMP / 14 °C
 *   - TOTAL / 33560.5 km
 *   - TIME / 10:32 PM
 */
Item {
    id: blockRoot

    // ── PUBLIC API ────────────────────────────────────
    property string label: ""       // small uppercase (e.g., "TEMP")
    property string value: ""       // large white (e.g., "14 °C")

    // Typography
    property int    labelSize: 10
    property int    valueSize: 16
    property real   labelSpacing: 2

    implicitWidth:  column.implicitWidth
    implicitHeight: column.implicitHeight

    ColumnLayout {
        id: column
        anchors.centerIn: parent
        spacing: 2

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: blockRoot.label
            color: Theme.colorTextMuted
            font.family:        Theme.fontPrimary
            font.pixelSize:     blockRoot.labelSize
            font.weight:        Theme.fontWeightMedium
            font.letterSpacing: blockRoot.labelSpacing
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: blockRoot.value
            color: Theme.colorTextPrimary
            font.family:    Theme.fontPrimary
            font.pixelSize: blockRoot.valueSize
            font.weight:    Theme.fontWeightMedium
        }
    }
}
