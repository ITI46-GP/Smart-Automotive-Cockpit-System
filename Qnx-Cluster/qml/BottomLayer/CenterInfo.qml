import QtQuick
import QtQuick.Layouts
import QnxCluster

/*
 * CENTER INFO SECTION
 *   3 InfoBlock items separated by vertical dividers.
 */
Item {
    id: centerRoot

    // ── PUBLIC API ────────────────────────────────────
    property string tempText:  "14 °C"
    property string totalText: "33560.5 km"
    property string timeText:  "10:32 PM"
    // S7/S9 diagnostic: see the matching note in FuelIndicator.qml. InfoBlock
    // already exposes labelSize/valueSize, so this just drives them uniform.
    property bool flatFontSize: false

    // Divider styling
    property color  dividerColor: "#333333"
    property real   dividerWidth: 1
    property real   dividerHeight: 28

    implicitWidth:  row.implicitWidth
    implicitHeight: row.implicitHeight

    RowLayout {
        id: row
        anchors.centerIn: parent
        spacing: 24

        InfoBlock {
            label: "TEMP"
            value: centerRoot.tempText
            labelSize: centerRoot.flatFontSize ? 12 : 10
            valueSize: centerRoot.flatFontSize ? 12 : 16
        }

        // Divider
        Rectangle {
            Layout.preferredWidth:  centerRoot.dividerWidth
            Layout.preferredHeight: centerRoot.dividerHeight
            color: centerRoot.dividerColor
        }

        InfoBlock {
            label: "TOTAL"
            value: centerRoot.totalText
            labelSize: centerRoot.flatFontSize ? 12 : 10
            valueSize: centerRoot.flatFontSize ? 12 : 16
        }

        // Divider
        Rectangle {
            Layout.preferredWidth:  centerRoot.dividerWidth
            Layout.preferredHeight: centerRoot.dividerHeight
            color: centerRoot.dividerColor
        }

        InfoBlock {
            label: "TIME"
            value: centerRoot.timeText
            labelSize: centerRoot.flatFontSize ? 12 : 10
            valueSize: centerRoot.flatFontSize ? 12 : 16
        }
    }
}
