import QtQuick
import QtQuick.Layouts
import Digital_Cluster_DesignStudio

/*
 * FUEL INDICATOR
 *   - Pump icon + range text
 *   - Segmented gauge
 *   - 0 / 1/2 / 1 labels
 */
Item {
    id: fuelRoot

    // ── PUBLIC API ────────────────────────────────────
    property real fuelPercent: 100     // 0–100
    property int  rangeKm:     520     // estimated remaining range
    property url  iconSource:  ""      // optional pump icon image

    implicitWidth:  220
    implicitHeight: column.implicitHeight

    ColumnLayout {
        id: column
        anchors.fill: parent
        spacing: 6

        // ── Header: icon + range text ────────────────
        RowLayout {
            Layout.alignment: Qt.AlignLeft
            spacing: 6

            // Pump icon (use Image if iconSource is set, otherwise emoji fallback)
            Item {
                Layout.preferredWidth:  24
                Layout.preferredHeight: 24

                Image {
                    anchors.fill: parent
                    source: fuelRoot.iconSource
                    visible: fuelRoot.iconSource != ""
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    mipmap: true
                }
                Text {
                    anchors.centerIn: parent
                    visible: fuelRoot.iconSource == ""
                    text: "⛽"
                    color: Theme.colorTextPrimary
                    font.pixelSize: 14
                }
            }

            Text {
                text: fuelRoot.rangeKm + " km"
                color: Theme.colorTextPrimary
                font.family:    Theme.fontPrimary
                font.pixelSize: 14
                font.weight:    Theme.fontWeightMedium
            }
        }

        // ── Segmented gauge ─────────────────────────
        SegmentedGauge {
            Layout.fillWidth: true
            Layout.preferredHeight: 14
            value:    fuelRoot.fuelPercent
            maxValue: 100
            segmentCount: 30
            startThresholdPercent: 0.25
            colorStart: Theme.colorDanger
        }

        // ── Labels: 0, 1/2, 1 ────────────────────────
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 12

            Text {
                anchors.left: parent.left
                text: "0"
                color: Theme.colorTextMuted
                font.family:    Theme.fontPrimary
                font.pixelSize: 10
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "1/2"
                color: Theme.colorTextMuted
                font.family:    Theme.fontPrimary
                font.pixelSize: 10
            }
            Text {
                anchors.right: parent.right
                text: "1"
                color: Theme.colorTextMuted
                font.family:    Theme.fontPrimary
                font.pixelSize: 10
            }
        }
    }
}
