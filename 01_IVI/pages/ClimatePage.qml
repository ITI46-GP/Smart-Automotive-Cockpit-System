import QtQuick
import QtQuick.Controls
import QtQuick.Shapes
import QtQuick.Layouts

Item {
    id: root
    width: 1024
    height: 600

    signal backClicked()

    Rectangle {
        id: bgRoot
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#0b172d" }
            GradientStop { position: 0.5; color: "#0f1123" }
            GradientStop { position: 1.0; color: "#1c2837" }
        }

        Rectangle {
            anchors.fill: parent
            opacity: 0.25
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "#1a153a" }
                GradientStop { position: 0.5; color: "transparent" }
                GradientStop { position: 1.0; color: "#1a153a" }
            }
        }
    }

    Item {
        id: header
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 80

        Rectangle {
            id: backBtn
            width: 50
            height: 50
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 35
            radius: 14
            color: backTap.pressed ? Qt.rgba(255/255, 255/255, 255/255, 0.08) : Qt.rgba(255/255, 255/255, 255/255, 0.03)
            border.color: Qt.rgba(255/255, 255/255, 255/255, 0.08)
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: "\u2190"
                color: "#a0a5c0"
                font.pixelSize: 20
                font.bold: true
            }

            TapHandler {
                id: backTap
                onTapped: root.backClicked()
            }
        }

        Text {
            anchors.centerIn: parent
            text: "HVAC"
            color: "#FFFFFF"
            font.pixelSize: 26
            font.bold: true
            font.letterSpacing: 6
        }
    }

    RowLayout {
        id: mainPanel
        anchors.top: header.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 35
        spacing: 30

        Loader {
            id: driverLoader
            Layout.fillWidth: true
            Layout.fillHeight: true
            sourceComponent: zoneComp
            onLoaded: {
                item.title = "DRIVER"
                item.isDriver = true
                item.currentTemp = Qt.binding(function() { return HvacBackend.driverTemp })
                item.currentFanMode = 0
                item.zonePower = Qt.binding(function() { return HvacBackend.driverPowerOn })
                item.reqIncreaseTemp.connect(HvacBackend.increaseDriverTemp)
                item.reqDecreaseTemp.connect(HvacBackend.decreaseDriverTemp)
                item.reqSetFanMode.connect(function(mode) { item.currentFanMode = mode })
                item.reqTogglePower.connect(HvacBackend.toggleDriverPower)
            }
        }

        Item {
            id: carContainer
            Layout.preferredWidth: 260
            Layout.fillHeight: true

            Image {
                id: carImage
                anchors.centerIn: parent
                width: parent.width * 1.1
                height: parent.height * 1.1
                source: "qrc:/qt/qml/GP_IVI/assets/images/car_climate.png"
                fillMode: Image.PreserveAspectFit
                opacity: 0.85
            }
        }

        Loader {
            id: passengerLoader
            Layout.fillWidth: true
            Layout.fillHeight: true
            sourceComponent: zoneComp
            onLoaded: {
                item.title = "PASSENGER"
                item.isDriver = false
                item.currentTemp = Qt.binding(function() { return HvacBackend.passengerTemp })
                item.currentFanMode = 0
                item.zonePower = Qt.binding(function() { return HvacBackend.passengerPowerOn })
                item.reqIncreaseTemp.connect(HvacBackend.increasePassengerTemp)
                item.reqDecreaseTemp.connect(HvacBackend.decreasePassengerTemp)
                item.reqSetFanMode.connect(function(mode) { item.currentFanMode = mode })
                item.reqTogglePower.connect(HvacBackend.togglePassengerPower)
            }
        }
    }

    Component {
        id: zoneComp
        Item {
            id: zoneRoot
            anchors.fill: parent

            property string title: "DRIVER"
            property double currentTemp: 21.5
            property int    currentFanMode: 0
            property bool   zonePower: true
            property bool   isDriver: true

            signal reqIncreaseTemp()
            signal reqDecreaseTemp()
            signal reqSetFanMode(int mode)
            signal reqTogglePower()

            Rectangle {
                anchors.fill: parent
                color: zoneRoot.zonePower ? Qt.rgba(20/255, 20/255, 35/255, 0.4) : Qt.rgba(15/255, 15/255, 25/255, 0.2)
                border.color: zoneRoot.zonePower ? Qt.rgba(255/255, 255/255, 255/255, 0.08) : Qt.rgba(255/255, 255/255, 255/255, 0.03)
                border.width: 1
                radius: 28

                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    color: "transparent"
                    border.color: Qt.rgba(168/255, 85/255, 247/255, 0.12)
                    border.width: 1.5
                    visible: zoneRoot.zonePower
                }
            }

            Text {
                id: titleText
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.topMargin: 25
                text: zoneRoot.title
                color: zoneRoot.zonePower ? "#7e84a3" : "#4a4e69"
                font.pixelSize: 13
                font.bold: true
                font.letterSpacing: 3
            }

            Row {
                id: modeRow
                anchors.top: titleText.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.topMargin: 20
                spacing: 14

                Repeater {
                    model: [
                        "qrc:/qt/qml/GP_IVI/assets/icons/vent.png",
                        "qrc:/qt/qml/GP_IVI/assets/icons/vent_blow.png",
                        "qrc:/qt/qml/GP_IVI/assets/icons/windscreen-air.png"
                    ]

                    Rectangle {
                        id: modeBtn
                        required property int index
                        required property var modelData
                        width: 58
                        height: 58
                        radius: 16

                        color: {
                            if (!zoneRoot.zonePower) {
                                return Qt.rgba(255/255, 255/255, 255/255, 0.01);
                            }
                            return zoneRoot.currentFanMode === index
                                   ? "#8b2cf5"
                                   : (modeTap.pressed ? Qt.rgba(255/255, 255/255, 255/255, 0.06) : Qt.rgba(255/255, 255/255, 255/255, 0.02));
                        }

                        border.color: {
                            if (!zoneRoot.zonePower) {
                                return Qt.rgba(255/255, 255/255, 255/255, 0.04);
                            }
                            return zoneRoot.currentFanMode === index
                                   ? "#c084fc"
                                   : Qt.rgba(255/255, 255/255, 255/255, 0.06);
                        }
                        border.width: 1

                        Rectangle {
                            anchors.fill: parent
                            radius: parent.radius
                            color: "transparent"
                            border.color: "#dfc6ff"
                            border.width: 1
                            opacity: 0.3
                            visible: zoneRoot.zonePower && zoneRoot.currentFanMode === index
                        }

                        Image {
                            anchors.centerIn: parent
                            width: 26
                            height: 26
                            source: modelData
                            fillMode: Image.PreserveAspectFit
                            opacity: zoneRoot.zonePower ? (zoneRoot.currentFanMode === index ? 1.0 : 0.6) : 0.25
                        }

                        TapHandler {
                            id: modeTap
                            enabled: zoneRoot.zonePower
                            onTapped: zoneRoot.reqSetFanMode(index)
                        }
                    }
                }
            }

            Item {
                id: switchContainer
                width: 90
                height: 65
                anchors.top: modeRow.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.topMargin: 20

                Rectangle {
                    id: switchBg
                    width: 56
                    height: 28
                    radius: 14
                    anchors.top: parent.top
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: zoneRoot.zonePower ? "#a855f7" : Qt.rgba(255/255, 255/255, 255/255, 0.08)
                    border.color: zoneRoot.zonePower ? Qt.rgba(234/255, 179/255, 8/255, 0.0) : Qt.rgba(255/255, 255/255, 255/255, 0.08)
                    border.width: 1

                    Rectangle {
                        width: 22
                        height: 22
                        radius: 11
                        anchors.verticalCenter: parent.verticalCenter
                        x: zoneRoot.zonePower ? parent.width - width - 3 : 3
                        color: "#FFFFFF"

                        Behavior on x {
                            NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
                        }
                    }

                    TapHandler {
                        onTapped: zoneRoot.reqTogglePower()
                    }
                }

                Text {
                    anchors.top: switchBg.bottom
                    anchors.topMargin: 8
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: zoneRoot.isDriver ? "PWR (DRV)" : "PWR (PAS)"
                    color: zoneRoot.zonePower ? "#7e84a3" : "#4a4e69"
                    font.pixelSize: 11
                    font.bold: true
                }
            }

            Item {
                id: dialContainer
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottomMargin: 25
                width: 200
                height: 200

                property real cx: width / 2
                property real cy: height / 2
                property real radius: 82
                property real strokeW: 8
                property real startAngle: 140
                property real maxSweep: 260
                property real tempMin: 16.0
                property real tempMax: 30.0
                property real currentSweep: zoneRoot.zonePower
                                            ? ((zoneRoot.currentTemp - tempMin) / (tempMax - tempMin)) * maxSweep
                                            : 0

                Shape {
                    anchors.fill: parent
                    layer.enabled: true
                    layer.samples: 4
                    ShapePath {
                        strokeColor: Qt.rgba(255/255, 255/255, 255/255, 0.04)
                        strokeWidth: dialContainer.strokeW
                        fillColor: "transparent"
                        capStyle: ShapePath.RoundCap
                        PathMove {
                            x: dialContainer.cx + dialContainer.radius * Math.cos(dialContainer.startAngle * Math.PI / 180)
                            y: dialContainer.cy - dialContainer.radius * Math.sin(dialContainer.startAngle * Math.PI / 180)
                        }
                        PathAngleArc {
                            centerX: dialContainer.cx
                            centerY: dialContainer.cy
                            radiusX: dialContainer.radius
                            radiusY: dialContainer.radius
                            startAngle: dialContainer.startAngle
                            sweepAngle: dialContainer.maxSweep
                        }
                    }
                }

                Shape {
                    anchors.fill: parent
                    visible: zoneRoot.zonePower
                    layer.enabled: true
                    layer.samples: 4
                    ShapePath {
                        strokeColor: "#bc77ff"
                        strokeWidth: dialContainer.strokeW
                        fillColor: "transparent"
                        capStyle: ShapePath.RoundCap
                        PathMove {
                            x: dialContainer.cx + dialContainer.radius * Math.cos(dialContainer.startAngle * Math.PI / 180)
                            y: dialContainer.cy - dialContainer.radius * Math.sin(dialContainer.startAngle * Math.PI / 180)
                        }
                        PathAngleArc {
                            centerX: dialContainer.cx
                            centerY: dialContainer.cy
                            radiusX: dialContainer.radius
                            radiusY: dialContainer.radius
                            startAngle: dialContainer.startAngle
                            sweepAngle: dialContainer.currentSweep
                        }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: -20
                    text: zoneRoot.zonePower ? zoneRoot.currentTemp.toFixed(1) + "°" : "— —"
                    color: zoneRoot.zonePower ? "#FFFFFF" : "#3b3e54"
                    font.pixelSize: zoneRoot.zonePower ? 46 : 40
                    font.bold: true
                }

                Row {
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottomMargin: 0
                    spacing: 20

                    Rectangle {
                        width: 46
                        height: 46
                        radius: 14
                        color: plusTap.pressed ? Qt.rgba(255/255, 255/255, 255/255, 0.06) : Qt.rgba(255/255, 255/255, 255/255, 0.02)
                        border.color: zoneRoot.zonePower ? Qt.rgba(255/255, 255/255, 255/255, 0.08) : Qt.rgba(255/255, 255/255, 255/255, 0.03)
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "+"
                            color: zoneRoot.zonePower ? "#FFFFFF" : "#4a4e69"
                            font.pixelSize: 22
                        }

                        TapHandler {
                            id: plusTap
                            enabled: zoneRoot.zonePower
                            onTapped: zoneRoot.reqIncreaseTemp()
                        }
                    }

                    Rectangle {
                        width: 46
                        height: 46
                        radius: 14
                        color: minusTap.pressed ? Qt.rgba(255/255, 255/255, 255/255, 0.06) : Qt.rgba(255/255, 255/255, 255/255, 0.02)
                        border.color: zoneRoot.zonePower ? Qt.rgba(255/255, 255/255, 255/255, 0.08) : Qt.rgba(255/255, 255/255, 255/255, 0.03)
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "−"
                            color: zoneRoot.zonePower ? "#FFFFFF" : "#4a4e69"
                            font.pixelSize: 22
                        }

                        TapHandler {
                            id: minusTap
                            enabled: zoneRoot.zonePower
                            onTapped: zoneRoot.reqDecreaseTemp()
                        }
                    }
                }
            }
        }
    }
}