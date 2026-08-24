// S9 — the road. The component PLAN.md named at the outset as the root cause
// of the original app's 24 fps and 32 ms GUI-thread polish, and the only entry
// in the ladder marked REWRITE rather than PORT.
//
// ── WHAT THE ORIGINAL DID ──
// Six `Canvas` items. Three paint once (road surface gradient, horizon fog,
// centre-lane highlight); three repaint on an animated `offset` via
// `onWatchOffsetChanged: requestPaint()` — CPU software rasterisation on the
// GUI thread, every frame, forever.
//
// ── WHAT THIS DOES ──
// Layers 1-3 are baked offline into one PNG (tools/gen_road.py, pycairo, same
// gradients and constants): one texture, one draw call, no Canvas.
// Layers 4-6 are `Rectangle`s placed by the same perspective maths.
//
// ── THE PER-FRAME COST, AND THE FIX ──
// The first version of this rewrite made `animations` jump from 4 ms to 14 ms
// (GUI thread 7 -> 17). Replacing Canvas painting with ~38 delegates each
// re-evaluating a dozen derived properties every frame just moved the CPU cost
// from rasterisation into binding evaluation.
//
// The simplification that fixes it: a dash's endpoints are
//     x = vpX + side*span*t        y = vpY + (H - vpY)*t
// both LINEAR in t. So every dash on a side lies on one straight line, which
// means its **rotation and length are constants**, not per-frame values.
// Verified numerically across offsets and indices: spread 5e-13 deg and 2e-14
// px. They are hoisted to per-side constants here, halving the per-frame work
// to just position, thickness and fade.
//
// ── DELIBERATE SIMPLIFICATION ──
// The original strokes each dash twice — a wide translucent glow under a
// narrow bright line. That doubles the geometry and makes every dash
// overlapping translucent content, the most expensive thing measured on this
// GPU (S6: 130 overlapping ticks = 37 ms vs 11 ms non-overlapping). Glow
// dropped, dash alpha lifted 0.7 -> 0.8. If it is wanted back, bake it into
// the backdrop rather than stroking it live.

import QtQuick

