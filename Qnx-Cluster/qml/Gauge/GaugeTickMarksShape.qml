// CANDIDATE FIX for S6 — drop-in alternative to GaugeTickMarks.qml with the
// same public API and the same visual result, but a handful of scene-graph
// nodes instead of 130.
//
// ── WHY ──
// S6 measured render p50 6 -> 12 ms when 130 tick Items were added. Six
// hypotheses were tested on target and all disproved (batching/draw calls,
// rounded-rect material, antialiasing, ColorAnimation, per-item opacity,
// batch re-upload and batch thresholds — see PLAN.md's S6 diagnosis table).
// What survives is that the cost tracks the sheer number of rendered
// primitives. So the fix has to reduce that number rather than restyle them.
//
// ── HOW ──
// Every tick is a radial line segment, so the whole ring is expressible as
// stroked polylines. `PathMultiline` takes a list of polylines in ONE
// ShapePath, so all ticks sharing a stroke width and colour collapse into a
// single path. A tick has 3 possible widths (big/medium/small) and 2 colour
// states (active/passive), giving 6 ShapePaths inside 1 Shape — versus 130
// Items each with a Rotation transform and a Rectangle.
//
// The active set is always a contiguous prefix (a tick is active when its
// value <= the gauge value), so it is fully described by `activeCount`. That
// is an integer that only changes when the needle crosses a tick, NOT every
// frame — so the path geometry is rebuilt a few times a second rather than 60
// times. Even if it were every frame, S3 established that animating a Shape's
// path geometry costs ~1-2 ms on this board, so this is safe either way.
//
// ── WHAT IS GIVEN UP ──
// The per-tick `Behavior on color` fade. A tick now flips colour the instant
// the value crosses it, because colour is a property of the whole path, not
// of an individual tick. Round 1 measured `--ticks-noanim` as visually
// near-identical and performance-identical, so this costs very little. If the
// fade is wanted back, it can be done by animating a third "just crossed"
// path's opacity — but measure before adding it.

import QtQuick
import QtQuick.Shapes
import QnxCluster

