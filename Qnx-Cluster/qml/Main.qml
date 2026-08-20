// S4 — second gauge (RPM), positioned with the ORIGINAL cluster's geometry.
//
// ════════════════════════════════════════════════════════════════════
//  GEOMETRY IS NOW TAKEN FROM THE ORIGINAL, NOT INVENTED
// ════════════════════════════════════════════════════════════════════
// The first S4 draft placed the gauges at root.width * 0.25 / 0.75, which
// measured fine but was made up. Everything below is lifted verbatim from
// 02-Digital-Cluster so that every later stage (ticks, labels, needles,
// bars) can be dropped in at its original coordinates without re-deriving
// a layout. The original chain, from Screen01.qml:
//
//   digitalCluster   1024 x 600            <- Constants.qml, the design space
//     gaugeArea      x:-148  y:75  scale:0.9   <- a Studio GroupItem
//       SpeedGauge   x:92    y:0   450x450  scale:0.7
//       RPMGauge     x:772   y:0   450x450  scale:0.7
//
// Two subtleties that make this worth replicating structurally rather than
// flattening into constants:
//
// 1. `x:92` / `x:772` do not appear as live values in Screen01.qml — they
//    are commented out there, because the gauges are parked at x:432,
//    scale:0.1, opacity:0 for a startup animation. The resting values come
//    from the animation's `to:` targets (startupSequence, phase 1), which
//    is the authoritative source for where they actually end up.
//
// 2. `gaugeArea` is a Studio `GroupItem`, which sizes itself from its
//    children: implicitWidth = max(16, childrenRect.width + childrenRect.x).
//    Its `scale: 0.9` therefore pivots about the centre of the bounding box
//    of ALL its children -- including a 424x1320 `frame` rectangle and a
//    480x424 `contentArea` that belong to later stages. Leave those out and
//    the pivot moves, silently shifting both gauges. So they are present
//    here as geometry-only placeholders: plain `Item`s with the original
//    x/y/width/height and no visual content, which contribute to
//    childrenRect while costing zero draw calls. When S7/S10 bring in the
//    real frame and content area, they replace these at the same geometry
//    and nothing moves.
//
// The resolved centres are printed at startup (see Component.onCompleted)
// so the mapping can be checked against the original on real hardware
// rather than trusted from arithmetic.
//
// ── Why the stimulus is continuous (carried over from S3) ──
// S3's first stimulus was a 1400 ms Timer smoothed by a 300 ms Behavior,
// leaving the render loop idle ~82% of the time. Qt Quick renders on demand,
// so averaging frames over that window produced fps=14 and a false
// regression that cost a session and half a rendering rewrite. Driving
// `value` from a looping animation removes the idle windows entirely: both a
// harder test and a measurable one. Keep it this way for every later stage.
//
// GATE: frame period p99 <= 20 ms, sustained fps >= 55, polish+sync+render
// p95 <= 13 ms, polish p95 <= 2 ms. Read the verdict from
// tools/analyze_frames.py, never a raw fps average. See ../PLAN.md.

import QtQuick
import QtQuick.Window
import QnxCluster  // VehicleData (see src/Backend/), same as every ported
                    // component that references the C++-registered Theme
                    // singleton — required even within the same module.

