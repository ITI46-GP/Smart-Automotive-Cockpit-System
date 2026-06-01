import QtQuick
import QtQuick.Controls
import Digital_Cluster_DesignStudio
import QtQuick.Studio.DesignEffects

Item {
    id: carWrapper
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.horizontalCenterOffset: 0
    width: 300
    height: 300
    scale: 1
    y: 225

    // horizontal sway (lane-keeping)
    SequentialAnimation on x {
        loops: Animation.Infinite
        running: true
        NumberAnimation { to:  3; duration: 2200; easing.type: Easing.InOutSine }
        NumberAnimation { to: -3; duration: 2400; easing.type: Easing.InOutSine }
        NumberAnimation { to:  2; duration: 1800; easing.type: Easing.InOutSine }
        NumberAnimation { to: -1; duration: 2000; easing.type: Easing.InOutSine }
        NumberAnimation { to:  0; duration: 1600; easing.type: Easing.InOutSine }
    }

    Image {
        id: car
        anchors.centerIn: parent
        source: "../assets/Tesla_Car.png"
        // source: "../assets/Tesla_Car.png"
        scale: 0.25
        fillMode: Image.PreserveAspectFit
        smooth: true

        // engine vibration (fast tiny jitter)
        SequentialAnimation on y {
            loops: Animation.Infinite
            running: true
            NumberAnimation { to:  0.4; duration: 60; easing.type: Easing.InOutSine }
            NumberAnimation { to: -0.4; duration: 60; easing.type: Easing.InOutSine }
            NumberAnimation { to:  0.3; duration: 55; easing.type: Easing.InOutSine }
            NumberAnimation { to: -0.3; duration: 55; easing.type: Easing.InOutSine }
            NumberAnimation { to:  0.0; duration: 60; easing.type: Easing.InOutSine }
        }
        opacity: 0.8

        // road bumps (slower bounce)
        SequentialAnimation on anchors.verticalCenterOffset {
            loops: Animation.Infinite
            running: true
            NumberAnimation { to:  2.5; duration: 700; easing.type: Easing.InOutSine }
            NumberAnimation { to: -1.0; duration: 600; easing.type: Easing.InOutSine }
            NumberAnimation { to:  1.5; duration: 800; easing.type: Easing.InOutSine }
            NumberAnimation { to: -0.5; duration: 650; easing.type: Easing.InOutSine }
            NumberAnimation { to:  0.0; duration: 700; easing.type: Easing.InOutSine }
        }

        // body roll (tilt while swaying)
        SequentialAnimation on rotation {
            loops: Animation.Infinite
            running: true
            NumberAnimation { to:  0.4; duration: 1100; easing.type: Easing.InOutSine }
            NumberAnimation { to: -0.4; duration: 1200; easing.type: Easing.InOutSine }
            NumberAnimation { to:  0.2; duration: 900;  easing.type: Easing.InOutSine }
            NumberAnimation { to: -0.2; duration: 950;  easing.type: Easing.InOutSine }
            NumberAnimation { to:  0.0; duration: 800;  easing.type: Easing.InOutSine }
        }

        // subtle scale breathing
        SequentialAnimation on scale {
            loops: Animation.Infinite
            running: true
            NumberAnimation { to: 0.252; duration: 1400; easing.type: Easing.InOutSine }
            NumberAnimation { to: 0.248; duration: 1400; easing.type: Easing.InOutSine }
        }

        DesignEffect {
            layerBlurRadius: 2
            effects: [
                DesignDropShadow {
                    color: "#a7000000"
                    showBehind: true
                    offsetY: 110
                    offsetX: 0
                    blur: 25
                }
            ]
        }
    }

    // ground shadow under the car
    Rectangle {
        id: groundShadow
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: 70
        width: 110
        height: 12
        radius: height / 2
        color: "black"
        opacity: 0.45
        z: -1

        SequentialAnimation on opacity {
            loops: Animation.Infinite
            running: true
            NumberAnimation { to: 0.55; duration: 700; easing.type: Easing.InOutSine }
            NumberAnimation { to: 0.35; duration: 600; easing.type: Easing.InOutSine }
            NumberAnimation { to: 0.50; duration: 800; easing.type: Easing.InOutSine }
            NumberAnimation { to: 0.40; duration: 650; easing.type: Easing.InOutSine }
            NumberAnimation { to: 0.45; duration: 700; easing.type: Easing.InOutSine }
        }

        SequentialAnimation on scale {
            loops: Animation.Infinite
            running: true
            NumberAnimation { to: 1.05; duration: 700; easing.type: Easing.InOutSine }
            NumberAnimation { to: 0.95; duration: 600; easing.type: Easing.InOutSine }
            NumberAnimation { to: 1.02; duration: 800; easing.type: Easing.InOutSine }
            NumberAnimation { to: 0.98; duration: 650; easing.type: Easing.InOutSine }
            NumberAnimation { to: 1.00; duration: 700; easing.type: Easing.InOutSine }
        }
    }
}