Item {
    id: ticksRoot

    // ════════════════════════════════════════════════════
    //  PUBLIC API — identical to GaugeTickMarks.qml
    // ════════════════════════════════════════════════════
    property real value:    0
    property real maxValue: 240

    property real bigStep:    30
    property real mediumStep: 10
    property real smallStep:  5

    property real tickOuterRadius: 220
    property real tickLengthBig:    35
    property real tickLengthMedium: 20
    property real tickLengthSmall:  12

    property real tickWidthBig:    3
    property real tickWidthMedium: 1.8
    property real tickWidthSmall:  1.0

    property real startAngle: 135
    property real sweepAngle: 270

    property color colorActive:  Theme.colorTextPrimary
    property color colorPassive: Theme.colorTextMuted

    // Matches GaugeTickMarks' `dimPassiveSmall`: small passive ticks are
    // dimmer. Applied as a separate ShapePath opacity rather than per tick.
    property bool dimPassiveSmall: true

    // Use the triangulating renderer rather than CurveRenderer. These are
    // straight line segments — there are no curves for CurveRenderer to
    // resolve analytically, so the simpler renderer is the right default.
    // Flip to compare if a measurement ever suggests otherwise.
    property bool useCurveRenderer: false

    // ── Two diagnostics for "why redraw static ticks at all?" ──
    //
    // The honest answer is that a GPU redraws the entire scene every frame;
    // nothing persists. But there IS avoidable work on top of that: the
    // active/passive split changes ~48 times a second, and each change makes
    // QQuickShape re-triangulate and re-upload the tick geometry even though
    // no tick ever moves. These two flags measure how much that costs and
    // what the floor would be if it were eliminated.
    //
    //   frozen    draws every tick in one colour from geometry built once and
    //             never touched again — no split, so `paths` never changes and
    //             nothing is re-triangulated. Deliberately reads the wrong
    //             colours; it establishes the floor, it is not a candidate UI.
    //   useLayer  renders the ticks once into a texture (FBO) and composites
    //             that each frame instead of re-stroking the segments. Only
    //             helps if the content is not invalidated constantly, so it is
    //             most meaningful combined with `frozen`.
    //
    // Worth measuring rather than assuming, because this board was just shown
    // to be fill-bound: a cached layer replaces ~2k blended stroke pixels with
    // a full-quad blend over the whole gauge, which could easily be worse.
    property bool frozen:   false
    property bool useLayer: false

    readonly property real centerX: width  / 2
    readonly property real centerY: height / 2


    // ════════════════════════════════════════════════════
    //  MODEL — identical generation to GaugeTickMarks
    // ════════════════════════════════════════════════════
    readonly property var tickModel: {
        var arr = []
        var eps = 0.0001

        function isMultipleOf(v, step) {
            var remainder = v % step
            return remainder < eps || (step - remainder) < eps
        }

        for (var v = 0; v <= maxValue + eps; v += smallStep) {
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

    // How many leading ticks are "active". Integer, so it only changes when
    // the value actually crosses a tick — this is what keeps the path
    // rebuilds discrete instead of per-frame.
    //
    // Computed by division rather than by scanning the model: `value` changes
    // every frame, so a 130-iteration scan here would run 60 times a second
    // per gauge for an answer that is a fixed arithmetic function of the
    // value. Ticks sit at 0, smallStep, 2*smallStep, ... so the count of
    // ticks with val <= value is floor(value/smallStep) + 1.
    // No epsilon fudge here: adding one made agreement with the model WORSE
    // (30 disagreements per 20k sampled values instead of 7), because it
    // activates a tick slightly before its boundary. Checked against a
    // scan of the real model over 200k values: the remaining disagreements
    // are pure double-precision knife-edge — they only occur within 9e-16 of
    // a tick boundary, never differ by more than one tick, and land on
    // 0.0035% of values. That is one tick's colour differing for at most one
    // frame while the value is within 1e-15 of the threshold: invisible, and
    // self-correcting on the next frame.
    readonly property int activeCount: {
        if (value < 0)
            return 0
        var n = Math.floor(value / smallStep) + 1
        return Math.max(0, Math.min(n, tickModel.length))
    }

    // ── Precomputed geometry ─────────────────────────────
    // The first version of this rebuilt every polyline from scratch — trig
    // and fresh Qt.point allocations for all 130 ticks, across 12 bindings —
    // every time activeCount changed. On target that is ~48 times a second,
    // and it MEASURED: render dropped 11 -> 7 ms as intended, but `animations`
    // rose 5 -> 10 ms, so the budget still failed. The cost had moved from the
    // render thread to the GUI thread rather than going away.
    //
    // Tick endpoints never change — only which ticks are active. So compute
    // the polylines once here, grouped by kind and ordered by value, and let
    // the per-frame path bindings be nothing but an array slice.
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
            // Same polar convention as GaugeLabels: 0 deg = right, +CW, which
            // is what GaugeActiveArc's PathAngleArc uses. (GaugeTickMarks
            // reaches the identical placement the long way round, by parking a
            // Rectangle at 12 o'clock and rotating by angle + 90 — verified
            // to match to 4 decimal places.)
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

    // For each possible activeCount, how many ticks of each kind are active.
    // Precomputed so the split point is an O(1) lookup rather than a scan.
    readonly property var activePrefix: {
        var out = [ { "big": 0, "medium": 0, "small": 0 } ]
        if (!visible)
            return out
        var model = tickModel
        var b = 0, m = 0, s = 0
        for (var i = 0; i < model.length; ++i) {
            if (model[i].kind === "big") b++
            else if (model[i].kind === "medium") m++
            else s++
            out.push({ "big": b, "medium": m, "small": s })
        }
        return out
    }

    // The only work done per update: one slice of a prebuilt array.
    //
    // In `frozen` mode this deliberately never reads `activeCount`. QML
    // captures binding dependencies dynamically, so not touching it means the
    // path bindings are never re-evaluated, `paths` never changes, and Qt
    // never re-triangulates — which is the whole point of that measurement.
    function segments(kind, active) {
        var all = ticksRoot.segmentsByKind[kind]
        if (!all || all.length === 0)
            return []
        if (ticksRoot.frozen)
            return active ? [] : all
        var idx = Math.max(0, Math.min(ticksRoot.activeCount,
                                       ticksRoot.activePrefix.length - 1))
        var split = ticksRoot.activePrefix[idx][kind]
        return active ? all.slice(0, split) : all.slice(split)
    }


    // ════════════════════════════════════════════════════
    //  RENDERING — 1 Shape, 6 ShapePaths
    // ════════════════════════════════════════════════════
    Shape {
        anchors.fill: parent
        // Cache the whole ring into a texture when asked; see `useLayer`.
        layer.enabled: ticksRoot.useLayer
        preferredRendererType: ticksRoot.useCurveRenderer ? Shape.CurveRenderer
                                                          : Shape.GeometryRenderer

        // ── PASSIVE ──────────────────────────────────────
        ShapePath {
            strokeWidth: ticksRoot.tickWidthBig
            strokeColor: ticksRoot.colorPassive
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathMultiline {
                paths: ticksRoot.segments("big", false)
            }
        }
        ShapePath {
            strokeWidth: ticksRoot.tickWidthMedium
            strokeColor: ticksRoot.colorPassive
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathMultiline {
                paths: ticksRoot.segments("medium", false)
            }
        }
        ShapePath {
            strokeWidth: ticksRoot.tickWidthSmall
            // The original dims small passive ticks to 0.5 opacity. Fold that
            // into the stroke colour instead of a separate opacity, so this
            // stays one path with no extra node.
            strokeColor: ticksRoot.dimPassiveSmall
                         ? Qt.rgba(ticksRoot.colorPassive.r, ticksRoot.colorPassive.g,
                                   ticksRoot.colorPassive.b, ticksRoot.colorPassive.a * 0.5)
                         : ticksRoot.colorPassive
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathMultiline {
                paths: ticksRoot.segments("small", false)
            }
        }

        // ── ACTIVE ───────────────────────────────────────
        ShapePath {
            strokeWidth: ticksRoot.tickWidthBig
            strokeColor: ticksRoot.colorActive
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathMultiline {
                paths: ticksRoot.segments("big", true)
            }
        }
        ShapePath {
            strokeWidth: ticksRoot.tickWidthMedium
            strokeColor: ticksRoot.colorActive
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathMultiline {
                paths: ticksRoot.segments("medium", true)
            }
        }
        ShapePath {
            strokeWidth: ticksRoot.tickWidthSmall
            strokeColor: ticksRoot.colorActive
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathMultiline {
                paths: ticksRoot.segments("small", true)
            }
        }
    }
}
