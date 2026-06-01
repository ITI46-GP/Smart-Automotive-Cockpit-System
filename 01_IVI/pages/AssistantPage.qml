pragma ComponentBehavior: Bound

import QtQuick

Item {
    id: root
    width: 1024
    height: 600

    signal backClicked()
    signal keyboardRequested(var textInput)

    property color bg: "#07000E"
    property color panel: "#090613"
    property color line: "#342544"
    property color text: "#CBC4CD"
    property color muted: "#8F7AA8"
    property color violet: "#8B5CF6"
    property color cyan: "#21D4FD"

    readonly property bool listening: assistantManager.listening
    readonly property bool voiceEnabled: assistantManager.voiceEnabled
    property bool vehicleAccess: true
    property bool diagnosticsEnabled: true
    property string inputText: ""

    Rectangle {
        anchors.fill: parent
        color: root.bg

        Rectangle {
            anchors.fill: parent
            opacity: 0.65
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#10081A" }
                GradientStop { position: 0.55; color: "#07000E" }
                GradientStop { position: 1.0; color: "#050009" }
            }
        }

        Rectangle {
            width: 360
            height: 360
            radius: 180
            x: -130
            y: 120
            color: root.violet
            opacity: 0.055
        }

        Rectangle {
            width: 430
            height: 430
            radius: 215
            anchors.right: parent.right
            anchors.rightMargin: -170
            anchors.top: parent.top
            anchors.topMargin: 55
            color: root.cyan
            opacity: 0.035
        }
    }

    Row {
        id: header
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: 28
        anchors.rightMargin: 28
        anchors.topMargin: 22
        height: 52
        spacing: 18

        TouchIconButton {
            width: 52
            height: 52
            iconText: "‹"
            onClicked: root.backClicked()
        }

        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 4

            Text {
                text: "AI COPILOT"
                color: root.muted
                font.pixelSize: 11
                font.bold: true
                font.letterSpacing: 2.4
            }

            Text {
                text: "Chat & Voice Assistant"
                color: "#F4EEF7"
                font.pixelSize: 24
                font.bold: true
            }
        }
    }

    Row {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: header.bottom
        anchors.bottom: parent.bottom
        anchors.leftMargin: 28
        anchors.rightMargin: 28
        anchors.topMargin: 22
        anchors.bottomMargin: 26
        spacing: 22

        Rectangle {
            width: 318
            height: parent.height
            radius: 30
            color: root.panel
            border.color: root.line
            border.width: 1
            clip: true

            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                opacity: 0.42
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#241238" }
                    GradientStop { position: 0.52; color: "#111023" }
                    GradientStop { position: 1.0; color: "#07000E" }
                }
            }

            Rectangle {
                width: root.listening ? 152 : 136
                height: width
                radius: width / 2
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: root.listening ? 34 : 42
                color: "#120A1F"
                border.color: root.listening ? root.cyan : root.violet
                border.width: 2

                Behavior on width {
                    NumberAnimation {
                        duration: 160
                        easing.type: Easing.OutQuad
                    }
                }
            }

            Rectangle {
                width: root.listening ? 190 : 150
                height: width
                radius: width / 2
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: root.listening ? 15 : 35
                color: root.cyan
                opacity: root.listening ? 0.07 : 0.0
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: root.listening ? 75 : 80
                text: root.listening ? "◉" : "✦"
                color: root.listening ? root.cyan : root.violet
                font.pixelSize: root.listening ? 64 : 58
            }

            Column {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.topMargin: 198
                anchors.leftMargin: 22
                anchors.rightMargin: 22
                spacing: 8

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: !root.voiceEnabled ? "VOICE DISABLED"
                          : root.listening ? "VOICE ACTIVE"
                          : "COPILOT READY"
                    color: "#F4EEF7"
                    font.pixelSize: 22
                    font.bold: true
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: !root.voiceEnabled ? "Enable voice to listen"
                          : root.listening ? "Speak now"
                          : "Navigation · Climate · Media · Vehicle"
                    color: root.muted
                    font.pixelSize: 12
                    horizontalAlignment: Text.AlignHCenter
                    width: parent.width
                    elide: Text.ElideRight
                }
            }

            Column {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 22
                anchors.leftMargin: 20
                anchors.rightMargin: 20
                spacing: 9

                BigVoiceButton {
                    width: parent.width
                    height: 50
                    text: root.voiceEnabled
                          ? (root.listening ? "STOP LISTENING" : "START VOICE")
                          : "VOICE DISABLED"

                    active: root.listening
                    enabled: root.voiceEnabled

                    onClicked: assistantManager.toggleListening()
                }

                MiniStatusRow {
                    title: "Voice Control"
                    value: root.voiceEnabled ? "On" : "Off"
                }

                MiniStatusRow {
                    title: "Vehicle Access"
                    value: root.vehicleAccess ? "Allowed" : "Limited"
                }

                MiniStatusRow {
                    title: "Diagnostics"
                    value: root.diagnosticsEnabled ? "Ready" : "Off"
                }
            }
        }

        Column {
            width: parent.width - 318 - 22
            height: parent.height
            spacing: 12

            Rectangle {
                width: parent.width
                height: 88
                radius: 26
                color: root.panel
                border.color: root.line
                border.width: 1
                clip: true

                Row {
                    anchors.fill: parent
                    anchors.margins: 15
                    spacing: 12

                    StatusMetric {
                        width: (parent.width - 36) / 4
                        height: 58
                        title: "VOICE"
                        value: !root.voiceEnabled ? "Off"
                              : root.listening ? "Live"
                              : "Idle"
                    }

                    StatusMetric {
                        width: (parent.width - 36) / 4
                        height: 58
                        title: "CHAT"
                        value: "Ready"
                    }

                    StatusMetric {
                        width: (parent.width - 36) / 4
                        height: 58
                        title: "CAR"
                        value: root.vehicleAccess ? "Linked" : "Local"
                    }

                    StatusMetric {
                        width: (parent.width - 36) / 4
                        height: 58
                        title: "MODEL"
                        value: "IVI"
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: parent.height - 88 - 12
                radius: 26
                color: root.panel
                border.color: root.line
                border.width: 1
                clip: true

                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    opacity: 0.24
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "#1C162B" }
                        GradientStop { position: 1.0; color: "#080512" }
                    }
                }

                Column {
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 9

                    Text {
                        text: "ASSISTANT CONVERSATION"
                        color: root.muted
                        font.pixelSize: 11
                        font.bold: true
                        font.letterSpacing: 2.2
                    }

                    Rectangle {
                        width: parent.width
                        height: 142
                        radius: 22
                        color: "#080512"
                        border.color: root.line
                        border.width: 1
                        clip: true

                        Column {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 8

                            ChatBubble {
                                width: parent.width
                                fromUser: false
                                message: "Hello " + profileManager.activeProfileName + ". I can help with vehicle status, navigation, climate and media."
                            }

                            ChatBubble {
                                width: parent.width
                                fromUser: true
                                message: assistantManager.lastUserMessage
                            }

                            ChatBubble {
                                width: parent.width
                                fromUser: false
                                message: assistantManager.lastAssistantReply
                            }
                        }
                    }

                    Text {
                        text: "QUICK COMMANDS"
                        color: root.muted
                        font.pixelSize: 11
                        font.bold: true
                        font.letterSpacing: 2.0
                    }

                    Row {
                        width: parent.width
                        height: 58
                        spacing: 10

                        QuickCommandCard {
                            width: (parent.width - 30) / 4
                            height: parent.height
                            title: "Navigate"
                            subtitle: "Find charger"
                        }

                        QuickCommandCard {
                            width: (parent.width - 30) / 4
                            height: parent.height
                            title: "Climate"
                            subtitle: "Set comfort"
                        }

                        QuickCommandCard {
                            width: (parent.width - 30) / 4
                            height: parent.height
                            title: "Media"
                            subtitle: "Play music"
                        }

                        QuickCommandCard {
                            width: (parent.width - 30) / 4
                            height: parent.height
                            title: "Status"
                            subtitle: "Vehicle check"
                            onClicked: assistantManager.sendMessage("status")
                        }
                    }

                    Row {
                        width: parent.width
                        height: 48
                        spacing: 10

                        ModeToggleCard {
                            width: (parent.width - 20) / 3
                            height: parent.height
                            title: "Voice"
                            checked: root.voiceEnabled
                            onClicked: assistantManager.toggleVoiceEnabled()
                        }

                        ModeToggleCard {
                            width: (parent.width - 20) / 3
                            height: parent.height
                            title: "Car Access"
                            checked: root.vehicleAccess
                            onClicked: root.vehicleAccess = !root.vehicleAccess
                        }

                        ModeToggleCard {
                            width: (parent.width - 20) / 3
                            height: parent.height
                            title: "Diagnostics"
                            checked: root.diagnosticsEnabled
                            onClicked: root.diagnosticsEnabled = !root.diagnosticsEnabled
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 46
                        radius: 18
                        color: "#080512"
                        border.color: inputField.activeFocus ? root.cyan : root.line
                        border.width: 1

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 16
                            anchors.verticalCenter: parent.verticalCenter
                            visible: inputField.text.length === 0 && !inputField.activeFocus
                            text: "Ask the copilot..."
                            color: root.muted
                            font.pixelSize: 13
                        }

                        TextInput {
                            id: inputField
                            anchors.left: parent.left
                            anchors.right: sendButton.left
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.leftMargin: 16
                            anchors.rightMargin: 10

                            text: root.inputText
                            color: "#F4EEF7"
                            selectionColor: root.violet
                            selectedTextColor: "#FFFFFF"
                            font.pixelSize: 14
                            clip: true

                            onActiveFocusChanged: {
                                if (activeFocus) {
                                    root.keyboardRequested(inputField)
                                }
                            }

                            onTextChanged: {
                                root.inputText = text
                            }

                            onAccepted: {
                                assistantManager.sendMessage(inputField.text)
                                root.inputText = ""
                                inputField.text = ""
                            }
                        }

                        TouchSmallButton {
                            id: sendButton
                            width: 76
                            height: 34
                            anchors.right: parent.right
                            anchors.rightMargin: 7
                            anchors.verticalCenter: parent.verticalCenter
                            text: "SEND"

                            onClicked: {
                                assistantManager.sendMessage(inputField.text)
                                root.inputText = ""
                                inputField.text = ""
                            }
                        }
                    }
                }
            }
        }
    }

    component TouchIconButton: Item {
        id: iconBtn
        property string iconText: ""
        signal clicked()

        Rectangle {
            anchors.fill: parent
            radius: 18
            color: iconTap.pressed ? "#171025" : "#090613"
            border.color: iconTap.pressed ? root.violet : root.line
            border.width: 1
            scale: iconTap.pressed ? 0.94 : 1.0

            Behavior on scale {
                NumberAnimation {
                    duration: 110
                    easing.type: Easing.OutQuad
                }
            }

            Text {
                anchors.centerIn: parent
                text: iconBtn.iconText
                color: iconTap.pressed ? "#FFFFFF" : root.text
                font.pixelSize: 34
                font.bold: true
            }
        }

        TapHandler {
            id: iconTap
            gesturePolicy: TapHandler.ReleaseWithinBounds
            onTapped: iconBtn.clicked()
        }
    }

    component BigVoiceButton: Item {
        id: voiceButton
        property string text: ""
        property bool active: false
        signal clicked()

        opacity: enabled ? 1.0 : 0.45

        Rectangle {
            anchors.fill: parent
            radius: 21
            color: !voiceButton.enabled ? "#0A0710"
                  : voiceTap.pressed ? root.violet
                  : (voiceButton.active ? "#101C2A" : "#171025")

            border.color: !voiceButton.enabled ? "#24182F"
                        : voiceButton.active ? root.cyan
                        : root.line

            border.width: 1
            scale: voiceTap.pressed && voiceButton.enabled ? 0.97 : 1.0

            Behavior on scale {
                NumberAnimation {
                    duration: 110
                    easing.type: Easing.OutQuad
                }
            }

            Text {
                anchors.centerIn: parent
                text: voiceButton.text
                color: !voiceButton.enabled ? root.muted
                      : voiceButton.active ? root.cyan
                      : "#F4EEF7"
                font.pixelSize: 12
                font.bold: true
                font.letterSpacing: 1.6
            }
        }

        TapHandler {
            id: voiceTap
            enabled: voiceButton.enabled
            gesturePolicy: TapHandler.ReleaseWithinBounds
            onTapped: voiceButton.clicked()
        }
    }

    component MiniStatusRow: Rectangle {
        id: miniStatusRow
        property string title: ""
        property string value: ""

        width: parent.width
        height: 32
        radius: 14
        color: "#080512"
        border.color: root.line
        border.width: 1

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            text: miniStatusRow.title
            color: root.muted
            font.pixelSize: 11
        }

        Text {
            anchors.right: parent.right
            anchors.rightMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            text: miniStatusRow.value
            color: root.cyan
            font.pixelSize: 12
            font.bold: true
        }
    }

    component StatusMetric: Rectangle {
        id: statusMetric
        property string title: ""
        property string value: ""

        radius: 17
        color: "#080512"
        border.color: root.line
        border.width: 1

        Column {
            anchors.centerIn: parent
            spacing: 4

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: statusMetric.title
                color: root.muted
                font.pixelSize: 8
                font.bold: true
                font.letterSpacing: 1.3
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: statusMetric.value
                color: "#F4EEF7"
                font.pixelSize: 13
                font.bold: true
            }
        }
    }

    component ChatBubble: Item {
        id: bubble
        property bool fromUser: false
        property string message: ""

        height: Math.max(34, messageText.paintedHeight + 18)

        Rectangle {
            width: bubble.width * (bubble.fromUser ? 0.58 : 0.76)
            height: parent.height
            radius: 16
            anchors.right: bubble.fromUser ? parent.right : undefined
            anchors.left: bubble.fromUser ? undefined : parent.left
            color: bubble.fromUser ? "#15102A" : "#0B0712"
            border.color: bubble.fromUser ? root.violet : root.line
            border.width: 1

            Text {
                id: messageText
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 13
                anchors.rightMargin: 13
                text: bubble.message
                color: bubble.fromUser ? "#F4EEF7" : root.text
                font.pixelSize: 12
                wrapMode: Text.WordWrap
            }
        }
    }

    component QuickCommandCard: Item {
        id: quickCard
        property string title: ""
        property string subtitle: ""
        signal clicked()

        Rectangle {
            anchors.fill: parent
            radius: 17
            color: quickTap.pressed ? "#171025" : "#080512"
            border.color: quickTap.pressed ? root.cyan : root.line
            border.width: 1
            scale: quickTap.pressed ? 0.98 : 1.0

            Behavior on scale {
                NumberAnimation {
                    duration: 110
                    easing.type: Easing.OutQuad
                }
            }

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.top: parent.top
                anchors.topMargin: 11
                text: quickCard.title
                color: "#F4EEF7"
                font.pixelSize: 12
                font.bold: true
            }

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.top: parent.top
                anchors.topMargin: 32
                text: quickCard.subtitle
                color: root.muted
                font.pixelSize: 9
            }
        }

        TapHandler {
            id: quickTap
            gesturePolicy: TapHandler.ReleaseWithinBounds
            onTapped: quickCard.clicked()
        }
    }

    component ModeToggleCard: Item {
        id: modeCard
        property string title: ""
        property bool checked: false
        signal clicked()

        Rectangle {
            anchors.fill: parent
            radius: 17
            color: modeTap.pressed ? "#171025" : "#080512"
            border.color: modeCard.checked ? root.violet : root.line
            border.width: 1

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 13
                anchors.verticalCenter: parent.verticalCenter
                text: modeCard.title
                color: "#F4EEF7"
                font.pixelSize: 12
                font.bold: true
            }

            Rectangle {
                width: 42
                height: 23
                radius: 12
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                color: modeCard.checked ? "#1A1230" : "#0B0712"
                border.color: modeCard.checked ? root.cyan : root.line
                border.width: 1

                Rectangle {
                    width: 17
                    height: 17
                    radius: 9
                    anchors.verticalCenter: parent.verticalCenter
                    x: modeCard.checked ? parent.width - width - 3 : 3
                    color: modeCard.checked ? root.cyan : root.muted

                    Behavior on x {
                        NumberAnimation {
                            duration: 130
                            easing.type: Easing.OutQuad
                        }
                    }
                }
            }
        }

        TapHandler {
            id: modeTap
            gesturePolicy: TapHandler.ReleaseWithinBounds
            onTapped: modeCard.clicked()
        }
    }

    component TouchSmallButton: Item {
        id: smallButton
        property string text: ""
        signal clicked()

        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: smallButtonTap.pressed ? root.violet : "#171025"
            border.color: smallButtonTap.pressed ? "#B99CFF" : "#352347"
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: smallButton.text
                color: "#F4EEF7"
                font.pixelSize: 10
                font.bold: true
                font.letterSpacing: 1.4
            }
        }

        TapHandler {
            id: smallButtonTap
            gesturePolicy: TapHandler.ReleaseWithinBounds
            onTapped: smallButton.clicked()
        }
    }
}
