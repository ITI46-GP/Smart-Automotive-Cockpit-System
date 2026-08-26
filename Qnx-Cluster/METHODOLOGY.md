# Qnx-Cluster — Rebuild Methodology

Pure Qt Creator / CMake rebuild of the Digital Cluster QML UI, targeting the
QNX guest on i.MX8QM. This file is the short version of *how* we work in
this project. For *what's* been done and measured, see `PLAN.md`. For the
full technical detail behind every rule here — exact commands, on-target
evidence, diagnosis techniques — see the `qnx-qtquick-cluster-perf` skill,
which applies automatically whenever working in this project.

## The method

1. **Add exactly one visual element per stage.** `PLAN.md`'s S0-S10 ladder
   defines the order. Never add stage N+1 until stage N passes its gate —
   that way a regression is always attributable to exactly one change.
2. **Verify visually before deploying to the board, if the change is
   non-trivial.** Learned this the hard way in S3: a geometrically fiddly
   QML rewrite (a rotating-mask reveal effect) got shipped straight to the
   board without being seen rendered first, and it visibly broke the UI.
   For anything more involved than a one-line tweak, build it in a
   checkable increment or hand it back for visual confirmation before
   pushing further — don't guess a whole non-trivial rewrite blind.
3. **Deploy to the real QNX guest and measure.** Desktop builds are useful
   for a quick visual sanity check, but the numbers that matter only come
   from the board — this project's whole premise is that "smooth on
   desktop" has repeatedly NOT meant "smooth on the QNX guest." See the
   skill for the exact measurement harness.
4. **Gate: `polish <= 2ms`, `render <= 4ms`, `fps >= 55`.** A one-time
   startup stall that fully resolves to a clean steady state doesn't fail
   the stage, but treat it as a real defect worth fixing before moving on
   if it's cheap to fix (e.g. it's a `Canvas` you just added).
5. **If it fails, diagnose before guessing at a fix.** Two techniques,
   both detailed in the skill: a core-dump stack sample of the GUI thread
   for a per-frame regression (polish/render high on every frame), or live
   `pidin` blocked-reason sampling for a stall/hang (catch the process
   while it's stuck and read what it's actually blocked on). Cross-check
   any "which process/subsystem is the culprit" hypothesis against a
   control test before committing to a fix — this project has walked back
   more than one confident-sounding wrong guess (fontconfig, a streaming
   service, a Shape renderer choice) by finding a cleaner A/B comparison
   or a reference app that disproved it.
6. **Fix, re-measure, only then move to the next stage.**

## The core question for every component

**How is this actually drawn, and is that the cheapest way on this specific
hardware?** Concretely, for anything visual:

- **Never changes at runtime** (a bezel frame, a badge, background art) —
  bake it to a PNG offline with a small, committed Python/pycairo generator
  script and load it with `Image` + `sourceSize`. Never `Canvas`, not even
  once for a single one-time paint — a Canvas-backed texture's first
  composite costs a one-time ~19s (QNX) / ~4-5s (desktop) stall on this
  board's GPU driver, from first-use shader compilation, regardless of how
  many times it repaints afterward.
- **Moves, fades, or recolors, but its outline/shape never changes** —
  animate a transform (position, rotation, scale) or an opacity/color
  property on a shape that's drawn once and left alone. This is cheap,
  proven repeatedly on this board (a pulsing indicator, a `gles3-gears`
  reference app doing continuous per-frame rotation-matrix updates).
- **Its actual path geometry needs to change over time** (an arc's sweep
  angle, a needle's length, anything where the vertex data itself is
  different frame to frame) — **this is fine on this board.** Measured in
  S3: a `Shape` whose `PathAngleArc.sweepAngle` is animated every single
  frame renders at a locked 60 fps with `render=1ms`, `sync=0ms`,
  `polish=0ms`. An earlier reading of that same log had this recorded as
  the expensive case (60 fps → 14 fps, render thread "blocked on the QNX
  `screen` compositor") and a rewrite was started to avoid it. That was
  wrong — the app was **idle**, not stalled. The correction is important
  enough to be its own rule.

## The rule that came out of S3: idle is not slow

Qt Quick's render loop is demand-driven. If nothing on screen is changing it
draws nothing, correctly. So an averaged fps over a window where the UI is
deliberately idle most of the time measures your *stimulus*, not your
renderer. S3's stimulus animated for 300 ms out of every 1400 ms; the naive
average came out at 14 fps while every burst was running at a locked 60.

Two things follow, both cheap:

1. **Never read a bare fps average.** Run `tools/analyze_frames.py <log>`.
   It segments the log into animation bursts, reports instantaneous fps
   *inside* each one plus a pass/fail against the gate, and states how much
   of the window was idle — so the distinction is impossible to miss.
   `tools/measure_board.py` runs the app on the board and pipes straight
   into it; `deploy_and_measure.sh <stage>` does build + deploy + both.
   The gate is applied at **percentiles, not the worst frame** — over a
   thousand frames there is always one outlier, and a max-based gate fails
   every stage eventually, which teaches you to ignore the verdict.

### Corollary: verification tooling must prove its own inputs

The harness itself then produced a false PASS, which is worth knowing about
because it is the same mistake wearing a different hat. A root-owned
`/tmp/x.log` left behind by an earlier root shell meant the measure script —
running as `qnxuser` — silently failed to delete or write it, and pulled the
*previous session's* log instead. It printed a confident PASS for a binary
that had never run. The stderr saying "permission denied" had been discarded
by the calling code.

`measure_board.py` now uses a unique per-run log name, refuses to start if it
exists, surfaces launch stderr, verifies the deployed binary's size against
the local one, and checks the log actually grew. When a tool exists to stop
you trusting a bad number, the tool's own inputs are the first thing to
doubt.
2. **Make the stimulus continuous** when you want a meaningful average —
   drive the value from a looping animation rather than a periodic `Timer`,
   so there are no idle windows at all. It's also a strictly harder test.

And a caution about diagnosis, since this one produced three confident wrong
answers in a row (`clusterStreaming`, then the `screen` compositor, then
`CurveRenderer`): a `pidin` sample showing the render thread in
`REPLY <sbin/screen>` means it is waiting on the compositor, which is
*equally consistent with having nothing to draw*. Before concluding "blocked
on X", establish that the thread should have had work to do at that instant.
Likewise, a control test (`gles3-gears` holding 60 fps) only isolates a
variable if it differs from your case in exactly one way — gears differed in
several, and the wrong one got picked.

## Reference documents

- `PLAN.md` — the stage-by-stage log: what's done, the measured numbers,
  every finding and the reasoning behind it, open items.
- `qnx-qtquick-cluster-perf` skill (saved to the account, auto-applies in
  this project) — full technical detail: exact measurement harness
  commands, board access notes, the two diagnosis techniques, and every
  rule with the on-target evidence that produced it.
- `tools/` — `analyze_frames.py` (burst-aware log verdict; run this on
  every stage), `measure_board.py` (run on the board + analyse in one
  command), `deploy_and_measure.sh` (build + deploy + measure),
  `fonts.conf` (fixes a slow fontconfig fallback search on this QNX
  image), `gen_bazel_frame.py` (the baked-art generator pattern to copy
  for future static assets).
