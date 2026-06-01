import QtQuick

Item {
    id: root
    width: 1024
    height: 600

    signal backClicked()

    property color bg: "#07000E"
    property color panel: "#090613"
    property color panel2: "#1C162B"
    property color soft: "#201926"
    property color line: "#342544"
    property color text: "#CBC4CD"
    property color muted: "#8F7AA8"
    property color violet: "#8B5CF6"
    property color cyan: "#21D4FD"

    readonly property bool headlightsOn: lightsController.headlightsOn
    readonly property bool fogLightsOn: lightsController.fogLightsOn
    readonly property bool cabinAmbientOn: lightsController.cabinAmbientOn
    readonly property bool autoMode: lightsController.autoLightsOn
    readonly property int ambientLevel: lightsController.ambientLevel

    Rectangle {
        anchors.fill: parent
        color: root.bg

        Rectangle {
            anchors.fill: parent
            opacity: 0.65
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#10081A" }
                GradientStop { position: 0.52; color: "#07000E" }
                GradientStop { position: 1.0; color: "#050009" }
            }
        }

        Rectangle {
            width: 360
            height: 360
            radius: 180
            x: -120
            y: 120
            color: root.violet
            opacity: 0.055
        }

        Rectangle {
            width: 420
            height: 420
            radius: 210
            anchors.right: parent.right
            anchors.rightMargin: -170
            anchors.top: parent.top
            anchors.topMargin: 45
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
                text: "VEHICLE LIGHTING"
                color: root.muted
                font.pixelSize: 11
                font.bold: true
                font.letterSpacing: 2.4
            }

            Text {
                text: "Lights & Ambient Control"
                color: "#F4EEF7"
                font.pixelSize: 24
                font.bold: true
            }
        }
    }

    Row {
        id: content
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
            width: 344
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
                    GradientStop { position: 0.5; color: "#111023" }
                    GradientStop { position: 1.0; color: "#07000E" }
                }
            }

            Rectangle {
                width: 230
                height: 230
                radius: 115
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 76
                color: root.cyan
                opacity: root.headlightsOn ? 0.06 : 0.02
            }

            Rectangle {
                width: 146
                height: 146
                radius: 73
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 92
                color: "#120A1F"
                border.color: root.headlightsOn ? root.cyan : root.line
                border.width: 2
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 126
                text: "✦"
                color: root.headlightsOn ? root.cyan : root.muted
                font.pixelSize: 66
            }

            Column {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.topMargin: 286
                anchors.leftMargin: 24
                anchors.rightMargin: 24
                spacing: 9

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.headlightsOn ? "HEADLIGHTS ACTIVE" : "HEADLIGHTS OFF"
                    color: "#F4EEF7"
                    font.pixelSize: 22
                    font.bold: true
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.autoMode ? "Auto mode is monitoring external light" : "Manual lighting control"
                    color: root.muted
                    font.pixelSize: 12
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Ambient intensity " + root.ambientLevel + "%"
                    color: root.cyan
                    font.pixelSize: 12
                    opacity: 0.92
                }
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 28
                spacing: 12

                TouchPillButton {
                    width: 128
                    text: root.headlightsOn ? "TURN OFF" : "TURN ON"
                    onClicked: lightsController.toggleHeadlights()
                }

                TouchPillButton {
                    width: 128
                    text: root.autoMode ? "AUTO ON" : "MANUAL"
                    onClicked: lightsController.toggleAutoLights()
                }
            }
        }

        Column {
            width: parent.width - 344 - 22
            height: parent.height
            spacing: 16

            Rectangle {
                width: parent.width
                height: 116
                radius: 26
                color: root.panel
                border.color: root.line
                border.width: 1
                clip: true

                Row {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 12

                    StatusMetric {
                        width: (parent.width - 36) / 4
                        height: 76
                        title: "MODE"
                        value: root.autoMode ? "Auto" : "Manual"
                    }

                    StatusMetric {
                        width: (parent.width - 36) / 4
                        height: 76
                        title: "HEAD"
                        value: root.headlightsOn ? "On" : "Off"
                    }

                    StatusMetric {
                        width: (parent.width - 36) / 4
                        height: 76
                        title: "FOG"
                        value: root.fogLightsOn ? "On" : "Off"
                    }

                    StatusMetric {
                        width: (parent.width - 36) / 4
                        height: 76
                        title: "AMBIENT"
                        value: root.cabinAmbientOn ? root.ambientLevel + "%" : "Off"
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: parent.height - 116 - 16
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
                    anchors.margins: 22
                    spacing: 14

                    Text {
                        text: "LIGHT CONTROLS"
                        color: root.muted
                        font.pixelSize: 11
                        font.bold: true
                        font.letterSpacing: 2.2
                    }

                    Grid {
                        width: parent.width
                        columns: 2
                        rowSpacing: 12
                        columnSpacing: 12

                        LightToggleCard {
                            width: (parent.width - 12) / 2
                            height: 78
                            title: "Headlights"
                            subtitle: "Main beam"
                            checked: root.headlightsOn
                            onClicked: lightsController.toggleHeadlights()
                        }

                        LightToggleCard {
                            width: (parent.width - 12) / 2
                            height: 78
                            title: "Fog Lights"
                            subtitle: "Low visibility"
                            checked: root.fogLightsOn
                            onClicked: lightsController.toggleFogLights()
                        }

                        LightToggleCard {
                            width: (parent.width - 12) / 2
                            height: 78
                            title: "Cabin Ambient"
                            subtitle: "Interior glow"
                            checked: root.cabinAmbientOn
                            onClicked: lightsController.toggleCabinAmbient()
                        }

                        LightToggleCard {
                            width: (parent.width - 12) / 2
                            height: 78
                            title: "Auto Mode"
                            subtitle: "Smart lighting"
                            checked: root.autoMode
                            onClicked: lightsController.toggleAutoLights()
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 78
                        radius: 22
                        color: "#080512"
                        border.color: root.line
                        border.width: 1

                        Column {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.leftMargin: 18
                            anchors.rightMargin: 18
                            spacing: 10

                            Row {
                                width: parent.width
                                height: 24

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "AMBIENT INTENSITY"
                                    color: "#F4EEF7"
                                    font.pixelSize: 13
                                    font.bold: true
                                    font.letterSpacing: 1.1
                                }

                                Text {
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: root.ambientLevel + "%"
                                    color: root.cyan
                                    font.pixelSize: 14
                                    font.bold: true
                                }
                            }

                            Row {
                                width: parent.width
                                height: 26
                                spacing: 12

                                SmallRoundButton {
                                    width: 42
                                    height: 26
                                    text: "-"
                                    onClicked: lightsController.decreaseAmbientLevel()
                                }

                                Rectangle {
                                    width: parent.width - 42 - 42 - 24
                                    height: 12
                                    radius: 6
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: "#120B1E"
                                    border.color: "#2A1B38"
                                    border.width: 1

                                    Rectangle {
                                        width: parent.width * root.ambientLevel / 100
                                        height: parent.height
                                        radius: parent.radius
                                        color: root.cyan
                                        opacity: 0.9
                                    }
                                }

                                SmallRoundButton {
                                    width: 42
                                    height: 26
                                    text: "+"
                                    onClicked: lightsController.increaseAmbientLevel()
                                }
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

    component TouchPillButton: Item {
        id: pill

        property string text: ""
        signal clicked()

        height: 42

        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: tap.pressed ? root.violet : "#171025"
            border.color: tap.pressed ? "#B99CFF" : "#352347"
            border.width: 1
            scale: tap.pressed ? 0.96 : 1.0

            Behavior on scale {
                NumberAnimation {
                    duration: 110
                    easing.type: Easing.OutQuad
                }
            }

            Text {
                anchors.centerIn: parent
                text: pill.text
                color: tap.pressed ? "#FFFFFF" : root.text
                font.pixelSize: 10
                font.bold: true
                font.letterSpacing: 1.6
            }
        }

        TapHandler {
            id: tap
            gesturePolicy: TapHandler.ReleaseWithinBounds
            onTapped: pill.clicked()
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
                font.pixelSize: 16
                font.bold: true
            }
        }

        TapHandler {
            id: tap
            gesturePolicy: TapHandler.ReleaseWithinBounds
            onTapped: smallBtn.clicked()
        }
    }

    component StatusMetric: Rectangle {
        id: metric

        property string title: ""
        property string value: ""

        radius: 20
        color: "#080512"
        border.color: root.line
        border.width: 1

        Column {
            anchors.centerIn: parent
            spacing: 6

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: metric.title
                color: root.muted
                font.pixelSize: 9
                font.bold: true
                font.letterSpacing: 1.6
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: metric.value
                color: "#F4EEF7"
                font.pixelSize: 15
                font.bold: true
            }
        }
    }

    component LightToggleCard: Item {
        id: card

        property string title: ""
        property string subtitle: ""
        property bool checked: false

        signal clicked()

        Rectangle {
            anchors.fill: parent
            radius: 20
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

            Column {
                anchors.left: parent.left
                anchors.leftMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4

                Text {
                    text: card.title
                    color: "#F4EEF7"
                    font.pixelSize: 14
                    font.bold: true
                }

                Text {
                    text: card.subtitle
                    color: root.muted
                    font.pixelSize: 10
                }
            }

            Rectangle {
                width: 50
                height: 28
                radius: 14
                anchors.right: parent.right
                anchors.rightMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                color: card.checked ? "#1A1230" : "#0B0712"
                border.color: card.checked ? root.cyan : root.line
                border.width: 1

                Rectangle {
                    width: 20
                    height: 20
                    radius: 10
                    anchors.verticalCenter: parent.verticalCenter
                    x: card.checked ? parent.width - width - 4 : 4
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
}
