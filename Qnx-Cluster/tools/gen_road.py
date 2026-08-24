#!/usr/bin/env python3
"""
Bake the road's three STATIC layers into one PNG.

WHY
---
The original Road.qml is six `Canvas` items. Three of them paint once
(road surface gradient, horizon fog, centre-lane highlight) and three repaint
on an animated `offset` — `onWatchOffsetChanged: requestPaint()` — i.e. CPU
software rasterisation on the GUI thread, every frame, forever. That is
exactly the pattern PLAN.md identified at the very start as the root cause of
the original app's 24 fps and 32 ms polish.

The three static layers never change, so per Rule 2 they are baked here into a
single image: one texture, one draw call, no Canvas, no first-use shader stall.
The three animated layers are rebuilt in QML as plain `Rectangle`s (see
qml/ContentArea/Road.qml) — Rectangles batch nearly perfectly on this board
(measured: 60 of them cost 2-3 batches, 130 tick Shapes cost 0).

Geometry is copied exactly from Road.qml's own constants so the baked art
lines up with the QML-drawn dashes:

    vpX = width * 0.50      vanishing point
    vpY = height * 0.55
    halfRoad = width * 0.30

Usage:
    python3 tools/gen_road.py
"""

import math
import os

import cairo

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.normpath(os.path.join(HERE, "..", "assets", "RoadBackdrop.png"))

# ── THESE MUST MATCH Road.qml's CALL SITE, NOT Road.qml's DEFAULTS ──
# The first version baked at 480x520 with the vanishing point at 0.55 of the
# height, then Main.qml displayed it stretched into a 480x424 area with
# vpFraction 0.377. The art therefore had one vanishing point and the QML
# dashes another, and the dashes visibly diverged from the painted road.
# Baked geometry and live geometry are one thing; changing either alone is a
# bug. Keep these three numbers in step with Main.qml's `Road { ... }`.
BASE_W, BASE_H = 480, 424      # the contentArea the road fills
VP_FRACTION = 0.377            # Main.qml: Road { vpFraction: 0.377 }
SCALE = 2                      # supersample

W, H = BASE_W * SCALE, BASE_H * SCALE

VPX = W * 0.50
VPY = H * VP_FRACTION
HALF_ROAD = W * 0.30
DASH_SIDE = 0.28


def road_surface(ctx):
    """Layer 1: the road slab, a gradient trapezoid from the vanishing point."""
    ctx.new_path()
    ctx.move_to(VPX, VPY)
    ctx.line_to(VPX + HALF_ROAD, H)
    ctx.line_to(VPX - HALF_ROAD, H)
    ctx.close_path()

    grad = cairo.LinearGradient(0, VPY, 0, H)
    grad.add_color_stop_rgba(0.00, 15 / 255, 15 / 255, 20 / 255, 0.0)
    grad.add_color_stop_rgba(0.20, 15 / 255, 15 / 255, 20 / 255, 0.3)
    grad.add_color_stop_rgba(0.50, 20 / 255, 20 / 255, 28 / 255, 0.5)
    grad.add_color_stop_rgba(1.00, 25 / 255, 25 / 255, 35 / 255, 0.7)
    ctx.set_source(grad)
    ctx.fill()


def horizon_fog(ctx):
    """Layer 2: soft radial haze at the vanishing point."""
    r = 120 * SCALE
    fog = cairo.RadialGradient(VPX, VPY, 5 * SCALE, VPX, VPY, r)
    fog.add_color_stop_rgba(0.0, 120 / 255, 140 / 255, 180 / 255, 0.30)
    fog.add_color_stop_rgba(0.4, 80 / 255, 100 / 255, 140 / 255, 0.15)
    fog.add_color_stop_rgba(1.0, 0, 0, 0, 0.0)

    ctx.new_path()
    ctx.arc(VPX, VPY, r, 0, math.pi * 2)
    ctx.set_source(fog)
    ctx.fill()


def lane_highlight(ctx):
    """Layer 3: the brighter centre lane, plus its bright spine."""
    hr = W * 0.6
    l_bot = VPX + (-DASH_SIDE) * hr
    r_bot = VPX + (DASH_SIDE) * hr

    ctx.new_path()
    ctx.move_to(VPX, VPY)
    ctx.line_to(r_bot, H)
    ctx.line_to(l_bot, H)
    ctx.close_path()
    grad = cairo.LinearGradient(0, VPY, 0, H)
    grad.add_color_stop_rgba(0.00, 1, 1, 1, 0.00)
    grad.add_color_stop_rgba(0.25, 1, 1, 1, 0.03)
    grad.add_color_stop_rgba(0.60, 1, 1, 1, 0.09)
    grad.add_color_stop_rgba(1.00, 1, 1, 1, 0.20)
    ctx.set_source(grad)
    ctx.fill()

    spine_half = 60 * SCALE
    ctx.new_path()
    ctx.move_to(VPX, VPY)
    ctx.line_to(VPX - spine_half, H)
    ctx.line_to(VPX + spine_half, H)
    ctx.close_path()
    spine = cairo.LinearGradient(VPX - spine_half, 0, VPX + spine_half, 0)
    spine.add_color_stop_rgba(0.0, 1, 1, 1, 0.00)
    spine.add_color_stop_rgba(0.5, 1, 1, 1, 0.14)
    spine.add_color_stop_rgba(1.0, 1, 1, 1, 0.00)
    ctx.set_source(spine)
    ctx.fill()


def main():
    surface = cairo.ImageSurface(cairo.FORMAT_ARGB32, W, H)
    ctx = cairo.Context(surface)

    road_surface(ctx)
    horizon_fog(ctx)
    lane_highlight(ctx)

    # Crop to the painted area. The road occupies a trapezoid plus the fog
    # disc; the rest of the rect is fully transparent, and on this GPU a
    # transparent pixel in a blended quad still costs fill. Cropping roughly
    # halves the road's blended coverage.
    surface.flush()
    import struct
    data = surface.get_data()
    stride = surface.get_stride()
    min_x, min_y, max_x, max_y = W, H, -1, -1
    for y in range(H):
        row = data[y * stride:(y + 1) * stride]
        for x in range(W):
            if row[x * 4 + 3]:            # ARGB32 premultiplied: alpha byte
                if x < min_x: min_x = x
                if x > max_x: max_x = x
                if y < min_y: min_y = y
                if y > max_y: max_y = y
    cw, ch = max_x - min_x + 1, max_y - min_y + 1

    cropped = cairo.ImageSurface(cairo.FORMAT_ARGB32, cw, ch)
    cctx = cairo.Context(cropped)
    cctx.set_source_surface(surface, -min_x, -min_y)
    cctx.paint()
    cropped.write_to_png(OUT)

    print("wrote %s  %dx%d (cropped from %dx%d)  %d bytes"
          % (OUT, cw, ch, W, H, os.path.getsize(OUT)))
    print("  vp=(%.1f, %.1f)  halfRoad=%.1f  vpFraction=%.3f"
          % (VPX, VPY, HALF_ROAD, VP_FRACTION))
    print("  blended area cut to %.0f%% of the full rect" % (100.0 * cw * ch / (W * H)))
    print("  --> place the Image in Road.qml at these fractions of its size:")
    print("      x=%.6f  y=%.6f  w=%.6f  h=%.6f"
          % (min_x / W, min_y / H, cw / W, ch / H))


if __name__ == "__main__":
    main()
