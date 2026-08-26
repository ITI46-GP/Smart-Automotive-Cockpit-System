// S8 — ported from 02-Digital-Cluster/Digital_Cluster_DesignStudioContent/
// Content_Area/Car.qml: the car sprite with its idle motion, plus the small
// ground shadow ellipse under it.
//
// ── THE ONE REAL CHANGE: the drop shadow is baked ──
// The original wraps the car Image in a `DesignEffect` with a
// `DesignDropShadow` (offsetY 110, blur 25, #a7000000) and `layerBlurRadius: 2`.
// A DesignEffect is a `layer.enabled` pass: Qt renders the item to an offscreen
// texture, blurs it and composites it back, every frame, for a shadow whose
// shape relative to the car never changes. On this board that is doubly bad —
// an extra offscreen pass plus extra blended coverage, and S6 measured
// overlapping translucent content at 37 ms vs 11 ms.
//
// So the shadow is baked into the sprite offline (tools/gen_car.py). Runtime
// cost: one ordinary Image, no offscreen pass, no blur.
//
// ── SIZING ──
// The sprite is the car PLUS its shadow, so it is wider and taller than the
// car alone and the car is NOT centred in it. Both numbers come from
// tools/gen_car.py, which prints them:
//   * the car occupies 0.9152 of the sprite width, so a sprite drawn 159.2 px
//     wide puts the car at the original's 145.8 px (583 source px x scale 0.25)
//   * the car's centre sits at 0.4097 of the sprite height, so the Image is
//     nudged down by ~17 px to leave the CAR where the original centred it
// Re-run the generator if the shadow parameters change; it reprints both.
//
// The idle animations are kept verbatim. They are transform and opacity
// animations, which this board handles cheaply — S3 established that
// transform-only animation is free, and none of these add a draw call.

import QtQuick

