import QtQuick
import QtQuick.Shapes

import Digital_Cluster_DesignStudio

Item {
    id: arcRoot

    // ════════════════════════════════════════════════════
    //  PUBLIC API
    // ════════════════════════════════════════════════════

    // The driving data
    property real value:    0      // current value (e.g., speed)
    property real maxValue: 240    // gauge maximum

    // ── HALO GEOMETRY ─────────────────────────────────
    // The halo fills the radial range between innerRadius
    // and outerRadius — same as the needle.
    property real innerRadius:   120   // where halo starts (= needle base)
    property real outerRadius:   202.5   // where halo ends   (= needle tip)

    // Centerline radius (derived) — middle of inner and outer
    readonly property real haloCenterRadius: (innerRadius + outerRadius) / 2

    // Thickness needed to span from inner to outer
    readonly property real haloThickness: 32 +   outerRadius - innerRadius

    // ── HALO OPACITY THRESHOLDS ─────────────────────────
    // The opacity reacts to the current value, getting
    // brighter as you approach the max.
    //
    // You can override any of these thresholds from outside.
    property real haloOpacityLow:    0.15   // default state
    property real haloOpacityMid:    0.25   // approaching limit
    property real haloOpacityHigh:   0.35   // near max

    // Threshold boundaries (as percentages of maxValue)
    property real haloMidThreshold:   0.79   // ~190/240
    property real haloHighThreshold:  0.875  // ~210/240

    // ── COMPUTED HALO OPACITY ───────────────────────────
    //
    // This is a BINDING — it re-evaluates automatically
    // whenever `value` or `maxValue` changes.
    // No function needed, no side effects.
    readonly property real haloOpacity: {
        var pct = value / maxValue
        if (pct > haloHighThreshold) return haloOpacityHigh
        if (pct > haloMidThreshold)  return haloOpacityMid
        return haloOpacityLow
    }

    // Angle range (Qt PathAngleArc convention: 0=right, +CW)
    property real startAngle:  135   // where 0 value sits
    property real sweepAngle:  270   // total angular span

    // Colors (default to Theme — can be overridden)
    property color colorDeep:   Theme.colorAccentDeep
    property color colorMid:    Theme.colorAccentPrimary
    property color colorBright: Theme.colorAccentBright

    // Animation
    property int animationDuration: Theme.durationNormal

    // ── OUTER BORDER ─────────────────────────────────────
    property bool  showOuterBorder:      true
    property real  outerBorderRadius:    outerRadius + 20
    property real  outerBorderThickness: 3
    property real  outerBorderOpacity:   0.45
    property color outerBorderColor:     Theme.colorTextPrimary
    property bool  outerBorderFullCircle: false





    // ════════════════════════════════════════════════════
    //  INTERNAL
    // ════════════════════════════════════════════════════

    // Add a toggle for the smoothing
    property bool enableSmoothing: true

    // Smoothly animated value
    property real animatedValue: arcRoot.value
    Behavior on animatedValue {
        enabled: arcRoot.enableSmoothing // <-- Tie the behavior to the toggle
        NumberAnimation {
            duration: arcRoot.animationDuration
            easing.type: Easing.OutCubic
        }
    }
    onValueChanged: animatedValue = value
    Component.onCompleted: animatedValue = value

    // Compute the current sweep based on the animated value
    readonly property real currentSweep:
        Math.max(0, Math.min(animatedValue / maxValue, 1.0)) * sweepAngle


    // ════════════════════════════════════════════════════
    //  LAYER 1 — OUTER BORDER (thin static white frame)
    // ════════════════════════════════════════════════════
    Shape {
        id: outerBorder
        anchors.fill: parent
        layer.enabled: true
        layer.samples: 8

        visible: arcRoot.showOuterBorder
        opacity: arcRoot.outerBorderOpacity
        smooth: true

        ShapePath {
            strokeWidth: arcRoot.outerBorderThickness
            strokeColor: arcRoot.outerBorderColor
            fillColor:   "transparent"
            capStyle:    ShapePath.FlatCap   // flat ends (no rounded caps)

            PathAngleArc {
                centerX:    arcRoot.width  / 2
                centerY:    arcRoot.height / 2
                radiusX:    arcRoot.outerBorderRadius
                radiusY:    arcRoot.outerBorderRadius

                startAngle: arcRoot.outerBorderFullCircle ? 0   : arcRoot.startAngle
                sweepAngle: arcRoot.outerBorderFullCircle ? 360 : arcRoot.sweepAngle
            }
        }
    }


    // ════════════════════════════════════════════════════
    //  LAYER 2 — HALO (soft red zone matching needle range)
    // ════════════════════════════════════════════════════
    //
    // Drawn as a thick stroked arc:
    //   - Radius:    haloCenterRadius (midway between inner and outer)
    //   - Width:     haloThickness    (= outerRadius - innerRadius)
    //   - Cap:       FlatCap          (no rounded ends)
    //
    // Result: a "filled zone" from innerRadius to outerRadius,
    // sweeping the same angular range as the needle has covered.
    Shape {
        anchors.fill: parent
        layer.enabled: true
        layer.samples: 8

        // ── BIND opacity directly to the computed property ──
        opacity: arcRoot.haloOpacity

        // Smooth fade when opacity changes between thresholds
        Behavior on opacity {
            NumberAnimation { duration: Theme.durationNormal; easing.type: Easing.OutCubic }
        }

        visible: arcRoot.currentSweep > 0

        ShapePath {
            strokeWidth: arcRoot.haloThickness
            strokeColor: arcRoot.colorBright
            fillColor:   "transparent"
            capStyle:    ShapePath.FlatCap   // ← clean flat ends

            PathAngleArc {
                centerX:    arcRoot.width  / 2
                centerY:    arcRoot.height / 2
                radiusX:    arcRoot.haloCenterRadius
                radiusY:    arcRoot.haloCenterRadius
                startAngle: arcRoot.startAngle
                sweepAngle: arcRoot.currentSweep
            }
        }
    }

}