Window {
    id: root

    // Rule 0: never a literal. The QQNX platform overrides a requested size
    // to the real display anyway (1280x720 here), so a hardcoded number was
    // never authoritative — and guessing it wrong has already cost this
    // project two rounds of debugging.
    width: Screen.width
    height: Screen.height

    visible: true
    color: "#07000E"
    title: showTextLayers ? "QnxCluster - S5" : "QnxCluster - S4"

    // Normalised throttle, 0..1. Single source of truth for both gauges, so
    // both Shapes regenerate their geometry on the SAME frame — the worst
    // case for the renderer, not an average one.
    property real drive: 0

    // Backend (VehicleData, see src/Backend/) reads real values from
    // telemetry.json + /tmp/ivi/*.txt on a 50 ms poll, same as the
    // reference. THIS IS THE DEFAULT for production (2026-08-13) — flipped
    // from the earlier opt-in. `--simulate` goes the other way now: it
    // switches to `drive`'s continuous synthetic sweep, which every S0-S10
    // performance measurement in this file depends on (S3 — an intermittent
    // /idle-most-of-the-time stimulus makes the render loop go idle and
    // produces a misleading low fps reading, the exact trap that stage cost
    // a session over). Perf work now reads `deploy_and_measure.sh <stage>
    // <secs> --simulate`; a plain production build reads real files.
    readonly property bool simulate: Qt.application.arguments.indexOf("--simulate") !== -1
    readonly property bool liveData: !simulate
    readonly property real speedValue: liveData ? VehicleData.speedProvider.speedValue : root.drive * 240
    readonly property real rpmValue:   liveData ? VehicleData.rpmProvider.rpmValue     : (0.8 + root.drive * 6.7)

    // Drive mode: thresholds verbatim from Screen01.qml's `simMode`
    // (rpmValue is already the same 0-8 scale as the original's simRpm).
    readonly property string driveMode: {
        if (root.rpmValue < 2) return "ECO"
        if (root.rpmValue < 4) return "NORMAL"
        return "SPORT"
    }
    // Hardcoded in the reference too (SpeedGauge.qml's own default).
    property int speedLimitKph: 90

    // Wheel D-pad -> content view switching, per Cluster-Handoff-Mahgoub.md:
    // left/right cycle the 6 views (Car/Map/Contacts/Music/Fuel/Settings),
    // ok confirms. Up/down stay ContactsView-only (list scroll), unchanged.
    // NOTE: left/right briefly drove the turn-signal flashers in an earlier
    // revision; moved to L3/R3 (below) once the handoff claimed left/right
    // for view switching instead -- see that Connections block for why.
    Connections {
        target: VehicleData.steeringWheel
        function onLeftPressed() {
            clusterNavigation.selectView((root.currentView - 1 + 6) % 6)
        }
        function onRightPressed() {
            clusterNavigation.selectView((root.currentView + 1) % 6)
        }
        function onOkPressed() {
            // Design intentionally left open by the handoff ("pick what fits
            // the UI") -- no per-view confirm action exists in the backend
            // yet (e.g. ContactsModel has no "call" invokable), so this is a
            // visible, testable stub rather than invented behaviour.
            console.log("[SteeringWheel] OK pressed on view", root.currentView)
        }
    }

    // Turn signal flashers -- L3/R3 (paddle shifters), deliberately NOT
    // left/right, since the D-pad's left/right is claimed by view switching
    // above and the transport is a fixed signal set. One press toggles that
    // side and forces the other off, matching a real stalk.
    // forceRightIndicator (declared below with the other S10 flags) still
    // seeds the initial value for bench perf runs via --right-indicator-on.
    property bool leftIndicatorOn: true
    property bool rightIndicatorOn: root.forceRightIndicator

    Connections {
        target: VehicleData.steeringWheel
        function onL3Pressed() {
            root.leftIndicatorOn = !root.leftIndicatorOn
            if (root.leftIndicatorOn)
                root.rightIndicatorOn = false
        }
        function onR3Pressed() {
            root.rightIndicatorOn = !root.rightIndicatorOn
            if (root.rightIndicatorOn)
                root.leftIndicatorOn = false
        }
    }

    // Generic error surface. VehicleData.errorOccurred is real (wired to
    // SteeringWheelController's UDP bind failure) and can also be triggered
    // manually via VehicleData.raiseError("...") for testing.
    Connections {
        target: VehicleData
        function onErrorOccurred(message) {
            errorDialog.show(message)
        }
    }

    // Which content-area view is showing: 0 Car/Road, 1 Map, 2 Contacts,
    // 3 Music, 4 Fuel, 5 Settings. Matches the reference's Screen01.qml
    // numbering exactly, driven by TopBar's viewSelected (see below).
    readonly property int currentView: clusterNavigation.effectiveView

    // ════════════════════════════════════════════════════════════
    //  S5 TOGGLE — two stages from one build
    // ════════════════════════════════════════════════════════════
    // S4's geometry was reworked to the original cluster's coordinates AFTER
    // S4 was measured, so that rework is itself unmeasured. Stacking S5's
    // text layers straight on top would make any regression ambiguous between
    // the two changes — exactly the attribution problem the one-change-per-
    // stage ladder exists to prevent.
    //
    // Rather than spend a whole build cycle on it, the text layers are behind
    // a runtime flag. One binary, two measurements:
    //     <app> --no-text     -> S4 with the corrected geometry
    //     <app>               -> S5, text layers on
    // Run them back to back and the delta is attributable to the text alone.
    property bool showTextLayers: Qt.application.arguments.indexOf("--no-text") === -1

    // S6 — same trick, one stage later. `--no-ticks` gives the S5 baseline
    // from the same binary, so the tick marks' cost is isolated even though
    // S5 and S6 ship together. 130 tick instances is the biggest single jump
    // in the ladder, so an attributable delta matters more here than anywhere.
    property bool showTicks: Qt.application.arguments.indexOf("--no-ticks") === -1

    // S6 diagnostic flags. S6 failed (render p50 6 -> 12 ms) and the leading
    // hypothesis — draw-call explosion from per-tick Rotation transforms —
    // was disproved on the board: 130 tick nodes cost only 12 extra batches.
    // These isolate each remaining suspect from a single build, so no guess
    // costs a rebuild. All default to the faithful original.
    readonly property bool tickSquare:  Qt.application.arguments.indexOf("--ticks-square")  !== -1
    readonly property bool tickNoAA:    Qt.application.arguments.indexOf("--ticks-noaa")    !== -1
    readonly property bool tickNoAnim:  Qt.application.arguments.indexOf("--ticks-noanim")  !== -1
    readonly property bool tickNoDim:   Qt.application.arguments.indexOf("--ticks-nodim")   !== -1

    // Round 2. The first four knobs above all measured identical, so the
    // mechanism is not styling. These separate node count / fill / transform,
    // and `--ticks-shape` swaps in the candidate fix (6 ShapePaths instead of
    // 130 Items) so it can be measured in the same session.
    readonly property bool tickTiny:  Qt.application.arguments.indexOf("--ticks-tiny")  !== -1
    readonly property bool tickNoRot: Qt.application.arguments.indexOf("--ticks-norot") !== -1
    // S6 CONCLUDED: the Shape/PathMultiline implementation is the default.
    // Measured on target — Rectangles: render p95 14 ms, 56.9 fps (FAIL);
    // Shape: render p95 8 ms, 62.3 fps (PASS). `--ticks-rects` restores the
    // 130-Rectangle version so the comparison stays reproducible, and
    // `--ticks-shape` is kept as a no-op alias so older commands still work.
    readonly property bool tickShape: Qt.application.arguments.indexOf("--ticks-rects") === -1
    readonly property bool tickCurve: Qt.application.arguments.indexOf("--ticks-curve") !== -1

    // Round 3: is the per-frame geometry REBUILD (not the draw) what is left?
    // --ticks-frozen removes the active/passive split so `paths` never
    // changes; --ticks-layer caches the ring to a texture. Both are
    // measurements, not candidate UI — frozen shows the wrong colours.
    readonly property bool tickFrozen: Qt.application.arguments.indexOf("--ticks-frozen") !== -1
    readonly property bool tickLayer:  Qt.application.arguments.indexOf("--ticks-layer")  !== -1

    // S6.5 — redline zone, isolated the same way every stage has been.
    readonly property bool showRedline: Qt.application.arguments.indexOf("--no-redline") === -1

    // S7 — bottom info bar.
    readonly property bool showBottomBar: Qt.application.arguments.indexOf("--no-bottombar") === -1
    // Bisect the bar's 7 ms: bars (60 Rectangles) vs centre text (~14 Text).
    readonly property bool showBars:   Qt.application.arguments.indexOf("--no-bars")       === -1
    readonly property bool showCenter: Qt.application.arguments.indexOf("--no-bottomtext") === -1

    // S7 batch-cost test. Measured on this board: render ~= 0.42 ms per batch
    // + 0.037 ms per node, so DISTINCT MATERIALS among siblings are what
    // costs, not element counts. Per-item colour animation and per-item
    // opacity both create distinct materials and block merging.
    readonly property bool flatLabels: Qt.application.arguments.indexOf("--flat-labels") !== -1
    readonly property bool flatBars:   Qt.application.arguments.indexOf("--flat-bars")   !== -1

    // S9 (2026-08-12): render p95 fails even with --no-road, matching S7.5's
    // recorded "still short of gate" state -- the regression predates Road
    // entirely. PLAN.md's S7 section names two untested next levers; this is
    // the cheaper one to test (one flag, fully reversible, no new asset).
    readonly property bool flatFontSize: Qt.application.arguments.indexOf("--flat-fontsize") !== -1

    // S7 fix: dial labels are baked to a PNG by default (18 Text -> 1 Image,
    // ~8 batches -> ~1). `--live-labels` restores the Text Repeater so the
    // before/after stays reproducible.
    readonly property bool bakedLabels: Qt.application.arguments.indexOf("--live-labels") === -1

    // S7.5 — top bar. PREDICTION being tested: ~8 distinct icon textures
    // cannot merge, so the S7 model (~0.5 ms per batch) expects roughly +8
    // batches / +4 ms. If that lands, the fix is a sprite atlas, not the
    // buttons. Stated before measuring so this tests the model.
    readonly property bool showTopBar: Qt.application.arguments.indexOf("--no-topbar") === -1

    // S10 — TopBar's three DesignEffect shadows, left out at S7.5 on
    // purpose (see TopBar.qml header). Naive `MultiEffect` port, one flag
    // per shadow so a bisect doesn't need a guess.
    readonly property bool showShadowPill:      Qt.application.arguments.indexOf("--no-shadow-pill")       === -1
    readonly property bool showShadowLeftGlow:  Qt.application.arguments.indexOf("--no-shadow-leftglow")   === -1
    readonly property bool showShadowRightGlow: Qt.application.arguments.indexOf("--no-shadow-rightglow")  === -1
    // rightIndicatorOn defaults false (matching the original), so its glow
    // never actually renders unless something turns the indicator on. This
    // project measures the honest worst case (S3, S7), not just the idle
    // default, so this flag can force it on for that measurement.
    readonly property bool forceRightIndicator: Qt.application.arguments.indexOf("--right-indicator-on")   !== -1

    // Splash screen (ported from Screen01.qml, see SplashScreen.qml). One-
    // time ~3.3 s startup play, does not touch steady-state measurement.
    // `--no-splash` skips it for faster dev iteration.
    readonly property bool showSplash: Qt.application.arguments.indexOf("--no-splash") === -1

    // S7.5 fix: mipmap forces an Image out of Qt's shared texture atlas, so
    // each icon became its own texture and its own batch. Off by default now;
    // `--icon-mipmap` restores the original behaviour for comparison.
    readonly property bool iconMipmap: Qt.application.arguments.indexOf("--icon-mipmap") !== -1

    // S8 — car sprite. Its drop shadow is baked into the PNG rather than being
    // a per-frame DesignEffect layer pass; see qml/ContentArea/Car.qml.
    readonly property bool showCar: Qt.application.arguments.indexOf("--no-car") === -1

    // Small adjustment added on top of the original's verbatim
    // verticalCenterOffset (235, see the CarView Item below) -- 0 changes
    // nothing. Not a replacement for that number, just a knob to nudge it
    // from after seeing a screenshot, instead of hand-deriving a new
    // absolute position again.
    property real carViewY: 0

    // S9 — the road. Six Canvases in the original, three of them repainting
    // every frame; now one baked image plus ~38 Rectangles. See Road.qml.
    readonly property bool showRoad: Qt.application.arguments.indexOf("--no-road") === -1

    // S9 first measurement FAILED on render (p95 21 ms, gate 13) with GUI
    // thread already passing (11 ms) — so this is fill-rate/overdraw, not
    // binding churn. Draw calls should already be cheap (1 image + a couple
    // of Rectangle batches), so the leading hypothesis is three stacked
    // translucent layers (backdrop under dashes under streaks) rather than
    // any one layer being expensive alone. These isolate each layer so one
    // build measures all four combinations instead of guessing.
    readonly property bool roadBackdrop: Qt.application.arguments.indexOf("--no-road-backdrop") === -1
    readonly property bool roadDashes:   Qt.application.arguments.indexOf("--no-road-dashes")   === -1
    readonly property bool roadStreaks:  Qt.application.arguments.indexOf("--no-road-streaks")  === -1

    // `--ticks-every=N` renders every Nth tick. Sweeping N gives the
    // render-time-vs-node-count curve, which is the one measurement that can
    // confirm or kill the "it is simply the primitive count" conclusion.
    readonly property int tickEvery: {
        var a = Qt.application.arguments
        for (var i = 0; i < a.length; ++i) {
            if (a[i].indexOf("--ticks-every=") === 0) {
                var n = parseInt(a[i].substring(14))
                if (!isNaN(n) && n > 0)
                    return n
            }
        }
        return 1
    }

    // The QNX target has no fonts installed at all (verified: `find / -name
    // '*.ttf'` returns nothing on the guest). The face is embedded in the
    // binary via resources.qrc and registered here, so text does not depend
    // on target filesystem state. `status` is logged at startup — if this
    // ever reports Error, every Text below silently falls back to nothing.
    FontLoader {
        id: uiFont
        source: "qrc:/fonts/KdamThmorPro-Regular.ttf"
        // Logging status from Component.onCompleted reported "1 = Loading"
        // and therefore proved nothing. Report the settled result instead —
        // if this ever says Error, every Text in the app is silently blank.
        onStatusChanged: console.log("fontLoader settled:", status,
                                     "(2=Ready 3=Error) family:", name)
    }

    // The bezel is baked at the real panel size (1280x720) and fills the
    // window, rather than living inside the 1024x600 design space below.
    // That leaves the gauges' position relative to the bezel about 1% off
    // the original. Deliberate for now: the PNG was authored at 1280x720 in
    // S1 specifically to avoid non-uniform stretching. Revisit at S7, when
    // the real frame/content-area arrive and the bezel's relationship to
    // them actually matters.
    BazelFrame {
        id: frame
        width: root.width
        height: root.height
        anchors.centerIn: parent
    }

    // ════════════════════════════════════════════════════════════
    //  DESIGN SPACE — the original cluster's 1024x600 coordinates
    // ════════════════════════════════════════════════════════════
    // 1024x600 is not an assumption about this display (that would break
    // Rule 0); it is the original's authoring coordinate system, taken from
    // Constants.qml. The real display is read live via root.width/height and
    // the whole space is scaled uniformly to fit — uniformly, because a
    // non-uniform stretch turns circular gauges into ellipses. On this board
    // that is min(1280/1024, 720/600) = 1.2, centred, leaving ~26 px at each
    // side. Every child below uses the original numbers verbatim.
    Item {
        id: designRoot
        width: 1024
        height: 600
        scale: Math.min(root.width / width, root.height / height)
        anchors.centerIn: parent

        Item {
            id: gaugeArea
            x: -148
            y: 75
            scale: 0.9

            // Verbatim from QtQuick.Studio.Components/GroupItem.qml. This is
            // what makes the pivot depend on the placeholders below.
            implicitWidth:  Math.max(16, childrenRect.width  + childrenRect.x)
            implicitHeight: Math.max(16, childrenRect.height + childrenRect.y)

            // ── geometry-only placeholders (no visual content, no draw calls)
            // Present solely so childrenRect — and therefore gaugeArea's size
            // and scale pivot — match the original. Replace with the real
            // components at their own stages, keeping this geometry.
            Item { id: framePlaceholder;       x: 442; y: -435; width: 424; height: 1320 }
            // ════════════════════════════════════════════════════════
            //  CONTENT AREA — anchored 2026-08-12, not hand-computed.
            // ════════════════════════════════════════════════════════
            // THE BUG in every earlier attempt: contentArea is a direct
            // child of gaugeArea, so its x/y/width/height live in
            // gaugeArea-LOCAL coordinates -- the same frame as
            // `speedGauge.x: 92`. But the numbers used here were taken from
            // `designRoot.mapFromItem(...)`, which are DESIGN-space
            // coordinates -- already passed through gaugeArea's own scale
            // AND its own non-trivial scale pivot (gaugeArea's
            // transformOrigin is NOT (0,0); it's the centre of
            // childrenRect, offset by the frame placeholder). Assigning a
            // design-space number directly to a gaugeArea-local property is
            // a unit mismatch, and it produced a different wrong position
            // every time depending which number got reused.
            // THE FIX: anchor to the gauges directly. `horizontalCenter`
            // and `verticalCenter` are scale-invariant (an item's centre
            // does not move when its own `scale` changes), so these are
            // safe regardless of gaugeArea's pivot -- no cross-frame
            // conversion needed anywhere. `gaugeVisualRadius` is the one
            // real number here (a gauge's rendered half-width/height,
            // 225 * 0.7, in the SAME gaugeArea-local frame speedGauge.x
            // already uses -- no *0.9, that was the bug), and the margins
            // are a plain, adjustable gap on top of it.
            readonly property real gaugeVisualRadius: 225 * 0.7   // 157.5
            readonly property real contentGap: 10                 // tune this
            // 2026-08-12: car+road looked too small against the reference
            // screenshot. contentArea itself is capped by the fixed gap
            // between the gauges, so this scales carView's content up
            // on top of that, allowed to overflow contentArea's nominal
            // box (not clipped, same as everywhere else this project
            // already lets Road/Car overflow their container) rather than
            // shrinking to fit. Single knob — tune this, not carView.scale.
            readonly property real contentVisualScale: 1.6

            Item {
                id: contentArea
                anchors.left: speedGauge.horizontalCenter
                anchors.leftMargin: gaugeArea.gaugeVisualRadius + gaugeArea.contentGap
                anchors.right: rightGauge.horizontalCenter
                anchors.rightMargin: gaugeArea.gaugeVisualRadius + gaugeArea.contentGap
                anchors.verticalCenter: speedGauge.verticalCenter
                height: gaugeArea.gaugeVisualRadius * 2
                // NOT clipped. A first version set clip: true here and cut
                // the roof off the car. The original clips only at the top
                // level (`digitalCluster`), not at contentArea.

                // ════════════════════════════════════════════════════
                //  CarView + Road — ported verbatim from 02-Digital-Cluster/
                //  Digital_Cluster_DesignStudioContent/Content_Area/
                //  CarView.qml, not re-derived. Two prior attempts here
                //  (an absolute y tuned for one box size, then a "dead
                //  centre" guess) both invented numbers instead of copying
                //  the reference, and both broke. The original's actual
                //  values, read directly from CarView.qml/Car.qml:
                //    CarView: 800x700 canvas. Road: 800x700, anchors.
                //    centerIn, opacity 0.55 -- fills the canvas exactly.
                //    Car: anchors.verticalCenter + verticalCenterOffset
                //    235 (i.e. LOW in the canvas, 350+235=585 of 700 =
                //    83.6% down -- not centred), horizontalCenterOffset 0.
                //  Ported at those exact numbers, then the WHOLE canvas is
                //  scaled to fit contentArea and pinned to it horizontally
                //  centred / bottom-aligned -- so the internal proportions
                //  are always the original's, regardless of container size.
                //
                //  transformOrigin: Item.Bottom, not the default Center.
                //  `contentVisualScale` above (1.6) makes this canvas
                //  bigger than contentArea on purpose (overflow, not
                //  clipped) -- with the default Center origin, growing the
                //  scale pushes the TOP further up AND the BOTTOM further
                //  down equally, so Road's bottom edge drifted below the
                //  gauges' bottom every time the scale changed. Anchoring
                //  bottom-centre instead of centre, and pivoting the scale
                //  around that same point (Item.Bottom), means growing the
                //  scale only extends upward -- the bottom edge is pinned
                //  to contentArea's bottom (= the gauges' bottom) at any
                //  scale value. anchors.bottom/horizontalCenter use the
                //  UNSCALED box, which is exactly why this only works
                //  because the transformOrigin is the SAME point being
                //  anchored -- scaling around a point that is already
                //  pinned in the parent's frame cannot move it.
                // ════════════════════════════════════════════════════
                Item {
                    id: carView
                    visible: root.showCar && root.currentView === 0
                    width: 800
                    height: 700
                    scale: (contentArea.width / width) * gaugeArea.contentVisualScale
                    transformOrigin: Item.Bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom

                    Road {
                        id: road
                        anchors.fill: parent
                        visible: root.showRoad
                        opacity: 0.55
                        vpFraction: 0.377
                        showBackdrop: root.roadBackdrop
                        showDashes: root.roadDashes
                        showStreaks: root.roadStreaks
                    }

                    Car {
                        id: carItem
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.verticalCenterOffset: 235 + root.carViewY
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }

                // Views 1-5, ported from 02-Digital-Cluster's Content_Area/
                // — see PLAN.md's "Production port" entry for what changed
                // in each (MapView's Canvas baked, MusicView's cover URLs
                // now qrc:/, everything else verbatim). All share this same
                // contentArea box, same as the original.
                MapView {
                    anchors.fill: parent
                    visible: root.currentView === 1
                }

                ContactsView {
                    anchors.fill: parent
                    visible: root.currentView === 2
                }

                MusicView {
                    anchors.fill: parent
                    visible: root.currentView === 3
                }

                FuelView {
                    anchors.fill: parent
                    visible: root.currentView === 4
                    fuelPercent: root.liveData ? VehicleData.bottomBar.fuelProvider.fuelValue : 100 - root.drive * 85
                    rangeText: root.liveData
                        ? Math.round(VehicleData.bottomBar.fuelProvider.fuelValue * 5.2) + " km"
                        : Math.round((100 - root.drive * 85) * 5.2) + " km"
                }

                SettingsView {
                    anchors.fill: parent
                    visible: root.currentView === 5
                }
            }

            // ── LEFT: speed, 0-240 km/h ─────────────────────────
            Item {
                id: speedGauge
                x: 92
                y: 0
                width: 450
                height: 450
                scale: 0.7

                // Child order follows SpeedGauge.qml's z-order exactly:
                // ticks -> labels -> active arc -> hero number. (An earlier
                // draft had the arc under the labels, which is wrong: the
                // halo is meant to wash over them.)

                // S6 — 49 ticks (0-240 step 5), steps from SpeedGauge.qml.
                GaugeTickMarks {
                    anchors.fill: parent
                    visible: root.showTicks && !root.tickShape
                    value: root.speedValue
                    maxValue: 240
                    bigStep:    30.0
                    mediumStep: 10.0
                    smallStep:   5.0
                    roundedTicks:    !root.tickSquare
                    antialiasTicks:  !root.tickNoAA
                    animateColor:    !root.tickNoAnim
                    dimPassiveSmall: !root.tickNoDim
                    drawEvery:       root.tickEvery
                    tinyTicks:       root.tickTiny
                    noRotation:      root.tickNoRot
                }

                // Candidate fix, selected with --ticks-shape. Same visual, 6
                // ShapePaths instead of 130 Items. Mutually exclusive with the
                // Rectangle-based version above so both ship in one binary.
                GaugeTickMarksShape {
                    anchors.fill: parent
                    visible: root.showTicks && root.tickShape
                    value: root.speedValue
                    maxValue: 240
                    bigStep:    30.0
                    mediumStep: 10.0
                    smallStep:  5.0
                    dimPassiveSmall: !root.tickNoDim
                    useCurveRenderer: root.tickCurve
                    frozen:   root.tickFrozen
                    useLayer: root.tickLayer
                }

                // S6.5 — redline ticks over the danger range. Geometry and steps from
                // the original composer; static, so it never re-triangulates.
                GaugeRedlineZone {
                    anchors.fill: parent
                    visible: root.showRedline
                    redlineStart: 210
                    maxValue: 240
                    bigStep:    30.0
                    mediumStep: 10.0
                    smallStep:  5.0
                    useCurveRenderer: root.tickCurve
                }

                // S5 — labels around the dial. Geometry from SpeedGauge.qml:
                // anchors.fill the 450x450 gauge, labelStep 30 (0..240 = 9).
                GaugeLabels {
                    anchors.fill: parent
                    visible: root.showTextLayers
                    value: root.speedValue
                    maxValue: 240
                    labelStep: 30.0
                    animateColor: !root.flatLabels
                    baked: root.bakedLabels
                    bakedSource: "qrc:/art/DialLabelsSpeed.png"
                }

                GaugeActiveArc {
                    anchors.fill: parent
                    maxValue: 240
                    value: root.speedValue
                    enableSmoothing: false   // driven continuously; no second easing
                }

                // S5 — hero number. Geometry from SpeedGauge.qml: 300x300
                // centred inside the 450x450 gauge.
                GaugeSpeedNumber {
                    anchors.centerIn: parent
                    width: 300
                    height: 300
                    visible: root.showTextLayers
                    value: root.speedValue
                    maxValue: 240
                    unitText: "KM/H"
                }

                // Speed limit sign, ported from SpeedGauge.qml verbatim
                // (anchors.verticalCenterOffset: 170 within the 450x450
                // gauge — same local frame as everything else here).
                GaugeSpeedLimitBadge {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: 170
                    speedLimit: root.speedLimitKph
                    currentSpeed: root.speedValue
                    badgeSize: 60
                }
            }

            // ── RIGHT: engine speed, 0-8 (x1000 rpm) ────────────
            // Idles at 0.8 rather than 0 so the arc never collapses to zero
            // sweep — a real tachometer never reads zero with the engine
            // running, and it keeps the Shape's geometry live for the whole
            // measurement.
            Item {
                id: rightGauge
                x: 772
                y: 0
                width: 450
                height: 450
                scale: 0.7

                // S6 — 81 ticks (0-8 step 0.1), steps from RPMGauge.qml. This
                // gauge alone carries more tick instances than the speed
                // gauge and the labels combined.
                GaugeTickMarks {
                    anchors.fill: parent
                    visible: root.showTicks && !root.tickShape
                    value: root.rpmValue
                    maxValue: 8
                    bigStep:    1.0
                    mediumStep: 0.5
                    smallStep:  0.1
                    roundedTicks:    !root.tickSquare
                    antialiasTicks:  !root.tickNoAA
                    animateColor:    !root.tickNoAnim
                    dimPassiveSmall: !root.tickNoDim
                    drawEvery:       root.tickEvery
                    tinyTicks:       root.tickTiny
                    noRotation:      root.tickNoRot
                }

                // Candidate fix, selected with --ticks-shape. Same visual, 6
                // ShapePaths instead of 130 Items. Mutually exclusive with the
                // Rectangle-based version above so both ship in one binary.
                GaugeTickMarksShape {
                    anchors.fill: parent
                    visible: root.showTicks && root.tickShape
                    value: root.rpmValue
                    maxValue: 8
                    bigStep:    1.0
                    mediumStep: 0.5
                    smallStep:  0.1
                    dimPassiveSmall: !root.tickNoDim
                    useCurveRenderer: root.tickCurve
                    frozen:   root.tickFrozen
                    useLayer: root.tickLayer
                }

                // S6.5 — redline ticks over the danger range. Geometry and steps from
                // the original composer; static, so it never re-triangulates.
                GaugeRedlineZone {
                    anchors.fill: parent
                    visible: root.showRedline
                    redlineStart: 6
                    maxValue: 8
                    bigStep:    1.0
                    mediumStep: 0.5
                    smallStep:  0.1
                    useCurveRenderer: root.tickCurve
                }

                // S5 — labels. Geometry from RPMGauge.qml: labelStep 1.0
                // (0..8 = 9 labels), same 450x450 fill.
                GaugeLabels {
                    anchors.fill: parent
                    visible: root.showTextLayers
                    value: root.rpmValue
                    maxValue: 8
                    labelStep: 1.0
                    animateColor: !root.flatLabels
                    baked: root.bakedLabels
                    bakedSource: "qrc:/art/DialLabelsRpm.png"
                }

                GaugeActiveArc {
                    anchors.fill: parent
                    maxValue: 8
                    value: root.rpmValue
                    haloMidThreshold: 0.75   // matches the old RPMGauge composer
                    enableSmoothing: false
                }

                // S5 — hero number. RPMGauge.qml passes a one-decimal string
                // and tighter thresholds (amber at 6.0, red at 7.2). Kept
                // faithful deliberately: toFixed(1) on a continuously
                // animating value re-shapes glyphs far more often than the
                // speed gauge's rounded integer does, so this is the honest
                // worst case for text layout cost. If it shows up in polish,
                // quantising the string is the fix — but measure first.
                GaugeSpeedNumber {
                    anchors.centerIn: parent
                    width: 300
                    height: 300
                    visible: root.showTextLayers
                    value: root.rpmValue
                    maxValue: 8
                    displayValue: (root.rpmValue).toFixed(1)
                    unitText: "RPM ×1000"
                    warnThreshold:   0.75   // amber at 6.0
                    dangerThreshold: 0.90   // red at 7.2
                }

                // Gear (P/R/N/D) and drive-mode badges, ported from
                // RPMGauge.qml verbatim (offsets -80 / +170 within the
                // same 450x450 gauge local frame).
                GaugeGearBadge {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: -80
                    currentGear: VehicleData.gearProvider.gearValue
                }

                GaugeModeBadge {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.verticalCenterOffset: 170
                    mode: root.driveMode
                }
            }
        }

        // ════════════════════════════════════════════════════
        //  S7.5 — TOP BAR
        // ════════════════════════════════════════════════════
        // Geometry from Screen01.qml: horizontally centred, 90 px from the
        // top, in the same 1024x600 design space as everything else.
        TopBar {
            visible: root.showTopBar
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 90
            currentView: root.currentView
            onViewSelected: function(index) { clusterNavigation.selectView(index) }
            useMipmap: root.iconMipmap
            showPillShadow: root.showShadowPill
            showLeftGlow: root.showShadowLeftGlow
            showRightGlow: root.showShadowRightGlow
            leftIndicatorOn: root.leftIndicatorOn
            rightIndicatorOn: root.rightIndicatorOn
        }

        // ════════════════════════════════════════════════════
        //  S7 — BOTTOM INFO BAR
        // ════════════════════════════════════════════════════
        // Geometry from Screen01.qml, in the same 1024x600 design space as
        // the gauges. The original specifies BOTH `y: 470` and
        // `anchors.bottom` with `bottomMargin: 60`; anchors win, giving
        // bottom = 600 - 60 = 540 and, with height 70, a top edge at 470 —
        // so the two agree and either can be used. Anchors are kept because
        // that is what actually drove the original layout.
        BottomLayer {
            visible: root.showBottomBar
            showBars:   root.showBars
            showCenter: root.showCenter
            flatBars:   root.flatBars
            flatFontSize: root.flatFontSize
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 60
            height: 70

            // Default: driven from the same normalised value as the gauges
            // so the whole scene animates together and every measurement
            // is comparable — see root.liveData's note above for why this
            // stays the default rather than the real backend.
            // --live-data: the original's actual bindings, VehicleData.
            // bottomBar.*, now that the Backend port exists.
            fuelPercent: root.liveData ? VehicleData.bottomBar.fuelProvider.fuelValue
                                        : 100 - root.drive * 85
            rangeKm:     root.liveData ? Math.round(VehicleData.bottomBar.fuelProvider.fuelValue * 5.2)
                                        : Math.round((100 - root.drive * 85) * 5.2)
            motorTempC:  root.liveData ? VehicleData.bottomBar.engineTempProvider.tempValue
                                        : 70 + root.drive * 45
            // .toFixed(1) explicitly, not qreal+string concatenation: a
            // qreal that happens to be a whole number (e.g. 14.0) stringifies
            // via plain JS Number.toString() as "14", not "14.0" -- given the
            // live-data path is now the default, an even value from the
            // telemetry file would silently drop its decimal. Pinning the
            // format keeps it consistent regardless of the incoming value.
            outsideTempText: root.liveData ? VehicleData.bottomBar.envTempProvider.tempValue.toFixed(1) + " °C"
                                            : "14 °C"
            odometerText:    root.liveData ? VehicleData.bottomBar.totalKmsProvider.kmsValue.toFixed(1) + " km"
                                            : "33560.5 km"
            clockText:       root.liveData ? VehicleData.bottomBar.timeProvider.timeValue
                                            : "10:32 PM"
        }
    }

    // Only runs during --simulate (perf testing); wasted otherwise since
    // nothing reads `drive` when liveData is true (the production path).
    SequentialAnimation on drive {
        running: root.simulate
        loops: Animation.Infinite

        NumberAnimation { to: 0.92; duration: 2500; easing.type: Easing.InOutSine }
        NumberAnimation { to: 0.17; duration: 2500; easing.type: Easing.InOutSine }
        NumberAnimation { to: 0.63; duration: 1800; easing.type: Easing.InOutSine }
        NumberAnimation { to: 0.04; duration: 1800; easing.type: Easing.InOutSine }
    }

    // Splash screen — ported from Screen01.qml verbatim (see SplashScreen.
    // qml). Sits directly on the Window, not inside designRoot: it fills
    // the real screen, not the 1024x600 design space, same reasoning as
    // BazelFrame above. Declared last (and z:999, belt-and-braces) so it
    // paints over everything else during its one-time ~3.3 s play.
    // `--no-splash` (property declared up with the other flags near the
    // top of this file) skips it — convenient while iterating, and it was
    // already established this doesn't touch any steady-state measurement
    // (see the header note in SplashScreen.qml).
    SplashScreen {
        anchors.fill: parent
        visible: root.showSplash
        z: 999
    }

    ErrorDialog {
        id: errorDialog
        anchors.fill: parent
    }

    // Print the resolved geometry so the mapping is verifiable on target
    // instead of trusted from hand arithmetic. Expected in design space:
    // speed centre ~(198.4, 321.75), rpm centre ~(810.4, 321.75), each gauge
    // 450 * 0.7 * 0.9 = 283.5 design px across.
    Component.onCompleted: {
        console.log("window:", root.width, "x", root.height,
                    "designScale:", designRoot.scale.toFixed(4))
        console.log("stage: text=" + root.showTextLayers + " ticks=" + root.showTicks,
                    " fontLoader.status:", uiFont.status, "(1=Loading 2=Ready 3=Error)")
        console.log("gaugeArea:", gaugeArea.width + "x" + gaugeArea.height,
                    "childrenRect:", gaugeArea.childrenRect.x, gaugeArea.childrenRect.y,
                    gaugeArea.childrenRect.width, gaugeArea.childrenRect.height)
        // Verify the 2026-08-12 relayout landed where predicted: between the
        // gauges (SPEED right edge ~340.15, RPM left edge ~668.65) and
        // starting at their bottom (~463.5) -- see the long note at
        // contentArea's declaration for the arithmetic this checks.
        var caTL = designRoot.mapFromItem(contentArea, 0, 0)
        var caBR = designRoot.mapFromItem(contentArea, contentArea.width, contentArea.height)
        console.log("CONTENT area top-left (design):", caTL.x.toFixed(2), caTL.y.toFixed(2),
                    " bottom-right:", caBR.x.toFixed(2), caBR.y.toFixed(2))
        var c1 = designRoot.mapFromItem(speedGauge, speedGauge.width / 2, speedGauge.height / 2)
        var c2 = designRoot.mapFromItem(rightGauge, rightGauge.width / 2, rightGauge.height / 2)
        console.log("SPEED centre (design):", c1.x.toFixed(2), c1.y.toFixed(2))
        console.log("RPM   centre (design):", c2.x.toFixed(2), c2.y.toFixed(2))
        if (root.showCar) {
            // carItem's own box is NOT the car's pixels — it's sized for the
            // sprite, which includes the shadow below the car. Map the
            // actual Image (see the alias in Car.qml), not the wrapper.
            var img = carItem.carImage
            var cc = designRoot.mapFromItem(img, img.width / 2, img.height / 2)
            console.log("CAR   centre (design):", cc.x.toFixed(2), cc.y.toFixed(2),
                        " screen y:", (cc.y * designRoot.scale).toFixed(1))
        }
        if (root.showRoad) {
            // Road's own vpX/vpY are local to itself; map through the same
            // chain as the car/gauges above so the two can be compared
            // directly from hardware output instead of hand arithmetic.
            var vp = designRoot.mapFromItem(road, road.vpX, road.vpY)
            var bot = designRoot.mapFromItem(road, road.width / 2, road.height)
            console.log("ROAD  vanishing pt (design):", vp.x.toFixed(2), vp.y.toFixed(2),
                        " screen y:", (vp.y * designRoot.scale).toFixed(1))
            console.log("ROAD  bottom edge  (design):", bot.x.toFixed(2), bot.y.toFixed(2),
                        " screen y:", (bot.y * designRoot.scale).toFixed(1))
        }
    }
}
