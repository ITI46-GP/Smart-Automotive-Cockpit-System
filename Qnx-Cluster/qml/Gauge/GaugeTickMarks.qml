// Ported from 02-Digital-Cluster/Gauge/GaugeTickMarks.qml — Repeater of
// rotated Rectangles, no Canvas. Per PLAN.md's audit this was already
// compliant before the rebuild started, so it is ported close to verbatim.
// Changes: the Theme import (C++ QML_SINGLETON now, needs `import
// QnxCluster`), an explicit `required property var modelData`, and the notes
// below. The rendering strategy is untouched.
//
// ── WHY THIS IS PORTED AS-IS RATHER THAN "IMPROVED" FIRST ──
// This is the heaviest stage in the ladder by instance count: 49 ticks on the
// speed gauge (0-240 step 5) and 81 on the rpm gauge (0-8 step 0.1) = 130
// rotated Items, each with a Rectangle and a ColorAnimation Behavior. It is
// tempting to pre-optimise. Don't. This project has already built half a
// rendering rewrite for a problem that did not exist; the discipline is to
// port faithfully, measure, and only then change what the numbers say to
// change. If it fails, the likely culprits in order are:
//
//   1. `animations=` — 130 more ColorAnimation Behaviors. This is GUI-thread
//      work in the same pass as polish, and it is now part of the measured
//      budget in tools/analyze_frames.py precisely because of this stage.
//      Fix if needed: drop the Behavior and switch colour instantly, or
//      colour ticks by static position instead of animating (the approach
//      BottomLayer/SegmentedGauge.qml already uses).
//   2. Draw-call count — each tick's Rotation transform breaks batching, so
//      130 ticks is ~130 extra draw calls. Fix if needed: bake the passive
//      tick ring to a PNG (Rule 2) and draw only the active ticks live.
//
// Both fixes cost visual fidelity, so neither is worth spending until a
// measurement says so.

import QtQuick
import QnxCluster

