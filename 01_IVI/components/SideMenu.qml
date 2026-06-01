import QtQuick

Item {
    id: root
    width: 238
    height: 444

    signal profileClicked()
    signal assistantClicked()
    signal lightsClicked()
    signal climateClicked()
    signal settingsClicked()

    property color bg: "#07000E"
    property color panel: "#101020"
    property color panel2: "#1C162B"
    property color soft: "#201926"
    property color line: "#342544"
    property color text: "#CBC4CD"
    property color muted: "#8F7AA8"
    property color violet: "#8B5CF6"
    property color violetSoft: "#6D3FB5"
    property color red: "#A6080D"
    property color cyan: "#21D4FD"
    property string profileName: "Abdelfattah"
    property string profileSummary: "Comfort mode · 15 messages"
    property string assistantSummary: "Chat, voice control, vehicle diagnostics and smart navigation."
    property string lightsSubtitle: "Headlights · ambient"
    property string settingsSubtitle: "Vehicle and system"

    readonly property bool compact: height < 470
    readonly property real columnSpacing: compact ? 9 : 11
    readonly property real profileHeight: compact ? 88 : 112
    readonly property real assistantHeight: compact ? 124 : 146
    readonly property real menuButtonHeight: compact ? 56 : 60

    Column {
        anchors.fill: parent
        spacing: root.columnSpacing

        // Profile premium glass card
        Rectangle {
            id: profileCard
            width: parent.width
            height: root.profileHeight
            radius: root.compact ? 22 : 26
            clip: true
            color: "#0B0714"
            border.color: profileTap.pressed ? root.violet : root.line
            border.width: 1
            scale: profileTap.pressed ? 0.985 : 1.0
            transformOrigin: Item.Center

            Behavior on scale {
                NumberAnimation {
                    duration: 120
                    easing.type: Easing.OutQuad
                }
            }

            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                opacity: profileTap.pressed ? 0.32 : 0.18
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#2A1742" }
                    GradientStop { position: 0.55; color: "#151023" }
                    GradientStop { position: 1.0; color: "#080512" }
                }
            }

            Rectangle {
                width: root.compact ? 70 : 92
                height: width
                radius: width / 2
                anchors.left: parent.left
                anchors.leftMargin: root.compact ? -14 : -18
                anchors.verticalCenter: parent.verticalCenter
                color: root.violet
                opacity: 0.055
            }

            Item {
                id: avatar
                width: root.compact ? 54 : 64
                height: width
                anchors.left: parent.left
                anchors.leftMargin: root.compact ? 16 : 22
                anchors.verticalCenter: parent.verticalCenter

                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: "#140C22"
                    border.color: profileTap.pressed ? "#B99CFF" : root.violet
                    border.width: 1
                    opacity: 0.95
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: root.compact ? 44 : 52
                    height: width
                    radius: width / 2
                    color: "#21152F"
                }

                Rectangle {
                    width: root.compact ? 16 : 20
                    height: width
                    radius: width / 2
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: root.compact ? 11 : 13
                    color: root.text
                    opacity: 0.9
                }

                Rectangle {
                    width: root.compact ? 30 : 36
                    height: root.compact ? 15 : 18
                    radius: height / 2
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: root.compact ? 9 : 11
                    color: root.text
                    opacity: 0.9
                }

                Rectangle {
                    width: 9
                    height: 9
                    radius: 5
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    color: root.cyan
                    border.color: "#07000E"
                    border.width: 2
                }
            }

            Column {
                anchors.left: avatar.right
                anchors.leftMargin: root.compact ? 12 : 18
                anchors.right: parent.right
                anchors.rightMargin: root.compact ? 14 : 20
                anchors.verticalCenter: parent.verticalCenter
                spacing: root.compact ? 4 : 5

                Text {
                    text: "DRIVER PROFILE"
                    color: root.muted
                    font.pixelSize: root.compact ? 9 : 10
                    font.letterSpacing: root.compact ? 2.0 : 2.6
                    opacity: 0.92
                }

                Text {
                    text: root.profileName.length > 0 ? "Hi, " + root.profileName : "Hi"
                    color: "#F4EEF7"
                    font.pixelSize: root.compact ? 17 : 22
                    font.bold: true
                }

                Text {
                    text: root.profileSummary
                    color: root.muted
                    font.pixelSize: root.compact ? 10 : 12
                    opacity: 0.9
                }
            }

            TapHandler {
                id: profileTap
                gesturePolicy: TapHandler.ReleaseWithinBounds
                onTapped: root.profileClicked()
            }
        }

        // AI Assistant hero card
        Rectangle {
            id: assistantCard
            width: parent.width
            height: root.assistantHeight
            radius: root.compact ? 22 : 28
            clip: true
            color: "#080512"
            border.color: assistantTap.pressed ? root.violet : root.line
            border.width: 1
            scale: assistantTap.pressed ? 0.985 : 1.0
            transformOrigin: Item.Center

            Behavior on scale {
                NumberAnimation {
                    duration: 120
                    easing.type: Easing.OutQuad
                }
            }

            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#241238" }
                    GradientStop { position: 0.45; color: "#111023" }
                    GradientStop { position: 1.0; color: "#07000E" }
                }
                opacity: assistantTap.pressed ? 0.78 : 0.58
            }

            Rectangle {
                width: root.compact ? 112 : 150
                height: width
                radius: width / 2
                anchors.right: parent.right
                anchors.rightMargin: root.compact ? -34 : -48
                anchors.top: parent.top
                anchors.topMargin: root.compact ? -32 : -42
                color: root.violet
                opacity: assistantTap.pressed ? 0.11 : 0.055
            }

            Rectangle {
                width: root.compact ? 58 : 70
                height: width
                radius: width / 2
                anchors.right: parent.right
                anchors.rightMargin: root.compact ? 14 : 18
                anchors.verticalCenter: parent.verticalCenter
                color: "#110A1D"
                border.color: assistantTap.pressed ? "#8B5CF6" : "#4B2C73"
                border.width: 1
                opacity: 0.9

                Image {
                    anchors.centerIn: parent
                    width: root.compact ? 42 : 46
                    height: width

                    source: "qrc:/qt/qml/GP_IVI/assets/icons/ai_assistant.svg"
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    mipmap: true
                    opacity: assistantTap.pressed ? 1.0 : 0.88

                    sourceSize.width: 96
                    sourceSize.height: 96
                }
            }

            Column {
                anchors.left: parent.left
                anchors.leftMargin: root.compact ? 18 : 24
                anchors.right: parent.right
                anchors.rightMargin: root.compact ? 82 : 92
                anchors.verticalCenter: parent.verticalCenter
                spacing: root.compact ? 9 : 12

                Text {
                    text: "AI COPILOT"
                    color: "#F4EEF7"
                    font.pixelSize: root.compact ? 15 : 18
                    font.bold: true
                    font.letterSpacing: root.compact ? 2.4 : 3
                }

                Text {
                    width: parent.width
                    text: root.assistantSummary
                    color: root.muted
                    font.pixelSize: root.compact ? 10 : 12
                    lineHeight: 1.25
                    wrapMode: Text.WordWrap
                    opacity: 0.95
                }

                Rectangle {
                    width: root.compact ? 126 : 150
                    height: root.compact ? 30 : 34
                    radius: height / 2
                    color: assistantTap.pressed ? root.violet : "#171025"
                    border.color: assistantTap.pressed ? "#B99CFF" : "#352347"
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "OPEN ASSISTANT"
                        color: assistantTap.pressed ? "#FFFFFF" : root.text
                        font.pixelSize: root.compact ? 9 : 10
                        font.bold: true
                        font.letterSpacing: root.compact ? 1.2 : 1.6
                    }
                }
            }

            TapHandler {
                id: assistantTap
                gesturePolicy: TapHandler.ReleaseWithinBounds
                onTapped: root.assistantClicked()
            }
        }

        PremiumMenuButton {
            title: "LIGHTS"
            subtitle: root.lightsSubtitle
            iconType: "light"
            onClicked: root.lightsClicked()
        }

        PremiumMenuButton {
            title: "CLIMATE"
            subtitle: "Cabin comfort"
            iconType: "climate"
            onClicked: root.climateClicked()
        }

        PremiumMenuButton {
            title: "SETTINGS"
            subtitle: root.settingsSubtitle
            iconType: "settings"
            onClicked: root.settingsClicked()
        }
    }

    component PremiumMenuButton: Item {
        id: item
        width: root.width
        height: root.menuButtonHeight

        property string title: ""
        property string subtitle: ""
        property string iconType: ""

        signal clicked()

        Rectangle {
            anchors.fill: parent
            radius: 22
            color: "#090613"
            border.color: btnTap.pressed ? root.violetSoft : root.line
            border.width: 1
            scale: btnTap.pressed ? 0.985 : 1.0
            transformOrigin: Item.Center

            Behavior on scale {
                NumberAnimation {
                    duration: 120
                    easing.type: Easing.OutQuad
                }
            }

            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                opacity: btnTap.pressed ? 0.38 : 0.18
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#20142F" }
                    GradientStop { position: 1.0; color: "#090613" }
                }
            }

            Rectangle {
                width: 3
                height: 30
                radius: 2
                anchors.left: parent.left
                anchors.leftMargin: 1
                anchors.verticalCenter: parent.verticalCenter
                color: root.violet
                opacity: btnTap.pressed ? 0.9 : 0.0

                Behavior on opacity {
                    NumberAnimation {
                        duration: 120
                    }
                }
            }

            Rectangle {
                id: iconBox
                width: root.compact ? 36 : 38
                height: root.compact ? 36 : 38
                radius: root.compact ? 13 : 14
                anchors.left: parent.left
                anchors.leftMargin: root.compact ? 14 : 18
                anchors.verticalCenter: parent.verticalCenter
                color: btnTap.pressed ? "#201230" : "#130D20"
                border.color: btnTap.pressed ? root.violet : "#352347"
                border.width: 1

                Image {
                    id: menuIconImage
                    anchors.centerIn: parent
                    width: iconImageSize()
                    height: iconImageSize()

                    source: iconSource()
                    visible: source !== ""
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    mipmap: true
                    opacity: btnTap.pressed ? 1.0 : 0.86

                    sourceSize.width: 96
                    sourceSize.height: 96
                }
            }

            Column {
                anchors.left: iconBox.right
                anchors.leftMargin: root.compact ? 12 : 16
                anchors.verticalCenter: parent.verticalCenter
                spacing: root.compact ? 3 : 4

                Text {
                    text: item.title
                    color: "#F4EEF7"
                    font.pixelSize: root.compact ? 12 : 14
                    font.bold: true
                    font.letterSpacing: root.compact ? 1.9 : 2.4
                }

                Text {
                    text: item.subtitle
                    color: root.muted
                    font.pixelSize: root.compact ? 10 : 11
                    opacity: 0.9
                }
            }

            Text {
                anchors.right: parent.right
                anchors.rightMargin: root.compact ? 14 : 20
                anchors.verticalCenter: parent.verticalCenter
                text: "›"
                color: btnTap.pressed ? root.violet : root.muted
                font.pixelSize: root.compact ? 21 : 24
            }
        }

        function iconSource() {
            if (item.iconType === "light")
                return "qrc:/qt/qml/GP_IVI/assets/icons/light.png"
            if (item.iconType === "climate")
                return "qrc:/qt/qml/GP_IVI/assets/icons/climate_fan.svg"
            if (item.iconType === "settings")
                return "qrc:/qt/qml/GP_IVI/assets/icons/settings_gear.svg"
            return ""
        }

        function iconImageSize() {
            if (item.iconType === "light")
                return root.compact ? 28 : 30
            if (item.iconType === "climate")
                return root.compact ? 25 : 27
            if (item.iconType === "settings")
                return root.compact ? 25 : 27
            return 25
        }

        TapHandler {
            id: btnTap
            gesturePolicy: TapHandler.ReleaseWithinBounds
            onTapped: item.clicked()
        }
    }
}
