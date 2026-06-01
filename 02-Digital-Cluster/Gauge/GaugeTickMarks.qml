import QtQuick
import Digital_Cluster_DesignStudio

/*
 * ╔═══════════════════════════════════════════════════════════════╗
 * ║  GAUGE TICK MARKS                                             ║
 * ║                                                               ║
 * ║  Draws tick marks around a circular gauge.                    ║
 * ║  Variable sizes:                                              ║
 * ║    - BIG tick      → every `bigStep` units (with labels)      ║
 * ║    - MEDIUM tick   → every `mediumStep` units                 ║
 * ║    - SMALL tick    → every `smallStep` units                  ║
 * ║                                                               ║
 * ║  Active state (below current value) → bright color            ║
 * ║  Passive state (above current value) → muted color            ║
 * ║                                                               ║
 * ║  IMPLEMENTATION:                                              ║
 * ║    Uses Repeater of Rectangles rotated around the center.     ║
 * ║    NO Canvas → no lag, GPU-rendered.                          ║
 * ║                                                               ║
 * ║  ANGLE CONVENTION:                                            ║
 * ║    Item.rotation: 0° = up, +CW                                ║
 * ║    So when value=0, the tick at startAngle should point at... ║
 * ║    we compute rotation = startAngle + (value/max)*sweep       ║
 * ║    where startAngle uses standard math (0=right, +CCW would   ║
 * ║    be the opposite — but Qt's Item rotation is CW positive)   ║
 * ╚═══════════════════════════════════════════════════════════════╝
 */
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
    property real tickLengthBig:    35  // BIG tick length
    property real tickLengthMedium: 20  // MEDIUM tick length
    property real tickLengthSmall:  12  // SMALL tick length

    // Tick line widths
    property real tickWidthBig:    3
    property real tickWidthMedium: 1.8
    property real tickWidthSmall:  1.0

    // Angle range (Item rotation convention: 0=up, +CW)
    // To match GaugeActiveArc (0=right, +CW from 135°):
    //   startRotation = 135 + 90 = 225  (rotation when tick is at value=0)
    //   But Item.rotation 0 = up, so we need to subtract 90:
    //   Use the SAME values as the arc, the math handles it below
    property real startAngle: 135   // matches GaugeActiveArc startAngle
    property real sweepAngle: 270   // matches GaugeActiveArc sweepAngle

    // Colors (default to Theme)
    property color colorActive:  Theme.colorTextPrimary
    property color colorPassive: Theme.colorTextMuted


    // ════════════════════════════════════════════════════
    //  INTERNAL — build the tick model
    // ════════════════════════════════════════════════════

    // Generate a list of tick descriptions:
    //   { val: 30, kind: "big" }, { val: 35, kind: "small" }, ...
    readonly property var tickModel: {
        var arr = []
        // Small epsilon for floating point comparison
        var eps = 0.0001

        // Helper: check if value is a multiple of step (float-safe)
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
        return arr
    }

    // Center point of the gauge (the Item rotates around its own center)
    readonly property real centerX: width  / 2
    readonly property real centerY: height / 2


    // ════════════════════════════════════════════════════
    //  TICK RENDERING
    // ════════════════════════════════════════════════════
    //
    //  Strategy:
    //    1. Each tick is a small Rectangle.
    //    2. We place it at the top of the gauge (12 o'clock).
    //    3. We rotate the whole thing around the gauge center.
    //
    //  Why this works without Canvas:
    //    - Rectangle is GPU-rendered.
    //    - Rotation is also GPU.
    //    - No per-frame paint code.
    //    - Repaints only when active/passive color changes.

    Repeater {
        model: ticksRoot.tickModel

        delegate: Item {
            // The whole tick is a child of this Item, which is rotated
            // around the gauge center.

            // Compute this tick's angle:
            //   value=0       → at startAngle
            //   value=maxValue → at startAngle + sweepAngle
            //
            //   Convert from "math angle" (0=right) to "Item rotation" (0=up)
            //   by adding 90.
            property real tickAngleDeg:
                ticksRoot.startAngle
                + (modelData.val / ticksRoot.maxValue) * ticksRoot.sweepAngle
                + 90

            // Look up dimensions by tick kind
            property real tickLength:
                modelData.kind === "big"    ? ticksRoot.tickLengthBig    :
                modelData.kind === "medium" ? ticksRoot.tickLengthMedium :
                                              ticksRoot.tickLengthSmall

            property real tickWidth:
                modelData.kind === "big"    ? ticksRoot.tickWidthBig    :
                modelData.kind === "medium" ? ticksRoot.tickWidthMedium :
                                              ticksRoot.tickWidthSmall

            // Active = tick is below or at current value
            property bool isActive: modelData.val <= ticksRoot.value

            // The container Item fills the whole gauge area
            // and rotates around its center
            anchors.fill: parent
            transform: Rotation {
                origin.x: ticksRoot.centerX
                origin.y: ticksRoot.centerY
                angle:    tickAngleDeg
            }

            // The actual tick: a small rectangle at the top
            Rectangle {
                width:  tickWidth
                height: tickLength
                radius: tickWidth / 2

                // Position: horizontally centered, sitting on the outer edge
                x: ticksRoot.centerX - width / 2
                y: ticksRoot.centerY - ticksRoot.tickOuterRadius

                color: isActive
                       ? ticksRoot.colorActive
                       : ticksRoot.colorPassive

                // Subtle opacity tweak so big ticks really stand out
                opacity: modelData.kind === "small" && !isActive ? 0.5 : 1.0

                // Smooth color change when value crosses this tick
                Behavior on color {
                    ColorAnimation { duration: Theme.durationFast }
                }
            }
        }
    }
}
