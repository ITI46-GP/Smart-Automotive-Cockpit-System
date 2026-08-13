// Ported from 02-Digital-Cluster's Content_Area/FuelView.qml. The reference
// leaves fuelPercent/consumption/rangeText/tripText as plain properties set
// by the caller (Screen01.qml passed `fuelPercent: digitalCluster.simFuel`);
// this rebuild's caller (Main.qml) binds fuelPercent/rangeText to
// VehicleData.bottomBar.fuelProvider directly — same real-data source the
// bottom bar already uses, no separate consumption/trip provider exists in
// the reference either, so those two stay as the original's own defaults.
import QtQuick

Item {
    id: fuelView

    property real fuelPercent: 100
    property real consumption: 8.5
    property string rangeText: "420 km"
    property string tripText: "127 km"

    Column {
        anchors.centerIn: parent
        spacing: 18

        Text {
            text: "⛽ Fuel Consumption"
            color: "#ffffff"
            font.pixelSize: 22
            font.bold: true
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Text {
            text: fuelView.consumption.toFixed(1) + " L/100km"
            color: "#4aff8e"
            font.pixelSize: 36
            font.bold: true
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Text {
            text: "Average"
            color: "#8888aa"
            font.pixelSize: 12
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Rectangle {
            width: 320
            height: 24
            radius: 12
            color: "#15151f"
            border.color: "#2a2a3a"
            anchors.horizontalCenter: parent.horizontalCenter

            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.margins: 3
                width: (parent.width - 6) * (fuelView.fuelPercent / 100)
                radius: 10
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "#4aff8e" }
                    GradientStop { position: 1.0; color: "#4a9eff" }
                }
                Behavior on width { NumberAnimation { duration: 300 } }
            }
        }

        Text {
            text: "Tank: " + Math.round(fuelView.fuelPercent) + "%"
            color: "#aaaacc"
            font.pixelSize: 14
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Row {
            spacing: 30
            anchors.horizontalCenter: parent.horizontalCenter

            FuelStatItem {
                label: "RANGE"
                value: fuelView.rangeText
            }
            FuelStatItem {
                label: "TRIP"
                value: fuelView.tripText
            }
        }
    }
}
