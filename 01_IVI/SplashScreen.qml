import QtQuick

Item {
    id: splashRoot
    anchors.fill: parent

    signal finished()

    property int splashDuration: 4000

    Rectangle {
        anchors.fill: parent
        color: "#07000E"

        Rectangle {
            width: parent.width * 1.2
            height: parent.height * 1.2
            anchors.centerIn: parent
            radius: width / 2
            opacity: 0.45

            gradient: Gradient {
                GradientStop { position: 0.0; color: "#1C162B" }
                GradientStop { position: 0.45; color: "#0A0A1B" }
                GradientStop { position: 1.0; color: "#07000E" }
            }

            SequentialAnimation on rotation {
                loops: Animation.Infinite
                NumberAnimation {
                    from: 0
                    to: 360
                    duration: 18000
                }
            }
        }

        Image {
            id: itiLogo
            width: 115
            height: 115
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: -115
            source: "assets/images/iti_logo.png"
            fillMode: Image.PreserveAspectFit
            smooth: true
            opacity: 0.95
        }

        Text {
            id: logoText
            anchors.top: itiLogo.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.topMargin: 22
            text: "NOVA Cockpit"
            color: "#CBC4CD"
            font.pixelSize: 64
            font.bold: true
            font.letterSpacing: 8
            opacity: 0.95
        }

        Text {
            id: cockpitText
            anchors.top: logoText.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.topMargin: 14
            text: "Intelligence Cockpit"
            color: "#8F7AA8"
            font.pixelSize: 19
            font.letterSpacing: 4
            opacity: 0.88
        }

        Text {
            id: sloganText
            anchors.top: cockpitText.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.topMargin: 12
            text: "Drive Beyond Limits"
            color: "#CBC4CD"
            font.pixelSize: 13
            font.letterSpacing: 3
            opacity: 0.55
        }

        Rectangle {
            id: loadingTrack
            width: 260
            height: 4
            radius: 2
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: sloganText.bottom
            anchors.topMargin: 34
            color: "#201926"
            border.color: "#3B2B55"

            Rectangle {
                id: loadingBar
                width: 0
                height: parent.height
                radius: 2
                color: "#A6080D"

                NumberAnimation on width {
                    from: 0
                    to: loadingTrack.width
                    duration: splashRoot.splashDuration - 500
                    easing.type: Easing.InOutQuad
                }
            }
        }

        Text {
            anchors.top: loadingTrack.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.topMargin: 18
            text: "INITIALIZING SYSTEM"
            color: "#CBC4CD"
            font.pixelSize: 13
            font.letterSpacing: 4
            opacity: 0.7
        }
    }

    Timer {
        interval: splashRoot.splashDuration
        running: true
        repeat: false

        onTriggered: {
            splashRoot.finished()
        }
    }
}
