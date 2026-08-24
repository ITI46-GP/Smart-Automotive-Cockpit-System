import QtQuick
import QtQuick.Layouts
import QnxCluster

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

    // S7 diagnostic: hide just the segmented bar (see BottomLayer.qml).
    property bool showBar: true
    property bool flatBar: false
    // S7/S9 diagnostic: the still-open "batches track font size, not item
    // count" hypothesis (PLAN.md S7) has never actually been tested. Forces
    // every Text here to one pixelSize so a single atlas can hold them all.
    property bool flatFontSize: false

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
                    // mipmap would take this out of Qt's shared texture
                    // atlas and cost it its own batch (~0.5 ms here); with
                    // sourceSize set there is nothing to mip. See
                    // qml/ContentArea/TopBarButton.qml.
                    sourceSize: Qt.size(24, 24)
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    mipmap: false
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
                font.pixelSize: fuelRoot.flatFontSize ? 12 : 14
                font.weight:    Theme.fontWeightMedium
            }
        }

        // ── Segmented gauge ─────────────────────────
        SegmentedGauge {
            visible: fuelRoot.showBar
            flatOpacity: fuelRoot.flatBar
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
                font.pixelSize: fuelRoot.flatFontSize ? 12 : 10
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "1/2"
                color: Theme.colorTextMuted
                font.family:    Theme.fontPrimary
                font.pixelSize: fuelRoot.flatFontSize ? 12 : 10
            }
            Text {
                anchors.right: parent.right
                text: "1"
                color: Theme.colorTextMuted
                font.family:    Theme.fontPrimary
                font.pixelSize: fuelRoot.flatFontSize ? 12 : 10
            }
        }
    }
}
