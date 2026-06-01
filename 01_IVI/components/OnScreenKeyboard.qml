pragma ComponentBehavior: Bound

import QtQuick

Item {
    id: keyboard

    property var targetInput: null
    property bool opened: false

    readonly property color bg: "#07000E"
    readonly property color panel: "#090613"
    readonly property color panel2: "#1C162B"
    readonly property color line: "#342544"
    readonly property color text: "#CBC4CD"
    readonly property color muted: "#8F7AA8"
    readonly property color violet: "#8B5CF6"
    readonly property color cyan: "#21D4FD"

    height: 206
    visible: opened
    enabled: opened

    function openFor(textInput) {
        if (!textInput) {
            return
        }

        targetInput = textInput
        opened = true
        targetInput.forceActiveFocus()
    }

    function closeKeyboard() {
        var input = targetInput
        opened = false

        if (input) {
            input.focus = false
        }

        targetInput = null
    }

    function removeSelection(input) {
        if (!input || !input.selectedText || input.selectedText.length === 0) {
            return false
        }

        var start = Math.min(input.selectionStart, input.selectionEnd)
        var end = Math.max(input.selectionStart, input.selectionEnd)
        input.remove(start, end)
        input.cursorPosition = start
        return true
    }

    function insertCharacter(character) {
        var input = targetInput

        if (!input) {
            return
        }

        input.forceActiveFocus()
        removeSelection(input)
        input.insert(input.cursorPosition, character)
        input.forceActiveFocus()
    }

    function backspace() {
        var input = targetInput

        if (!input) {
            return
        }

        input.forceActiveFocus()

        if (!removeSelection(input) && input.cursorPosition > 0) {
            var cursor = input.cursorPosition
            input.remove(cursor - 1, cursor)
            input.cursorPosition = cursor - 1
        }

        input.forceActiveFocus()
    }

    function clearInput() {
        var input = targetInput

        if (!input) {
            return
        }

        input.forceActiveFocus()
        input.text = ""
        input.cursorPosition = 0
        input.forceActiveFocus()
    }

    Rectangle {
        anchors.fill: parent
        color: keyboard.panel
        border.color: keyboard.line
        border.width: 1

        Rectangle {
            anchors.fill: parent
            opacity: 0.35
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#1C162B" }
                GradientStop { position: 1.0; color: keyboard.bg }
            }
        }

        Column {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 7

            Row {
                id: previewRow
                width: parent.width
                height: 26
                spacing: 8

                Rectangle {
                    width: parent.width - doneKey.width - parent.spacing
                    height: parent.height
                    radius: 12
                    color: "#080512"
                    border.color: keyboard.line
                    border.width: 1

                    Text {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14
                        text: keyboard.targetInput ? keyboard.targetInput.text : ""
                        color: text.length > 0 ? "#F4EEF7" : keyboard.muted
                        font.pixelSize: 11
                        elide: Text.ElideRight
                    }
                }

                KeyboardKey {
                    id: doneKey
                    width: 88
                    height: parent.height
                    label: "DONE"
                    accent: true
                    onClicked: keyboard.closeKeyboard()
                }
            }

            Row {
                id: topKeyRow
                width: parent.width
                height: 32
                spacing: 6

                Repeater {
                    model: ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"]

                    KeyboardKey {
                        required property string modelData

                        width: (topKeyRow.width - topKeyRow.spacing * 9) / 10
                        height: topKeyRow.height
                        label: modelData
                        onClicked: keyboard.insertCharacter(modelData.toLowerCase())
                    }
                }
            }

            Row {
                id: middleKeyRow
                width: parent.width - 52
                height: 32
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 6

                Repeater {
                    model: ["A", "S", "D", "F", "G", "H", "J", "K", "L"]

                    KeyboardKey {
                        required property string modelData

                        width: (middleKeyRow.width - middleKeyRow.spacing * 8) / 9
                        height: middleKeyRow.height
                        label: modelData
                        onClicked: keyboard.insertCharacter(modelData.toLowerCase())
                    }
                }
            }

            Row {
                id: bottomKeyRow
                width: parent.width - 104
                height: 32
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 6

                Repeater {
                    model: ["Z", "X", "C", "V", "B", "N", "M"]

                    KeyboardKey {
                        required property string modelData

                        width: (bottomKeyRow.width - bottomKeyRow.spacing * 6) / 7
                        height: bottomKeyRow.height
                        label: modelData
                        onClicked: keyboard.insertCharacter(modelData.toLowerCase())
                    }
                }
            }

            Row {
                id: actionKeyRow
                width: parent.width
                height: 38
                spacing: 8

                KeyboardKey {
                    width: 104
                    height: parent.height
                    label: "CLEAR"
                    destructive: true
                    onClicked: keyboard.clearInput()
                }

                KeyboardKey {
                    width: parent.width - 104 - 104 - 88 - parent.spacing * 3
                    height: parent.height
                    label: "SPACE"
                    onClicked: keyboard.insertCharacter(" ")
                }

                KeyboardKey {
                    width: 104
                    height: parent.height
                    label: "BACK"
                    onClicked: keyboard.backspace()
                }

                KeyboardKey {
                    width: 88
                    height: parent.height
                    label: "DONE"
                    accent: true
                    onClicked: keyboard.closeKeyboard()
                }
            }
        }
    }

    component KeyboardKey: Item {
        id: keyRoot

        property string label: ""
        property bool accent: false
        property bool destructive: false

        signal clicked()

        Rectangle {
            anchors.fill: parent
            radius: Math.min(14, height / 2)
            color: keyTap.pressed
                   ? (keyRoot.destructive ? "#20101A" : keyboard.violet)
                   : (keyRoot.accent ? "#15102A" : "#080512")
            border.color: keyRoot.accent ? keyboard.cyan
                         : keyTap.pressed ? "#B99CFF"
                         : keyboard.line
            border.width: 1
            scale: keyTap.pressed ? 0.97 : 1.0

            Behavior on scale {
                NumberAnimation {
                    duration: 90
                    easing.type: Easing.OutQuad
                }
            }

            Text {
                anchors.centerIn: parent
                text: keyRoot.label
                color: keyRoot.accent ? keyboard.cyan
                     : keyRoot.destructive ? "#F4EEF7"
                     : keyboard.text
                font.pixelSize: keyRoot.label.length > 1 ? 10 : 14
                font.bold: true
                font.letterSpacing: keyRoot.label.length > 1 ? 1.2 : 0
            }
        }

        TapHandler {
            id: keyTap
            gesturePolicy: TapHandler.ReleaseWithinBounds
            onTapped: keyRoot.clicked()
        }
    }
}
