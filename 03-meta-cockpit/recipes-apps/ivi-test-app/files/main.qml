import QtQuick
import QtQuick.Controls

Rectangle {
    width: 1024
    height: 600
    color: "#07000E"

    Text {
        anchors.centerIn: parent
        text: "IVI Qt EGLFS Test\n1024 x 600"
        color: "#CBC4CD"
        font.pixelSize: 42
        horizontalAlignment: Text.AlignHCenter
    }

    Rectangle {
        width: 220
        height: 70
        radius: 18
        color: mouseArea.pressed ? "#00D9FF" : "#7C3AED"
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 70

        Text {
            anchors.centerIn: parent
            text: mouseArea.pressed ? "Pressed" : "Touch Me"
            color: "white"
            font.pixelSize: 26
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
        }
    }
}
