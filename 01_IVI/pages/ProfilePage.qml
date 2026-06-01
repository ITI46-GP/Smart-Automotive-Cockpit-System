pragma ComponentBehavior: Bound

import QtQuick
Item {
    id: root
    width: 1024
    height: 600

    signal backClicked()
    signal editProfileClicked()
    signal switchProfileClicked(string profileName)

    property color bg: "#07000E"
    property color panel: "#090613"
    property color panel2: "#1C162B"
    property color soft: "#201926"
    property color line: "#342544"
    property color text: "#CBC4CD"
    property color muted: "#8F7AA8"
    property color violet: "#8B5CF6"
    property color cyan: "#21D4FD"
    property color red: "#A6080D"
    readonly property string activeProfileName: profileManager.activeProfileName
    readonly property string activeProfileRole: profileManager.activeProfileRole
    property bool editPanelOpen: false

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
            x: -120
            y: 60
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
            anchors.topMargin: 80
            color: root.cyan
            opacity: 0.035
        }
    }

    // Header
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
                text: "DRIVER PROFILE"
                color: root.muted
                font.pixelSize: 11
                font.bold: true
                font.letterSpacing: 2.4
            }

            Text {
                text: "Profile & Comfort Settings"
                color: "#F4EEF7"
                font.pixelSize: 24
                font.bold: true
            }
        }

    }

    // Main content
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

        // Profile card
        Rectangle {
            width: 370
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
                width: 190
                height: 190
                radius: 95
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 38
                color: root.violet
                opacity: 0.075
            }

            Item {
                id: bigAvatar
                width: 132
                height: 132
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 56

                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: "#140C22"
                    border.color: root.violet
                    border.width: 2
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: 104
                    height: 104
                    radius: 52
                    color: "#21152F"
                }

                Rectangle {
                    width: 38
                    height: 38
                    radius: 19
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: 28
                    color: root.text
                    opacity: 0.9
                }

                Rectangle {
                    width: 72
                    height: 34
                    radius: 17
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 25
                    color: root.text
                    opacity: 0.9
                }

                Rectangle {
                    width: 14
                    height: 14
                    radius: 7
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.rightMargin: 12
                    anchors.bottomMargin: 14
                    color: root.cyan
                    border.color: root.bg
                    border.width: 3
                }
            }

            Column {
                anchors.top: bigAvatar.bottom
                anchors.topMargin: 24
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 8

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.activeProfileName
                    color: "#F4EEF7"
                    font.pixelSize: 28
                    font.bold: true
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.activeProfileRole
                    color: root.muted
                    font.pixelSize: 13
                    font.letterSpacing: 1.2
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: profileManager.activeDriveMode + " · " + profileManager.activeSeatPreset + " · " + profileManager.activeDriverTemp + "°"
                    color: root.cyan
                    font.pixelSize: 12
                    opacity: 0.9
                }
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 30
                spacing: 14

                TouchPillButton {
                    text: "EDIT"
                    width: 118
                    onClicked: {
                        root.editPanelOpen = true
                        root.editProfileClicked()
                    }
                }

                TouchPillButton {
                    text: "SWITCH"
                    width: 126
                    onClicked: profileManager.switchProfile(root.activeProfileName === "Guest" ? "Abdelfattah" : "Guest")
                }
            }
        }

        // Settings / profile data
        Column {
            width: parent.width - 370 - 22
            height: parent.height
            spacing: 18

            Rectangle {
                width: parent.width
                height: 142
                radius: 26
                color: root.panel
                border.color: root.line
                border.width: 1

                Column {
                    anchors.left: parent.left
                    anchors.leftMargin: 26
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 10

                    Text {
                        text: "PROFILE SUMMARY"
                        color: root.muted
                        font.pixelSize: 11
                        font.bold: true
                        font.letterSpacing: 2.2
                    }

                    Row {
                        spacing: 18

                        SummaryMetric {
                            title: "MODE"
                            value: profileManager.activeDriveMode
                        }

                        SummaryMetric {
                            title: "SEAT"
                            value: profileManager.activeSeatPreset
                        }

                        SummaryMetric {
                            title: "CLIMATE"
                            value: profileManager.activeDriverTemp + "°/" + profileManager.activePassengerTemp + "°"
                        }

                        SummaryMetric {
                            title: "MEDIA"
                            value: profileManager.activeMediaPreset
                        }
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: parent.height - 142 - 18
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
                    anchors.margins: 24
                    spacing: 14

                    Text {
                        text: "AVAILABLE PROFILES"
                        color: root.muted
                        font.pixelSize: 11
                        font.bold: true
                        font.letterSpacing: 2.2
                    }

                    ProfileRow {
                        name: "Abdelfattah"
                        role: "Primary driver"
                        active: root.activeProfileName === "Abdelfattah"
                        onClicked: profileManager.switchProfile("Abdelfattah")
                    }

                    ProfileRow {
                        name: "Guest"
                        role: "Temporary profile"
                        active: root.activeProfileName === "Guest"
                        onClicked: profileManager.switchProfile("Guest")
                    }

                    ProfileRow {
                        name: "Family"
                        role: "Shared comfort settings"
                        active: root.activeProfileName === "Family"
                        onClicked: profileManager.switchProfile("Family")
                    }

                    Item {
                        width: 1
                        height: 8
                    }

                    TouchPillButton {
                        width: 178
                        height: 42
                        text: "+ ADD PROFILE"
                        onClicked: console.log("TODO: add profile UI is not connected yet")
                    }
                }
            }
        }
    }

    Item {
        id: editOverlay
        anchors.fill: parent
        z: 40
        visible: root.editPanelOpen
        enabled: visible

        Rectangle {
            anchors.fill: parent
            color: "#000000"
            opacity: 0.64
        }

        Rectangle {
            width: 820
            height: 470
            anchors.centerIn: parent
            radius: 28
            color: root.panel
            border.color: root.violet
            border.width: 1
            clip: true

            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                opacity: 0.38
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#241238" }
                    GradientStop { position: 0.55; color: "#111023" }
                    GradientStop { position: 1.0; color: "#07000E" }
                }
            }

            Column {
                anchors.fill: parent
                anchors.margins: 24
                spacing: 16

                Row {
                    width: parent.width
                    height: 42

                    Column {
                        width: parent.width - closeEditButton.width
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 3

                        Text {
                            text: "EDIT PROFILE SETUP"
                            color: root.muted
                            font.pixelSize: 10
                            font.bold: true
                            font.letterSpacing: 2.2
                        }

                        Text {
                            text: root.activeProfileName + " · " + root.activeProfileRole
                            color: "#F4EEF7"
                            font.pixelSize: 19
                            font.bold: true
                        }
                    }

                    TouchPillButton {
                        id: closeEditButton
                        width: 102
                        height: 38
                        text: "DONE"
                        onClicked: root.editPanelOpen = false
                    }
                }

                Row {
                    width: parent.width
                    height: parent.height - 58
                    spacing: 18

                    Column {
                        width: (parent.width - parent.spacing) / 2
                        height: parent.height
                        spacing: 11

                        SectionLabel {
                            text: "DRIVE & CABIN"
                        }

                        OptionGroup {
                            width: parent.width
                            height: 64
                            title: "DRIVE MODE"
                            options: ["Comfort", "Sport", "Eco"]
                            currentValue: profileManager.activeDriveMode
                            onSelected: function(value) {
                                profileManager.setActiveDriveMode(value)
                            }
                        }

                        OptionGroup {
                            width: parent.width
                            height: 64
                            title: "SEAT PRESET"
                            options: ["Relax", "Normal", "Focus"]
                            currentValue: profileManager.activeSeatPreset
                            onSelected: function(value) {
                                profileManager.setActiveSeatPreset(value)
                            }
                        }

                        StepEditRow {
                            width: parent.width
                            height: 48
                            title: "DRIVER TEMP"
                            value: profileManager.activeDriverTemp + "°"
                            onMinusClicked: profileManager.setActiveDriverTemp(profileManager.activeDriverTemp - 1)
                            onPlusClicked: profileManager.setActiveDriverTemp(profileManager.activeDriverTemp + 1)
                        }

                        StepEditRow {
                            width: parent.width
                            height: 48
                            title: "PASSENGER TEMP"
                            value: profileManager.activePassengerTemp + "°"
                            onMinusClicked: profileManager.setActivePassengerTemp(profileManager.activePassengerTemp - 1)
                            onPlusClicked: profileManager.setActivePassengerTemp(profileManager.activePassengerTemp + 1)
                        }
                    }

                    Column {
                        width: (parent.width - parent.spacing) / 2
                        height: parent.height
                        spacing: 11

                        SectionLabel {
                            text: "MEDIA & SYSTEM"
                        }

                        OptionGroup {
                            width: parent.width
                            height: 64
                            title: "MEDIA SOURCE"
                            options: ["Radio", "USB", "Bluetooth"]
                            currentValue: profileManager.activeMediaSource
                            onSelected: function(value) {
                                profileManager.setActiveMediaSource(value)
                            }
                        }

                        OptionGroup {
                            width: parent.width
                            height: 64
                            title: "MEDIA PRESET"
                            options: ["Night Drive", "Quran", "Favorites"]
                            currentValue: profileManager.activeMediaPreset
                            onSelected: function(value) {
                                profileManager.setActiveMediaPreset(value)
                            }
                        }

                        ToggleEditRow {
                            width: parent.width
                            height: 44
                            title: "DARK MODE"
                            checked: profileManager.activeDarkMode
                            onClicked: profileManager.setActiveDarkMode(!profileManager.activeDarkMode)
                        }

                        ToggleEditRow {
                            width: parent.width
                            height: 44
                            title: "VOICE ENABLED"
                            checked: profileManager.activeVoiceEnabled
                            onClicked: profileManager.setActiveVoiceEnabled(!profileManager.activeVoiceEnabled)
                        }

                        AmbientEditRow {
                            width: parent.width
                            height: 62
                            title: "AMBIENT LEVEL"
                            value: profileManager.activeAmbientLevel + "%"
                            percentValue: profileManager.activeAmbientLevel
                            onMinusClicked: profileManager.setActiveAmbientLevel(profileManager.activeAmbientLevel - 8)
                            onPlusClicked: profileManager.setActiveAmbientLevel(profileManager.activeAmbientLevel + 8)
                        }
                    }
                }
            }
        }
    }

    component SectionLabel: Text {
        color: root.muted
        font.pixelSize: 10
        font.bold: true
        font.letterSpacing: 2.0
    }

    component OptionGroup: Rectangle {
        id: optionGroup

        property string title: ""
        property var options: []
        property string currentValue: ""

        signal selected(string value)

        radius: 18
        color: "#080512"
        border.color: root.line
        border.width: 1

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 14
            anchors.top: parent.top
            anchors.topMargin: 10
            text: optionGroup.title
            color: root.muted
            font.pixelSize: 9
            font.bold: true
            font.letterSpacing: 1.3
        }

        Row {
            id: optionButtons
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            anchors.bottomMargin: 9
            height: 28
            spacing: 8

            Repeater {
                model: optionGroup.options

                OptionChoiceButton {
                    required property string modelData

                    width: (optionButtons.width - optionButtons.spacing * Math.max(0, optionGroup.options.length - 1)) / Math.max(1, optionGroup.options.length)
                    height: optionButtons.height
                    label: modelData
                    active: modelData === optionGroup.currentValue
                    onClicked: optionGroup.selected(modelData)
                }
            }
        }
    }

    component OptionChoiceButton: Item {
        id: choice

        property string label: ""
        property bool active: false

        signal clicked()

        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: choiceTap.pressed ? root.violet : (choice.active ? "#15102A" : "#171025")
            border.color: choice.active ? root.cyan : "#352347"
            border.width: 1
            scale: choiceTap.pressed ? 0.96 : 1.0

            Behavior on scale {
                NumberAnimation {
                    duration: 100
                    easing.type: Easing.OutQuad
                }
            }

            Text {
                anchors.centerIn: parent
                text: choice.label
                color: choice.active ? root.cyan : root.text
                font.pixelSize: choice.label.length > 9 ? 8 : 9
                font.bold: true
                font.letterSpacing: 1.0
                elide: Text.ElideRight
                width: parent.width - 10
                horizontalAlignment: Text.AlignHCenter
            }
        }

        TapHandler {
            id: choiceTap
            gesturePolicy: TapHandler.ReleaseWithinBounds
            onTapped: choice.clicked()
        }
    }

    component StepEditRow: Rectangle {
        id: stepRow

        property string title: ""
        property string value: ""

        signal minusClicked()
        signal plusClicked()

        radius: 18
        color: "#080512"
        border.color: root.line
        border.width: 1

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            text: stepRow.title
            color: "#F4EEF7"
            font.pixelSize: 11
            font.bold: true
            font.letterSpacing: 1.2
        }

        Text {
            anchors.right: minusButton.left
            anchors.rightMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            text: stepRow.value
            color: root.cyan
            font.pixelSize: 14
            font.bold: true
        }

        RoundEditButton {
            id: minusButton
            width: 32
            height: 28
            anchors.right: plusButton.left
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            text: "-"
            onClicked: stepRow.minusClicked()
        }

        RoundEditButton {
            id: plusButton
            width: 32
            height: 28
            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            text: "+"
            onClicked: stepRow.plusClicked()
        }
    }

    component ToggleEditRow: Rectangle {
        id: toggleRow

        property string title: ""
        property bool checked: false

        signal clicked()

        radius: 18
        color: "#080512"
        border.color: root.line
        border.width: 1

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            text: toggleRow.title
            color: "#F4EEF7"
            font.pixelSize: 11
            font.bold: true
            font.letterSpacing: 1.2
        }

        Rectangle {
            width: 48
            height: 26
            radius: 13
            anchors.right: parent.right
            anchors.rightMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            color: toggleRow.checked ? "#1A1230" : "#0B0712"
            border.color: toggleRow.checked ? root.cyan : root.line
            border.width: 1

            Rectangle {
                width: 18
                height: 18
                radius: 9
                anchors.verticalCenter: parent.verticalCenter
                x: toggleRow.checked ? parent.width - width - 4 : 4
                color: toggleRow.checked ? root.cyan : root.muted

                Behavior on x {
                    NumberAnimation {
                        duration: 130
                        easing.type: Easing.OutQuad
                    }
                }
            }
        }

        TapHandler {
            gesturePolicy: TapHandler.ReleaseWithinBounds
            onTapped: toggleRow.clicked()
        }
    }

    component AmbientEditRow: Rectangle {
        id: ambientRow

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
            anchors.leftMargin: 14
            anchors.top: parent.top
            anchors.topMargin: 9
            text: ambientRow.title
            color: "#F4EEF7"
            font.pixelSize: 11
            font.bold: true
            font.letterSpacing: 1.1
        }

        Text {
            anchors.right: parent.right
            anchors.rightMargin: 84
            anchors.top: parent.top
            anchors.topMargin: 9
            text: ambientRow.value
            color: root.cyan
            font.pixelSize: 13
            font.bold: true
        }

        Rectangle {
            anchors.left: parent.left
            anchors.leftMargin: 14
            anchors.right: parent.right
            anchors.rightMargin: 94
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 11
            height: 9
            radius: 5
            color: "#120B1E"
            border.color: "#2A1B38"
            border.width: 1

            Rectangle {
                width: parent.width * ambientRow.percentValue / 100
                height: parent.height
                radius: parent.radius
                color: root.cyan
                opacity: 0.88
            }
        }

        RoundEditButton {
            width: 31
            height: 27
            anchors.right: plusButton.left
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            text: "-"
            onClicked: ambientRow.minusClicked()
        }

        RoundEditButton {
            id: plusButton
            width: 31
            height: 27
            anchors.right: parent.right
            anchors.rightMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            text: "+"
            onClicked: ambientRow.plusClicked()
        }
    }

    component RoundEditButton: Item {
        id: roundButton

        property string text: ""

        signal clicked()

        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: roundTap.pressed ? root.violet : "#171025"
            border.color: roundTap.pressed ? "#B99CFF" : "#352347"
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: roundButton.text
                color: "#F4EEF7"
                font.pixelSize: 15
                font.bold: true
            }
        }

        TapHandler {
            id: roundTap
            gesturePolicy: TapHandler.ReleaseWithinBounds
            onTapped: roundButton.clicked()
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

    component TouchPillButton: Item {
        id: pill

        property string text: ""
        signal clicked()

        width: 120
        height: 40

        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: pillTap.pressed ? root.violet : "#171025"
            border.color: pillTap.pressed ? "#B99CFF" : "#352347"
            border.width: 1
            scale: pillTap.pressed ? 0.96 : 1.0

            Behavior on scale {
                NumberAnimation {
                    duration: 110
                    easing.type: Easing.OutQuad
                }
            }

            Text {
                anchors.centerIn: parent
                text: pill.text
                color: pillTap.pressed ? "#FFFFFF" : root.text
                font.pixelSize: 10
                font.bold: true
                font.letterSpacing: 1.6
            }
        }

        TapHandler {
            id: pillTap
            gesturePolicy: TapHandler.ReleaseWithinBounds
            onTapped: pill.clicked()
        }
    }

    component SummaryMetric: Rectangle {
        id: metric

        property string title: ""
        property string value: ""

        width: 112
        height: 58
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
                font.pixelSize: 9
                font.bold: true
                font.letterSpacing: 1.6
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

    component ProfileRow: Item {
        id: row

        property string name: ""
        property string role: ""
        property bool active: false

        signal clicked()

        width: parent.width
        height: 68

        Rectangle {
            anchors.fill: parent
            radius: 20
            color: profileRowTap.pressed ? "#171025" : (row.active ? "#100A1C" : "#080512")
            border.color: row.active ? root.violet : root.line
            border.width: 1
            scale: profileRowTap.pressed ? 0.985 : 1.0

            Behavior on scale {
                NumberAnimation {
                    duration: 110
                    easing.type: Easing.OutQuad
                }
            }

            Rectangle {
                width: 42
                height: 42
                radius: 21
                anchors.left: parent.left
                anchors.leftMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                color: "#21152F"
                border.color: row.active ? root.cyan : "#352347"
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: row.name.length > 0 ? row.name[0] : "?"
                    color: "#F4EEF7"
                    font.pixelSize: 17
                    font.bold: true
                }
            }

            Column {
                anchors.left: parent.left
                anchors.leftMargin: 72
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4

                Text {
                    text: row.name
                    color: "#F4EEF7"
                    font.pixelSize: 15
                    font.bold: true
                }

                Text {
                    text: row.role
                    color: root.muted
                    font.pixelSize: 11
                }
            }

            Text {
                anchors.right: parent.right
                anchors.rightMargin: 18
                anchors.verticalCenter: parent.verticalCenter
                text: row.active ? "ACTIVE" : "›"
                color: row.active ? root.cyan : root.muted
                font.pixelSize: row.active ? 10 : 24
                font.bold: true
                font.letterSpacing: row.active ? 1.4 : 0
            }
        }

        TapHandler {
            id: profileRowTap
            gesturePolicy: TapHandler.ReleaseWithinBounds
            onTapped: row.clicked()
        }
    }
}
