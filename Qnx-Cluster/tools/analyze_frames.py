#!/usr/bin/env python3
"""
Burst-aware analyser for a QSG_RENDER_TIMING=1 log.

WHY THIS EXISTS
---------------
Two ways of reading these logs have each produced a confidently wrong answer
in this project, in opposite directions. This script exists to prevent both.

1. FALSE FAILURE, from averaging across idle time. The naive metric --
   `grep -c "frame rendered"` divided by elapsed seconds -- is only valid when
   the UI animates continuously for the whole window. Qt Quick's render loop is
   demand-driven: nothing changing means nothing drawn, on purpose. A UI that
   animates hard for 300 ms then sits still for 1.1 s is behaving correctly but
   averages to ~14 fps. That reading cost this project a session and half a
   rendering rewrite before burst segmentation showed every burst was running
   at a locked 60 fps with render=1ms.

2. FALSE FAILURE, from gating on the single worst frame. Over ~1300 frames
   there is always one outlier -- a first-use shader compile, a scheduling
   hiccup. Judging a stage on `max` makes every stage fail eventually and
   teaches you to ignore the verdict, which is worse than having no verdict.

So: bursts are segmented, and the gate is applied to PERCENTILES, with the
worst frame reported separately as an informational "worst hitch". The
headline number is the delivered frame period at p99 -- that is what actually
answers "are we hitting 60 fps", because a render spike absorbed by swap slack
costs the user nothing.

READ THE VERDICT, NOT THE AVERAGE, AND NOT THE MAX.

Usage:
    python3 tools/analyze_frames.py /path/to/x.log
    python3 tools/analyze_frames.py x.log --idle-threshold 100
"""

import argparse
import re
import sys
from collections import Counter

# A gap longer than this between two render-thread frames is treated as the
# render loop going idle rather than as a stall. 100 ms is ~6 missed vsyncs at
# 60 Hz -- comfortably longer than any real hitch, comfortably shorter than a
# genuine idle window.
DEFAULT_IDLE_THRESHOLD_MS = 100

# Gates are applied at p95 (steady-state cost), except the frame period which
# is applied at p99 because a late frame is what the eye actually sees.
GATE_POLISH_MS = 2
GATE_FPS = 55
GATE_PERIOD_MS = 20   # 60 Hz is 16.7 ms; 20 allows one marginal frame
GATE_BUDGET_MS = 13   # polish+sync+render; swap absorbs the rest until vblank

RE_START = re.compile(
    r"render thread.*syncAndRender: start, elapsed since last call: (\d+) ms"
)
RE_RENDERED = re.compile(
    r"render thread.*frame rendered in (\d+)ms, sync=(\d+), render=(\d+), swap=(\d+)"
)
RE_PREPARED = re.compile(
    r"Frame prepared, polish=(\d+) ms, lock=(\d+) ms, "
    r"blockedForSync=(\d+) ms, animations=(\d+) ms"
)


class Frame:
    __slots__ = ("t", "gap", "total", "sync", "render", "swap")

    def __init__(self, t, gap):
        self.t = t
        self.gap = gap
        self.total = self.sync = self.render = self.swap = None

    @property
    def timed(self):
        return self.render is not None


def pct(values, p):
    if not values:
        return -1
    s = sorted(values)
    return s[min(len(s) - 1, int(len(s) * p / 100.0))]


def parse(path):
    """Rebuild a render-thread timeline plus the GUI-thread cost breakdown.

    The log has no absolute timestamps, so wall-clock position is
    reconstructed by accumulating each frame's 'elapsed since last call'.
    """
    frames, prepared = [], []
    t = 0
    with open(path, "r", errors="replace") as fh:
        for line in fh:
            m = RE_START.search(line)
            if m:
                gap = int(m.group(1))
                t += gap
                frames.append(Frame(t, gap))
                continue
            m = RE_RENDERED.search(line)
            if m and frames:
                f = frames[-1]
                f.total, f.sync, f.render, f.swap = (int(x) for x in m.groups())
                continue
            m = RE_PREPARED.search(line)
            if m:
                prepared.append(tuple(int(x) for x in m.groups()))
    return frames, prepared


def split_bursts(frames, idle_threshold):
    """Group frames into contiguous runs, splitting wherever the loop idled."""
    bursts, cur = [], []
    for f in frames:
        if f.gap > idle_threshold and cur:
            bursts.append(cur)
            cur = [f]
        else:
            cur.append(f)
    if cur:
        bursts.append(cur)
    return bursts


