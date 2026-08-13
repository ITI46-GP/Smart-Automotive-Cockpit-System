# Qnx-Cluster Rebuild Plan

Rebuild of the Digital Cluster as a clean, pure Qt Creator CMake project (no Qt
Design Studio), built up one layer at a time and measured on the real QNX guest
at every step. Target: 60 fps on i.MX8QM GPU1, display 4.

**Display size — confirmed 1280x720, don't hardcode it either.** We briefly
"corrected" this to 1024x600 based on a description of a physical panel that
turned out to be the RPi's own attached screen (downstream of the network
stream), not the QNX guest's real composited display — the original 1280x720
in memory notes was right all along. Confirmed live, not assumed: a
`console.log` in `Main.qml` printed the real `root.width x root.height` on
the actual board. The bug that exposed the wrong assumption: the pulse
Rectangle (bound to `root.width`) reached the true screen edges while
`BazelFrame` (silently relying on a hardcoded default matching the
*assumed* size) visibly didn't — a live symptom of one hardcoded literal
sitting next to one correct relative binding. **Fix: `Main.qml`'s `Window`
now binds `width`/`height` to `Screen.width`/`Screen.height` (`import
QtQuick.Window`), not a literal number at all** — the QQNX platform
overrides a requested size to the real display anyway, so a hardcoded
literal was never authoritative even before this bug. Everything below the
Window level (BazelFrame, pulse indicator, future gauges) stays bound to
`root.width`/`root.height`, never literals, so a future resolution
difference (different board/panel) doesn't require re-touching every
component — this is now a standing rule in the skill, not just this file.

## Why a rebuild, not a patch

Direct measurement on the board (2026-08-09, see below) proved the QNX/Qt
platform itself is healthy — a bare `simpleQt` app (one animated Rectangle)
locks 60 fps with 0 ms polish. The old `Digital_Cluster_DesignStudioApp`
(`02-Digital-Cluster/`) runs the same platform at 24 fps with **32 ms of GUI-thread
polish**, traced by core-dump stack walk to `QRasterPaintEngine` inside
`polishItems` — i.e. a `Canvas`/`QQuickPaintedItem` doing CPU software painting
every frame. That's 100% application QML, not the platform, the JIT, or Shape
triangulation (all ruled out by measurement — see Appendix).

A fresh, pure-CMake project lets us keep only what's proven fast, drop the
Design Studio plugin/qrc overhead, and gate every added layer on a measured
budget instead of discovering the regression after the whole UI is built.

## Audit of the existing code (`02-Digital-Cluster/`)

| Component | Canvas? | Status | Action |
|---|---|---|---|
| `Gauge/GaugeActiveArc.qml` | No | `Shape` + `CurveRenderer`, already correct | **Port as-is** |
| `Gauge/GaugeNeedle.qml` | Yes, but painted **once** on `Component.onCompleted` only, rotation is a transform | Compliant (static raster cached as texture) | **Port as-is** |
| `Gauge/GaugeTickMarks.qml`, `GaugeLabels.qml`, `GaugeSpeedNumber.qml`, `GaugeSpeedLimitBadge.qml`, `GaugeRedlineZone.qml`, `GaugeGearBadge.qml`, `GaugeModeBadge.qml`, `GaugeInnerDisc.qml` | No | Rectangle/Text/Repeater based | **Port as-is** |
| `BottomLayer/SegmentedGauge.qml`, `TempIndicator.qml`, `InfoBlock.qml`, `CenterInfo.qml`, `FuelIndicator.qml` | No | GPU-rendered | **Port as-is** |
| `Digital_Cluster_DesignStudioContent/BazelFrame.qml` | Yes, but painted once (`onCompleted`/`onWidthChanged` only) | Compliant | **Port as-is**, keep an eye on it if it ever gets wrapped in something that resizes it every frame |
| `Digital_Cluster_DesignStudioContent/Content_Area/Road.qml` | Yes — **6 Canvases**, two of them repainted via `NumberAnimation on offset { onOffsetChanged: requestPaint() }`, i.e. every frame forever | **Confirmed root-cause layer** | **Rewrite** — Repeater of Rectangles/dashes bound to the same offset, per S9 |
| `Digital_Cluster_DesignStudioContent/Content_Area/MapView.qml` | Yes | Not yet profiled in isolation, but same pattern risk | **Rewrite or defer out of the always-visible path** — confirm with a dedicated stage before porting |
| `Digital_Cluster_DesignStudio/Theme.qml` | No | Plain `QtObject` singleton, colors/fonts/spacing | **Port as-is** |
| Backend C++ providers (`Backend/**`) | n/a | Plain `QObject` data providers, not on the render path | **Port as-is**, register the same way in `main.cpp` |
| 224 `DesignEffect` references (blur/layers) | n/a | Unmeasured, `layer.enabled` cost is real on this GPU | **Add one at a time in S10, measure each, keep only what's needed** |

So the rebuild is not "start from zero" — most of `Gauge/` and `BottomLayer/`
already follow the rules and can be copied over close to verbatim. The real
work is: new clean project skeleton, and rebuilding `Road.qml` (and vetting
`MapView.qml`) without per-frame Canvas repaint.

## Target project layout (`Qnx-Cluster/`)

```
Qnx-Cluster/
  CMakeLists.txt              # pure CMake, no qds.cmake, no .qmlproject
  BUILD.md                    # the exact QNX build commands
  src/
    main.cpp
    Backend/                  # ported verbatim from 02-Digital-Cluster/Backend
  qml/
    Main.qml                  # grows stage by stage, S0 -> S10
    Theme.qml                 # ported from Digital_Cluster_DesignStudio/Theme.qml
    Gauge/                    # ported verbatim
    BottomLayer/               # ported verbatim
    ContentArea/
      BazelFrame.qml           # ported verbatim
      Road.qml                 # REWRITTEN, no Canvas
      CarView.qml, TopBar.qml, BottomBar.qml, ...  # ported, DesignEffects added last
```

## Geometry reference — taken from the original cluster

Every stage places its components at the **original cluster's coordinates**,
not at invented fractions. This is the one place to look them up.

**Design space is 1024x600** (`Digital_Cluster_DesignStudio/Constants.qml`),
not the 1280x720 of this panel. `Main.qml` therefore has a `designRoot` Item
of exactly 1024x600, scaled uniformly to fit the live window
(`Math.min(root.width/1024, root.height/600)` = 1.2 here) and centred.
Uniform, because a non-uniform stretch turns circular gauges into ellipses.
This is not a Rule 0 violation: 1024x600 is the original's authoring
coordinate system, while the actual display is still read live from
`Screen.width`/`Screen.height` — nothing assumes a panel size.

The transform chain from `Screen01.qml`:

| Level | Geometry | Source |
|---|---|---|
| `digitalCluster` | 1024 x 600 | `Constants.qml` |
| `gaugeArea` (Studio `GroupItem`) | `x:-148  y:75  scale:0.9` | `Screen01.qml` |
| `SpeedGauge` | `x:92  y:0  450x450  scale:0.7` | resting values, see note |
| `RPMGauge` | `x:772  y:0  450x450  scale:0.7` | resting values, see note |
| `BazelFrame` | anchors fill `digitalCluster` | `Screen01.qml` |

Resolved into design-space coordinates (what to actually aim at):

| | centre (design px) | as a fraction | visual size |
|---|---|---|---|
| Speed gauge | (198.4, 321.75) | (0.194, 0.536) | 283.5 px across |
| RPM gauge | (810.4, 321.75) | (0.791, 0.536) | 283.5 px across |

283.5 = 450 x 0.7 x 0.9. Centre separation is 612 design px.

**Two traps in reading this off the original**, both of which would silently
move the gauges:

1. `x:92` / `x:772` are **commented out** in `Screen01.qml`. The live values
   there are `x:432, scale:0.1, opacity:0` — the parked state for a startup
   animation. The resting geometry comes from that animation's `to:` targets
   in `startupSequence` phase 1, which is the authoritative source.
2. `gaugeArea` is a Studio `GroupItem`, which sizes itself from its children
   (`implicitWidth = max(16, childrenRect.width + childrenRect.x)`). Its
   `scale: 0.9` pivots about the centre of the bounding box of **all** its
   children — including a 424x1320 `frame` rectangle and a 480x424
   `contentArea` belonging to later stages. Omit those and the pivot moves,
   shifting both gauges. `Main.qml` keeps them as geometry-only placeholders
   (plain `Item`s, original x/y/w/h, no visual content, zero draw calls) so
   `childrenRect` matches; later stages replace them in place.

Because of trap 2, `Main.qml` replicates the structure and lets QML recompute
the mapping rather than hardcoding the resolved centres, and prints the
result at startup so it can be checked on target instead of trusted from
arithmetic.

**Known deviation, deliberate:** `BazelFrame` fills the real 1280x720 window
rather than sitting inside the 1024x600 design space, because the PNG was
baked at panel size in S1 to avoid non-uniform stretching. That puts the
gauges ~1% off their original position *relative to the bezel*. Revisit at
S7, when the real frame and content area arrive and that relationship starts
to matter.

## Build-up ladder (S0 -> S10)

Never move to stage N+1 until stage N passes its gate. A regression is then
always attributable to exactly one change.

**Gate per stage:** `polish <= 2 ms`, `render <= 4 ms`, `fps >= 55`.

