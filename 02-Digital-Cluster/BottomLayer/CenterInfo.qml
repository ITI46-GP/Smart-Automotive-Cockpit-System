import QtQuick
import QtQuick.Layouts
import Digital_Cluster_DesignStudio

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
        }
    }
}
