import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Window {
    width: 320
    height: 320
    visible: true
    title: "Steering Wheel Controller"
    color: "#1e1e24"

    // Helper to send command
    function trigger(cmd) {
        // Provide visual feedback
        flashRectangle.opacity = 0.5
        flashAnim.restart()
        udpSender.sendCommand(cmd)
    }

    Rectangle {
        id: flashRectangle
        anchors.fill: parent
        color: "#ffffff"
        opacity: 0
        z: 99
        NumberAnimation on opacity {
            id: flashAnim
            to: 0
            duration: 150
            running: false
        }
    }

    // A simple D-Pad layout
    Item {
        anchors.centerIn: parent
        width: 200
        height: 200

        // UP
        Button {
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            width: 60
            height: 60
            text: "▲"
            font.pixelSize: 24
            onClicked: trigger("BTN_UP")
        }

        // DOWN
        Button {
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            width: 60
            height: 60
            text: "▼"
            font.pixelSize: 24
            onClicked: trigger("BTN_DOWN")
        }

        // LEFT
        Button {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: 60
            height: 60
            text: "◀"
            font.pixelSize: 24
            onClicked: trigger("BTN_LEFT")
        }

        // RIGHT
        Button {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: 60
            height: 60
            text: "▶"
            font.pixelSize: 24
            onClicked: trigger("BTN_RIGHT")
        }

        // OK / CENTER
        Button {
            anchors.centerIn: parent
            width: 60
            height: 60
            text: "OK"
            font.pixelSize: 18
            font.bold: true
            onClicked: trigger("BTN_OK")
        }
    }

    // L3 / R3 -- paddle shifters, drive the turn-signal flashers. Separate
    // row from the D-pad since they're physically distinct buttons on the
    // real wheel, not part of the 5-button D-pad vocabulary.
    RowLayout {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 12
        spacing: 16

        Button {
            text: "L3"
            font.pixelSize: 14
            font.bold: true
            onClicked: trigger("BTN_L3")
        }
        Button {
            text: "R3"
            font.pixelSize: 14
            font.bold: true
            onClicked: trigger("BTN_R3")
        }
    }

    // Keyboard support for easy testing
    Item {
        focus: true
        anchors.fill: parent
        Keys.onUpPressed: trigger("BTN_UP")
        Keys.onDownPressed: trigger("BTN_DOWN")
        Keys.onLeftPressed: trigger("BTN_LEFT")
        Keys.onRightPressed: trigger("BTN_RIGHT")
        Keys.onReturnPressed: trigger("BTN_OK")
        Keys.onEnterPressed: trigger("BTN_OK")
        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Q) trigger("BTN_L3")
            else if (event.key === Qt.Key_E) trigger("BTN_R3")
        }
    }
}