def burst_row(burst):
    """Per-burst summary for the table. The first frame's gap is excluded --
    it measures the idle period before the burst, not a frame period."""
    if len(burst) < 3:
        return None
    duration = burst[-1].t - burst[0].t
    if duration <= 0:
        return None
    timed = [f for f in burst if f.timed]
    return {
        "frames": len(burst),
        "duration_ms": duration,
        "fps": (len(burst) - 1) / (duration / 1000.0),
        "p99_period": pct([f.gap for f in burst[1:]], 99),
        "p95_render": pct([f.render for f in timed], 95),
        "max_render": max((f.render for f in timed), default=-1),
    }


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("log")
    ap.add_argument("--idle-threshold", type=int, default=DEFAULT_IDLE_THRESHOLD_MS,
                    help="ms; gaps longer than this split bursts (default %(default)s)")
    ap.add_argument("--skip-first", type=int, default=1,
                    help="leading bursts excluded from the verdict, to drop "
                         "first-frame / shader-warmup cost (default %(default)s). "
                         "Ignored when it would leave nothing to judge.")
    ap.add_argument("--warmup-frames", type=int, default=30,
                    help="when the whole run is one continuous burst, exclude this "
                         "many leading frames instead (default %(default)s)")
    args = ap.parse_args()

    frames, prepared = parse(args.log)
    if not frames:
        sys.exit("No render-thread timing lines found. Was QSG_RENDER_TIMING=1 set, "
                 "and QT_FORCE_STDERR_LOGGING=1 for an ssh session?")

    wall_ms = frames[-1].t
    print(f"log                : {args.log}")
    print(f"frames rendered    : {len(frames)}")
    print(f"wall time          : {wall_ms / 1000.0:.2f} s")
    print(f"NAIVE average fps  : {len(frames) / (wall_ms / 1000.0):.1f}   "
          f"<-- meaningless if there are idle gaps below")
    print()

    bursts = split_bursts(frames, args.idle_threshold)
    idle = [b[0].gap for b in bursts[1:]]
    print(f"idle gaps > {args.idle_threshold} ms  : {len(idle)}"
          + (f"  (total {sum(idle) / 1000.0:.2f} s, "
             f"{100.0 * sum(idle) / wall_ms:.0f}% of the window)" if idle else ""))
    if idle:
        print("                     no frames were produced here because nothing "
              "changed -- that is")
        print("                     demand-driven rendering working, not a stall.")
    print()

    # Exclude leading bursts as warmup -- but only when that still leaves
    # something to judge. A continuous stimulus (the preferred kind) is ONE
    # burst for the whole run; there, trim leading frames instead.
    single_burst = len(bursts) <= args.skip_first
    judged_idx = set(range(len(bursts))) if single_burst \
        else set(range(args.skip_first, len(bursts)))

    print("burst  frames  dur_ms   inst_fps  p99_period  p95_render  max_render")
    judged_frames = []
    periods = []
    for i, b in enumerate(bursts):
        row = burst_row(b)
        if not row:
            continue
        if i in judged_idx:
            jb = b[args.warmup_frames:] if single_burst else b
            judged_frames += jb
            # Drop each burst's FIRST frame gap: that gap measures the idle
            # period preceding the burst, not a frame period. Concatenating
            # bursts and then slicing [1:] once would let every idle gap but
            # the first leak into the distribution and wreck it.
            periods += [f.gap for f in jb[1:]]
        print(f"{i:5d}  {row['frames']:6d}  {row['duration_ms']:6d}  {row['fps']:9.1f}  "
              f"{row['p99_period']:10d}  {row['p95_render']:10d}  {row['max_render']:10d}")
    if single_burst:
        print(f"       (one continuous burst -- verdict excludes the first "
              f"{args.warmup_frames} frames as warmup)")
    print()

    if not judged_frames:
        sys.exit("Not enough sustained frames to judge. Is the UI animating at all?")

    timed = [f for f in judged_frames if f.timed]
    renders = [f.render for f in timed]
    syncs = [f.sync for f in timed]
    swaps = [f.swap for f in timed]
    polishes = [p[0] for p in prepared]

    print("steady-state distribution (judged frames only)")
    print("               p50   p90   p95   p99    max")
    for name, vals in [("frame period", periods), ("render", renders),
                       ("sync", syncs), ("swap", swaps), ("polish", polishes),
                       ("animations", [p[3] for p in prepared])]:
        if vals:
            print(f"  {name:<12} {pct(vals,50):5d} {pct(vals,90):5d} {pct(vals,95):5d} "
                  f"{pct(vals,99):5d} {max(vals):6d}")
    print()

    if prepared:
        print(f"  animations ms  : {dict(sorted(Counter(p[3] for p in prepared).items()))}")
        print()

    # fps from in-burst periods only, so intermittent stimuli are judged on how
    # fast they render while rendering, not on how often they choose to render.
    fps = len(periods) / (sum(periods) / 1000.0) if periods else 0

    # The physically meaningful CPU-side gate is the documented budget: the
    # per-frame work must fit in a frame with room for swap to absorb the wait
    # for vblank. Gating each component separately with a made-up number
    # produces failures that mean nothing -- a render p95 of 5 ms is perfectly
    # healthy inside a 13 ms budget.
    #
    # `animations` is included because it is real GUI-thread work in the same
    # polishAndSync pass as polish, and it is the component that grows with
    # concurrent Behaviors/ColorAnimations -- the exact thing a gauge cluster
    # accumulates as tick marks and labels pile up. Leaving it out would hide
    # the one cost this UI is most likely to blow.
    #
    # polish keeps its own separate check because sustained GUI-thread
    # painting is a specific defect signature (a Canvas repainting every
    # frame), not just generic cost.
    # The two threads are checked SEPARATELY, because they run concurrently.
    #
    # An earlier version of this summed polish+animations+sync+render into one
    # budget. That double-counts: Qt Quick's threaded render loop advances
    # animations and polishes on the GUI thread while the render thread renders
    # the previous frame. Frame rate is limited by whichever thread is slower,
    # max(gui, render) -- not by their sum. Summing them failed a
    # configuration that was actually delivering a locked 62 fps with every
    # frame inside one vsync, which is the gate contradicting the very thing it
    # exists to predict.
    #
    #   GUI thread    polish + animations
    #   render thread sync + render        (swap is the wait for vblank, not work)
    anims = [p[3] for p in prepared]
    n_gui = min(len(polishes), len(anims))
    gui_work = [polishes[i] + anims[i] for i in range(n_gui)] or polishes
    n_rt = min(len(syncs), len(renders))
    rt_work = [syncs[i] + renders[i] for i in range(n_rt)] or renders
    checks = [
        ("frame period p99   ", pct(periods, 99), GATE_PERIOD_MS,
         pct(periods, 99) <= GATE_PERIOD_MS, "%d ms"),
        ("sustained fps      ", fps, GATE_FPS, fps >= GATE_FPS, "%.1f"),
        ("GUI thread p95     ", pct(gui_work, 95), GATE_BUDGET_MS,
         pct(gui_work, 95) <= GATE_BUDGET_MS, "%d ms"),
        ("render thread p95  ", pct(rt_work, 95), GATE_BUDGET_MS,
         pct(rt_work, 95) <= GATE_BUDGET_MS, "%d ms"),
        ("polish p95         ", pct(polishes, 95), GATE_POLISH_MS,
         pct(polishes, 95) <= GATE_POLISH_MS, "%d ms"),
    ]

    print("VERDICT (gate applied at percentiles, not max -- see module docstring)")
    for name, val, gate, ok, fmt in checks:
        print(f"  {'PASS' if ok else 'FAIL'}  {name} = {fmt % val}  (gate {gate})")

    worst_render = max(renders, default=0)
    worst_period = max(periods, default=0)
    print(f"\n  worst hitch: render {worst_render} ms, frame period {worst_period} ms "
          f"(informational -- a lone outlier is not a stage failure)")

    passed = all(c[3] for c in checks)
    print()
    print("=> STAGE PASSES" if passed else "=> STAGE FAILS")

    # Sustained GUI-thread painting is the Canvas-every-frame signature. An
    # occasional 1 ms polish with animations running is normal and is NOT that.
    if pct(polishes, 50) >= GATE_POLISH_MS:
        print("   note: polish is high on most frames -- look for a Canvas / "
              "QQuickPaintedItem\n         repainting on a per-frame binding "
              "(see the skill's core-dump stack-sample technique).")
    return 0 if passed else 1


if __name__ == "__main__":
    sys.exit(main())
