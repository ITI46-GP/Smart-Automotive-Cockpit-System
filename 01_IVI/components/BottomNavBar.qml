import QtQuick

Item {
    id: root
    height: 70
    width: parent ? parent.width : 1024

    signal homeClicked()
    signal weatherClicked()
    signal settingsClicked()
    signal climateClicked()
    signal mediaClicked()
    signal assistantClicked()

    signal driverTempUp()
    signal driverTempDown()
    signal passengerTempUp()
    signal passengerTempDown()
    signal volumeUp()
    signal volumeDown()

    // keep old signal so DashboardPage old handler will not break if still exists
    signal appsClicked()

    property int driverTemp: 20
    property int passengerTemp: 20
    property int volume: 52

    property color barBg: "#020106"
    property color line: "#24182F"
    property color text: "#CBC4CD"
    property color muted: "#8F7AA8"
    property color violet: "#8B5CF6"
    property color cyan: "#21D4FD"

    Rectangle {
        anchors.fill: parent
        radius: 22
        color: root.barBg
        border.color: root.line
        border.width: 1

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: "#000000"
            opacity: 0.35
        }

        // Must stay exactly in the center
        ClimateGroup {
            id: climateGroup
            width: 318
            height: parent.height - 12
            anchors.centerIn: parent
        }

        // Left side: Home / Weather / Settings
        Row {
            id: leftControls
            height: parent.height - 12
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: climateGroup.left
            anchors.rightMargin: 16
            spacing: 10

            BottomIconButton {
                width: 72
                height: parent.height
                iconType: "car"
                label: "HOME"
                active: true
                onClicked: root.homeClicked()
            }

            Separator {
                anchors.verticalCenter: parent.verticalCenter
            }

            BottomIconButton {
                width: 66
                height: parent.height
                iconType: "weather"
                label: "WEATHER"
                onClicked: root.weatherClicked()
            }

            BottomIconButton {
                width: 66
                height: parent.height
                iconType: "settings"
                label: "SETTINGS"
                onClicked: root.settingsClicked()
            }
        }

        // Right side: Media / Volume / AI
        Row {
            id: rightControls
            height: parent.height - 12
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: climateGroup.right
            anchors.leftMargin: 16
            spacing: 10

            BottomIconButton {
                width: 66
                height: parent.height
                iconType: "media"
                label: "MEDIA"
                onClicked: root.mediaClicked()
            }

            VolumeControl {
                width: 106
                height: parent.height
                volumeValue: root.volume
                onIncreaseVolume: root.volumeUp()
                onDecreaseVolume: root.volumeDown()
            }

            Separator {
                anchors.verticalCenter: parent.verticalCenter
            }

            BottomIconButton {
                width: 66
                height: parent.height
                iconType: "ai"
                label: "AI"
                onClicked: root.assistantClicked()
            }
        }
    }

    component Separator: Rectangle {
        width: 1
        height: 34
        color: root.line
        opacity: 0.9
    }

    component ClimateGroup: Rectangle {
        id: climateGroupRoot
        radius: 20
        color: "#05030A"
        border.color: "#1A1024"
        border.width: 1

        Row {
            anchors.centerIn: parent
            spacing: 8

            TempControl {
                width: 92
                height: climateGroupRoot.height
                title: "DRIVER"
                value: root.driverTemp

                onUpClicked: {
                    root.driverTempUp()
                }

                onDownClicked: {
                    root.driverTempDown()
                }
            }

            ClimateFanButton {
                width: 82
                height: climateGroupRoot.height
                onClicked: root.climateClicked()
            }

            TempControl {
                width: 92
                height: climateGroupRoot.height
                title: "PASSENGER"
                value: root.passengerTemp

                onUpClicked: {
                    root.passengerTempUp()
                }

                onDownClicked: {
                    root.passengerTempDown()
                }
            }
        }
    }

    component TempControl: Item {
        id: temp

        property string title: ""
        property int value: 20
        readonly property int displayValue: Math.max(16, Math.min(30, value))

        signal upClicked()
        signal downClicked()

        Column {
            anchors.centerIn: parent
            spacing: 0

            StepArrow {
                anchors.horizontalCenter: parent.horizontalCenter
                direction: "up"
                onClicked: temp.upClicked()
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: temp.displayValue + "°"
                color: "#F4EEF7"
                font.pixelSize: 18
                font.bold: true
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: temp.title
                color: root.muted
                font.pixelSize: 8
                font.bold: true
                font.letterSpacing: 1.0
            }

            StepArrow {
                anchors.horizontalCenter: parent.horizontalCenter
                direction: "down"
                onClicked: temp.downClicked()
            }
        }
    }

    component ClimateFanButton: Item {
        id: climate

        signal clicked()

        Rectangle {
            anchors.fill: parent
            radius: 18
            color: climateTap.pressed ? "#130B1F" : "transparent"
            border.color: climateTap.pressed ? root.violet : "transparent"
            border.width: climateTap.pressed ? 1 : 0
            scale: climateTap.pressed ? 0.94 : 1.0

            Behavior on scale {
                NumberAnimation {
                    duration: 100
                    easing.type: Easing.OutQuad
                }
            }

            Image {
                width: 31
                height: 31
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 7

                source: "qrc:/qt/qml/GP_IVI/assets/icons/climate_fan.svg"
                fillMode: Image.PreserveAspectFit
                smooth: true
                mipmap: true
                opacity: climateTap.pressed ? 1.0 : 0.88
                sourceSize.width: 64
                sourceSize.height: 64
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 6
                text: "CLIMATE"
                color: root.muted
                font.pixelSize: 8
                font.bold: true
                font.letterSpacing: 1.0
            }
        }

        TapHandler {
            id: climateTap
            gesturePolicy: TapHandler.ReleaseWithinBounds
            onTapped: climate.clicked()
        }
    }

    component BottomIconButton: Item {
        id: btn

        property string iconType: ""
        property string label: ""
        property bool active: false

        signal clicked()

        Rectangle {
            anchors.fill: parent
            radius: 18
            color: btnTap.pressed ? "#130B1F" : "transparent"
            border.color: btn.active ? root.cyan : (btnTap.pressed ? root.violet : "transparent")
            border.width: btn.active || btnTap.pressed ? 1 : 0
            scale: btnTap.pressed ? 0.94 : 1.0

            Behavior on scale {
                NumberAnimation {
                    duration: 100
                    easing.type: Easing.OutQuad
                }
            }

            Image {
                id: iconImage
                width: iconSize()
                height: iconSize()
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: iconTopMargin()

                source: iconSource()
                visible: source !== ""
                fillMode: Image.PreserveAspectFit
                smooth: true
                mipmap: true
                opacity: btn.active ? 1.0 : 0.88
                sourceSize.width: 96
                sourceSize.height: 96
            }

            Canvas {
                id: mediaCanvas
                width: 30
                height: 30
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 8
                visible: btn.iconType === "media"

                Connections {
                    target: btnTap

                    function onPressedChanged() {
                        mediaCanvas.requestPaint()
                    }
                }

                onPaint: {
                    var ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)

                    var c = btn.active ? root.cyan : (btnTap.pressed ? root.violet : root.text)
                    ctx.strokeStyle = c
                    ctx.fillStyle = c
                    ctx.lineWidth = 1.8
                    ctx.lineCap = "round"
                    ctx.lineJoin = "round"

                    ctx.beginPath()
                    ctx.moveTo(12, 7)
                    ctx.lineTo(12, 22)
                    ctx.stroke()

                    ctx.beginPath()
                    ctx.moveTo(12, 7)
                    ctx.lineTo(23, 5)
                    ctx.lineTo(23, 19)
                    ctx.stroke()

                    ctx.beginPath()
                    ctx.arc(10, 23, 3.2, 0, Math.PI * 2)
                    ctx.fill()

                    ctx.beginPath()
                    ctx.arc(21, 20, 3.2, 0, Math.PI * 2)
                    ctx.fill()
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 6
                text: btn.label
                color: btn.active ? root.cyan : root.muted
                font.pixelSize: 8
                font.bold: true
                font.letterSpacing: 0.9
            }
        }

        function iconSource() {
            if (btn.iconType === "car")
                return "qrc:/qt/qml/GP_IVI/assets/icons/car_home.svg"
            if (btn.iconType === "weather")
                return "qrc:/qt/qml/GP_IVI/assets/icons/weather.png"
            if (btn.iconType === "settings")
                return "qrc:/qt/qml/GP_IVI/assets/icons/settings_gear.svg"
            if (btn.iconType === "ai")
                return "qrc:/qt/qml/GP_IVI/assets/icons/ai_assistant.svg"
            return ""
        }

        function iconSize() {
            if (btn.iconType === "ai")
                return 31
            if (btn.iconType === "weather")
                return 30
            if (btn.iconType === "settings")
                return 30
            if (btn.iconType === "car")
                return 28
            return 30
        }

        function iconTopMargin() {
            if (btn.iconType === "ai")
                return 6
            return 8
        }

        TapHandler {
            id: btnTap
            gesturePolicy: TapHandler.ReleaseWithinBounds
            onTapped: btn.clicked()
        }
    }

    component VolumeControl: Item {
        id: vol
        property int volumeValue: 52
        signal increaseVolume()
        signal decreaseVolume()

        Row {
            anchors.centerIn: parent
            spacing: 6

            Canvas {
                width: 27
                height: 27
                anchors.verticalCenter: parent.verticalCenter

                onPaint: {
                    var ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)

                    ctx.strokeStyle = root.text
                    ctx.lineWidth = 1.8
                    ctx.lineCap = "round"
                    ctx.lineJoin = "round"

                    ctx.beginPath()
                    ctx.moveTo(5, 11)
                    ctx.lineTo(10, 11)
                    ctx.lineTo(17, 6)
                    ctx.lineTo(17, 22)
                    ctx.lineTo(10, 17)
                    ctx.lineTo(5, 17)
                    ctx.closePath()
                    ctx.stroke()

                    ctx.beginPath()
                    ctx.arc(19, 14, 5, -0.7, 0.7)
                    ctx.stroke()
                }
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 0

                StepArrow {
                    anchors.horizontalCenter: parent.horizontalCenter
                    direction: "up"

                    onClicked: {
                        vol.increaseVolume()
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: vol.volumeValue + "%"
                    color: "#F4EEF7"
                    font.pixelSize: 13
                    font.bold: true
                }

                StepArrow {
                    anchors.horizontalCenter: parent.horizontalCenter
                    direction: "down"

                    onClicked: {
                        vol.decreaseVolume()
                    }
                }
            }
        }
    }

    component StepArrow: Item {
        id: arrow
        width: 34
        height: 13

        property string direction: "up"

        signal clicked()

        Canvas {
            id: arrowCanvas
            anchors.fill: parent

            Connections {
                target: arrowTap

                function onPressedChanged() {
                    arrowCanvas.requestPaint()
                }
            }

            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)

                ctx.strokeStyle = arrowTap.pressed ? root.violet : root.muted
                ctx.lineWidth = 1.7
                ctx.lineCap = "round"
                ctx.lineJoin = "round"

                ctx.beginPath()

                if (arrow.direction === "up") {
                    ctx.moveTo(width / 2 - 5, 8)
                    ctx.lineTo(width / 2, 3)
                    ctx.lineTo(width / 2 + 5, 8)
                } else {
                    ctx.moveTo(width / 2 - 5, 4)
                    ctx.lineTo(width / 2, 9)
                    ctx.lineTo(width / 2 + 5, 4)
                }

                ctx.stroke()
            }
        }

        TapHandler {
            id: arrowTap
            gesturePolicy: TapHandler.ReleaseWithinBounds
            onTapped: arrow.clicked()
        }
    }
}
