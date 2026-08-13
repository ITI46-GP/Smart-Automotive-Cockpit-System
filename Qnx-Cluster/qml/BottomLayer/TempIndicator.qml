import QtQuick
import QtQuick.Layouts
import QnxCluster

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
    property real minTempC:   70       // Start the gauge at 70°C
    property real maxTempC:   120      // max scale (up to 120°C)
    property real dangerStartPercent: (105 - minTempC) / (maxTempC - minTempC) // Starts turning red at 105°C
    property real coldEndPercent:     (82 - minTempC) / (maxTempC - minTempC)  // Light blue up to 82°C
    property url  iconSource: ""

    // S7 diagnostic: hide just the segmented bar (see BottomLayer.qml).
    property bool showBar: true
    property bool flatBar: false
    // S7/S9 diagnostic: see the matching note in FuelIndicator.qml.
    property bool flatFontSize: false

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
                text: Math.round(tempRoot.motorTempC) + " °C"
                color: Theme.colorTextPrimary
                font.family:    Theme.fontPrimary
                font.pixelSize: tempRoot.flatFontSize ? 12 : 14
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
                    visible: tempRoot.iconSource == ""
                    text: "🌡"
                    color: Theme.colorTextPrimary
                    font.pixelSize: 14
                }
            }
        }

        // ── Segmented gauge with danger zone ─────────
        SegmentedGauge {
            visible: tempRoot.showBar
            flatOpacity: tempRoot.flatBar
            Layout.fillWidth: true
            Layout.preferredHeight: 14
            value:    tempRoot.motorTempC
            minValue: tempRoot.minTempC
            maxValue: tempRoot.maxTempC
            segmentCount: 30
            endThresholdPercent: tempRoot.dangerStartPercent
            startThresholdPercent:   tempRoot.coldEndPercent
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
                font.pixelSize: tempRoot.flatFontSize ? 12 : 10
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "NORMAL"
                color: Theme.colorTextMuted
                font.family:    Theme.fontPrimary
                font.pixelSize: tempRoot.flatFontSize ? 12 : 10
                font.letterSpacing: 1
            }
            Text {
                anchors.right: parent.right
                text: "H"
                color: Theme.colorTextMuted
                font.family:    Theme.fontPrimary
                font.pixelSize: tempRoot.flatFontSize ? 12 : 10
            }
        }
    }
}