- **S0** — new project skeleton, single animated `Rectangle`, `Screen.width x Screen.height` window (1280x720 on this board). Re-establishes the 60 fps reference inside the new CMake setup (not reusing the old `simpleQt` binary). *(done)*
- **S1** — `BazelFrame` ported in as a baked PNG (Image), not Canvas — see "S1 finding" below for why. *(done)*
- **S1.5 lesson (applies to every future component that uses `Theme`):** the QML-authored `pragma Singleton` mechanism for `Theme` never worked reliably in this Qt/CMake config — two attempts (module auto-registration from the pragma text, then a C++-loaded root context property) both silently resolved every `Theme.*` reference to `undefined` at runtime with zero build errors, across full clean reconfigures on both the desktop kit and the QNX target. **Fixed by switching to a real C++ `QML_SINGLETON`** (`src/Theme.h`, `QObject` + `QML_NAMED_ELEMENT(Theme)` + `QML_SINGLETON` + one `Q_PROPERTY` per value) — the same proven pattern the old app used for its `Backend/*.h` providers. That surfaced a second, genuinely different bug: `qt_add_qml_module`'s generated `qmltyperegistrations.cpp` does `#include <Theme.h>` (bare filename, resolved via the compiler's include *search path*, not a relative path) but `SOURCES` entries in `qt_add_qml_module` don't automatically add their own directory to the target's include path — fixed with `target_include_directories(QnxClusterApp PRIVATE src)` in `CMakeLists.txt`. Every ported Gauge/BottomLayer/ContentArea component that references `Theme` needs `import QnxCluster` (required for a C++-registered module type, unlike same-module plain composite `.qml` types).
- **S2** — one gauge arc (`GaugeActiveArc`), static value (90/240), no `layer.enabled`. Ported close to verbatim — already `Shape`+`CurveRenderer` before this rebuild started. Measured on the QNX guest: `fps=60`, `polish=0ms`, steady `render≈1ms` — gate passed. (One-time ~2.2s stall seen when relaunching immediately after `slay`-ing a prior instance, tied to QNX's `_ProcessShLockLibFile`/`_ProcessExLockLibFile` messages — the previous process's teardown racing the new one's shared-library lock, a testing-workflow artifact from rapid relaunches, not a per-frame regression or a production boot-path concern.) *(done)*
- **S3** — animate `GaugeActiveArc.value` over time. This is the stage that stress-tests continuous `sweepAngle` change on a `Shape`, exactly what would have exploded if this were still the old Canvas-based ArcItem. Retired the S0/S1 pulse indicator now that the gauge itself exercises `animations=`. **PASSES — 60 fps, `polish=0ms`, `render=1ms`.** *(done)*
  - **The `fps=14` failure was a measurement artifact, not a rendering problem.** Re-analysing the original failing log (`tools/analyze_frames.py`, written for exactly this) settles it. The stimulus was a 1400 ms `Timer` whose jumps were smoothed by the component's internal 300 ms `Behavior on animatedValue`. The log shows the render thread producing **19-20 frames in ~280 ms after every single tick — a frame period of 16-17 ms, i.e. a locked 60 fps, with `render=1ms`, `sync=0ms`, `polish=0ms`** — and then producing nothing for the remaining ~1.1 s of each 1.4 s cycle. The idle windows line up with the Timer period to within ±20 ms across all 19 cycles, and the active windows line up with the 300 ms animation duration. Qt Quick's threaded render loop is **demand-driven**: when the `Behavior` finishes, nothing on screen is changing, so no frames are drawn. That is correct, desirable behaviour. Averaging `grep -c "frame rendered"` over a window that is deliberately idle 82% of the time yields 14 — a number that describes the *stimulus*, not the renderer.
  - **The cross-check that makes this airtight:** S2 measured a clean 60 fps with a *static* arc value. If a static arc could sustain 60 fps, an animating one going idle could not be the regression. What actually differed between S2 and S3 was that **S2 still had the S0/S1 pulse indicator animating continuously**, keeping the render loop busy; S3 retired it, so the app went idle between ticks for the first time in the ladder. The variable that changed was the pulse `Rectangle`, not the arc.
  - **Everything previously blamed is exonerated, in order:** `clusterStreaming` (already ruled out by A/B, correctly); the `screen` compositor (the `pidin` samples showing `REPLY <sbin/screen>` were taken *during the idle windows* — a render thread waiting for its next frame request legitimately sits in `REPLY` to the compositor, so that observation was real but meant "idle", not "stalled"); `Shape.CurveRenderer` and dynamic path geometry generally (this log is direct evidence that regenerating the halo's `PathAngleArc` geometry every frame costs `render=1ms` on this board and sustains 60 fps). **The `gles3-gears` control test was sound but the inference from it was not** — gears differs from our arc in more than one way, and "changes a uniform, not geometry" was picked out of several candidate differences without testing that one in isolation.
  - **Actual change made:** none to `GaugeActiveArc.qml` — it was never wrong. `Main.qml`'s stimulus is now a looping `SequentialAnimation` driving `value` **continuously** (no idle windows at all, `enableSmoothing: false` so there is no second easing layer), which is strictly *harder* than the old Timer + Behavior pattern and makes the averaged fps number meaningful again. Also fixed a live Rule 0 violation in the same file: `width`/`height` were hardcoded to `1024x600` with the `Screen.width`/`Screen.height` binding commented out.
  - **Attempted fix, now moot: rotating cover-mask (reverted, broke the visual).** Tried making the halo `Shape` geometry fully static and faking the reveal with two large rotating `Rectangle` covers. Worked through the rotation math by hand but never saw it rendered before deploying — it visibly broke the gauge, and was reverted. Worth keeping in the record because the lesson stands on its own: **don't ship a geometrically fiddly rewrite in one shot when it can't be visually verified first.** The deeper lesson is the one above it, though — *this rewrite should never have been started*, because the measurement that motivated it was never validated.
  - **Standing rule that came out of this:** before treating a low fps as a regression, check whether the render loop was *idle* or *stalled*. `tools/analyze_frames.py` answers this in one run: it segments the log into animation bursts and reports instantaneous fps inside each, instead of an average across idle time. Run it on every stage from here on; never read a bare fps average again.
  - **CONFIRMED ON TARGET (fresh run, continuous stimulus):** 1295 frames in one
    unbroken burst, **sustained 62 fps**, frame period p50/p95/p99 = 16/18/20 ms,
    `polish+sync+render` p95 = **7 ms of the 13 ms budget**, polish p95 = 1 ms.
    Two `Shape`s regenerating arc geometry every single frame, with zero idle
    windows. S3 closed.
  - **Second measurement incident, worth as much as the first: the harness
    reported PASS on a stale log.** A `deploy_and_measure.sh` run returned
    byte-for-byte the same 225805-byte log as the *previous* session — same
    frame count, same burst table, same window pointer — while a hand-run of the
    same binary showed the correct continuous trace. Cause: an earlier root
    shell had left a **root-owned `/tmp/x.log`** on the board. `measure_board.py`
    connects as `qnxuser`, so its `rm -f` failed silently, the shell redirect was
    permission-denied, and `sftp.get` happily pulled the stale root-owned file.
    The script had discarded the launch command's stderr, which is exactly where
    "permission denied" was printed. **Fixed:** unique per-run log filename that
    cannot collide with anything left behind, refusal to start if it somehow
    exists, launch stderr surfaced instead of swallowed, deploy size verified
    against the local binary, and a check that the log actually grew during the
    window. The lesson is the S3 lesson again in a different costume: a number
    that looks authoritative but describes something other than what you meant
    to measure. Verification tooling has to prove its own inputs are fresh.
  - **Gate reworked from max to percentiles.** The first version of
    `analyze_frames.py` gated on the worst single frame, which failed the real
    S3 run on one 18 ms render outlier out of 1296 frames (p50 was 2 ms). Over
    thousands of frames there is always an outlier, so a max-based gate makes
    every stage fail eventually and teaches you to ignore the verdict — the
    mirror image of the false-PASS problem. The gate is now: frame period p99
    <= 20 ms, sustained fps >= 55, **`polish+sync+render` p95 <= 13 ms** (the
    budget this project already documented, rather than an invented per-component
    number), and polish p95 <= 2 ms kept separately because sustained GUI-thread
    painting is a specific defect signature. The worst frame is still printed,
    labelled as informational.

- **S4** — second gauge (RPM), alongside the speed gauge. Both `GaugeActiveArc`
  instances are driven from one normalised `drive` property, so both `Shape`s
  regenerate geometry on the same frame — the worst case, not an average one.
  **PASSES: sustained 61.9 fps, frame period p99 = 17 ms, `polish+sync+render`
  p95 = 2 ms of 13, polish p95 = 0 ms, worst render 4 ms.** 1693 frames in one
  unbroken burst. *(done)*
  - Two animating gauges measured **cheaper** than one did in S3 (render p95
    2 ms vs 5 ms, worst 4 ms vs 18 ms). Two arcs cannot cost less than one, so
    the S3 run simply caught transient load — a useful reminder that a single
    run's tail percentiles carry noise even when the verdict is solid. Both
    pass with a wide margin; not worth chasing.
  - **Geometry then re-done from the original.** The first S4 draft placed the
    gauges at `root.width * 0.25 / 0.75` — measured fine, but invented. They
    now come from `02-Digital-Cluster`'s own transform chain; see the geometry
    reference section above for the values and the two traps in reading them
    off (`x:92`/`x:772` are commented out in `Screen01.qml`, and `gaugeArea`'s
    `scale: 0.9` pivots about a bounding box that includes elements from later
    stages). Needs a re-measure after the geometry change, since gauge size
    went from 420 px to an effective 283.5 design px and the whole scene now
    sits under an extra scale transform.
- **S5** — text layers: `GaugeSpeedNumber` + `GaugeLabels` on both gauges, ported
  close to verbatim (both were already pure `Text`, no Canvas). Geometry from the
  originals: labels `anchors.fill` the 450x450 gauge with `labelStep` 30 (speed,
  0-240) and 1.0 (rpm, 0-8) = 9 labels each; the hero number is 300x300 centred.
  **PASSES: sustained 62.0 fps, frame period p99 = 17 ms,
  `polish+anim+sync+render` p95 = 10 ms of 13, polish p95 = 0 ms.** *(done)*
  - **The cost of text, measured:** `render` p50 went 2 ms -> 6 ms and
    `animations` 0 ms -> 2 ms versus S4. `swap` absorbed it (13 -> 8 ms) so the
    frame period never moved off 16-17 ms. So ~22 `Text` items cost about 4 ms
    of render and 2 ms of animation on this board — comfortably affordable
    here, but it is now half the 13 ms budget spent, and S6 adds 130 more
    instances. Worth knowing the headroom before that lands.
  - `polish` stayed at 0 ms p95, so glyph layout is not hitting the GUI
    thread — including for the RPM number's `toFixed(1)` string, which changes
    many times a second. The worst case that was deliberately kept is a
    non-issue; no need to quantise the string.
  - **BLOCKER FOUND FIRST: the QNX target has no fonts at all.** `find / -name
    '*.ttf'` on the guest returns nothing, and there is no `/usr/share/fonts`,
    `/qt/lib/fonts` or `/qt/fonts`. The original never hit this because Qt Design
    Studio's `QuickStudioApplication` calls `QFontDatabase::addApplicationFont()`
    over a bundled `fonts/` directory — machinery the clean rebuild deliberately
    dropped. **Fix:** `KdamThmorPro-Regular.ttf` (85 KB) is embedded in
    `resources.qrc` and registered by a `FontLoader` in `Main.qml`, whose
    `status` is logged at startup. Embedding beats installing on target for an
    embedded cluster anyway — no dependency on filesystem state, nothing to lose
    on a reflash. Only this one face is needed so far: `Theme.fontPrimary` is
    "Kdam Thmor Pro" and `GaugeSpeedNumber` hardcodes it too. `Theme.fontSecondary`
    ("Inter") is unreferenced by anything ported to date; add it when a component
    that uses it lands, rather than embedding 16 unused faces now.
  - **Second harness bug, same family as the stale log:** the measurement
    environment exports `FONTCONFIG_FILE=/tmp/fonts.conf` to skip a slow
    fontconfig fallback search, but nothing ever put that file on the board — it
    had been dangling at a missing path this whole time. `measure_board.py` now
    ships `tools/fonts.conf` on every run.
  - **Measured as two stages from one build.** S4's geometry rework landed after
    S4 was measured, so it is itself unmeasured; stacking text on top would make
    a regression ambiguous between the two. The text layers sit behind
    `--no-text` (read via `Qt.application.arguments`), so one binary gives both
    numbers back to back and the delta is attributable to the text alone.
  - **What to watch:** `polish`, since text layout/shaping is GUI-thread work. The
    speed number's `displayValue` defaults to `Math.round(value)`, so its string
    only changes when the integer does. The RPM number passes `toFixed(1)` — kept
    faithful to `RPMGauge.qml` deliberately, so this measures the honest worst
    case (a string changing many times a second on a continuously animating
    value). If it shows up, quantising the string is the fix — but measure first.
    Also note the `animations=` bucket now: 18 `ColorAnimation` Behaviors (one per
    label) is the start of the growth that reached ~98 in the original, which S6's
    tick marks will push on.
- **S6** — tick marks (`GaugeTickMarks`, `Repeater`-based), ported verbatim.
  Steps from the originals: speed `big/medium/small = 30/10/5` over 0-240,
  rpm `1.0/0.5/0.1` over 0-8. *(built, awaiting on-target measurement)*
  - **Instance count is the whole story: 130 ticks**, not the ~98 this plan
    previously estimated — 49 on the speed gauge and **81 on the rpm gauge**,
    because `smallStep 0.1` over a 0-8 range generates far more ticks than a
    step of 5 over 0-240. Each is an `Item` + `Rotation` + `Rectangle` +
    `ColorAnimation` Behavior. This is the largest single jump in the ladder.
  - **Ported as-is on purpose.** The temptation is to pre-optimise 130
    instances. This project has already built half a rendering rewrite for a
    problem that did not exist; the discipline is to port faithfully, measure,
    and change only what the numbers say to change. If it fails, the ranked
    suspects are (1) `animations=`, fixable by dropping the Behavior or
    colouring by static position as `SegmentedGauge.qml` does, and (2) draw
    calls, since each tick's `Rotation` breaks batching — fixable by baking the
    passive tick ring to a PNG per Rule 2 and drawing only active ticks live.
    Both cost visual fidelity, so neither is worth spending unmeasured.
  - **Isolated behind `--no-ticks`**, same one-build-two-stages trick as S5.
  - **Gate now includes `animations`.** `tools/analyze_frames.py` previously
    checked `polish+sync+render`; `animations` is real GUI-thread work in the
    same `polishAndSync` pass and is exactly the component that grows with
    concurrent Behaviors, so leaving it out would have hidden the one cost this
    stage is most likely to blow. Re-checked against the S3/S4/S5 logs: all
    still pass with it included.
  - **z-order fixed while porting.** `SpeedGauge.qml`/`RPMGauge.qml` draw
    ticks -> redline -> labels -> active arc -> inner disc -> number. S5's
    draft had the arc *under* the labels; the halo is meant to wash over them.
    Corrected in `Main.qml`.
  - **RESULT: FAILS.** `render` p50 6 -> 12 ms, `animations` 2 -> 4 ms, frame
    period p50 16 -> 18 ms, `swap` collapsed 8 -> 4 ms (no slack left),
    sustained 56.9 fps, frame period p99 = 22 ms, budget p95 = 19 ms of 13.
    `polish` stayed 0, so the GUI thread is not the problem.

### S6 diagnosis: six hypotheses tested on target, all disproved

Every one of these was measured on the board, not reasoned about. Recorded in
full because the negative results are what stop the next person re-testing
them — and because the first two were the "obvious" answers.

| # | Hypothesis | Test | Result |
|---|---|---|---|
| 1 | Draw-call explosion: per-tick `Rotation` breaks batching | `QSG_RENDERER_DEBUG=render` batch counts | **Disproved.** 130 tick nodes add only 12 batches (22 vs 10). Qt batches them fine. |
| 2 | Rounded ticks force the smooth/AA material into the alpha pass | `--ticks-square` | **Disproved.** render unchanged at 11 ms. |
| 3 | Antialiasing specifically | `--ticks-noaa` | **Disproved.** 11 ms. |
| 4 | 130 `ColorAnimation` Behaviors | `--ticks-noanim` | **Disproved.** 11 ms. |
| 5 | Per-item `opacity` dim forcing nodes into the alpha pass | `--ticks-nodim` | **Disproved.** 11 ms. |
| 6 | Merged batches re-uploading vertices every frame | upload-vs-retained counts, then raising `QSG_RENDERER_BATCH_NODE_THRESHOLD`/`_VERTEX_THRESHOLD` | **Disproved.** *Every* batch already uploads every frame in both configs (12/12 and 19/19), and raising the thresholds changed nothing. |

All three styling flags combined (`--ticks-square --ticks-noanim --ticks-nodim`)
also measured 11 ms — identical to the faithful original.

**Conclusion: the cost is the node/primitive count itself.** ~130 extra small
quads cost ~5 ms of render on this GC7000XSVX regardless of material,
antialiasing, animation, opacity, or batching. A tempting correlation —
render time tracked batch count almost linearly (12 batches -> 6 ms, 19 -> 11,
~0.55 ms per batch) — turned out to be coincidence: raising the batch
thresholds changed the batching without changing the time.

The diagnostic knobs are left in `GaugeTickMarks.qml` (all defaulting to the
faithful original) so this is re-testable in one run after any future change.

**Implication for the fix:** anything that keeps 130 live primitives is
unlikely to help. The count has to come down.

### S6 diagnosis round 2 — separating count from fill from transform

Round 1 killed every *styling* explanation, which leaves three mechanisms that
all scale with "130 more things on screen" and that round 1 could not tell
apart. Round 2 changes exactly one of them at a time, all from one build:

| Flag | Holds fixed | Varies | Tells us |
|---|---|---|---|
| `--ticks-every=N` | size, transforms, material | **node count** | If render time scales with N, primitive count is the mechanism |
| `--ticks-tiny` | node count, transforms, material | **covered area** (3 px ticks) | Whether it is fill rate / blended overdraw |
| `--ticks-norot` | node count, size, material | **per-tick transform** | Whether it is transform nodes / scene-graph traversal |
| `--ticks-shape` | the visual | **implementation** | Measures the candidate fix directly |

`--ticks-norot` deliberately renders incorrectly (all ticks stack at 12
o'clock). It is a measurement, not a rendering.

**Candidate fix, `qml/Gauge/GaugeTickMarksShape.qml`** — drop-in replacement
with the same public API. Every tick is a radial line segment, so the ring is
expressible as stroked polylines: `PathMultiline` puts all ticks sharing a
stroke width and colour into ONE `ShapePath`. Three widths x two colour states
= **6 ShapePaths in 1 Shape, instead of 130 Items each with a Rotation and a
Rectangle.** The active set is always a contiguous prefix, so it is fully
described by an integer `activeCount` that changes only when the value crosses
a tick — the path geometry is rebuilt a few times a second, not 60. (And S3
established that animating a Shape's geometry costs ~1-2 ms here anyway, so it
is safe even in the worst case.)

Its tick placement was verified against the Rectangle implementation
numerically before building: the Shape version computes positions directly in
polar form, while the original parks a Rectangle at 12 o'clock and rotates by
`angle + 90`. Both land on identical coordinates to 4 decimal places at v=0,
120 and 240 — so any measured difference is performance, not geometry.

What it gives up: the per-tick colour fade, since colour now belongs to a path
rather than a tick. Round 1 measured `--ticks-noanim` as performance-identical
and visually near-identical, so this costs little.

Both implementations return an empty model when `!visible`, so the unused one
costs nothing and cannot contaminate the comparison it exists to inform.

### S6 round 2 results — measured on target

| Variant | ticks | render p50 | fps |
|---|---|---|---|
| `--no-ticks` (S5 baseline) | 0 | 6 ms | 62.2 |
| `--ticks-every=8` | 18 | 7 ms | 62.4 |
| `--ticks-every=4` | 34 | 7 ms | 62.4 |
| `--ticks-every=2` | 66 | 7 ms | 62.4 |
| full | 130 | **11 ms** | 57.9 |
| `--ticks-tiny` (3 px ticks) | 130 | 8 ms | 62.4 |
| `--ticks-norot` (all stacked) | 130 | **37 ms** | **22.6** |
| **`--ticks-shape`** (GeometryRenderer) | 130 | **7 ms** | **62.3** |
| `--ticks-shape --ticks-curve` | 130 | 13 ms | 60.3 |

**The mechanism is blended fill, not node count.** The count curve is flat from
18 to 66 ticks and only bends at 130, so "more primitives" is not a
proportional cost. The two decisive rows are the last-but-two: holding node
count, transforms and material fixed while shrinking the ticks to 3 px
recovers 3 ms, and stacking all 130 ticks on top of each other — same count,
same size, same material, only overlapping — explodes render to 37 ms and
22.6 fps. This GPU is cheap on geometry and expensive on blended pixels, and
punishing about overdraw specifically.

That is a reusable finding well beyond S6: **treat overlapping translucent
layers as the expensive thing on this board, not element counts.** It should
be the first suspect for S8's car image, S10's effects, and anything stacking
alpha.

`CurveRenderer` being nearly twice the cost of `GeometryRenderer` here is
consistent with Rule 2.5 rather than a contradiction: these are straight line
segments, so there are no curves for the analytic renderer to resolve — it
only adds work. **Refined guidance: `CurveRenderer` for actual curves,
`GeometryRenderer` for polylines.**

**The fix lands.** `GaugeTickMarksShape` matches the zero-tick baseline
(render 7 ms vs 6 ms, 62.3 fps) while drawing all 130 ticks.

**But the first cut of it only moved the cost.** A full-gate run showed render
correctly down at 7-8 ms yet `animations` up from 5 to 10 ms p95. Cause:
`buildSegments` recomputed trig and allocated fresh points for all 130 ticks
across 12 bindings every time `activeCount` changed — about 48 times a second.
Fixed by precomputing the polylines once (they never move; only which ones are
active changes) so each update is an array slice, and by computing
`activeCount` arithmetically instead of scanning the model every frame.

**S6 PASSES with `GaugeTickMarksShape`:** sustained 62.3 fps, frame period p99
17 ms, render p50 7 ms (baseline 6), polish 0. GUI thread 10 ms and render
thread 9 ms, both against a 13 ms gate.

### The gate itself was wrong: it double-counted concurrent threads

The shape fix initially read as a 1 ms FAIL (14 vs 13) while simultaneously
delivering 62.3 fps with every frame inside one vsync — a gate contradicting
the outcome it exists to predict, which is a reason to audit the gate, not the
code.

It was summing `polish + animations + sync + render` into a single budget. That
double-counts: Qt Quick's threaded render loop advances animations and polishes
on the **GUI thread** while the **render thread** renders the previous frame.
Frame rate is bounded by `max(gui, render)`, never by their sum. Corrected to
check the two threads separately:

- GUI thread: `polish + animations` <= 13 ms
- render thread: `sync + render` <= 13 ms (`swap` is the wait for vblank, not work)

Re-verified across every log on hand: the S3 runs and the fixed S6 pass, the
Rectangle-based S6 still fails on render thread (1 + 14 = 15 ms), and the
synthetic Canvas-every-frame regression still fails on GUI thread, polish, fps
and frame period. The correction does not weaken what the gate catches.

**Note for future stages:** `--ticks-frozen` and `--ticks-layer` are wired but
not yet measured. They answer "how much is the per-frame geometry *rebuild*
costing, versus the draw?" — `frozen` removes the active/passive split so
`paths` never changes and nothing is re-triangulated; `layer` caches the ring
to a texture. Not needed now that S6 passes, but they establish the GUI-thread
floor, which matters as S7-S10 add work to the same thread.

- **S6.5** — `GaugeRedlineZone`: red ticks over the danger range, overlaid on
  the normal ticks. Speed 210-240 step 5 (7 ticks), rpm 6.0-8.0 step 0.1 (21),
  28 total. Isolated behind `--no-redline`. *(built, awaiting measurement)*
  - **Built Shape-based from the start** — the one justified departure from
    "port faithfully, then measure". S6 tested this exact content type on this
    exact board: tick Rectangles cost ~5 ms of render thread, the same ticks as
    stroked `PathMultiline` cost ~1 ms. Porting 28 Rectangles would re-run a
    settled experiment, not exercise caution.
  - This component has it easier than `GaugeTickMarks`: the redline never
    changes at all. It does not read `value`, has no active/passive split and
    is one flat colour, so its three `ShapePath`s are built once at startup and
    Qt never re-triangulates them. Expected cost is close to zero.
  - **`GaugeTickMarksShape` is now the default** for S6 following its measured
    win (Rectangles: render p95 14 ms / 56.9 fps FAIL; Shape: 8 ms / 62.3 fps
    PASS). `--ticks-rects` restores the Rectangle version so the comparison
    stays reproducible.
- **S7** — `BottomLayer` (bottom info bar). Six components ported close to
  verbatim: `BottomLayer`, `CenterInfo`, `InfoBlock`, `FuelIndicator`,
  `TempIndicator`, `SegmentedGauge`. All were already layout/`Text`/`Rectangle`
  based with no Canvas and no `DesignEffect`. Isolated behind `--no-bottombar`.
  *(built, awaiting measurement)*
  - **Split from TopBar.** The ladder had these as one stage, but `TopBar`
    carries four `DesignEffect` drop shadows, which the ladder puts in S10, plus
    its own `TopBarButton` and several icon assets. Pulling it in here would
    both break one-change-per-stage and drag S10's work forward. TopBar is now
    S7.5.
  - Geometry from `Screen01.qml`, in the same 1024x600 design space: full
    width, `height: 70`, `anchors.bottom` with `bottomMargin: 60`. The original
    specifies both `y: 470` and those anchors; anchors win, and the two agree
    (600 - 60 - 70 = 470), so this is unambiguous.
  - Two icons (`fuel_icon_unselected.png`, `engineTemp.png`) embedded via
    `resources.qrc` with explicit aliases, referenced as `qrc:/icons/...` — not
    the original's relative `"../Digital_Cluster_DesignStudioContent/assets/..."`,
    which would not resolve from inside the compiled module (the S1 trap).
  - **Dead code dropped, not ported:** `SegmentedGauge` declared
    `isDangerZone` from `gaugeRoot.dangerThresholdPercent`, a property that is
    never declared anywhere in the component. It evaluated against `undefined`,
    and nothing read the result — the colour logic uses
    `isStartSegment`/`isEndSegment`. Porting it would emit a runtime warning on
    every one of the 60 delegates for no behaviour.
  - Adds ~60 small `Rectangle`s (two 30-segment bars). Values are driven from
    the same `drive` property so the whole scene animates together; the
    original's `VehicleData` bindings arrive with the Backend port.
  - **RESULT: FAILS.** render p50 7 -> 14 ms, frame period p50 16 -> 20 ms,
    swap down to 3 ms (no slack), sustained 51.0 fps. GUI thread stayed clean
    at 8 ms and polish at 1 ms, so this is render-thread again.
  - **Isolated on target with the existing flags:**

    | config | render p50 |
    |---|---|
    | S7 full | 14 ms |
    | `--no-bottombar` | 7 ms |
    | `--no-text` (bar on, gauge text off) | 9 ms |

    So the bottom bar costs **7 ms** and the S5 gauge text **5 ms**. The
    prediction that 60 non-overlapping Rectangles would be free — from S6's
    flat 18-to-66 tick curve — did not hold, so the bar is not simply "more
    small rects"; something in it is disproportionate.
  - **A measurement artefact worth recording:** a first pass at this sweep read
    `--no-bottombar` as 11 ms, not 7. Cause was the previous variant's process
    not having fully exited before the next launch, so two apps briefly shared
    the display. Fixed by lengthening the slay-and-settle pause. Any sweep that
    launches variants back to back needs that guard — an 11-vs-7 error is large
    enough to have sent the next fix in the wrong direction entirely.
  - **Full decomposition, measured layer by layer:**

    | layer added | render p50 | delta |
    |---|---|---|
    | baseline: arcs, ticks, redline, bezel | 5 ms | — |
    | + gauge text (22 `Text`) | 9 ms | **+4** |
    | + bottom-bar text (~14 `Text`) | 11 ms | **+2** |
    | + segmented bars (60 `Rectangle`) | 14 ms | **+3** |

    **Text dominates: 6 ms of the 14 for ~36 `Text` items**, about 0.17 ms
    each — twice the cost of the 60 Rectangles. So the obvious fix (apply S6's
    Rectangles -> `PathMultiline` trick to the segmented bars) would have
    chased the smaller half of the problem. Worth noting the earlier
    prediction that "60 non-overlapping Rectangles will be free, S6 showed
    18-to-66 ticks was flat" was also wrong: they cost 3 ms.
  - This fits S6's mechanism rather than contradicting it. Qt's default
    distance-field text draws every glyph as a blended quad whose antialiased
    falloff region is larger than the glyph, and this GPU is fill/blend bound.
    ~36 Text items is on the order of 180 blended glyph quads.
  - **`--native-text` measured, and DISPROVED.** `QQuickWindow::
    setTextRenderType(NativeTextRendering)` gave render p95 **16 ms vs 15 ms**
    for the default distance-field path, frame period p99 25 vs 23 — slightly
    worse, better on nothing. So the cost is not glyph rasterisation; it is the
    number of blended glyph quads, which is identical either way. Default left
    unchanged; the flag stays so the negative result is re-checkable rather
    than re-theorised later. (Eighth hypothesis tested on this board and
    disproved. The pattern by now is unmistakable: on this GPU, blended pixel
    coverage is the only thing that has ever mattered — never the code path
    producing it.)
  - **★ THE REAL MECHANISM: ~0.42 ms per BATCH.** "Text is expensive" was the
    wrong conclusion, and the right objection to it was that 36 `Text` items
    cannot plausibly cost 6 ms. Measuring node and batch counts per
    configuration against the render times settles it:

    | config | render p50 | alpha nodes | alpha batches |
    |---|---|---|---|
    | `--no-bottombar` | 7 ms | 45 | 15 |
    | `--no-text` (bar on) | 9 ms | 99 | **15** |
    | `--no-bars` (text on) | 11 ms | 61 | **21** |
    | full S7 | 14 ms | 121 | 23 |

    Rows 2 and 3 are decisive: **more nodes but fewer batches renders faster.**
    A fit over all four gives `render ≈ 0.42 ms × batches + 0.037 ms × nodes`,
    predicting every configuration within 1 ms. Batches account for ~9.6 ms of
    the 14 — a draw call on this driver costs more than eleven nodes.

    So the cost of `Text` is not glyphs, it is **materials**. Qt only merges
    sibling nodes that share a material, and a colour is part of the material.
    The 18 gauge labels each run a `ColorAnimation`, so at any instant they
    hold 18 *different* interpolated colours and can never merge — 18 labels
    become 18 batches. `SegmentedGauge` does the same thing with three per-item
    opacity levels across 30 segments.

    This also retires the earlier "it is fill-bound" framing from S6 as
    incomplete. Overdraw is genuinely catastrophic here (`--ticks-norot`, all
    130 ticks stacked, cost 37 ms) — but for non-overlapping content the
    dominant term is the draw call, not the pixel. Both are true; the batch
    term is the one that has been driving every stage since S5.

  - **The "materials" half of that was ALSO wrong.** `--flat-labels
    --flat-bars` collapsed the colour and opacity variation and moved batches
    from 23 to **22** — one batch, 1 ms. So distinct colours are not what
    prevents merging. Ninth hypothesis, disproved.
  - **What IS true — batch attribution per component**, measured by toggling
    each and reading the batch count:

    | component | nodes added | batches added |
    |---|---|---|
    | tick marks (`Shape`) | 12 | **0** |
    | redline (`Shape`) | 6 | **0** |
    | segmented bars (`Rectangle`) | 60 | 2-3 |
    | bottom-bar text | ~16 | **6** |
    | gauge text | 22 | **8** |

    Removing the ticks or the redline changes the batch count by *nothing* —
    `Shape` and `Rectangle` siblings merge nearly perfectly. **`Text` is the
    only thing in this UI that does not merge**, at roughly one batch per 2.7
    items, and at ~0.5 ms per batch that is where the frame goes.
  - **So baking static text is the right fix after all — but for a different
    reason than first proposed.** The earlier argument was "fewer glyph quads";
    that reasoning was wrong (`--native-text` proved glyph rasterisation is not
    the cost). The correct argument is **fewer batches**: every `Text` removed
    takes ~0.37 of a batch with it. The 18 gauge labels plus the two unit
    captions are fixed strings — baking them into the already-drawn
    `BazelFrame` PNG removes ~20 `Text` items and ~7 batches for zero
    additional draw cost. `--no-text` already measures the ceiling for this:
    render 14 -> 9 ms.
  - The live readouts stay live: the hero speed/rpm numbers, and the bottom
    bar's TEMP / TOTAL KM / TIME values, which are real data and must remain
    `Text`. Six items, ~2 batches, ~1 ms — affordable and non-negotiable.
  - Cost of baking the gauge labels: they lose the active/passive colour change
    as the needle passes. That is the only visual concession, and it is a
    design decision rather than a technical one.
  - **Implemented.** `tools/gen_dial_labels.py` (Pillow, uses the same embedded
    Kdam Thmor Pro face) bakes `DialLabelsSpeed.png` and `DialLabelsRpm.png` at
    2x supersample **in the gauge's own 450x450 coordinate space** — the same
    space `GaugeLabels.qml` works in — so the image just fills the gauge Item
    and inherits the already-verified transform chain. No scene geometry is
    re-derived in the generator, which is what would have made it fragile.
    `GaugeLabels` gained a `baked` mode (default on) that swaps the Repeater
    for one `Image`; `--live-labels` restores the Text version so the
    before/after stays reproducible. Output was inspected before shipping —
    0 at lower-left, sweeping clockwise through 120 at top to 240 at
    lower-right, per the 135 deg / 270 deg convention.
  - Left live on purpose: the hero numbers, the unit captions (their position
    depends on the hero number's font metrics, which cannot be reproduced in
    the generator without duplicating Qt's text layout — two items is not worth
    that fragility), and the bottom bar's TEMP / TOTAL / TIME readouts.
  - **Also fixed:** `tools/gen_bazel_frame.py` wrote its PNG to an absolute
    path from a long-dead session (`/sessions/festive-happy-rubin/...`), so
    re-running it would have failed rather than regenerating the art. It now
    writes to `assets/` relative to the script.
  - **RESULT: helped, under-delivered, and corrected the model again.**
    render p50 14 -> 12 ms, p95 15 -> 13, sustained fps **51.0 -> 57.4**.
    But batches only went 23 -> 21, not the ~8 predicted:

    | config | nodes | batches |
    |---|---|---|
    | live labels (before) | 121 | 23 |
    | baked labels (after) | 105 | 21 |
    | baked, no bottom bar | 29 | 12 |

    Removing 18 `Text` items saved **2** batches, not 8. So "one batch per 2.7
    Text items" was itself an artefact of how the earlier test was built:
    `--no-text` removes `GaugeLabels` *and* `GaugeSpeedNumber`, i.e. the 18
    labels **plus** the hero number and unit caption. The labels were never the
    expensive part.
  - **Best-supported explanation (NOT yet isolated, flagged as such):** text
    batches track the number of distinct **font sizes**, not the number of
    `Text` items. Qt keeps a distance-field glyph atlas per font/size, and
    nodes sampling different textures cannot merge. The 18 dial labels all
    share size 18 and were therefore *already* merged into ~2-3 batches — which
    is exactly what baking replaced them with. Meanwhile four items (hero
    number at 104 px, unit caption at 24 px, x2 gauges) span two more atlases,
    and the bottom bar adds sizes 10, 14 and 16. That predicts the bottom bar's
    9 batches better than its item count does.
    **Do not treat this as settled** — it is a hypothesis that fits, and this
    stage has already killed three plausible ones. Isolating it needs a build
    where the bottom bar's three font sizes are unified, which has not been run.
  - **Where S7 stands: two metrics miss by 1 ms** — render thread p95 14 vs
    gate 13, frame period p99 21 vs gate 20. GUI thread (7), fps (57.4) and
    polish (1) all pass. The remaining levers, in order of expected value:
    bake the bottom bar's static captions (TEMP/TOTAL/TIME labels, E/F/1/2,
    C/H — the *values* stay live), or unify its font sizes if the atlas
    hypothesis holds.

### A harness bug that voided a whole sweep — worth remembering

A bisect run produced "whole bar off = 20 ms" against a carefully measured
7 ms, with the sequence climbing 9 -> 18 -> 20 across successive variants.
Cause: the sweep script slayed `TrialClusterS6` while measuring
`TrialClusterS7`, left over from a `sed` that rewrote the binary *path* but
not the bare process name in the kill command. Three instances had accumulated
and were sharing the display.

The fix is not just the name: the sweep now derives the process name from the
binary path, and **verifies the process is actually gone** (`pidin` count, up
to six attempts) before launching the next variant, aborting the whole run
rather than reporting a contaminated number. Same principle as the stale-log
incident in S3 — a measurement tool has to prove its own preconditions, because
a plausible-but-wrong number is more expensive than no number at all.
  - **Also fixed:** the `FontLoader` status was logged from
    `Component.onCompleted`, where it reads `1 = Loading` and proves nothing.
    It now logs from `onStatusChanged`, so a failed font load is actually
    visible rather than falsely reassuring.

- **S7.5** — `TopBar`: two turn indicators either side of a pill bar with six
  view-selector buttons. Ported close to verbatim; its three `DesignEffect`
  drop shadows stay off until S10. Geometry from `Screen01.qml`: horizontally
  centred, 90 px from the top of the 1024x600 design space. Isolated behind
  `--no-topbar`. *(built, awaiting measurement)*
  - **PREDICTION, stated before measuring:** distinct textures cannot merge
    into one batch, and a batch costs ~0.5 ms here. Six buttons with six
    different icons plus two arrows is ~8 textures, so the S7 model expects
    **~+8 batches / ~+4 ms**. If that lands, the model is right and the fix is
    a sprite atlas (one texture, `sourceClipRect` per icon) rather than
    anything about the buttons. If it does not, the model needs revising again.
    Writing the prediction down first is the point — this stage has produced
    too many retrospective explanations that fit whatever happened.
  - **Icons downscaled 512x512 -> 96x96** offline (`tools/gen_icons.py`), and
    `sourceSize` set in QML. Every icon in the original is a 512x512 RGBA PNG
    displayed at 22-35 px — about 1 MB of texture each, ~15 MB across the set,
    to fill a thumbnail. This is not a speculative optimisation but the
    project's existing standing rule applied to the source asset rather than
    only to the QML; 185 KB -> 52 KB on disk and ~28x less texture memory.
  - `viewSelected` is emitted but nothing consumes it yet — view switching
    arrives with the ContentArea stages. The buttons stay live so their
    selected-state colour `Behavior` is exercised, and the turn-indicator blink
    animation is kept, since both are part of the honest worst case.
  - **PREDICTION CONFIRMED.** Measured: batches **21 -> 30 (+9)**, render p50
    **12 -> 16 ms (+4)**, fps 57.4 -> 44.8. The written-down prediction was
    "+8 batches / +4 ms". First time in this stage that a stated mechanism
    predicted a result instead of explaining one after the fact, so the
    `~0.5 ms per batch` model is now trustworthy enough to design against.

### ★ THE ACTUAL RULE, and the fix: mipmap defeats Qt's texture atlas

Qt Quick automatically packs small images into a **shared texture atlas**, and
images living in that atlas can be merged into a single batch. **`mipmap: true`
opts an image out of the atlas** onto its own dedicated texture, because
mipmapping requires one. Every icon in the original sets `mipmap: true`, so
eight icons meant eight textures and eight batches.

Mipmapping was never needed here: `sourceSize` already decodes each image at
its display size, so there is no minification left for mip levels to improve.
The original's 512x512 source PNGs made mipmap *look* necessary — which is the
same root cause as the wasted texture memory.

Applied: `mipmap: false` (plus a correct `sourceSize`) on the six top-bar
icons, both turn arrows, the fuel/temp icons and the baked dial labels.
`--icon-mipmap` restores the old behaviour to keep the comparison reproducible.
`BazelFrame` keeps mipmap: at 1280x720 it is far past the atlas size limit and
would get its own texture regardless.

**Standing rule for every remaining stage:** an `Image` gets `sourceSize` set
to its display size and `mipmap: false` unless it is too large to be atlassed
anyway. This is the single highest-leverage rule found so far — it costs
nothing visually and it is worth ~0.5 ms per image.

**Measured:** batches **28 -> 23**, render **16 -> 13 ms**, fps **44.8 ->
52.9**. Five of the nine batches the top bar cost were recovered by one
property. The top bar now costs 4 batches instead of 9 (23 vs 19 without it).

### Where the remaining 23 batches live, and what is left

| component | batches |
|---|---|
| bottom-bar text (~16 `Text`, 3 font sizes) | ~6 |
| hero numbers + unit captions (4 `Text`, 2 sizes) | ~4 |
| top bar (icons now atlassed + 2 pill Rectangles) | 4 |
| segmented bars (60 `Rectangle`) | 2-3 |
| `BazelFrame` + 2 baked dial-label images | ~3 |
| all `Shape` content: 2 arcs, 130 ticks, 28 redline ticks | ~2 |

The whole gauge — two animated arcs, 130 tick marks and 28 redline ticks — now
costs about **2 batches**. Text costs about **10**. That is the entire story of
this stage, and it is why the ladder's remaining work should be judged on
"how many draw calls does this add", not "how many elements".

**S7.5 status: still short of the gate** — render thread p95 15 vs 13, frame
period p99 21 vs 20, fps 52.9 vs 55. Roughly 2-3 batches short.

**Next lever, if pushed:** bake the bottom bar's static captions (TEMP / TOTAL
/ TIME labels, E / F / 1/2, C / H — the *values* stay live `Text`, they are
real data). Same technique as the dial labels, ~8 static items, expected -3
batches. Alternatively unify the bottom bar's three font sizes, which is a
one-line change and would also test whether the font-size/atlas hypothesis
from S7 is actually right.

### Techniques proven on this board (use these, in this order)

1. **Many small primitives** (ticks, segments) -> one `Shape` with
   `PathMultiline`, `GeometryRenderer`. 130 items -> 0 extra batches.
2. **Every `Image`** -> `sourceSize` at display size, `mipmap: false`.
   Worth ~0.5 ms each.
3. **Static text** -> bake to PNG offline. Live text only for real data.
4. **Never overlap translucent content** — 130 overlapping ticks cost 37 ms
   versus 11 ms non-overlapping. Matters most for S8-S10.
- **S8** — the car sprite with its idle motion, inside `contentArea`.
  *(built, awaiting measurement)* Isolated behind `--no-car`.
  - **Drop shadow baked, not computed.** The original wraps the car in a
    `DesignEffect` (`DesignDropShadow` offsetY 110, blur 25, `#a7000000`, plus
    `layerBlurRadius: 2`). That is a `layer.enabled` pass — render to an
    offscreen texture, blur, composite back — every frame, for a shadow whose
    shape relative to the car never changes. `tools/gen_car.py` bakes it into
    the sprite: one ordinary Image, no offscreen pass, no blur.
  - **Sprite also trimmed and downscaled.** Source is 830x750 with an opaque
    bounding box of 583x622 — ~40% fully transparent padding that still gets
    uploaded, sampled and blended — and it was drawn at `scale: 0.25`. Now
    384 px wide with the shadow included: 305 KB -> 106 KB.
  - **Two generator bugs, both caught by a number that could not be true.**
    First the canvas had no horizontal padding, so the blur was clipped flat
    against the image edges. Then the blur was applied to the shadow at the
    car's own size *before* compositing onto the padded canvas, which clips it
    the same way. Both showed up as `car_fraction = 1.0000` — the car
    supposedly filling the full sprite width when a shadow spreading sideways
    must make it less than 1. Fixed by building the shadow on a full-size layer
    and blurring that. Output inspected visually before shipping.
  - Sizing is not guesswork: the generator prints the two numbers QML needs —
    the car occupies 0.9152 of sprite width (so a 159.2 px sprite puts the car
    at the original's 145.8 px) and the car's centre sits at 0.4097 of sprite
    height (so the Image is nudged down ~17 px to leave the car where the
    original centred it). Re-running the generator reprints both.
  - Idle animations (sway, vibration, body roll, scale breathing, and the
    pulsing ground-shadow ellipse) are kept verbatim — all transform/opacity,
    which this board handles cheaply and which add no draw calls.
  - `contentAreaPlaceholder` is now a real Item hosting the car, at the same
    x/y/size as before, so `gaugeArea`'s `childrenRect` — and therefore its 0.9
    scale pivot — is unchanged and the gauges do not move.
  - **Expected cost: ~2 batches** (car sprite + ground shadow), ~1 ms. The
    sprite is 384 px so it should join Qt's shared texture atlas.
  - **RESULT: cost as predicted, position wrong.** render p50 13 -> 14 ms,
    fps 52.9 -> 49.7. The baked shadow did its job — a `DesignEffect` layer
    pass here would have cost far more than 1 ms.
  - **Two placement bugs, found from a screenshot of the running cluster:**
    1. *Mine:* `clip: true` on the content area cut the roof off the car. The
       original clips only at the top level (`digitalCluster`), not there.
       Removed.
    2. *The original's:* `CarView { y: -365 }` resolves — through CarView's
       1.25 scale about its own centre, contentArea at y13, gaugeArea's 0.9
       scale about y442.5 then +75, and the 1.2 design->screen scale — to a car
       centre at **screen y 175**. The top bar occupies screen y 108..180, so
       the original numbers put the car *behind the top bar*.

       Why that was never noticed in the original: `contentArea` in
       `Screen01.qml` has **`opacity: 0`**. The car is invisible at rest there
       and only appears through the startup animation, so the geometry was
       never really exercised. This is the second time a value taken faithfully
       from `Screen01.qml` turned out to be unused/parked rather than
       authoritative — the first was the gauges' `x` being animation targets
       rather than live values. **Treat Screen01.qml positions as suspect
       unless something visible depends on them.**

       Corrected to `carViewY: -193`, which puts the car centre at design y 300
       / screen y 360 — level with the gauge centres (386) and in the gap
       between them. It is a single named property, and the resolved position
       is now logged at startup next to the gauge centres so it can be checked
       on hardware rather than trusted from arithmetic.
- **S9** — `Road`, rebuilt. This is the component this whole project was
  started for: PLAN.md's audit named it the confirmed root cause of the
  original app's 24 fps and 32 ms GUI-thread polish, and it is the only entry
  in the ladder marked REWRITE rather than PORT. Isolated behind `--no-road`.
  *(built, awaiting measurement)*
  - **The original is six `Canvas` items.** Three paint once (road surface
    gradient, horizon fog, centre-lane highlight); three repaint on an animated
    `offset` via `onWatchOffsetChanged: requestPaint()` — CPU software
    rasterisation on the GUI thread, every frame, forever. That is the Rule 1
    violation in its original habitat.
  - **Layers 1-3 baked** into one PNG by `tools/gen_road.py` (pycairo, same
    gradients and the same `vpX/vpY/halfRoad` constants): one texture, one draw
    call, no Canvas and so no first-use shader stall either. Output inspected
    before shipping.
  - **Layers 4-6 rebuilt as `Rectangle`s** positioned by the same perspective
    maths the Canvas used — a dash is a rotated rounded Rectangle rather than a
    stroked line. ~38 of them, in two single-delegate `Repeater`s so they stay
    a contiguous run of siblings and can batch. S7 measured 60 Rectangles at
    2-3 batches, so this should be cheap, and none of it touches the GUI thread.
  - **The maths was verified numerically before building**, not eyeballed: for
    several offsets and indices, the Rectangle placement (centre + rotation +
    length) reproduces the original Canvas line's two endpoints to 0.000000.
  - **One deliberate simplification: the glow pass is dropped.** The original
    strokes every dash twice — a wide translucent glow under a narrow bright
    line. That doubles the geometry and, worse, makes every dash *overlapping
    translucent content*, which is the single most expensive thing measured on
    this GPU (S6: 130 overlapping ticks = 37 ms vs 11 ms non-overlapping). Dash
    alpha lifted 0.7 -> 0.8 to compensate. If the glow is wanted back, bake it
    into the backdrop rather than stroking it live.
  - There is now **no `Canvas` anywhere in the project** — verified across all
    QML files.
  - **First build: FAILED on both counts, and instructively.**
    render p50 14 -> 18 ms, but the real damage was **`animations` 4 -> 14 ms**
    (GUI thread 7 -> 17), sustained fps 50.2 -> 39.4. `polish` stayed at 1 ms,
    so this was not Canvas-style painting — it was **binding evaluation**.
    Replacing Canvas rasterisation with ~38 delegates each re-deriving a dozen
    properties per frame simply moved the CPU cost from one place to another.
    Worth stating plainly: *"not a Canvas" is not the same as "cheap"*.
  - **The simplification that fixes it.** A dash's endpoints are
    `x = vpX + side*span*t` and `y = vpY + (H-vpY)*t` — both **linear in t**.
    So every dash on a side lies on one straight line, and its **rotation and
    length are constants**. Verified numerically: across all offsets and
    indices the spread is 5e-13 degrees and 2e-14 px. Hoisted to per-side
    constants, which halves the per-frame work to position, thickness and fade.
    Re-verified that the new centre+constant-rotation placement still
    reproduces the original Canvas endpoints: worst error 1.1e-13 px.
  - **Position was also wrong, and for the now-familiar reason.** The original
    nests Road in CarView at 800x700 with `anchors.centerIn`. Resolved through
    the transform chain, that puts the road's bottom edge at **screen y 799 on
    a 720-tall panel** — it ran off the bottom of the cluster, exactly as the
    screenshot showed. Same root cause as the car: `contentArea` has
    `opacity: 0` in `Screen01.qml`, so none of this geometry was ever
    displayed or tuned. **Third time an unused Screen01 value has misled this
    port.**
    Fixed by filling `contentArea` instead — bounding the road to screen y
    157..615, from just under the top bar to just under the bottom bar (which
    draws over its lower edge) — with `vpFraction: 0.377` putting the vanishing
    point at screen y ~330, just above the car centre at 360, so the car sits
    *on* the road rather than under it.
  - **QML gotcha worth remembering: `left` is a reserved property name.**
    The fixed version failed to load with `Cannot override FINAL property`.
    Every `Item` has FINAL anchor-line properties `left`, `right`, `top`,
    `bottom`, `horizontalCenter`, `verticalCenter` and `baseline` — that is
    what `parent.left` resolves to inside an anchor expression — so
    `property bool left` is illegal. Renamed to `isLeft`, and all QML was
    scanned for the other six names (no further collisions).
    Caught by building on the **desktop kit first**, which is exactly what that
    step is for: a load-time failure found in seconds instead of after a
    cross-compile and deploy.
  - **Second build: the linearity fix worked, `animations` 14 -> 8 ms** (GUI
    thread 17 -> 11, now passing). But render was 19-20 ms and fps 39, and the
    road still looked wrong: the dashes visibly diverged *outside* the painted
    road slab, when the maths puts them at ±80 px inside a slab of ±144 px.
  - **★ BAKED GEOMETRY AND LIVE GEOMETRY ARE ONE THING.** The backdrop was
    baked at 480x520 with the vanishing point at 0.55 of its height. It was
    then displayed stretched into a 480x424 area with `vpFraction: 0.377`. The
    art had one vanishing point and the dashes another. Changing either the
    generator or the call site alone is a bug — a whole class of error that
    only exists because part of the drawing moved offline.
    Fixed by giving `tools/gen_road.py` the same `BASE_W/BASE_H/VP_FRACTION` as
    the call site, with a comment at the top of both saying they must move
    together. Verified numerically afterwards: VP baked and live both 0.377,
    dashes at ±80.6 px inside the slab at ±144 px.
  - **Also cut the road's fill in half.** The backdrop is a trapezoid plus a
    fog disc inside a rectangular image; the rest is fully transparent, and a
    transparent pixel in a blended quad still costs fill on this GPU. The
    generator now crops to the painted bounds and prints the placement
    fractions, taking the blended coverage to **54%** of the full rect. Same
    trick as the car sprite's ~40% padding.
  - **Third build (2026-08-12): FAILS again, but differently.**
    render p99 30 ms / p95 21 ms (gate 13), sustained fps 39.6 (gate 55).
    `polish` 1 ms and GUI thread 11 ms both **pass** — the linearity fix
    holds, so this is not binding churn, it is render-thread fill cost, the
    same two-mechanism model as everywhere else on this board (draw calls,
    ~0.5 ms each, and overdraw). Draw calls here should already be cheap —
    1 backdrop image + a couple of Rectangle batches for ~38 dashes and 6
    streaks — which does not obviously add up to 21 ms on its own.
    **Leading hypothesis, stated before the next measurement**: overdraw
    from three translucent layers stacked on the same pixels — the backdrop
    (already a blended gradient), the dashes, and the streaks, all under
    `Road`'s own `opacity: 0.55` — rather than any one layer being
    individually expensive. Untested. Added `showBackdrop` / `showDashes` /
    `showStreaks` on `Road` (`--no-road-backdrop` / `--no-road-dashes` /
    `--no-road-streaks` on the app) so one binary can measure all four
    combinations instead of guessing which layer to cut.
  - **Road position flagged wrong again, from a screenshot on desktop
    (confirmed same on the NXP guest).** Traced the car-vs-road transform
    chain by hand (`carViewY` -> `carWrapper.y:225` -> the sprite's
    `verticalCenterOffset` -> `carView`'s 1.25 scale about its own centre)
    to check whether the car's actual pixels land inside the road's
    0..height slab. First pass said the car sits ~27 px below the road's
    bottom edge; a recheck of the same chain found an arithmetic slip
    (mixed up the scale pivot's position in the parent frame with its
    position in the item's own local frame) and the corrected numbers put
    the car back inside the slab, just below the vanishing point — i.e.
    inconclusive by hand, and this is exactly the kind of arithmetic the
    project has gotten wrong before (see the Screen01 traps above).
    **Not fixing blind.** Instead:
    1. Fixed a real, smaller bug found along the way: the startup log's
       `CAR centre` mapped `carItem.width/2, carItem.height/2` —
       `carWrapper`'s own box centre — not the actual car `Image`, which is
       nudged down by `verticalCenterOffset` inside it (~17 px, ~20 px on
       screen after the 1.25/0.9/1.2 scale stack). Exposed the real `Image`
       via `property alias carImage: car` in `Car.qml` and pointed the log
       at it.
    2. Added the log Road never had: `ROAD vanishing pt` and `ROAD bottom
       edge`, mapped through `designRoot` the same way as `CAR centre` and
       the gauge centres. Next run's log gives three directly comparable
       screen-y numbers instead of hand arithmetic — read those before
       touching `carViewY` or `vpFraction` again.
  - **The overdraw hypothesis above is DISPROVED — tested directly on the
    already-deployed `/tmp/TrialClusterS9` binary, no rebuild needed** (the
    three `--no-road-*` flags are runtime args). Render p95 barely moves:

    | config | render p95 |
    |---|---|
    | full S9 | 20-22 ms |
    | `--no-road-backdrop` | 22 ms |
    | `--no-road-dashes` | 20 ms |
    | `--no-road-streaks` | 20 ms |
    | `--no-road` (whole thing off) | **17 ms** |

    **The whole Road component only accounts for ~3-5 ms.** Removing it
    entirely still fails the render p95 gate (17 vs 13). So this was never
    an S9 problem — S9 just made an existing, unclosed failure worse.
  - **★ Real root cause: S7.5 already recorded "still short of the gate"
    (render p95 15 vs 13) and it was never brought back under budget before
    S8 and S9 built on top of it.** S7's own "Where S7 stands" note named
    two untested next levers for the remaining 1 ms miss — bake the bottom
    bar's static captions, or unify its three font sizes to test the
    font-atlas-per-size hypothesis — and neither was ever run. That gap
    (15 ms) plus S8's car (+1 ms implied) plus S9's own ~3-5 ms is roughly
    17 -> 20-22, which matches the measured numbers well enough to trust.
  - **Tested the cheaper of the two open levers.** Wired a reversible
    `--flat-fontsize` flag through `BottomLayer` -> `FuelIndicator` /
    `TempIndicator` / `CenterInfo` -> `InfoBlock`, forcing every bottom-bar
    `Text` (currently sizes 10/14/16) to one size (12). Does not touch
    layout or the live-data items. **Run `--flat-fontsize` against baseline
    on S9 (or any later stage) before writing the bottom-bar-caption baking
    generator** — if batches drop, the font-atlas hypothesis is confirmed
    cheaply; if not, go straight to baking (same technique as
    `gen_dial_labels.py`, which already proved out on this exact bar).
  - **Road/car position: recalibrated from the measured numbers, not fresh
    hand arithmetic.** With the old geometry (`carViewY -193`, `carView`
    `scale 1.25`), the log gave: CAR centre screen y **383.4**, ROAD
    vanishing pt **329.8**, ROAD bottom edge **615.1**. The car's centre sat
    only 54 px below the vanishing point, and its on-screen height at that
    scale (159.2 x 1.1915 sprite, x1.25 x0.9 x1.2 scale stack ~= 256 px) is
    90% of the road's own 285 px screen height — there is structurally no
    room for the road to show above *and* below the car at that size, which
    is exactly what both screenshots show (a sliver behind the bumper, an
    empty background everywhere else next to/above the car).
    **Fix (untested, stated as a prediction):** `carView.scale` 1.25 ->
    0.85 and `carViewY` -193 -> -46, targeting a car centre near screen y
    524 — low in the slab, near its bottom edge, with the convergence
    visible above it. Derived from the proven delta relationship
    `Δscreen = ΔcarViewY * (gaugeArea.scale * designRoot.scale)` plus the
    scale term, anchored on the measured 383.4 rather than re-deriving the
    whole pivot chain (that is what produced the wrong ~27 px number above).
    **Verify from the next startup log**, not from eyeballing the
    screenshot alone: CAR centre should read close to 524, comfortably
    between ROAD vanishing pt (329.8) and ROAD bottom edge (615.1) with
    room on both sides.
- **Content-area relayout (2026-08-12), between S9 and S10.** User request: the
  content area should sit *between* the two gauges and *start at their bottom
  edge*, not overlap them the way the original Screen01 box did (x420 y13
  480x424, chosen only because it never actually needed to look right —
  `contentArea` there had `opacity:0` at rest). Renamed
  `contentAreaPlaceholder` -> `contentArea` and resized it using live-logged,
  resolution-independent design-space numbers (not hand arithmetic): SPEED/RPM
  centre y 321.75, gauge half-height post-gaugeArea-scale `225*0.7*0.9 =
  141.75` -> gauge bottom **463.5**, SPEED right edge **340.15**, RPM left
  edge **668.65**. New box: `x:340 y:464 width:329 height:136`. Checked first
  that this box contributes nothing to `gaugeArea.childrenRect` (frame and the
  gauges already dominate every edge — logged `92 -435 1130 1320`), so the
  gauges do not move.
  **Deliberately NOT done in this pass:** Road/CarView still carry their old
  tuning (`vpFraction`, backdrop crop fractions, `carViewY`/`carView.scale`)
  sized for the old 480x424 box; the new box is ~4x shorter and narrower and
  will look wrong until they're retuned to it — next step. Also not done:
  porting the other Content_Area views from `02-Digital-Cluster`
  (`ContactsView`, `MusicView`, `FuelView`, `SettingsView`, `MapView`) — the
  user named all of these as eventually belonging in `contentArea`, switched
  by `TopBar`'s already-built `viewSelected` signal (currently unconsumed,
  see S7.5). Positions first, views next.
  **CORRECTION, same day: the above misread the request.** The user's own
  annotated screenshot made it unambiguous: the content area spans the
  gauges' FULL height (top red line = gauge top, bottom red line = gauge
  bottom), sitting in the horizontal gap between them — not a strip below
  them. Fixed box: `x:340.15 y:180.0 width:328.5 height:283.5` (gauge top
  180.0, bottom 463.5, from the same centre-321.75 / half-size-141.75
  numbers above). Height 283.5 is not a coincidence — it equals the gauge's
  own rendered diameter (`450*0.7*0.9`), since top and bottom are both tied
  to the same gauge geometry. Still contributes nothing to `childrenRect`.
  Screen size experiment (1024x600) was reverted by the user; the
  `window:1280x720` / `designScale` mismatch flagged earlier is moot.
  **Follow-up bug, same day: Car/CarView still used the OLD 700-tall,
  absolute-offset geometry, so shrinking contentArea to 283.5 tall put the
  car mostly below the visible cluster.** Fixed structurally rather than
  re-tuning another magic number: `carView` is now `anchors.fill: parent`
  (exactly contentArea's size, whatever that is) and `Car.qml`'s
  `carWrapper` is `anchors.centerIn: parent` instead of a fixed `y:225`.
  Because carWrapper centres on carView's own scale pivot, `carView.scale`
  (0.85) no longer moves it — verified by hand, twice, before applying:
  final car-image centre works out to contentArea-local (164.25, 156.3),
  comfortably inside the 0-328.5 x 0-283.5 box with margin on every side,
  regardless of contentArea's exact size. `carViewY` is now a small nudge
  (default 0) around that centre, not an absolute canvas position — the
  thing that broke twice. Not yet verified on a screenshot.
  **Third attempt, same day — the "centred" fix above was ALSO wrong**, per
  a screenshot: car rendered off to the left, overlapping the speed gauge.
  Stopped inventing numbers and read `CarView.qml` in full for the first
  time this stage (had only ever read `Car.qml`). The original: `CarView`
  is an 800x700 canvas; `Road` fills it exactly (`anchors.centerIn`, same
  size); `Car` sits at `anchors.verticalCenter` + `verticalCenterOffset:
  235` — 585 of 700 = **83.6% down**, low in the canvas, not centred.
  Ported those exact numbers verbatim (`carView` is 800x700 again, `Road`
  and `Car` positioned exactly as above, now both children of `carView`
  instead of siblings), then scale the WHOLE canvas to fit contentArea
  (`scale: contentArea.width / 800`) and centre it — internal proportions
  are always the original's, regardless of contentArea's size. contentArea
  (328.5x283.5) and the original canvas (800x700) have nearly identical
  aspect ratios (1.159 vs 1.143), so the fit should be close to
  undistorted. Not yet verified on a screenshot.
  **★ Root cause of all three contentArea attempts, found on the fourth:**
  `contentArea` is a direct child of `gaugeArea`, so its `x/y/width/height`
  are gaugeArea-LOCAL coordinates -- the same frame as `speedGauge.x: 92`.
  But every number fed into it came from `designRoot.mapFromItem(...)`,
  which is DESIGN-space -- already passed through gaugeArea's own `scale`
  *and* its own non-trivial transform pivot (a Studio `GroupItem`'s
  transformOrigin is the centre of `childrenRect`, not `(0,0)` -- offset by
  `framePlaceholder`'s `y:-435`). Assigning a design-space number to a
  gaugeArea-local property is a straight unit mismatch; hand-deriving the
  correct conversion (gaugeArea's pivot) was tried and got the pivot wrong
  too. **Fixed by not converting between frames at all:** `contentArea` now
  anchors directly to `speedGauge`/`rightGauge` (`horizontalCenter` /
  `verticalCenter`, both scale-invariant -- a scaled item's centre doesn't
  move) with a margin (`gaugeVisualRadius = 225*0.7` + a plain
  `contentGap: 10`), all still in gaugeArea-local units, matching
  `speedGauge.x` exactly -- no cross-frame math anywhere. This class of bug
  (design-space vs local-space numbers silently mixed) is worth watching
  for anywhere else a `mapFromItem` value gets assigned directly to a
  sibling's geometry.
  **CONFIRMED WORKING** (2026-08-12, screenshot): content area lands
  correctly centred between the gauges. Follow-up: car+road looked too
  small against the reference. Added `gaugeArea.contentVisualScale: 1.4` as
  a single multiplier on `carView.scale`, on top of the existing fit-to-
  width factor — allowed to overflow contentArea's nominal box into the
  gauge margin (not clipped), same convention Road/Car already use
  elsewhere. Not yet re-verified on a screenshot.
  **Bug in that fix: scaling around carView's default Center origin pushed
  the road's bottom edge below the gauges' bottom as scale grew** (it moves
  both top and bottom outward equally). Fixed by pivoting the scale around
  the bottom instead: `transformOrigin: Item.Bottom` +
  `anchors.bottom: parent.bottom` / `anchors.horizontalCenter` (replacing
  `anchors.centerIn`). Anchors use the unscaled box, and the transform
  origin is the same point being anchored, so scaling can't move it —
  growing `contentVisualScale` (now 1.6) only extends the canvas upward.
  Not yet verified on a screenshot.
- **S10** — `DesignEffect`s (blur/layers), one at a time, each one measured and treated as guilty until proven innocent. `MapView` gets profiled here too, before deciding whether it needs the same Road-style rewrite.
  - **Started 2026-08-12.** `MapView` is deferred — it isn't ported yet
    (still one of the other Content_Area views named for a later step,
    along with ContactsView/MusicView/FuelView/SettingsView). The
    immediately actionable part is TopBar's three `DesignEffect` shadows,
    left out on purpose at S7.5. Ported naively (`QtQuick.Effects`'
    `MultiEffect` with `shadowEnabled`, in place of the Studio-only
    `DesignEffect`/`DesignDropShadow` this rebuild doesn't depend on) —
    same three shadows, same items, no baking yet. Each gets its own flag:
    `--no-shadow-pill` (the always-on black shadow under the static pill —
    a `layer.enabled` on a shape that never changes at runtime, exactly the
    shape "bake it" already fixed at S1/S8/S9), `--no-shadow-leftglow` /
    `--no-shadow-rightglow` (the green glow on each turn indicator, only
    live while blinking — `leftIndicatorOn` defaults true so its glow is
    live by default; `rightIndicatorOn` defaults false, so `--right-
    indicator-on` forces it on to measure the honest worst case rather than
    trusting the idle default, same principle as S3's continuous stimulus).
  - **PREDICTION, stated before measuring:** the pill shadow should be
    cheap to eliminate (bakeable, static) but is not free while live — one
    more `layer.enabled` offscreen pass, on the order of the ~1 ms a single
    extra draw call has cost everywhere else on this board. The two glow
    shadows are live-animating (opacity blinks every 450 ms) so a
    `layer.enabled` source there cannot be trivially baked away the same
    way; expect them to cost more, and expect turning both indicators on
    at once (worst case) to roughly double whatever one costs alone if the
    mechanism is "one offscreen pass per active shadow." Untested.
  - **Next**: `deploy_and_measure.sh S10`, then with each `--no-shadow-*`
    flag and `--right-indicator-on`, to attribute cost per shadow before
    deciding whether the pill shadow gets baked (near-certain) and what, if
    anything, is worth doing about the two glows.
  - **Splash screen ported, same day** (user request — the app-level
    startup sequence, not part of the S-ladder). Verbatim from Screen01.
    qml's `SplashScreen.qml`: pitch-black background, car image + halo +
    "HYPER-NOVA" wordmark fading in over ~1.2 s, held, then the whole thing
    fades out and self-hides (~3.3 s total), all opacity-only animation
    (S3's "transform/opacity is free" rule, so this is cheap regardless of
    stage). Two things fixed while porting, not just copied:
    1. `welcomeText` had no `font.family` in the original — silently blank
       on this QNX image, which ships no fonts at all (S5). Set to
       `Theme.fontPrimary`.
    2. Dropped `layer.enabled: true` on the two headlight-strip Rectangles
       — Studio left it with no `layer.effect`, so it was a no-op offscreen
       pass, exactly what the S6/S9/S10 notes say not to carry forward
       unmeasured.
    Asset: `front_car.png` (843x499) copied in as `SplashCar.png`, qrc-
    aliased, `sourceSize` set to its display extent. Lives at
    `qml/ContentArea/SplashScreen.qml`, instantiated last (declaration
    order + `z:999`) directly on the Window — not inside `designRoot`, same
    reasoning as `BazelFrame` (fills the real screen, not the design
    space). `--no-splash` skips it for faster dev iteration. Not yet
    verified on a screenshot.

## Backend port (2026-08-12)

User request: real data, same as the reference (02-Digital-Cluster), not the
synthetic `drive` sweep. Investigated the reference's actual data sources
first rather than assuming — `Backend/vehicledataprovider.cpp` polls
`telemetry.json` (CARLA-style schema: `speed_kph`, `rpm`, `gear`) every
50 ms via `QTimer`; `Backend/BottomBar/*Provider.cpp` each poll their own
plain-text file under `/tmp/ivi/` (`fuel.txt`, `engine_temp.txt`,
`env_temp.txt`, `total_kms.txt`) via `ifstream`; time is the system clock;
contacts/music are hardcoded mocks; steering wheel is a live UDP socket, not
a file. Ported the file-based half verbatim — `SpeedProvider`, `RpmProvider`,
`GearProvider`, `VehicleDataProvider` (`src/Backend/`) and `FuelProvider`,
`EngineTempProvider`, `EnvTempProvider`, `TotalKmsProvider`, `TimeProvider`,
`BottomBarDataProvider` (`src/Backend/BottomBar/`) — same paths, same
defaults, same poll interval. `ContactsModel`/`MusicController`/
`SteeringWheelController` left out: those views aren't ported into this
rebuild yet, and porting a UDP listener with nothing consuming it yet would
be scope creep — add each alongside the QML view that needs it.

**Registration deliberately differs from the reference.** The reference used
`qmlRegisterSingletonInstance` from `main.cpp`. This project already has a
*proven* pattern for exactly this (`src/Theme.h`'s own long comment: two
attempts at a QML-authored `pragma Singleton` for `Theme` both silently
resolved to `undefined` at runtime with no build error, on both the desktop
kit and the QNX target — fixed by a real C++ `QML_NAMED_ELEMENT`/
`QML_SINGLETON`, auto-registered by `qt_add_qml_module`). `VehicleDataProvider`
uses the same mechanism. The one difference from `Theme`: it isn't
default-constructible (needs a `telemetryPath`), so it also needs the static
`create(QQmlEngine*, QJSEngine*)` factory Qt's singleton machinery calls
when there's no default constructor — that's where `"telemetry.json"` is
hardcoded, matching the reference's `main.cpp`. Also reused the OTHER
Theme.h gotcha pre-emptively: the generated `qmltyperegistrations.cpp`
`#include`s a QML_SINGLETON's header by bare filename, resolved through the
compiler's include path, not a relative path — `Theme.h` needed `src` added
to `target_include_directories`; `VehicleDataProvider.h` lives one directory
deeper, so `src/Backend` was added too, pre-emptively rather than waiting to
hit the same build failure Theme already hit once.

**★ Root.drive is NOT replaced — this was the one live design decision.**
Every S0-S10 measurement in this file depends on `drive`'s continuous sweep;
that continuity is *why* those measurements mean anything (S3's whole
lesson: an intermittent/idle-most-of-the-time stimulus makes the render loop
go idle and produces a misleading low fps reading — the exact trap that
stage cost a session over). A telemetry file nothing is actively writing to
would reproduce precisely that failure mode. So the backend is opt-in:
`--live-data` switches `root.speedValue`/`root.rpmValue` and BottomLayer's
five bindings (`fuelPercent`, `rangeKm`, `motorTempC`, `outsideTempText`,
`odometerText`, `clockText`) over to `VehicleData.*`; without the flag,
every existing measurement in this file is bit-for-bit unchanged. `rangeKm`
has no separate provider in the reference either (it's derived,
`fuelPercent * 5.2`, matching the synthetic path's own formula) so
`--live-data` keeps that derivation, just from the live fuel value.
**Caught and fixed one bug before it shipped:** a `replace_all` swap of
`0.8 + root.drive * 6.7` -> `root.rpmValue` also matched inside `rpmValue`'s
own definition, making it self-referential. Found on the verification
re-grep, not assumed away.

Not yet verified on a screenshot or a build — this needs a full reconfigure
(new source files) and, to see real numbers instead of each provider's
hardcoded default, something writing `telemetry.json` and `/tmp/ivi/*.txt`
on the target (nothing does yet — CARLA/simulator integration is a separate,
later concern; `speed_kph`/`rpm`/`gear` plus `fuel`/`engine_temp`/
`env_temp`/`total_kms` as a bare number per file is the whole contract).

## Production port (2026-08-13)

User request: finalize the whole project for production — the gauge-area
widgets (Gear/Mode/Speed-limit) and all five remaining Content_Area views
(Nav/Contacts/Music/Fuel/Settings) were still missing, and simulated data
was still showing after a build. Researched the reference thoroughly first
(a dedicated pass read RPMGauge.qml/SpeedGauge.qml and all five views in
full, not summarized) rather than guessing at structure.

**Gauge widgets** (`qml/Gauge/GaugeGearBadge.qml`, `GaugeModeBadge.qml`,
`GaugeSpeedLimitBadge.qml`) — ported verbatim, all three are plain Rectangle
+ Text with no Canvas/DesignEffect/Studio components in the original either,
so no rework was needed. Wired into `speedGauge`/`rightGauge` at the
reference's exact `anchors.verticalCenterOffset` values (170 / -80 / 170) —
safe because that's the same 450x450 gauge-local frame every other gauge
child already uses, not a repeat of the contentArea coordinate-frame bug.
`driveMode` thresholds (`rpmValue` <2 ECO, <4 NORMAL, else SPORT) ported
from Screen01.qml's `simMode` verbatim; `speedLimitKph` defaults to 90,
same hardcoded value SpeedGauge.qml itself used.

**Five content views**, all sharing `contentArea` (same box Car/Road use),
switched by a new `root.currentView` (0 Car/Road .. 5 Settings) driven by
TopBar's already-built `viewSelected` signal:
- **MapView** — the original's Canvas (grid+route+dot) is now baked by
  `tools/gen_map.py` into `MapBackdrop.png` instead of ported as a live
  Canvas. Reason: S1 already proved a Canvas costs a one-time ~19s stall on
  this GPU from first-use shader compilation *even for a single
  `Component.onCompleted` paint* — this is exactly that pattern.
- **ContactsView** + **ContactItem** — ported verbatim, binds to
  `VehicleData.contactsModel` (new `ContactsModel : QAbstractListModel`,
  `src/Backend/ContentArea/`) and `VehicleData.steeringWheel` for up/down
  nav, which required also porting **SteeringWheelController** (UDP
  `localhost:8888`, `src/Backend/`) — needs `Qt6::Network`, added to
  `find_package`/`target_link_libraries`.
- **MusicView** — ported verbatim except the mock cover art URLs: the
  reference used relative `file://../../.../assets/...` paths that don't
  resolve from this rebuild's layout (and are fragile even in the original
  — relative `file:` URLs generally aren't valid). Copied the three cover
  images in (`MusicStarboy.jpeg`, `MusicBeAlright.jpeg`, `MusicShots.png`)
  and qrc-aliased them; **MusicController** (`src/Backend/ContentArea/`)
  ported with `qrc:/art/...` in place of the reference's paths.
- **FuelView** + **FuelStatItem** — ported verbatim; `fuelPercent`/
  `rangeText` now bound to `VehicleData.bottomBar.fuelProvider` (same
  provider BottomLayer already uses) rather than a caller-supplied
  property, since this view isn't on the always-visible perf-critical path
  and doesn't need the `--simulate` gate.
- **SettingsView** + **SettingItem** — ported verbatim, fully static in the
  reference too (no backend).

**★ Default data source flipped.** `--live-data` (opt-in) is now
`--simulate` (opt-out) — plain production builds read real files by
default; the synthetic `drive` sweep only runs, and its `SequentialAnimation`
only starts (`running: root.simulate`, was `running: true`), when
explicitly requested for perf work. `deploy_and_measure.sh <stage> <secs>
--simulate` is the new form for every future S-stage measurement.

Not yet built or verified on a screenshot — this needs a full reconfigure
(many new source files) and, for MusicController/ContactsModel to show
anything beyond their own mock defaults, nothing extra: unlike the
telemetry/`\/tmp/ivi` providers, contacts and music are self-contained mock
data in this pass, matching the reference exactly.

## Telemetry simulator + a real path bug found while building it (2026-08-13)

The board reset (see prior entry, GPU/display low-power state — matches
this project's own earlier-documented genpd/runtime-PM pattern, unrelated
to app code) let this move forward: `tools/simulate_telemetry.py` pushes
continuously-varying speed/rpm/gear (+ fuel/engine_temp/env_temp/total_kms)
to the board over SFTP from the developer's own machine, standing in for
whatever real telemetry source eventually replaces it.

**Building it found a real bug: `telemetry.json`'s path never actually
worked.** The reference's bare relative `"telemetry.json"` resolves against
the app's cwd — confirmed via ssh (`pwd`) to be `/home/qnxuser` — and
`/home/qnxuser` is NOT writable on this board (`touch` there fails with
ENOENT despite `ls` succeeding on the directory; likely a read-only-mounted
base image path). Fixed in `VehicleDataProvider.cpp`: hardcoded path is now
absolute, `/tmp/telemetry.json`, consistent with the four `/tmp/ivi/*.txt`
files that were already there and already proven writable all session.
**Needs a rebuild to take effect.**

Second, smaller finding while writing the script: this board's SFTP server
supports neither `posix_rename` nor plain SFTP `rename` ("Operation
unsupported" both ways) — the planned temp-file-then-rename atomic write
isn't available here. Falls back to a single direct write; safe in practice
for a payload this size, and `VehicleDataProvider` already treats a
failed/partial read as "keep the last value," not a crash.

Verified end to end: ran the script, `cat`'d `/tmp/telemetry.json` and the
four `/tmp/ivi/*.txt` files on the board directly, confirmed well-formed
content landing.

## Standing rules (see also the saved skill)

- No `Canvas` for anything that repaints on a per-frame binding (animation, `Timer`, `NumberAnimation on <prop>` with `requestPaint()` in the handler).
- **No `Canvas` at all for genuinely static content, not even a single `Component.onCompleted` paint** — bake it to a PNG offline instead (see "S1 finding" below). A one-time Canvas paint still cost a one-time ~19s stall on QNX / ~4-5s on desktop from first-use GPU shader compilation, not from repainting.
- Every `Shape` gets `preferredRendererType: Shape.CurveRenderer`.
- No `layer.enabled` / `layer.samples` unless measured necessary (GC7000XSVX clamps samples to 4 regardless).
- Every scaled `Image` gets `sourceSize`.
- **Never hardcode the Window's size, not even after "confirming" it once.** Bind `width`/`height` to `Screen.width`/`Screen.height` (`import QtQuick.Window`). Real resolution here is 1280x720, but the point is the binding, not the number — we got this number wrong twice by hardcoding a literal instead. Everything below the Window level (BazelFrame, gauges, everything) stays bound to `root.width`/`root.height`, never a literal, so nothing downstream needs to change if a different board/panel has a different real resolution. If baked art needs a specific pixel size (PNGs), bake it at the confirmed real size, not a guess.
- Measure after every stage using the harness in the skill/appendix below — don't eyeball smoothness.

## Appendix — measurement harness

```
export LD_LIBRARY_PATH=/qt/lib:/proc/boot:/lib:/usr/lib:/lib/dll:/lib/dll/pci:/opt/someip/libs:/usr/lib/graphics/iMX8QM
export QT_PLUGIN_PATH=/qt/plugins QML_IMPORT_PATH=/qt/qml QT_QUICK_CONTROLS_STYLE=Basic
export QQNX_PHYSICAL_SCREEN_SIZE=154,87
export QSG_RENDER_TIMING=1
export QT_FORCE_STDERR_LOGGING=1        # mandatory over ssh, else Qt logs to slog2 and you see nothing
<app> >/tmp/x.log 2>&1 &
sleep 14; A=$(grep -c "frame rendered" /tmp/x.log)
sleep 15; B=$(grep -c "frame rendered" /tmp/x.log)
slay <app>; echo "fps=$(( (B-A)/15 ))"
grep "Frame prepared" /tmp/x.log | tail -5
```

Two traps that cost hours previously: `grep -c syncAndRender` counts 2 lines
per frame (halves your fps reading); the GUI-thread cost breakdown line is
`Frame prepared, polish=, lock=, blockedForSync=, animations=` — not
`polishAndSync` (that one only ever prints "start, elapsed since last call").

## Baseline numbers (measured 2026-08-09, old app)

| | simpleQt (1 animated Rectangle) | Old Digital Cluster, currentView=2 |
|---|---|---|
| frame period | ~16 ms = 60 fps | 42 ms = 24 fps |
| polish | 0 ms | 32 ms |
| sync | 0 | 1-2 ms |
| render | 0-1 ms | 2-3 ms |
| swap | 10-17 ms (vsync block, normal) | 8-9 ms |
| blockedForSync | 5-12 ms | 1-2 ms |
| animations | 0 ms | 0 ms |

Budget at 60 fps: `polish + sync + render <= ~13 ms` (swap absorbs the rest
until vblank).

## S1 finding: one-time ~19s startup stall — RESOLVED by removing Canvas

First run of anything past S0 (i.e. the first frame that composites a second,
differently-shaped visual layer — `BazelFrame`) hung for ~18.9-19.0s after a
few frames rendered fine, then recovered to a clean steady state (`polish=0ms`,
`render~1ms`, ~60fps identical to S0). Did not fail the S-stage gate (steady
state was clean) but was a real defect for a cluster that must show speed the
instant it powers on.

Diagnosed live by SSH'ing into the guest mid-stall and sampling `pidin -p <pid>`
repeatedly: the render thread was blocked in `REPLY <sbin/screen>` — waiting on
QNX's `screen` compositor, not doing work itself. Ruled out fontconfig
(deploying `tools/fonts.conf` silenced the error line, stall unchanged) and
ruled out `clusterStreaming` contention (stopped the service entirely, stall
unchanged, byte-for-byte). The `/dev/shmem/viv_gc_noimg_builtin.lib` (Vivante
GC7000 shader cache) being 0 bytes was on the right track, just misattributed
to `screen`/streaming contention rather than to our own draw call.

**Confirmed cause:** the same delay shape (a handful of frames render fine,
then one huge stall, then clean) also appeared on desktop — a completely
different GPU, no QNX `screen`, no `clusterStreaming` — just ~4-5s there
instead of ~19s. The one thing both platforms share is the app's own QML:
`BazelFrame`'s `Canvas`. Even though it only painted once
(`Component.onCompleted`, compliant with the "no per-frame Canvas" rule),
the first time that Canvas-backed texture actually got composited, the GPU
driver had to compile a shader/pipeline it had never used before — slow on
any driver, catastrophic on this board's Vivante driver with an empty cache.
"Painted once" was never actually the safety condition; "the GPU has already
warmed up this exact draw path" is.

**Fix applied:** `BazelFrame.qml` no longer uses `Canvas` at all. Since the
frame's geometry is a fixed design-time shape (`frameRadius`, `bezelWidth`,
etc. never change at runtime), it's baked once, offline, to
`assets/BazelFrame.png` by `tools/gen_bazel_frame.py` (pycairo, mirrors the
old Canvas paint code path-for-path: same rounded-rect-with-bottom-notch
outline, same gradients, same drop shadow) and loaded with a plain `Image` +
`sourceSize`. This reuses the exact same texture-sampling shader every other
`Image`/`Rectangle` on screen already uses — no new pipeline, no stall.
**Retest pending** — rebuild, redeploy, and confirm the stall is gone.

**Rule for the rest of the ladder:** static art (S1 BazelFrame done; likely
also relevant for S8 Car image, S9 Road surface, any bezel/badge artwork) —
bake to PNG with a small pycairo/PIL generator script committed under
`tools/`, don't draw it live even once. Reserve `Shape`/`Canvas`-free QML
drawing for things that actually change at runtime (gauge arcs, needles,
animated ticks) — those stages (S2+) intentionally exercise a Shape-based
pipeline early and repeatedly so it's warm well before anything depends on it
being fast.
