import QtQuick

Item {
    id: root
    width: parent ? parent.width : 1024
    height: 40

    property int battery: 80
    property string gear: "D"
    property string driveState: "READY"
    property string cabinMode: "EASY ENTRY"
    property string network: "LTE"
    property string currentTime: Qt.formatTime(new Date(), "hh:mm")
    property string temperature: "8°C"
    property color readyGreen: "#5BFFB0"
    property color accentCyan: "#21D4FD"

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.currentTime = Qt.formatTime(new Date(), "hh:mm")
    }

    // ultra-transparent glass strip
    Rectangle {
        anchors.fill: parent
        color: "#07000E"
        opacity: 0.18
    }

    Rectangle {
        anchors.fill: parent
        opacity: 0.24
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#2A203A" }
            GradientStop { position: 1.0; color: "#07000E" }
        }
    }

    // subtle bottom separator
    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 1
        color: "#CBC4CD"
        opacity: 0.10
    }

    // tiny cinematic top glow
    Rectangle {
        width: parent.width * 0.28
        height: 1
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        color: "#A6080D"
        opacity: 0.28
    }

    // LEFT GROUP
    Row {
        anchors.left: parent.left
        anchors.leftMargin: 20
        anchors.verticalCenter: parent.verticalCenter
        spacing: 18

        Row {
            spacing: 8
            anchors.verticalCenter: parent.verticalCenter

            Rectangle {
                width: 7
                height: 7
                radius: 4
                color: root.readyGreen
                anchors.verticalCenter: parent.verticalCenter

                Rectangle {
                    anchors.centerIn: parent
                    width: 18
                    height: 18
                    radius: 9
                    color: root.readyGreen
                    opacity: 0.10
                }
            }

            Text {
                text: root.driveState
                color: "#CBC4CD"
                opacity: 0.92
                font.pixelSize: 12
                font.bold: true
                font.letterSpacing: 2.8
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        Rectangle {
            width: 1
            height: 16
            color: "#CBC4CD"
            opacity: 0.12
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text: root.temperature
            color: "#CBC4CD"
            opacity: 0.82
            font.pixelSize: 14
            font.weight: Font.Medium
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text: root.currentTime
            color: "#F2EEF3"
            opacity: 0.94
            font.pixelSize: 15
            font.bold: true
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    // CENTER GROUP
    Row {
        anchors.centerIn: parent
        spacing: 16

        Text {
            text: "SOS"
            color: "#CBC4CD"
            opacity: 0.48
            font.pixelSize: 11
            font.bold: true
            anchors.verticalCenter: parent.verticalCenter
        }

        Rectangle {
            width: 5
            height: 5
            radius: 3
            color: "#CBC4CD"
            opacity: 0.34
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            text: root.cabinMode
            color: "#CBC4CD"
            opacity: 0.88
            font.pixelSize: 14
            font.bold: true
            font.letterSpacing: 0.8
            anchors.verticalCenter: parent.verticalCenter
        }

        Item {
            width: 14
            height: 16
            anchors.verticalCenter: parent.verticalCenter

            Rectangle {
                x: 3
                y: 7
                width: 8
                height: 7
                radius: 2
                color: "#A88C32"
                opacity: 0.9
            }

            Rectangle {
                x: 4
                y: 2
                width: 6
                height: 8
                radius: 3
                color: "transparent"
                border.color: "#A88C32"
                border.width: 1
                opacity: 0.9
            }
        }
    }

    // RIGHT GROUP
    Row {
        anchors.right: parent.right
        anchors.rightMargin: 20
        anchors.verticalCenter: parent.verticalCenter
        spacing: 16

        // signal bars
        Row {
            spacing: 3
            anchors.verticalCenter: parent.verticalCenter

            Repeater {
                model: [6, 9, 12, 15]

                Rectangle {
                    width: 3
                    height: modelData
                    radius: 1
                    color: "#CBC4CD"
                    opacity: 0.38 + index * 0.12
                    anchors.bottom: parent.bottom
                }
            }
        }

        Text {
            text: root.network
            color: "#CBC4CD"
            opacity: 0.88
            font.pixelSize: 12
            font.bold: true
            font.letterSpacing: 1.2
            anchors.verticalCenter: parent.verticalCenter
        }

        // wifi icon drawn with canvas
        Canvas {
            width: 22
            height: 18
            anchors.verticalCenter: parent.verticalCenter
            opacity: 0.78

            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)
                ctx.strokeStyle = "#CBC4CD"
                ctx.lineWidth = 1.5
                ctx.lineCap = "round"

                ctx.beginPath()
                ctx.arc(11, 16, 11, Math.PI * 1.18, Math.PI * 1.82)
                ctx.stroke()

                ctx.beginPath()
                ctx.arc(11, 16, 7, Math.PI * 1.20, Math.PI * 1.80)
                ctx.stroke()

                ctx.beginPath()
                ctx.arc(11, 16, 3, Math.PI * 1.25, Math.PI * 1.75)
                ctx.stroke()

                ctx.fillStyle = "#CBC4CD"
                ctx.beginPath()
                ctx.arc(11, 15, 1.7, 0, Math.PI * 2)
                ctx.fill()
            }
        }

        Row {
            spacing: 8
            anchors.verticalCenter: parent.verticalCenter

            Item {
                width: 43
                height: 18
                anchors.verticalCenter: parent.verticalCenter

                Rectangle {
                    x: 0
                    y: 2
                    width: 36
                    height: 14
                    radius: 3
                    color: "transparent"
                    border.color: "#CBC4CD"
                    border.width: 1
                    opacity: 0.68
                }

                Rectangle {
                    x: 38
                    y: 6
                    width: 3
                    height: 6
                    radius: 1
                    color: "#CBC4CD"
                    opacity: 0.55
                }

                Rectangle {
                    x: 3
                    y: 5
                    width: Math.max(4, 30 * root.battery / 100)
                    height: 8
                    radius: 2
                    color: root.battery > 25 ? root.readyGreen : "#A6080D"
                    opacity: 0.9
                }
            }

            Text {
                text: root.battery + "%"
                color: root.battery > 25 ? root.readyGreen : "#A6080D"
                font.pixelSize: 14
                font.bold: true
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        Row {
            spacing: 9
            anchors.verticalCenter: parent.verticalCenter

            Repeater {
                model: ["P", "R", "N", "D"]

                Text {
                    text: modelData
                    color: modelData === root.gear ? root.accentCyan : "#CBC4CD"
                    opacity: modelData === root.gear ? 1.0 : 0.55
                    font.pixelSize: 13
                    font.bold: true
                    font.letterSpacing: 1.2
                }
            }
        }
    }
}
