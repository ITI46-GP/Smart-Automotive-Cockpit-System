import QtQuick
import QtQuick.Controls

Item {
    id: splashRoot
    anchors.fill: parent

    // This signal tells the main UI to start the gauge sweep
    signal startupComplete()

    // Pitch black background for a premium feel
    Rectangle {
        anchors.fill: parent
        color: "#050505"
    }

    // 1. Soft Behind-the-Car Glow
    Rectangle {
        id: haloGlow
        anchors.centerIn: carVisual
        width: 600; height: 300
        radius: 300
        anchors.verticalCenterOffset: 24
        anchors.horizontalCenterOffset: 0
        opacity: 0 // Starts hidden

        // Creates a smooth radial fade from center to transparent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#22ffffff" } // Very soft white in center
            GradientStop { position: 1.0; color: "transparent" }
        }
    }

    // 2. The Car Image
    Image {
        id: carVisual
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -40 // Lifted slightly above center
        width: 600
        fillMode: Image.PreserveAspectFit

        // IMPORTANT: Update this path to wherever you saved the image
        source: "assets/front_car.png"
        scale: 0.85

        opacity: 0 // Starts hidden
    }

    // 3. Headlight "Eyebrows" (DRLs)
    // These position small glowing lines over the physical headlights in the image
    Item {
        id: headlights
        anchors.centerIn: carVisual
        anchors.verticalCenterOffset: 15 // Tweak this to align exactly with the car's headlights
        width: 440 // Distance between the left and right headlights
        opacity: 0

        // Left Headlight Strip
        Rectangle {
            y: -17
            anchors.left: parent.left
            anchors.leftMargin: 63
            width: 60; height: 4
            radius: 2
            color: "#ffffff"
            rotation: 40.071 // Angles slightly to match the Model 3 hood line

            // Optional: built-in soft glow
            layer.enabled: true
        }

        // Right Headlight Strip
        Rectangle {
            x: 320
            y: -16
            anchors.right: parent.right
            anchors.rightMargin: 60
            width: 60; height: 4
            radius: 2
            color: "#ffffff"
            rotation: -37.346

            layer.enabled: true
        }
    }

    // 4. Premium Minimalist Text
    Text {
        id: welcomeText
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 80
        anchors.horizontalCenter: parent.horizontalCenter

        text: "HYPER-NOVA"
        color: "#ffffff"
        font.pixelSize: 42
        font.letterSpacing: 12 // Wide letter spacing looks more premium
        font.weight: Font.Light
        opacity: 0
    }

    // 5. The Wake-Up Choreography
    SequentialAnimation {
        running: true // Auto-starts when the app opens

        // PauseAnimation { duration: 400 } // Brief pause of pure black

        // Phase 1: Headlights snap on (fast)
        PropertyAnimation {
            target: headlights; property: "opacity"; to: 1.0;
            duration: 300; easing.type: Easing.OutQuint
        }

        // Phase 2: Smoothly reveal the car, halo, and text
        ParallelAnimation {
            PropertyAnimation { target: carVisual; property: "opacity"; to: 1.0; duration: 1200; easing.type: Easing.InOutQuad }
            PropertyAnimation { target: haloGlow; property: "opacity"; to: 1.0; duration: 1200; easing.type: Easing.InOutQuad }
            PropertyAnimation { target: welcomeText; property: "opacity"; to: 1.0; duration: 900; easing.type: Easing.InOutQuad }
        }

        PauseAnimation { duration: 1200 } // Hold the fully lit screen so the user can see it

        // Phase 3: Fade out everything to reveal the dashboard
        NumberAnimation {
            target: splashRoot
            property: "opacity"
            to: 0
            duration: 600
            easing.type: Easing.InOutQuad
        }

        ScriptAction {
            script: {
                splashRoot.visible = false
                splashRoot.startupComplete() // Trigger the gauge sweep!
            }
        }
    }
}