Item {
    id: ticksRoot

    // ════════════════════════════════════════════════════
    //  PUBLIC API
    // ════════════════════════════════════════════════════

    // Driving value (for active/passive coloring)
    property real value:    0
    property real maxValue: 240

    // Step sizes (in value units)
    property real bigStep:    30    // BIG tick + label every 30 units
    property real mediumStep: 10    // MEDIUM tick every 10 units
    property real smallStep:  5     // SMALL tick every 5 units

    // Tick geometry — distance from center
    property real tickOuterRadius: 220  // where ALL ticks end (outer)
    property real tickLengthBig:    35
    property real tickLengthMedium: 20
    property real tickLengthSmall:  12

    // Tick line widths
    property real tickWidthBig:    3
    property real tickWidthMedium: 1.8
    property real tickWidthSmall:  1.0

    // Angle range — MUST match GaugeActiveArc and GaugeLabels
    property real startAngle: 135
    property real sweepAngle: 270

    // Colors (default to Theme)
    property color colorActive:  Theme.colorTextPrimary
    property color colorPassive: Theme.colorTextMuted

    // ════════════════════════════════════════════════════
    //  S6 DIAGNOSTIC KNOBS — all default to the faithful original
    // ════════════════════════════════════════════════════
    // S6 failed its gate (render p50 6 -> 12 ms for +130 ticks) and the first
    // hypothesis — a draw-call explosion from per-tick Rotation transforms
    // breaking batching — was DISPROVED by QSG_RENDERER_DEBUG=render on the
    // board: 130 tick nodes added only 12 batches (22 vs 10). Qt batches them
    // fine. What the same dump did show is `Opaque: 0 nodes` — every node is
    // in the blended alpha pass.
    //
    // These four knobs exist so the remaining suspects can each be isolated
    // from ONE build, instead of rebuilding per guess. Each defaults to the
    // original behaviour, so leaving them alone changes nothing.
    //
    //   roundedTicks   radius = width/2 makes Qt use the smooth antialiased
    //                  rounded-rect material: extra AA border geometry and a
    //                  blended fill, versus a plain opaque quad.
    //   antialiasTicks the AA flag independently of the radius.
    //   animateColor   130 ColorAnimation Behaviors; any tick mid-transition
    //                  dirties its batch and forces a vertex re-upload.
    //   dimPassiveSmall the per-item opacity tweak, which also forces a node
    //                  into the alpha pass even when its colour is opaque.
    property bool roundedTicks:    true
    property bool antialiasTicks:  true
    property bool animateColor:    true
    property bool dimPassiveSmall: true

    // ── Round 2 knobs: separate NODE COUNT from FILL from TRANSFORM ──
    // Round 1 disproved every styling suspect, which leaves three mechanisms
    // that all scale with "130 more things on screen" and that round 1 could
    // not tell apart. Each of these changes exactly one of them while holding
    // the others fixed:
    //
    //   drawEvery   renders every Nth tick. Fewer nodes, same size, same
    //               transforms, same materials -> isolates NODE COUNT. If
    //               render time scales with this, count is the mechanism.
    //   tinyTicks   same node count and transforms, ~6x less covered area
    //               -> isolates FILL RATE / blended overdraw.
    //   noRotation  same node count and size, no per-tick Rotation transform
    //               -> isolates TRANSFORM/scene-graph traversal cost. The
    //               result looks wrong on screen (all ticks stack at 12
    //               o'clock); it is a measurement, not a rendering.
    property int  drawEvery:  1
    property bool tinyTicks:  false
    property bool noRotation: false


    // ════════════════════════════════════════════════════
    //  INTERNAL — build the tick model
    // ════════════════════════════════════════════════════
    //
    // Evaluated once (it depends only on the step/max properties, not on
    // `value`), so the per-frame cost of this component is colour changes
    // and transforms — not model rebuilding. If a future call site binds any
    // of these steps to something animated, this whole array rebuilds every
    // frame on the GUI thread; don't.
    readonly property var tickModel: {
        // Both tick implementations ship in the same binary and are selected
        // at runtime, so the unused one must cost nothing — otherwise its
        // Repeater still instantiates 130 delegates and contaminates exactly
        // the measurement it was built to inform.
        if (!ticksRoot.visible)
            return []

        var arr = []
        var eps = 0.0001

        function isMultipleOf(value, step) {
            var remainder = value % step
            return remainder < eps || (step - remainder) < eps
        }

        for (var v = 0; v <= maxValue + eps; v += smallStep) {
            // Round to avoid floating-point drift accumulating
            var roundedV = Math.round(v / smallStep) * smallStep

            var kind
            if (isMultipleOf(roundedV, bigStep)) {
                kind = "big"
            } else if (isMultipleOf(roundedV, mediumStep)) {
                kind = "medium"
            } else {
                kind = "small"
            }
            arr.push({ val: roundedV, kind: kind })
        }

        // drawEvery is a diagnostic subsample (see the knobs above), not a
        // feature. At 1 — the default — this is a no-op and the array is the
        // faithful original.
        if (ticksRoot.drawEvery > 1) {
            var sub = []
            for (var i = 0; i < arr.length; i += ticksRoot.drawEvery)
                sub.push(arr[i])
            return sub
        }
        return arr
    }

    readonly property real centerX: width  / 2
    readonly property real centerY: height / 2


    // ════════════════════════════════════════════════════
    //  TICK RENDERING
    // ════════════════════════════════════════════════════
    //   1. Each tick is a small Rectangle placed at 12 o'clock.
    //   2. Its container is rotated around the gauge centre.
    //   Rectangle and rotation are both GPU work; no per-frame paint code.
    Repeater {
        model: ticksRoot.tickModel

        delegate: Item {
            id: tickSlot
            required property var modelData

            // value=0 → startAngle; value=maxValue → startAngle + sweepAngle.
            // +90 converts from math angle (0=right) to Item rotation (0=up).
            property real tickAngleDeg:
                ticksRoot.startAngle
                + (tickSlot.modelData.val / ticksRoot.maxValue) * ticksRoot.sweepAngle
                + 90

            property real tickLength:
                ticksRoot.tinyTicks ? 3 :
                tickSlot.modelData.kind === "big"    ? ticksRoot.tickLengthBig    :
                tickSlot.modelData.kind === "medium" ? ticksRoot.tickLengthMedium :
                                                       ticksRoot.tickLengthSmall

            property real tickWidth:
                tickSlot.modelData.kind === "big"    ? ticksRoot.tickWidthBig    :
                tickSlot.modelData.kind === "medium" ? ticksRoot.tickWidthMedium :
                                                       ticksRoot.tickWidthSmall

            // Active = tick is below or at current value
            property bool isActive: tickSlot.modelData.val <= ticksRoot.value

            anchors.fill: parent
            transform: Rotation {
                origin.x: ticksRoot.centerX
                origin.y: ticksRoot.centerY
                // angle 0 keeps the transform node present but makes every
                // tick land in the same place — same node count, no distinct
                // transforms. Diagnostic only; it does not render correctly.
                angle:    ticksRoot.noRotation ? 0 : tickSlot.tickAngleDeg
            }

            Rectangle {
                width:  tickSlot.tickWidth
                height: tickSlot.tickLength
                radius: ticksRoot.roundedTicks ? tickSlot.tickWidth / 2 : 0
                antialiasing: ticksRoot.antialiasTicks && ticksRoot.roundedTicks

                x: ticksRoot.centerX - width / 2
                y: ticksRoot.centerY - ticksRoot.tickOuterRadius

                color: tickSlot.isActive ? ticksRoot.colorActive
                                         : ticksRoot.colorPassive

                // Subtle opacity tweak so big ticks really stand out
                opacity: (ticksRoot.dimPassiveSmall
                          && tickSlot.modelData.kind === "small"
                          && !tickSlot.isActive) ? 0.5 : 1.0

                Behavior on color {
                    enabled: ticksRoot.animateColor
                    ColorAnimation { duration: Theme.durationFast }
                }
            }
        }
    }
}