Item {
    id: root
    width: 480
    height: 520

    // ── shared road geometry ───────────────────────────────
    readonly property real vpX: width * 0.50

    // Vertical position of the vanishing point, as a fraction of height.
    // The original hardcodes 0.55. It is a property because the original's
    // CarView placement was never actually displayed (contentArea had
    // opacity 0), so the road has to be re-fitted to whatever region it is
    // given — see the call site in Main.qml.
    property real vpFraction: 0.55
    readonly property real vpY: height * vpFraction

    readonly property real halfRoad: width * 0.30
    readonly property real dashSide: 0.28

    // Dashes and streaks use this wider span; the original recomputes
    // `hr = W * 0.6` locally inside those Canvases.
    readonly property real dashSpan: width * 0.6

    property int dashCount: 16
    property int streakCount: 6

    // Isolation flags for the render-p95 regression (S9 first measurement:
    // 21 ms p95 against a 13 ms gate, GUI thread already passing). Draw
    // calls should be cheap here (1 image + a couple of Rectangle batches),
    // so the leading hypothesis is overdraw from three stacked translucent
    // layers (backdrop, dashes, streaks) rather than any single one being
    // expensive alone. These flags let one binary measure all four
    // combinations instead of guessing which layer to cut.
    property bool showBackdrop: true
    property bool showDashes: true
    property bool showStreaks: true

    // Dash length along t, from the original: t1 = t0 + 0.38/N.
    readonly property real dashSpanT: 0.38 / dashCount

    // ── PER-SIDE CONSTANTS (hoisted out of the per-frame path) ──
    // dx/dy for a full t-sweep; a dash covers dashSpanT of it.
    readonly property real runY: height - vpY
    readonly property real dashLen:
        Math.sqrt((dashSide * dashSpan) * (dashSide * dashSpan) + runY * runY) * dashSpanT
    // Rotation of the left/right road lines. Same magnitude, mirrored.
    readonly property real dashRotR:
        Math.atan2(runY * dashSpanT, dashSide * dashSpan * dashSpanT) * 180 / Math.PI
    readonly property real dashRotL:
        Math.atan2(runY * dashSpanT, -dashSide * dashSpan * dashSpanT) * 180 / Math.PI

    // ── LAYERS 1-3: baked, static ──────────────────────────
    //
    // NOT `anchors.fill`. The PNG is cropped to the painted trapezoid + fog
    // disc, because the rest of the rect is fully transparent and a
    // transparent pixel inside a blended quad still costs fill on this GPU.
    // Cropping cut the road's blended coverage to 54% of the full rect.
    //
    // These four fractions are printed by tools/gen_road.py — do not hand-tune
    // them. And the generator's BASE_W/BASE_H/VP_FRACTION must match this
    // component's size and `vpFraction` at the call site: baking at 480x520
    // with vp 0.55 and then displaying at 480x424 with vp 0.377 is what made
    // the dashes visibly diverge from the painted road.
    Image {
        visible: root.showBackdrop
        x: root.width  * 0.200000
        y: root.height * 0.096698
        width:  root.width  * 0.600000
        height: root.height * 0.903302

        source: "qrc:/art/RoadBackdrop.png"
        // Standing image rules (S7.5): decode at display size, no mipmap so it
        // can share Qt's texture atlas rather than take its own draw call.
        sourceSize: Qt.size(width, height)
        mipmap: false
        smooth: true
    }

    // ── LAYER 4: scrolling lane dashes ─────────────────────
    Item {
        id: dashes
        anchors.fill: parent
        visible: root.showDashes

        property real offset: 0.0
        NumberAnimation on offset {
            from: 0.0; to: 1.0
            duration: 300
            loops: Animation.Infinite
            running: true
        }

        Repeater {
            model: root.dashCount * 2

            delegate: Rectangle {
                id: dash
                required property int index

                // NOT named `left`: every Item has FINAL anchor-line
                // properties `left`/`right`/`top`/`bottom`/`horizontalCenter`/
                // `verticalCenter`/`baseline` (that is what `parent.left`
                // resolves to in an anchor expression), so declaring one
                // fails with "Cannot override FINAL property".
                readonly property bool isLeft: dash.index < root.dashCount
                readonly property real side: dash.isLeft ? -root.dashSide : root.dashSide

                // The ONLY genuinely per-frame value.
                readonly property real t: ((dash.index % root.dashCount + dashes.offset)
                                           / root.dashCount) % 1.0

                // Skip while wrapping the seam and just past the vanishing
                // point, as the original does.
                visible: dash.t >= 0.01 && dash.t + root.dashSpanT <= 1.0

                readonly property real lw: 1.0 + dash.t * 3.0
                readonly property real fade: dash.t < 0.06 ? dash.t / 0.06 : 1.0

                // Constant per side — see the note at the top.
                width: root.dashLen
                height: dash.lw
                radius: dash.lw / 2               // original used lineCap "round"
                rotation: dash.isLeft ? root.dashRotL : root.dashRotR

                // Centre of the dash segment, then offset to the Rectangle's
                // top-left. Rotation is about the item centre (the default
                // transformOrigin), so this reproduces the stroked line.
                x: root.vpX + dash.side * root.dashSpan * (dash.t + root.dashSpanT / 2)
                   - width / 2
                y: root.vpY + root.runY * (dash.t + root.dashSpanT / 2) - height / 2

                color: "#ffffff"
                opacity: 0.8 * dash.fade
                antialiasing: true
            }
        }
    }

    // ── LAYER 6: faint motion streaks down the centre ──────
    Item {
        id: streaks
        anchors.fill: parent
        visible: root.showStreaks

        property real offset: 0.0
        NumberAnimation on offset {
            from: 0.0; to: 1.0
            duration: 600
            loops: Animation.Infinite
            running: true
        }

        // Streak length is also constant: it spans a fixed 0.04 of t.
        readonly property real streakLen: root.runY * 0.04

        Repeater {
            model: root.streakCount

            delegate: Rectangle {
                id: streak
                required property int index

                readonly property real t: ((streak.index + streaks.offset)
                                           / root.streakCount) % 1.0
                visible: streak.t >= 0.15 && streak.t + 0.04 <= 1.0

                readonly property real xOff: (streak.index % 2 === 0 ? -20 : 20) * streak.t

                width: 1.5
                height: streaks.streakLen
                radius: 0.75
                // Near-vertical (the original tilts it by xOffset*0.1 over the
                // segment, which is under a degree); drawn vertical here.
                x: root.vpX + streak.xOff - width / 2
                y: root.vpY + root.runY * streak.t

                color: "#b4c8ff"                  // rgba(180, 200, 255)
                opacity: 0.12 * streak.t
                antialiasing: true
            }
        }
    }
}
