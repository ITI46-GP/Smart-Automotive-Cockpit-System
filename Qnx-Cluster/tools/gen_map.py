#!/usr/bin/env python3
"""
Bake MapView's mock map (grid + route curve + destination dot) into a PNG.

WHY
---
The original MapView.qml draws this with a Canvas, `Component.onCompleted:
requestPaint()` — a ONE-TIME paint. S1 already proved that doesn't matter on
this GPU: the first time ANY Canvas-backed texture composites, the driver
has to compile a shader/pipeline it has never used before, costing a one-time
~19s stall on the QNX target (~4-5s on desktop) — "painted once" was never
the safety condition, "the GPU has already warmed up this exact draw path"
was. So this bakes the same grid + bezier route + destination dot offline,
same technique as BazelFrame/Road/dial labels.

The content is a static mockup (no live telemetry backs it yet), so baking
loses nothing — there is nothing here that needs to animate.

Usage:
    python3 tools/gen_map.py
"""

import math
import os

import cairo

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.normpath(os.path.join(HERE, "..", "assets", "MapBackdrop.png"))

W, H = 360, 220
SCALE = 2  # supersample


def main():
    surface = cairo.ImageSurface(cairo.FORMAT_ARGB32, W * SCALE, H * SCALE)
    ctx = cairo.Context(surface)
    ctx.scale(SCALE, SCALE)

    # Grid — verbatim from the original Canvas paint code.
    ctx.set_source_rgba(100 / 255, 130 / 255, 200 / 255, 0.15)
    ctx.set_line_width(1)
    x = 0
    while x < W:
        ctx.move_to(x, 0)
        ctx.line_to(x, H)
        ctx.stroke()
        x += 20
    y = 0
    while y < H:
        ctx.move_to(0, y)
        ctx.line_to(W, y)
        ctx.stroke()
        y += 20

    # Route — same bezier curve.
    ctx.set_source_rgb(0x4a / 255, 0x9e / 255, 0xff / 255)
    ctx.set_line_width(3)
    ctx.move_to(40, H - 40)
    ctx.curve_to(120, H - 80, 200, 60, W - 40, 40)
    ctx.stroke()

    # Destination dot.
    ctx.set_source_rgb(0xff / 255, 0x4a / 255, 0x4a / 255)
    ctx.arc(W - 50 + 7, 30 + 7, 7, 0, 2 * math.pi)
    ctx.fill_preserve()
    ctx.set_source_rgb(1, 1, 1)
    ctx.set_line_width(2)
    ctx.stroke()

    surface.write_to_png(OUT)
    print("wrote %s  %dx%d" % (OUT, W * SCALE, H * SCALE))


if __name__ == "__main__":
    main()
