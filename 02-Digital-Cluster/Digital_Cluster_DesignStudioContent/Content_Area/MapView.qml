import QtQuick

Item {
    id: mapView

    property string nextInstruction: "Next: Main St in 250m"

    Column {
        anchors.centerIn: parent
        spacing: 14

        Text {
            text: "🗺 Navigation"
            color: "#ffffff"
            font.pixelSize: 22
            font.bold: true
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Rectangle {
            width: 360
            height: 220
            radius: 14
            color: "#15151f"
            border.color: "#2a2a3a"

            Canvas {
                anchors.fill: parent
                anchors.margins: 1
                Component.onCompleted: requestPaint()
                onPaint: {
                    var ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)

                    // grid
                    ctx.strokeStyle = "rgba(100, 130, 200, 0.15)"
                    ctx.lineWidth = 1
                    for (var x = 0; x < width; x += 20) {
                        ctx.beginPath()
                        ctx.moveTo(x, 0)
                        ctx.lineTo(x, height)
                        ctx.stroke()
                    }
                    for (var y = 0; y < height; y += 20) {
                        ctx.beginPath()
                        ctx.moveTo(0, y)
                        ctx.lineTo(width, y)
                        ctx.stroke()
                    }

                    // route
                    ctx.strokeStyle = "#4a9eff"
                    ctx.lineWidth = 3
                    ctx.beginPath()
                    ctx.moveTo(40, height - 40)
                    ctx.bezierCurveTo(120, height - 80, 200, 60, width - 40, 40)
                    ctx.stroke()
                }
            }

            Rectangle {
                width: 14
                height: 14
                radius: 7
                color: "#ff4a4a"
                border.color: "#ffffff"
                border.width: 2
                x: parent.width - 50
                y: 30
            }
        }

        Text {
            text: mapView.nextInstruction
            color: "#aaaacc"
            font.pixelSize: 14
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }
}
