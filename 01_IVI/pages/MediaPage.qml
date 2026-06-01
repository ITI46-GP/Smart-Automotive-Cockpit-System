import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Effects
import QtMultimedia

Item {
    id: root
    width: 1024
    height: 600

    signal backClicked()

    Component.onDestruction: {
        if (audioManager) {
            audioManager.togglePlayPause()
        }
    }

    Component.onCompleted: {
        if (audioManager && audioManager.currentSource === "") {
            audioManager.setSource(0)  // 0 = Radio
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "#07000E"
    }

    // Back button
    Rectangle {
        id: backBtn
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.topMargin: 20
        anchors.leftMargin: 20
        width: 44
        height: 44
        radius: 12
        color: backTap.pressed ? "#1C162B" : "#090613"
        border.color: "#342544"
        border.width: 1

        Text {
            anchors.centerIn: parent
            text: "<"
            color: "#CBC4CD"
            font.pixelSize: 18
            font.bold: true
        }

        TapHandler {
            id: backTap
            onTapped: root.backClicked()
        }
    }

    Text {
        anchors.top: parent.top
        anchors.topMargin: 28
        anchors.horizontalCenter: parent.horizontalCenter
        text: "Media Player"
        color: "#CBC4CD"
        font.pixelSize: 20
        font.bold: true
        font.letterSpacing: 0.5
    }

    RowLayout {
        anchors.top: backBtn.bottom
        anchors.topMargin: 16
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 16
        spacing: 0

        // --- Left Sidebar (Source Selection) ---
        Rectangle {
            Layout.preferredWidth: 205
            Layout.fillHeight: true
            color: "#0A0A1B"

            ColumnLayout {
                anchors.fill: parent
                anchors.topMargin: 22
                anchors.bottomMargin: 22
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                spacing: 6

                RowLayout {
                    spacing: 10
                    Layout.bottomMargin: 8

                    Rectangle {
                        width: 34; height: 34; radius: 10
                        color: "#A6080D18"
                        border.color: "#A6080D40"; border.width: 1

                        Image {
                            source: "qrc:/qt/qml/GP_IVI/assets/icons/2285924901582793664-128.png"
                            anchors.centerIn: parent
                            width: 22; height: 22
                            fillMode: Image.PreserveAspectFit
                        }
                    }

                    Text {
                        text: "My Player"
                        color: "#CBC4CD"
                        font.pixelSize: 16
                        font.bold: true
                        font.letterSpacing: 0.4
                    }
                }

                Rectangle {
                    Layout.fillWidth: true; height: 1
                    color: "#1C162B"
                    Layout.bottomMargin: 4
                }

                Repeater {
                    model: [
                        { label: "Player", source: "Bluetooth", icon: "qrc:/qt/qml/GP_IVI/assets/icons/Bluetooth.png", type: 2 },
                        { label: "Radio",  source: "Radio",     icon: "qrc:/qt/qml/GP_IVI/assets/icons/radio.png",      type: 0 },
                        { label: "USB",    source: "USB",       icon: "qrc:/qt/qml/GP_IVI/assets/icons/usb.png",        type: 1 }
                    ]

                    delegate: Rectangle {
                        Layout.fillWidth: true
                        height: 54
                        radius: 12
                        color: audioManager.currentSource === modelData.source
                               ? "#A6080D22" : "#1C162B30"
                        border.color: audioManager.currentSource === modelData.source
                                      ? "#0A0A1B" : "#1C162B"
                        border.width: audioManager.currentSource === modelData.source ? 1.5 : 1

                        Rectangle {
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: parent.height * 0.45
                            radius: 12
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: "#1C162B" }
                                GradientStop { position: 1.0; color: "transparent" }
                            }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 10

                            Rectangle {
                                width: 4; height: 26; radius: 2
                                color: audioManager.currentSource === modelData.source
                                       ? "#A6080D" : "transparent"
                            }

                            Image {
                                id: navIcon
                                source: modelData.icon
                                width: 20; height: 20
                                fillMode: Image.PreserveAspectFit
                                visible: false
                            }
                            MultiEffect {
                                width: 20; height: 20
                                source: navIcon
                                colorization: 1.0
                                colorizationColor: audioManager.currentSource === modelData.source
                                                   ? "#A6080D" : "#1C162B30"
                                NumberAnimation on opacity {
                                    running: modelData.source === "Bluetooth" && audioManager.btSearching
                                    from: 1.0; to: 0.2; duration: 800; loops: Animation.Infinite
                                }
                            }

                            Text {
                                text: modelData.label
                                color: "#CBC4CD"
                                font.pixelSize: 13
                                font.bold: audioManager.currentSource === modelData.source
                                Layout.fillWidth: true
                            }

                            Rectangle {
                                visible: modelData.source === "Bluetooth" && audioManager.btSearching
                                width: 6; height: 6; radius: 3
                                color: "#A6080D"
                                SequentialAnimation on opacity {
                                    running: parent.visible; loops: Animation.Infinite
                                    NumberAnimation { from: 1; to: 0.2; duration: 500 }
                                    NumberAnimation { from: 0.2; to: 1; duration: 500 }
                                }
                            }
                        }

                        TapHandler {
                            onTapped: {
                                if (modelData.source === "Bluetooth") {
                                    if (audioManager.currentSource !== "Bluetooth")
                                        audioManager.setSource(modelData.type)
                                    btSheet.open()
                                } else {
                                    audioManager.setSource(modelData.type)
                                }
                            }
                        }
                    }
                }

                Item { Layout.fillHeight: true }
            }
        }

        // --- Divider ---
        Rectangle {
            Layout.preferredWidth: 1
            Layout.fillHeight: true
            gradient: Gradient {
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.25; color: "#0A0A1B" }
                GradientStop { position: 0.75; color: "#0A0A1B" }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }

        // --- Main Content ---
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: 16
            spacing: 8

            // --- Album Art / Video Area ---
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 20
                clip: true
                color: "#1C162B"
                border.color: "#342544"; border.width: 1

                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left; anchors.right: parent.right
                    height: parent.height * 0.38; radius: 20
                    visible: !videoOut.visible
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "#0A0A1B" }
                        GradientStop { position: 1.0; color: "transparent" }
                    }
                    z: 1
                }

                VideoOutput {
                    id: videoOut
                    anchors.fill: parent
                    visible: audioManager ? (audioManager.currentSource === "USB" && audioManager.isVideo) : false
                    z: 2
                    fillMode: VideoOutput.PreserveAspectFit
                    Component.onCompleted: audioManager.bindVideoOutput(videoOut)
                }

                Image {
                    id: artImg
                    source: "qrc:/qt/qml/GP_IVI/assets/icons/2285924901582793664-128.png"
                    anchors.centerIn: parent
                    width: Math.min(parent.width * 0.52, parent.height * 0.72)
                    height: width
                    fillMode: Image.PreserveAspectFit
                    opacity: 0.95
                    visible: !videoOut.visible
                    z: 2
                }

                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left; anchors.right: parent.right
                    height: parent.height * 0.5
                    visible: !videoOut.visible
                    z: 3
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "transparent" }
                        GradientStop { position: 0.5; color: "#07000EBB" }
                        GradientStop { position: 1.0; color: "#07000E" }
                    }
                }

                Rectangle {
                    visible: audioManager.btSearching && !videoOut.visible
                    anchors.centerIn: parent
                    width: artImg.width + 22; height: width; radius: width / 2
                    color: "transparent"
                    border.color: "#A6080D"; border.width: 2.5; opacity: 0.75
                    z: 4
                    RotationAnimation on rotation {
                        running: parent.visible; from: 0; to: 360
                        duration: 1400; loops: Animation.Infinite
                    }
                }

                Rectangle {
                    visible: !videoOut.visible
                    anchors.centerIn: parent
                    width: artImg.width + 18; height: width; radius: width / 2
                    color: "transparent"
                    border.color: "#A6080D"; border.width: 1.5
                    opacity: 0; z: 4
                    SequentialAnimation on opacity {
                        running: parent.visible; loops: Animation.Infinite
                        NumberAnimation { to: 0.6; duration: 1000 }
                        NumberAnimation { to: 0.0; duration: 1000 }
                    }
                }

                ColumnLayout {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left; anchors.right: parent.right
                    anchors.bottomMargin: 14
                    anchors.leftMargin: 18; anchors.rightMargin: 18
                    spacing: 6; z: 5
                    visible: !videoOut.visible

                    Text {
                        text: audioManager.currentSongTitle
                        color: "white"
                        font.pixelSize: 17; font.bold: true
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                        maximumLineCount: 1
                    }

                    Rectangle {
                        height: 24
                        width: srcLbl.implicitWidth + 22
                        radius: 12
                        color: sourceColor(audioManager.currentSource) + "28"
                        border.color: sourceColor(audioManager.currentSource) + "75"
                        border.width: 1

                        Row {
                            anchors.centerIn: parent; spacing: 5
                            Rectangle {
                                width: 6; height: 6; radius: 3
                                color: sourceColor(audioManager.currentSource)
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Text {
                                id: srcLbl
                                text: audioManager.currentSource.toUpperCase()
                                color: sourceColor(audioManager.currentSource)
                                font.pixelSize: 10; font.letterSpacing: 2
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }
                }
            }

            // USB / Radio View Switcher
            Rectangle {
                visible: audioManager.currentSource === "USB" || audioManager.currentSource === "Radio"
                Layout.fillWidth: true
                Layout.preferredHeight: 54
                radius: 14
                color: "#1C162B55"
                border.color: "#0A0A1B"; border.width: 1
                clip: true

                Rectangle {
                    anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
                    height: parent.height * 0.4; radius: 14
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "#1C162B" }
                        GradientStop { position: 1.0; color: "transparent" }
                    }
                }

                StackLayout {
                    anchors.fill: parent
                    currentIndex: audioManager.currentSource === "USB" ? 0
                                                                       : audioManager.currentSource === "Radio" ? 1 : -1

                    UsbView   { visible: parent.currentIndex === 0 }
                    RadioView { visible: parent.currentIndex === 1 }
                }
            }

            // Progress Slider
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Text {
                    text: formatTime(audioManager.position)
                    color: "#CBC4CD"; font.pixelSize: 11
                    Layout.preferredWidth: 34
                }

                Slider {
                    id: progSlider
                    Layout.fillWidth: true
                    from: 0
                    to: audioManager.duration > 0 ? audioManager.duration : 100
                    value: audioManager.position
                    enabled: audioManager.currentSource !== "Bluetooth"
                    onMoved: audioManager.setPosition(value)
                    onPressedChanged: {
                        if (!pressed)
                            value = Qt.binding(function() { return audioManager.position })
                    }

                    background: Rectangle {
                        implicitHeight: 5; radius: 3; color: "#1C162B"
                        border.color: "#0A0A1B"; border.width: 1

                        Rectangle {
                            width: progSlider.visualPosition * parent.width
                            height: 5; radius: 3
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: "#1C162B" }
                                GradientStop { position: 1.0; color: "#A6080D" }
                            }
                        }
                    }

                    handle: Rectangle {
                        x: progSlider.leftPadding + progSlider.visualPosition
                           * (progSlider.availableWidth - width)
                        y: progSlider.topPadding + progSlider.availableHeight / 2 - height / 2
                        width: 15; height: 15; radius: 8
                        color: "#CBC4CD"
                        border.color: "#A6080D"; border.width: 2
                    }
                }

                Text {
                    text: formatTime(audioManager.duration)
                    color: "#CBC4CD"; font.pixelSize: 11
                    Layout.preferredWidth: 34
                    horizontalAlignment: Text.AlignRight
                }
            }

            // Playback Controls
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 62
                spacing: 0

                Item {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 250
                }

                RowLayout {
                    spacing: 20
                    Layout.preferredWidth: 160

                    Rectangle {
                        width: 42; height: 42; radius: 21
                        color: "#1C162B00"
                        border.color: "transparent"; border.width: 1
                        opacity: audioManager.currentSource === "Bluetooth" ? 0.3 : 1.0
                        Image {
                            source: "qrc:/qt/qml/GP_IVI/assets/icons/prev.png"
                            anchors.centerIn: parent; width: 22; height: 22
                            fillMode: Image.PreserveAspectFit
                        }
                        TapHandler { onTapped: audioManager.prev() }
                    }

                    Rectangle {
                        width: 58; height: 58; radius: 29
                        color: playTap.pressed ? "#0A0A1B" : "#A6080D"
                        border.color: "#0A0A1B"; border.width: 1

                        Rectangle {
                            anchors.top: parent.top; anchors.horizontalCenter: parent.horizontalCenter
                            width: parent.width * 0.68; height: parent.height * 0.44; radius: 29
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: "#0A0A1B" }
                                GradientStop { position: 1.0; color: "transparent" }
                            }
                        }

                        Rectangle {
                            anchors.centerIn: parent
                            width: parent.width + 14; height: width; radius: width / 2
                            color: "transparent"
                            border { color: "#A6080D"; width: 2 }
                            opacity: 0
                            SequentialAnimation on opacity {
                                running: audioManager.playing; loops: Animation.Infinite
                                NumberAnimation { to: 0.5; duration: 900 }
                                NumberAnimation { to: 0.0; duration: 900 }
                            }
                        }

                        Image {
                            source: audioManager.playing ? "qrc:/qt/qml/GP_IVI/assets/icons/pause.png" : "qrc:/qt/qml/GP_IVI/assets/icons/play.png"
                            anchors.centerIn: parent; width: 26; height: 26
                            fillMode: Image.PreserveAspectFit
                        }
                        TapHandler {
                            id: playTap
                            onTapped: audioManager.togglePlayPause()
                        }
                    }

                    Rectangle {
                        width: 42; height: 42; radius: 21
                        color: "#1C162B00"
                        border.color: "transparent"; border.width: 1
                        opacity: audioManager.currentSource === "Bluetooth" ? 0.3 : 1.0
                        Image {
                            source: "qrc:/qt/qml/GP_IVI/assets/icons/next.png"
                            anchors.centerIn: parent; width: 22; height: 22
                            fillMode: Image.PreserveAspectFit
                        }
                        TapHandler { onTapped: audioManager.next() }
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 60
                }

                // Volume
                RowLayout {
                    spacing: 8
                    Layout.preferredWidth: 180

                    Item {
                        width: 22; height: 22
                        Image {
                            id: vIco
                            source: audioManager.muted ? "qrc:/qt/qml/GP_IVI/assets/icons/mute.png" : "qrc:/qt/qml/GP_IVI/assets/icons/volume.png"
                            anchors.fill: parent; visible: false
                            fillMode: Image.PreserveAspectFit
                        }
                        MultiEffect {
                            anchors.fill: vIco; source: vIco
                            colorization: 1.0
                            colorizationColor: audioManager.muted ? "#A6080D" : "#CBC4CD"
                        }
                        TapHandler {
                            onTapped: manager.setMuted(!audioManager.muted)
                        }
                    }

                    Slider {
                        id: volSlider
                        Layout.fillWidth: true
                        from: 0; to: 100
                        value: profileManager.activeVolume
                        onMoved: {
                            profileManager.setActiveVolume(value)
                        }

                        background: Rectangle {
                            implicitHeight: 5; radius: 3; color: "#1C162B"
                            border.color: "#07000E"; border.width: 1
                            Rectangle {
                                width: volSlider.visualPosition * parent.width
                                height: 5; radius: 3
                                gradient: Gradient {
                                    orientation: Gradient.Horizontal
                                    GradientStop { position: 0.0; color: "#201926" }
                                    GradientStop { position: 1.0; color: "#A6080D" }
                                }
                            }
                        }

                        handle: Item {
                            x: volSlider.leftPadding + volSlider.visualPosition
                               * (volSlider.availableWidth - width)
                            y: volSlider.topPadding + volSlider.availableHeight / 2 - height / 2
                            width: volSlider.pressed ? 22 : 18
                            height: width

                            Rectangle {
                                width: 42; height: 26; radius: 7
                                color: "#1C162B"; border.color: "#A6080D"; border.width: 1
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.bottom: parent.top; anchors.bottomMargin: 8
                                opacity: volSlider.pressed ? 1 : 0
                                Behavior on opacity { NumberAnimation { duration: 120 } }
                                Text {
                                    anchors.centerIn: parent
                                    text: Math.round(volSlider.value * 100)
                                    color: "#CBC4CD"; font.bold: true; font.pixelSize: 11
                                }
                            }

                            Rectangle {
                                anchors.centerIn: parent
                                width: parent.width; height: width; radius: width / 2
                                color: "#CBC4CD"
                                border.color: "#201926"; border.width: 2
                            }

                            Behavior on width { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                        }
                    }

                    Text {
                        text: Math.round(profileManager.activeVolume) + "%"
                        color: "#A6080D"; font.pixelSize: 10
                        Layout.preferredWidth: 28
                        horizontalAlignment: Text.AlignRight
                    }
                }

                Item {
                    Layout.preferredWidth: 10
                }
            }
        }
    }

    BluetoothSheet {
        id: btSheet
        parent: Overlay.overlay
    }

    function formatTime(ms) {
        if (ms <= 0) return "0:00"
        var sec = Math.floor((ms / 1000) % 60)
        var min = Math.floor((ms / 60000) % 60)
        return min + ":" + (sec < 10 ? "0" + sec : sec)
    }

    function sourceColor(src) {
        if (src === "Bluetooth") return "#A6080D"
        if (src === "USB")       return "#A6080D"
        if (src === "Radio")     return "#A6080D"
        return "#06403F"
    }
}