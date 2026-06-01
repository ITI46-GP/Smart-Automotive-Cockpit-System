import QtQuick
import QtQuick.Layouts
import Digital_Cluster_DesignStudio

/*
 * MOTOR TEMPERATURE INDICATOR
 *   - Engine icon + temp value
 *   - Segmented gauge (with red danger zone)
 *   - C / Normal / H labels
 */
Item {
    id: tempRoot

    // ── PUBLIC API ────────────────────────────────────
    property real motorTempC: 90       // °C
    property real maxTempC:   120      // max scale
    property real dangerStartPercent: 0.8   // last 20% are red
    property url  iconSource: ""

    implicitWidth:  220
    implicitHeight: column.implicitHeight

    ColumnLayout {
        id: column
        anchors.fill: parent
        spacing: 6

        // ── Header: icon + temp text ─────────────────
        // Right-aligned to mirror the fuel side
        RowLayout {
            Layout.alignment: Qt.AlignRight
            spacing: 6

            Text {
                text: tempRoot.motorTempC + " °C"
                color: Theme.colorTextPrimary
                font.family:    Theme.fontPrimary
                font.pixelSize: 14
                font.weight:    Theme.fontWeightMedium
            }

            // Engine/motor icon
            Item {
                Layout.preferredWidth:  24
                Layout.preferredHeight: 24

                Image {
                    anchors.fill: parent
                    source: tempRoot.iconSource
                    visible: tempRoot.iconSource != ""
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    mipmap: true
                }
                Text {
                    anchors.centerIn: parent
                    visible: tempRoot.iconSource == ""
                    text: "🌡"
                    color: Theme.colorTextPrimary
                    font.pixelSize: 14
                }
            }
        }

        // ── Segmented gauge with danger zone ─────────
        SegmentedGauge {
            Layout.fillWidth: true
            Layout.preferredHeight: 14
            value:    tempRoot.motorTempC
            maxValue: tempRoot.maxTempC
            segmentCount: 30
            dangerThresholdPercent: tempRoot.dangerStartPercent
        }

        // ── Labels: C, Normal, H ────────────────────
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 12

            Text {
                anchors.left: parent.left
                text: "C"
                color: Theme.colorTextMuted
                font.family:    Theme.fontPrimary
                font.pixelSize: 10
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "NORMAL"
                color: Theme.colorTextMuted
                font.family:    Theme.fontPrimary
                font.pixelSize: 10
                font.letterSpacing: 1
            }
            Text {
                anchors.right: parent.right
                text: "H"
                color: Theme.colorTextMuted
                font.family:    Theme.fontPrimary
                font.pixelSize: 10
            }
        }
    }
}
