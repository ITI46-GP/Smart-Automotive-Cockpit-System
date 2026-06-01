import QtQuick

Item {
    id: root
    width: 382
    height: 444

    property int battery: 80
    property int rangeKm: 344
    property string driveMode: "Comfort"
    property string lockState: "Locked"
    property string lightState: "Auto"
    property string systemState: "Healthy"

    readonly property bool compact: height < 470 || width < 430
    readonly property real edge: compact ? 18 : 22
    readonly property real chipWidth: Math.max(84, Math.min(104, width * 0.22))
    readonly property real chipHeight: compact ? 48 : 58
    readonly property real chipSpacing: compact ? 8 : 14
    readonly property real carWidth: Math.max(148, Math.min(210, width - edge * 2 - chipWidth * 2 - 28))
    readonly property real carHeight: compact ? 200 : 285
    readonly property real statusTop: compact ? 128 : 138

    Rectangle {
        anchors.fill: parent
        radius: compact ? 24 : 30
        color: "#080512"
        border.color: "#342544"
        border.width: 1
        clip: true

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            opacity: 0.56
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#19102A" }
                GradientStop { position: 0.48; color: "#0B0A1B" }
                GradientStop { position: 1.0; color: "#07000E" }
            }
        }

        Canvas {
            anchors.fill: parent
            opacity: 0.18

            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()

            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)

                var centerY = height * 0.56
                var radiusA = Math.min(width, height) * 0.30
                var radiusB = Math.min(width, height) * 0.22

                ctx.strokeStyle = "#8B5CF6"
                ctx.lineWidth = 1

                ctx.beginPath()
                ctx.moveTo(width * 0.36, 76)
                ctx.lineTo(width * 0.28, height - 58)
                ctx.stroke()

                ctx.beginPath()
                ctx.moveTo(width * 0.64, 76)
                ctx.lineTo(width * 0.72, height - 58)
                ctx.stroke()

                ctx.strokeStyle = "#CBC4CD"
                ctx.globalAlpha = 0.12

                ctx.beginPath()
                ctx.arc(width / 2, centerY, radiusA, 0, Math.PI * 2)
                ctx.stroke()

                ctx.beginPath()
                ctx.arc(width / 2, centerY, radiusB, 0, Math.PI * 2)
                ctx.stroke()
            }
        }

        Column {
            anchors.top: parent.top
            anchors.topMargin: compact ? 20 : 28
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: compact ? 5 : 8

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 8

                Rectangle {
                    width: compact ? 22 : 24
                    height: width
                    radius: 8
                    color: "#171025"
                    border.color: "#8B5CF6"
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "V"
                        color: "#21D4FD"
                        font.pixelSize: compact ? 12 : 14
                        font.bold: true
                    }
                }

                Text {
                    text: "VEHICLE OVERVIEW"
                    color: "#CBC4CD"
                    opacity: 0.82
                    font.pixelSize: compact ? 11 : 13
                    font.letterSpacing: compact ? 2.6 : 4
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "SYSTEM STATUS"
                color: "#F4EEF7"
                font.pixelSize: compact ? 23 : 30
                font.bold: true
                font.letterSpacing: compact ? 1.2 : 2
            }
        }

        Rectangle {
            width: compact ? 164 : 210
            height: width
            radius: width / 2
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: compact ? 128 : 150
            color: "#8B5CF6"
            opacity: 0.04
        }

        Rectangle {
            width: root.carWidth + 24
            height: compact ? 54 : 70
            radius: height / 2
            anchors.horizontalCenter: carImage.horizontalCenter
            anchors.bottom: carImage.bottom
            anchors.bottomMargin: compact ? 8 : 10
            color: "#000000"
            opacity: 0.34
        }

        Image {
            id: carImage
            width: root.carWidth
            height: root.carHeight
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: compact ? 120 : 148
            source: "qrc:/qt/qml/GP_IVI/assets/images/tesla.png"
            fillMode: Image.PreserveAspectFit
            smooth: true
            opacity: 0.96
        }

        Column {
            anchors.left: parent.left
            anchors.leftMargin: root.edge
            anchors.top: parent.top
            anchors.topMargin: root.statusTop
            spacing: root.chipSpacing

            StatusChip {
                title: "BATTERY"
                value: root.battery + "%"
                accent: "#8B5CF6"
            }

            StatusChip {
                title: "RANGE"
                value: root.rangeKm + " km"
                accent: "#21D4FD"
            }

            StatusChip {
                title: "MODE"
                value: root.driveMode
                accent: "#A6080D"
            }
        }

        Column {
            anchors.right: parent.right
            anchors.rightMargin: root.edge
            anchors.top: parent.top
            anchors.topMargin: root.statusTop
            spacing: root.chipSpacing

            StatusChip {
                title: "DOORS"
                value: root.lockState
                accent: "#8B5CF6"
            }

            StatusChip {
                title: "LIGHTS"
                value: root.lightState
                accent: "#21D4FD"
            }

            StatusChip {
                title: "SYSTEM"
                value: root.systemState
                accent: "#8B5CF6"
            }
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: compact ? 18 : 24
            spacing: compact ? 8 : 14

            TouchActionButton {
                label: "LOCK"
                onClicked: console.log("Lock pressed")
            }

            TouchActionButton {
                label: "CHARGE"
                onClicked: console.log("Charge pressed")
            }

            TouchActionButton {
                label: "DIAGNOSTICS"
                wide: true
                onClicked: console.log("Diagnostics pressed")
            }
        }
    }

    component StatusChip: Rectangle {
        id: chip
        width: root.chipWidth
        height: root.chipHeight
        radius: root.compact ? 15 : 18

        property string title: ""
        property string value: ""
        property color accent: "#8B5CF6"

        color: "#090613"
        border.color: "#342544"
        border.width: 1

        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            opacity: 0.20
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#241238" }
                GradientStop { position: 1.0; color: "#090613" }
            }
        }

        Rectangle {
            width: 3
            height: root.compact ? 24 : 28
            radius: 2
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            color: chip.accent
            opacity: 0.82
        }

        Column {
            anchors.left: parent.left
            anchors.leftMargin: root.compact ? 13 : 18
            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            spacing: root.compact ? 4 : 5

            Text {
                text: chip.title
                color: "#8F7AA8"
                font.pixelSize: root.compact ? 8 : 9
                font.bold: true
                font.letterSpacing: root.compact ? 1.2 : 1.8
            }

            Text {
                width: parent.width
                text: chip.value
                color: "#F4EEF7"
                font.pixelSize: root.compact ? 12 : 15
                font.bold: true
                elide: Text.ElideRight
            }
        }
    }

    component TouchActionButton: Item {
        id: action
        width: wide ? (root.compact ? 112 : 120) : (root.compact ? 76 : 84)
        height: root.compact ? 38 : 42

        property string label: ""
        property bool wide: false

        signal clicked()

        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: tap.pressed ? "#8B5CF6" : "#120B1D"
            border.color: tap.pressed ? "#B99CFF" : "#342544"
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
                text: action.label
                color: tap.pressed ? "#FFFFFF" : "#CBC4CD"
                font.pixelSize: root.compact ? 9 : 10
                font.bold: true
                font.letterSpacing: root.compact ? 1.0 : 1.4
            }
        }

        TapHandler {
            id: tap
            gesturePolicy: TapHandler.ReleaseWithinBounds
            onTapped: action.clicked()
        }
    }
}
