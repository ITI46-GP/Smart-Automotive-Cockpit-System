// Generic error overlay. Hidden until VehicleData.errorOccurred fires (see
// VehicleDataProvider::raiseError / SteeringWheelController::bindFailed) or
// something calls errorDialog.show(message) directly. Styled from the real
// Theme singleton (src/Theme.h), matching the rest of this project rather
// than hardcoded hex.
import QtQuick
import QnxCluster

Item {
    id: errorDialog
    anchors.fill: parent
    visible: opacity > 0
    opacity: 0
    z: 998

    property string errorText: ""

    function show(message) {
        errorDialog.errorText = message
        errorDialog.opacity = 1
    }
    function hide() {
        errorDialog.opacity = 0
    }

    Behavior on opacity { NumberAnimation { duration: Theme.durationNormal } }

    // dim background, eats clicks so they don't reach the UI underneath
    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: 0.55
        MouseArea { anchors.fill: parent }
    }

    Rectangle {
        width: 420
        height: 200
        radius: Theme.radiusLarge
        color: Theme.colorBackgroundElevated
        border.color: Theme.colorDanger
        border.width: 1
        anchors.centerIn: parent

        Column {
            anchors.centerIn: parent
            spacing: Theme.spacingMedium
            width: parent.width - 60

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 40; height: 40; radius: 20
                color: Theme.colorDanger
                Text {
                    anchors.centerIn: parent
                    text: "!"
                    color: Theme.colorBackgroundElevated
                    font.family: Theme.fontPrimary
                    font.pixelSize: Theme.fontSizeLarge
                    font.bold: true
                }
            }

            Text {
                text: "Error"
                color: Theme.colorTextPrimary
                font.family: Theme.fontPrimary
                font.pixelSize: Theme.fontSizeLarge
                font.bold: true
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Text {
                width: parent.width
                text: errorDialog.errorText
                color: Theme.colorTextSecondary
                font.family: Theme.fontSecondary
                font.pixelSize: Theme.fontSizeSmall
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
            }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 100; height: 36; radius: Theme.radiusPill
                color: Theme.colorBackgroundActive
                border.color: Theme.colorTextMuted
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: "OK"
                    color: Theme.colorTextPrimary
                    font.family: Theme.fontSecondary
                    font.pixelSize: Theme.fontSizeSmall
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: errorDialog.hide()
                }
            }
        }
    }
}
