import QtQuick

Item {
    id: root
    width: 1024
    height: 600

    signal backClicked()

    property color bg: "#07000E"
    property color panel: "#090613"
    property color line: "#342544"
    property color text: "#CBC4CD"
    property color muted: "#8F7AA8"
    property color violet: "#8B5CF6"
    property color cyan: "#21D4FD"

    readonly property bool wifiOn: settingsManager.wifiOn
    readonly property bool bluetoothOn: settingsManager.bluetoothOn
    readonly property bool darkMode: settingsManager.darkMode
    readonly property bool autoBrightness: settingsManager.autoBrightness
    property bool driveAlerts: true
    readonly property bool privacyMode: settingsManager.privacyMode

    readonly property int brightness: settingsManager.brightness
    readonly property int systemVolume: settingsManager.systemVolume

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
            width: 420
            height: 420
            radius: 210
            anchors.right: parent.right
            anchors.rightMargin: -160
            anchors.top: parent.top
            anchors.topMargin: 50
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
                text: "SYSTEM SETTINGS"
                color: root.muted
                font.pixelSize: 11
                font.bold: true
                font.letterSpacing: 2.4
            }

            Text {
                text: "Vehicle & Cockpit Settings"
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
            width: 330
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
                width: 136
                height: 136
                radius: 68
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 38
                color: "#120A1F"
                border.color: root.violet
                border.width: 2
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 66
                text: "⚙"
                color: root.cyan
                font.pixelSize: 62
            }

            Column {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.topMargin: 198
                anchors.leftMargin: 24
                anchors.rightMargin: 24
                spacing: 8

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "COCKPIT READY"
                    color: "#F4EEF7"
                    font.pixelSize: 22
                    font.bold: true
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Vehicle systems synchronized"
                    color: root.muted
                    font.pixelSize: 12
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.darkMode ? "Dark mode active" : "Light mode selected"
                    color: root.cyan
                    font.pixelSize: 12
                    opacity: 0.95
                }
            }

            Column {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 24
                anchors.leftMargin: 22
                anchors.rightMargin: 22
                spacing: 9

                MiniStatusRow {
                    title: "Wi-Fi"
                    value: root.wifiOn ? "On" : "Off"
                }

                MiniStatusRow {
                    title: "Bluetooth"
                    value: root.bluetoothOn ? "On" : "Off"
                }

                MiniStatusRow {
                    title: "Dark Mode"
                    value: root.darkMode ? "On" : "Off"
                }

                MiniStatusRow {
                    title: "Privacy"
                    value: root.privacyMode ? "On" : "Off"
                }
            }
        }

        Column {
            width: parent.width - 330 - 22
            height: parent.height
            spacing: 14

            Rectangle {
                width: parent.width
                height: 96
                radius: 26
                color: root.panel
                border.color: root.line
                border.width: 1
                clip: true

                Row {
                    anchors.fill: parent
                    anchors.margins: 17
                    spacing: 12

                    StatusMetric {
                        width: (parent.width - 36) / 4
                        height: 62
                        title: "NETWORK"
                        value: root.wifiOn ? "Online" : "Local"
                    }

                    StatusMetric {
                        width: (parent.width - 36) / 4
                        height: 62
                        title: "PHONE"
                        value: root.bluetoothOn ? "Paired" : "Off"
                    }

                    StatusMetric {
                        width: (parent.width - 36) / 4
                        height: 62
                        title: "THEME"
                        value: root.darkMode ? "Dark" : "Light"
                    }

                    StatusMetric {
                        width: (parent.width - 36) / 4
                        height: 62
                        title: "DISPLAY"
                        value: root.brightness + "%"
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: parent.height - 96 - 14
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
                    spacing: 10

                    Text {
                        text: "QUICK CONTROLS"
                        color: root.muted
                        font.pixelSize: 11
                        font.bold: true
                        font.letterSpacing: 2.2
                    }

                    Grid {
                        width: parent.width
                        columns: 3
                        rowSpacing: 10
                        columnSpacing: 12

                        SettingsToggleCard {
                            width: (parent.width - 24) / 3
                            height: 68
                            title: "Wi-Fi"
                            subtitle: "Network"
                            checked: root.wifiOn
                            onClicked: settingsManager.toggleWifi()
                        }

                        SettingsToggleCard {
                            width: (parent.width - 24) / 3
                            height: 68
                            title: "Bluetooth"
                            subtitle: "Phone"
                            checked: root.bluetoothOn
                            onClicked: settingsManager.toggleBluetooth()
                        }

                        SettingsToggleCard {
                            width: (parent.width - 24) / 3
                            height: 68
                            title: "Dark Mode"
                            subtitle: "Theme"
                            checked: root.darkMode
                            onClicked: settingsManager.toggleDarkMode()
                        }

                        SettingsToggleCard {
                            width: (parent.width - 24) / 3
                            height: 68
                            title: "Auto Bright"
                            subtitle: "Display"
                            checked: root.autoBrightness
                            onClicked: settingsManager.toggleAutoBrightness()
                        }

                        SettingsToggleCard {
                            width: (parent.width - 24) / 3
                            height: 68
                            title: "Alerts"
                            subtitle: "Safety"
                            checked: root.driveAlerts
                            onClicked: root.driveAlerts = !root.driveAlerts
                        }

                        SettingsToggleCard {
                            width: (parent.width - 24) / 3
                            height: 68
                            title: "Privacy"
                            subtitle: "Personal"
                            checked: root.privacyMode
                            onClicked: settingsManager.togglePrivacyMode()
                        }
                    }

                    AdjustRow {
                        width: parent.width
                        height: 50
                        title: "DISPLAY BRIGHTNESS"
                        value: root.brightness + "%"
                        percentValue: root.brightness
                        onMinusClicked: settingsManager.decreaseBrightness()
                        onPlusClicked: settingsManager.increaseBrightness()
                    }

                    AdjustRow {
                        width: parent.width
                        height: 50
                        title: "SYSTEM VOLUME"
                        value: root.systemVolume + "%"
                        percentValue: root.systemVolume
                        onMinusClicked: settingsManager.decreaseSystemVolume()
                        onPlusClicked: settingsManager.increaseSystemVolume()
                    }

                    Rectangle {
                        width: parent.width
                        height: 42
                        radius: 18
                        color: "#080512"
                        border.color: root.line
                        border.width: 1

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 16
                            anchors.verticalCenter: parent.verticalCenter
                            text: "SYSTEM STATUS"
                            color: "#F4EEF7"
                            font.pixelSize: 12
                            font.bold: true
                            font.letterSpacing: 1.3
                        }

                        Text {
                            anchors.right: parent.right
                            anchors.rightMargin: 16
                            anchors.verticalCenter: parent.verticalCenter
                            text: "READY"
                            color: root.cyan
                            font.pixelSize: 12
                            font.bold: true
                            font.letterSpacing: 1.4
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
            color: tap.pressed ? "#171025" : "#090613"
            border.color: tap.pressed ? root.violet : root.line
            border.width: 1
            scale: tap.pressed ? 0.94 : 1.0

            Behavior on scale {
                NumberAnimation {
                    duration: 110
                    easing.type: Easing.OutQuad
                }
            }

            Text {
                anchors.centerIn: parent
                text: iconBtn.iconText
                color: tap.pressed ? "#FFFFFF" : root.text
                font.pixelSize: 34
                font.bold: true
            }
        }

        TapHandler {
            id: tap
            gesturePolicy: TapHandler.ReleaseWithinBounds
            onTapped: iconBtn.clicked()
        }
    }

    component StatusMetric: Rectangle {
        id: metric
        property string title: ""
        property string value: ""

        radius: 18
        color: "#080512"
        border.color: root.line
        border.width: 1

        Column {
            anchors.centerIn: parent
            spacing: 5

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: metric.title
                color: root.muted
                font.pixelSize: 8
                font.bold: true
                font.letterSpacing: 1.3
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: metric.value
                color: "#F4EEF7"
                font.pixelSize: 13
                font.bold: true
            }
        }
    }

    component MiniStatusRow: Rectangle {
        id: mini
        property string title: ""
        property string value: ""

        width: parent.width
        height: 34
        radius: 15
        color: "#080512"
        border.color: root.line
        border.width: 1

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            text: mini.title
            color: root.muted
            font.pixelSize: 11
        }

        Text {
            anchors.right: parent.right
            anchors.rightMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            text: mini.value
            color: root.cyan
            font.pixelSize: 12
            font.bold: true
        }
    }

    component SettingsToggleCard: Item {
        id: card
        property string title: ""
        property string subtitle: ""
        property bool checked: false
        signal clicked()

        Rectangle {
            anchors.fill: parent
            radius: 18
            color: tap.pressed ? "#171025" : "#080512"
            border.color: card.checked ? root.violet : root.line
            border.width: 1
            scale: tap.pressed ? 0.985 : 1.0

            Behavior on scale {
                NumberAnimation {
                    duration: 110
                    easing.type: Easing.OutQuad
                }
            }

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 14
                anchors.top: parent.top
                anchors.topMargin: 13
                text: card.title
                color: "#F4EEF7"
                font.pixelSize: 13
                font.bold: true
            }

            Text {
                anchors.left: parent.left
                anchors.leftMargin: 14
                anchors.top: parent.top
                anchors.topMargin: 36
                text: card.subtitle
                color: root.muted
                font.pixelSize: 9
            }

            Rectangle {
                width: 42
                height: 23
                radius: 12
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                color: card.checked ? "#1A1230" : "#0B0712"
                border.color: card.checked ? root.cyan : root.line
                border.width: 1

                Rectangle {
                    width: 17
                    height: 17
                    radius: 9
                    anchors.verticalCenter: parent.verticalCenter
                    x: card.checked ? parent.width - width - 3 : 3
                    color: card.checked ? root.cyan : root.muted

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
            id: tap
            gesturePolicy: TapHandler.ReleaseWithinBounds
            onTapped: card.clicked()
        }
    }

    component AdjustRow: Rectangle {
        id: adjust
        property string title: ""
        property string value: ""
        property int percentValue: 0

        signal minusClicked()
        signal plusClicked()

        radius: 18
        color: "#080512"
        border.color: root.line
        border.width: 1

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 16
            anchors.top: parent.top
            anchors.topMargin: 8
            text: adjust.title
            color: "#F4EEF7"
            font.pixelSize: 11
            font.bold: true
            font.letterSpacing: 1.2
        }

        Text {
            anchors.right: parent.right
            anchors.rightMargin: 86
            anchors.top: parent.top
            anchors.topMargin: 8
            text: adjust.value
            color: root.cyan
            font.pixelSize: 13
            font.bold: true
        }

        Rectangle {
            anchors.left: parent.left
            anchors.leftMargin: 16
            anchors.right: parent.right
            anchors.rightMargin: 96
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 9
            height: 9
            radius: 5
            color: "#120B1E"
            border.color: "#2A1B38"
            border.width: 1

            Rectangle {
                width: parent.width * adjust.percentValue / 100
                height: parent.height
                radius: parent.radius
                color: root.cyan
                opacity: 0.88
            }
        }

        SmallRoundButton {
            width: 31
            height: 27
            anchors.right: plusBtn.left
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            text: "-"
            onClicked: adjust.minusClicked()
        }

        SmallRoundButton {
            id: plusBtn
            width: 31
            height: 27
            anchors.right: parent.right
            anchors.rightMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            text: "+"
            onClicked: adjust.plusClicked()
        }
    }

    component SmallRoundButton: Item {
        id: smallBtn
        property string text: ""
        signal clicked()

        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: tap.pressed ? root.violet : "#171025"
            border.color: tap.pressed ? "#B99CFF" : "#352347"
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: smallBtn.text
                color: "#F4EEF7"
                font.pixelSize: 15
                font.bold: true
            }
        }

        TapHandler {
            id: tap
            gesturePolicy: TapHandler.ReleaseWithinBounds
            onTapped: smallBtn.clicked()
        }
    }
}