Item {
    id: carWrapper
    // Position is fully owned by the caller (see CarView in Main.qml,
    // ported verbatim from 02-Digital-Cluster's CarView.qml: `anchors.
    // verticalCenter` + `verticalCenterOffset: 235` on an 800x700 canvas —
    // i.e. the car sits LOW, ~84% down, not centred). Two earlier attempts
    // here (a fixed `y:225` tuned for one container size, then a hardcoded
    // `anchors.centerIn`) both fought whatever the caller was doing instead
    // of deferring to it. This wrapper now only centres itself horizontally
    // and otherwise stays out of the way.
    anchors.horizontalCenter: parent.horizontalCenter
    width: 300
    height: 300

    // Sprite geometry, from tools/gen_car.py's report.
    readonly property real spriteWidth:  159.2
    readonly property real spriteAspect: 1.1915   // height / width
    readonly property real carCentreY:   0.4097   // car centre, fraction of sprite height

    // Exposes the actual car Image, not just this wrapper's own bounding
    // box. The wrapper is sized for the sprite (which includes the shadow
    // below the car), so its own centre is NOT where the car pixels are —
    // Main.qml's startup log was mapping carItem.width/2,height/2 and
    // silently missing the ~17 px verticalCenterOffset below. Use
    // `carImage` for any position that needs to line up with what's drawn.
    property alias carImage: car

    // ── speed ──────────────────────────────────────────────
    //
    // The sway, engine vibration, body roll and scale breathing all used to
    // run at fixed amplitudes regardless of whether the car was moving, so a
    // stationary vehicle still weaved and shook.
    //
    // Amplitudes now scale with speed, reaching their original values at
    // referenceSpeedKph so the look at a normal cruise is unchanged. At a
    // standstill every amplitude is 0 and the car sits still.
    //
    // The animations keep running rather than being stopped: each step
    // re-reads its `to` when it begins, so amplitude tracks speed without
    // restarting the sequence, and animating toward a constant 0 is cheap.
    // Stopping them instead would freeze the car wherever its last step left
    // it, off-centre.
    property real speedKph: 0
    readonly property real referenceSpeedKph: 100
    readonly property real motion: Math.min(speedKph / referenceSpeedKph, 1.5)

    // horizontal sway (lane-keeping)
    SequentialAnimation on x {
        loops: Animation.Infinite
        running: true
        NumberAnimation { to:  3 * carWrapper.motion; duration: 2200; easing.type: Easing.InOutSine }
        NumberAnimation { to: -3 * carWrapper.motion; duration: 2400; easing.type: Easing.InOutSine }
        NumberAnimation { to:  2 * carWrapper.motion; duration: 1800; easing.type: Easing.InOutSine }
        NumberAnimation { to: -1 * carWrapper.motion; duration: 2000; easing.type: Easing.InOutSine }
        NumberAnimation { to:  0;                     duration: 1600; easing.type: Easing.InOutSine }
    }

    Image {
        id: car
        source: "qrc:/art/CarWithShadow.png"

        width: carWrapper.spriteWidth
        height: carWrapper.spriteWidth * carWrapper.spriteAspect

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        // Put the CAR (not the sprite, which includes the shadow below it)
        // where the original centred the car image.
        anchors.verticalCenterOffset:
            (0.5 - carWrapper.carCentreY) * height

        // Standing rules from S7.5: decode at display size, and keep mipmap
        // off so the sprite can live in Qt's shared texture atlas rather than
        // taking a dedicated texture and its own draw call.
        sourceSize: Qt.size(width, height)
        mipmap: false
        smooth: true
        opacity: 0.8

        // engine vibration (fast tiny jitter)
        SequentialAnimation on y {
            loops: Animation.Infinite
            running: true
            NumberAnimation { to:  0.4 * carWrapper.motion; duration: 60; easing.type: Easing.InOutSine }
            NumberAnimation { to: -0.4 * carWrapper.motion; duration: 60; easing.type: Easing.InOutSine }
            NumberAnimation { to:  0.3 * carWrapper.motion; duration: 55; easing.type: Easing.InOutSine }
            NumberAnimation { to: -0.3 * carWrapper.motion; duration: 55; easing.type: Easing.InOutSine }
            NumberAnimation { to:  0.0;                     duration: 60; easing.type: Easing.InOutSine }
        }

        // body roll (tilt while swaying)
        SequentialAnimation on rotation {
            loops: Animation.Infinite
            running: true
            NumberAnimation { to:  0.4 * carWrapper.motion; duration: 1100; easing.type: Easing.InOutSine }
            NumberAnimation { to: -0.4 * carWrapper.motion; duration: 1200; easing.type: Easing.InOutSine }
            NumberAnimation { to:  0.2 * carWrapper.motion; duration: 900;  easing.type: Easing.InOutSine }
            NumberAnimation { to: -0.2 * carWrapper.motion; duration: 950;  easing.type: Easing.InOutSine }
            NumberAnimation { to:  0.0;                     duration: 800;  easing.type: Easing.InOutSine }
        }

        // subtle scale breathing — the original animated 0.248..0.252 around a
        // base scale of 0.25, i.e. +/-0.8%. Expressed here as a scale around
        // 1.0 because the size is now set explicitly rather than via scale.
        SequentialAnimation on scale {
            loops: Animation.Infinite
            running: true
            NumberAnimation { to: 1.0 + 0.008 * carWrapper.motion; duration: 1400; easing.type: Easing.InOutSine }
            NumberAnimation { to: 1.0 - 0.008 * carWrapper.motion; duration: 1400; easing.type: Easing.InOutSine }
        }
    }

    // ground shadow under the car — kept live, not baked, because it pulses
    // and scales independently of the car.
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
            NumberAnimation { to: 0.45 + 0.10 * carWrapper.motion; duration: 700; easing.type: Easing.InOutSine }
            NumberAnimation { to: 0.45 - 0.10 * carWrapper.motion; duration: 600; easing.type: Easing.InOutSine }
            NumberAnimation { to: 0.45 + 0.05 * carWrapper.motion; duration: 800; easing.type: Easing.InOutSine }
            NumberAnimation { to: 0.45 - 0.05 * carWrapper.motion; duration: 650; easing.type: Easing.InOutSine }
            NumberAnimation { to: 0.45;                            duration: 700; easing.type: Easing.InOutSine }
        }

        SequentialAnimation on scale {
            loops: Animation.Infinite
            running: true
            NumberAnimation { to: 1.0 + 0.05 * carWrapper.motion; duration: 700; easing.type: Easing.InOutSine }
            NumberAnimation { to: 1.0 - 0.05 * carWrapper.motion; duration: 600; easing.type: Easing.InOutSine }
            NumberAnimation { to: 1.0 + 0.02 * carWrapper.motion; duration: 800; easing.type: Easing.InOutSine }
            NumberAnimation { to: 1.0 - 0.02 * carWrapper.motion; duration: 650; easing.type: Easing.InOutSine }
            NumberAnimation { to: 1.0;                            duration: 700; easing.type: Easing.InOutSine }
        }
    }
}
