// Ported from 02-Digital-Cluster's Content_Area/MapView.qml. The original's
// Canvas (grid + route + destination dot) is baked into MapBackdrop.png by
// tools/gen_map.py instead — see that script for why (S1's one-time-Canvas-
// stall finding). The frame Rectangle stays live (cheap, no Canvas needed
// for a plain rounded rect). No backend binding yet in the reference either
// — this is a static mockup, same as there.
import QtQuick
import QnxCluster

Item {
    id: mapView

    property string nextInstruction: "Next: Main St in 250m"

    Column {
        anchors.centerIn: parent
        spacing: 14

        Text {
            text: "🗺 Navigation"
            color: Theme.colorTextPrimary
            font.family: Theme.fontPrimary
            font.pixelSize: 22
            font.weight: Theme.fontWeightBold
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Rectangle {
            width: 360
            height: 220
            radius: 14
            color: "#15151f"
            border.color: "#2a2a3a"
            clip: true

            Image {
                anchors.fill: parent
                source: "qrc:/art/MapBackdrop.png"
                sourceSize: Qt.size(width, height)
                mipmap: false
                smooth: true
            }
        }

        Text {
            text: mapView.nextInstruction
            color: Theme.colorTextSecondary
            font.family: Theme.fontPrimary
            font.pixelSize: 14
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }
}
