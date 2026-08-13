import os
import cairo
import math

# Authored natively at the real panel size (1024x600) instead of the old
# 1200x600 design size + runtime stretch -- stretching non-uniformly
# squished the rounded corners. Proportions (radius, curve width/depth,
# bezel thickness) are scaled from the original 1200x600 design so the look
# stays the same, just rendered correctly for the actual target aspect.
BASE_W, BASE_H = 1280, 720
SCALE = 2
W, H = BASE_W * SCALE, BASE_H * SCALE

sx = BASE_W / 1200.0   # width scale vs. original design
sy = BASE_H / 600.0    # height scale vs. original design (1.0, height unchanged)

r = 200 * sx * SCALE
bw = 20 * ((sx + sy) / 2) * SCALE
cw = 600 * sx * SCALE
cd = 80 * sy * SCALE

surface = cairo.ImageSurface(cairo.FORMAT_ARGB32, W, H)
ctx = cairo.Context(surface)

def quad_to_cubic(ctx, x0, y0, cx, cy, x1, y1):
    c1x = x0 + 2.0/3.0 * (cx - x0)
    c1y = y0 + 2.0/3.0 * (cy - y0)
    c2x = x1 + 2.0/3.0 * (cx - x1)
    c2y = y1 + 2.0/3.0 * (cy - y1)
    ctx.curve_to(c1x, c1y, c2x, c2y, x1, y1)

def arc_to_corner(ctx, cx, cy, radius, start_deg, end_deg):
    ctx.arc(cx, cy, radius, math.radians(start_deg), math.radians(end_deg))

def build_outer_path(ctx, W, H, r, cw, cd):
    ctx.new_path()
    ctx.move_to(r, 0)
    ctx.line_to(W - r, 0)
    arc_to_corner(ctx, W - r, r, r, -90, 0)
    ctx.line_to(W, H - r)
    arc_to_corner(ctx, W - r, H - r, r, 0, 90)
    ctx.line_to(W / 2 + cw / 2, H)
    quad_to_cubic(ctx, W / 2 + cw / 2, H, W / 2, H - cd, W / 2 - cw / 2, H)
    ctx.line_to(r, H)
    arc_to_corner(ctx, r, H - r, r, 90, 180)
    ctx.line_to(0, r)
    arc_to_corner(ctx, r, r, r, 180, 270)
    ctx.close_path()

def build_inset_path(ctx, W, H, r, cw, cd, inset):
    off = inset
    ctx.new_path()
    ctx.move_to(r, off)
    ctx.line_to(W - r, off)
    arc_to_corner(ctx, W - off - (r - off), off + (r - off), r - off, -90, 0)
    ctx.line_to(W - off, H - r)
    arc_to_corner(ctx, W - off - (r - off), H - off - (r - off), r - off, 0, 90)
    ctx.line_to(W / 2 + cw / 2, H - off)
    quad_to_cubic(ctx, W / 2 + cw / 2, H - off, W / 2, H - cd - off, W / 2 - cw / 2, H - off)
    ctx.line_to(r, H - off)
    arc_to_corner(ctx, off + (r - off), H - off - (r - off), r - off, 90, 180)
    ctx.line_to(off, r)
    arc_to_corner(ctx, off + (r - off), off + (r - off), r - off, 180, 270)
    ctx.close_path()

shadow_layers = 18
for i in range(shadow_layers, 0, -1):
    alpha = 0.9 * (1 - i / shadow_layers) * 0.16
    ctx.save()
    ctx.translate(0, 12 * SCALE * sy)
    build_outer_path(ctx, W, H, r, cw, cd)
    ctx.set_source_rgba(0, 0, 0, alpha)
    ctx.fill()
    ctx.restore()

build_inset_path(ctx, W, H, r, cw, cd, bw / 2)
sgrad = cairo.LinearGradient(0, 0, 0, H)
sgrad.add_color_stop_rgba(0.0, 0x15/255, 0x16/255, 0x1a/255, 1.0)
sgrad.add_color_stop_rgba(0.5, 0x3a/255, 0x3b/255, 0x3f/255, 1.0)
sgrad.add_color_stop_rgba(1.0, 0x15/255, 0x16/255, 0x1a/255, 1.0)
ctx.set_source(sgrad)
ctx.set_line_width(bw)
ctx.set_line_join(cairo.LINE_JOIN_ROUND)
ctx.set_line_cap(cairo.LINE_CAP_ROUND)
ctx.stroke()

ctx.set_line_width(1 * SCALE)
ctx.set_source_rgba(120/255, 120/255, 130/255, 0.3)
ctx.new_path(); ctx.move_to(r + 30*SCALE*sx, 1*SCALE); ctx.line_to(W - r - 30*SCALE*sx, 1*SCALE); ctx.stroke()
ctx.new_path(); ctx.move_to(r + 30*SCALE*sx, H - 1*SCALE); ctx.line_to(W/2 - cw/2, H - 1*SCALE); ctx.stroke()
ctx.new_path(); ctx.move_to(W/2 + cw/2, H - 1*SCALE); ctx.line_to(W - r - 30*SCALE*sx, H - 1*SCALE); ctx.stroke()

ctx.set_source_rgba(140/255, 140/255, 145/255, 0.35)
ctx.new_path()
ctx.move_to(W/2 + cw/2, H - 1*SCALE)
quad_to_cubic(ctx, W/2 + cw/2, H - 1*SCALE, W/2, H - cd - 1*SCALE, W/2 - cw/2, H - 1*SCALE)
ctx.stroke()

ctx.set_operator(cairo.OPERATOR_CLEAR)
build_inset_path(ctx, W, H, r, cw, cd, bw)
ctx.fill()
ctx.set_operator(cairo.OPERATOR_OVER)

# Write next to the repo's assets/, not an absolute path from whatever
# session happened to generate it last — the previous hardcoded path pointed
# at a scratch directory that no longer exists, so re-running this script
# would have failed rather than regenerating the art.
_out = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "BazelFrame.png")
surface.write_to_png(os.path.normpath(_out))
print("wrote", os.path.normpath(_out), W, H, "r=",r/SCALE,"bw=",bw/SCALE,"cw=",cw/SCALE,"cd=",cd/SCALE)
