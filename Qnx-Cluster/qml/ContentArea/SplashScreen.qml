// Ported from 02-Digital-Cluster/Digital_Cluster_DesignStudioContent/
// SplashScreen.qml: the one-time wake-up choreography that plays before
// the dashboard, verbatim in structure and timing.
//
// ── WHAT CHANGED FROM THE ORIGINAL ──
//   * `assets/front_car.png` (843x499) -> qrc alias `qrc:/art/SplashCar.png`,
//     never a relative path (the S1 trap). `sourceSize` set to its actual
//     display extent (600 wide, preserving aspect) per the standing image
//     rule, and `mipmap: false` so it can share Qt's texture atlas — same
//     as every other Image in this project.
//   * `welcomeText` had no `font.family` in the original, which would
//     silently render blank text: this QNX image ships no fonts at all
//     (established at S5), so anything without an explicit embedded family
//     draws nothing. Set to `Theme.fontPrimary` ("Kdam Thmor Pro", the one
//     face embedded for the whole app) instead.
//   * Dropped `layer.enabled: true` on the two headlight strips. Studio
//     left it with no `layer.effect` attached, so it was a no-op offscreen
//     pass — exactly the kind of unmeasured `layer.enabled` this project's
//     standing rules say not to carry forward (see S6/S9/S10 notes on
//     `layer.enabled` costing a real pass on this GPU). Dropping it changes
//     nothing visually.
//
// ── WHY THIS IS SAFE FOR THE PERF LADDER ──
// Every animation here is opacity-only (S3's established "transform/opacity
// is free" rule) and the whole sequence is a ONE-TIME ~3.3 s startup play
// (300 + 1200 + 1200 + 600 ms) that sets `visible: false` on itself when
// done — it cannot contribute to any steady-state measurement window that
// starts after that, the same reasoning that already applies to the
// gauges' own startup state.

import QtQuick
import QnxCluster

Item {
    id: splashRoot
    anchors.fill: parent

    // Tells the main UI the wake-up sequence finished. Nothing in this
    // rebuild currently needs to react (the gauges are already live and
    // continuously animating underneath, unlike the original's parked-
    // then-swept startup choreography), but the signal is kept so a future
    // stage can hook it without touching this file again.
    signal startupComplete()

    // Pitch black background for a premium feel
    Rectangle {
        anchors.fill: parent
        color: "#050505"
    }

    // 1. Soft behind-the-car glow
    Rectangle {
        id: haloGlow
        anchors.centerIn: carVisual
        width: 600; height: 300
        radius: 300
        anchors.verticalCenterOffset: 24
        anchors.horizontalCenterOffset: 0
        opacity: 0

        gradient: Gradient {
            GradientStop { position: 0.0; color: "#22ffffff" }
            GradientStop { position: 1.0; color: "transparent" }
        }
    }

    // 2. The car image
    Image {
        id: carVisual
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -40
        width: 600
        height: width * (499 / 843)
        fillMode: Image.PreserveAspectFit

        source: "qrc:/art/SplashCar.png"
        sourceSize: Qt.size(width, height)
        mipmap: false
        smooth: true
        scale: 0.85

        opacity: 0
    }

    // 3. Headlight "eyebrows" (DRLs) — small glowing lines positioned over
    // the physical headlights in the image.
    Item {
        id: headlights
        anchors.centerIn: carVisual
        anchors.verticalCenterOffset: 15
        width: 440
        opacity: 0

        Rectangle {
            y: -17
            anchors.left: parent.left
            anchors.leftMargin: 63
            width: 60; height: 4
            radius: 2
            color: "#ffffff"
            rotation: 40.071
        }

        Rectangle {
            x: 320
            y: -16
            anchors.right: parent.right
            anchors.rightMargin: 60
            width: 60; height: 4
            radius: 2
            color: "#ffffff"
            rotation: -37.346
        }
    }

    // 4. Premium minimalist wordmark
    Text {
        id: welcomeText
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 80
        anchors.horizontalCenter: parent.horizontalCenter

        text: "HYPER-NOVA"
        color: "#ffffff"
        font.family: Theme.fontPrimary
        font.pixelSize: 42
        font.letterSpacing: 12
        font.weight: Font.Light
        opacity: 0
    }

    // 5. The wake-up choreography — timings verbatim from the original.
    SequentialAnimation {
        running: true

        // Phase 1: headlights snap on (fast)
        PropertyAnimation {
            target: headlights; property: "opacity"; to: 1.0
            duration: 300; easing.type: Easing.OutQuint
        }

        // Phase 2: smoothly reveal the car, halo, and text
        ParallelAnimation {
            PropertyAnimation { target: carVisual;  property: "opacity"; to: 1.0; duration: 1200; easing.type: Easing.InOutQuad }
            PropertyAnimation { target: haloGlow;   property: "opacity"; to: 1.0; duration: 1200; easing.type: Easing.InOutQuad }
            PropertyAnimation { target: welcomeText; property: "opacity"; to: 1.0; duration: 900;  easing.type: Easing.InOutQuad }
        }

        PauseAnimation { duration: 1200 }

        // Phase 3: fade out everything to reveal the dashboard
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
                splashRoot.startupComplete()
            }
        }
    }
}
