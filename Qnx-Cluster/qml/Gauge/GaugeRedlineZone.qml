// S6.5 — red tick marks over the danger portion of the dial, overlaid on
// GaugeTickMarks. Ported from 02-Digital-Cluster/Gauge/GaugeRedlineZone.qml
// with the same public API and the same visual result.
//
// ── WHY THIS IS SHAPE-BASED FROM THE START, UNLIKE THE OTHER PORTS ──
// The standing rule in this project is to port faithfully first and only
// change what a measurement demands. This is the one justified exception,
// because the measurement already exists: S6 tested this exact content type
// on this exact board. 130 tick Rectangles cost ~5 ms of render thread; the
// same ticks as stroked `PathMultiline` paths cost ~1 ms. Porting 28
// Rectangles here would not be caution, it would be re-running a settled
// experiment. `--no-redline` still isolates the stage's cost either way.
//
// This component has it even easier than GaugeTickMarks: the redline never
// changes at all. It does not read `value`, has no active/passive split, and
// is one flat colour — so its geometry is built once at startup and Qt never
// re-triangulates it. Three ShapePaths (big/medium/small stroke widths),
// fixed forever.
//
// Angle convention and tick geometry must stay in sync with GaugeTickMarks
// and GaugeLabels (startAngle 135, sweepAngle 270). A mismatch shows up as
// red ticks sitting slightly off the grey ones underneath, not as an error.

import QtQuick
import QtQuick.Shapes
import QnxCluster

Item {
    id: redlineRoot

    // ════════════════════════════════════════════════════
    //  PUBLIC API — identical to the original
    // ════════════════════════════════════════════════════

    // Range where the redline starts (in value units)
    property real redlineStart: 5      // e.g. 5 (= 5000 RPM) or 210 (= 210 km/h)
    property real maxValue:     6      // gauge max

    // Step sizes — should match GaugeTickMarks
    property real bigStep:    1
    property real mediumStep: 0.5
    property real smallStep:  0.1

    // Tick geometry — should match GaugeTickMarks
    property real tickOuterRadius: 220
    property real tickLengthBig:    35
    property real tickLengthMedium: 20
    property real tickLengthSmall:  12

    property real tickWidthBig:    3
    property real tickWidthMedium: 1.8
    property real tickWidthSmall:  1.0

    // Angle range — must match the rest of the gauge
    property real startAngle: 135
    property real sweepAngle: 270

    // Redline color (use Theme by default)
    property color redlineColor: Theme.colorDanger

    // Straight segments, so the triangulating renderer is the right choice —
    // S6 measured CurveRenderer at nearly double the cost for polylines,
    // since there are no curves for it to resolve analytically.
    property bool useCurveRenderer: false

    readonly property real centerX: width  / 2
    readonly property real centerY: height / 2


    // ════════════════════════════════════════════════════
    //  INTERNAL — build only the redline ticks
    // ════════════════════════════════════════════════════
    readonly property var tickModel: {
        var arr = []
        var eps = 0.0001

        function isMultipleOf(v, step) {
            var remainder = v % step
            return remainder < eps || (step - remainder) < eps
        }

        for (var v = redlineStart; v <= maxValue + eps; v += smallStep) {
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

    // Polylines per stroke width, computed once. Nothing here depends on the
    // gauge value, so these bindings evaluate at startup and never again.
    readonly property var segmentsByKind: {
        var out = { "big": [], "medium": [], "small": [] }
        if (!visible)
            return out

        var model = tickModel
        var rOut = tickOuterRadius
        var lens = { "big":    tickOuterRadius - tickLengthBig,
                     "medium": tickOuterRadius - tickLengthMedium,
                     "small":  tickOuterRadius - tickLengthSmall }

        for (var i = 0; i < model.length; ++i) {
            // Polar form, 0 deg = right, +CW — matching GaugeActiveArc's
            // PathAngleArc and GaugeLabels. (The original reached the same
            // placement by parking a Rectangle at 12 o'clock and rotating by
            // angle + 90; the two were verified numerically identical in S6.)
            var a = (startAngle + (model[i].val / maxValue) * sweepAngle)
                    * Math.PI / 180.0
            var dx = Math.cos(a), dy = Math.sin(a)
            var rIn = lens[model[i].kind]

            out[model[i].kind].push([
                Qt.point(centerX + dx * rIn,  centerY + dy * rIn),
                Qt.point(centerX + dx * rOut, centerY + dy * rOut)
            ])
        }
        return out
    }


    // ════════════════════════════════════════════════════
    //  RENDERING — 1 Shape, 3 static ShapePaths
    // ════════════════════════════════════════════════════
    Shape {
        anchors.fill: parent
        preferredRendererType: redlineRoot.useCurveRenderer ? Shape.CurveRenderer
                                                            : Shape.GeometryRenderer

        ShapePath {
            strokeWidth: redlineRoot.tickWidthBig
            strokeColor: redlineRoot.redlineColor
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathMultiline { paths: redlineRoot.segmentsByKind["big"] }
        }
        ShapePath {
            strokeWidth: redlineRoot.tickWidthMedium
            strokeColor: redlineRoot.redlineColor
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathMultiline { paths: redlineRoot.segmentsByKind["medium"] }
        }
        ShapePath {
            strokeWidth: redlineRoot.tickWidthSmall
            strokeColor: redlineRoot.redlineColor
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathMultiline { paths: redlineRoot.segmentsByKind["small"] }
        }
    }
}
