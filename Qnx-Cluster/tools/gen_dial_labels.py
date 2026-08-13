#!/usr/bin/env python3
"""
Bake a gauge's dial labels (0, 30, 60 ... 240 and 0 ... 8) into a PNG.

WHY
---
S7 measured render time on this board as roughly

    render_ms  ~=  0.5 * batches  +  0.04 * nodes

i.e. one draw call costs about as much as twelve scene-graph nodes. This GPU is
slow to *start* a batch, almost regardless of what is in it — 130 tick marks
drawn as Shapes add ZERO extra batches, while a handful of Text items add
several.

Baking these labels was worth about 2 batches (23 -> 21) and moved sustained
fps from 51.0 to 57.4.

HONEST NOTE ON THE PREDICTION
-----------------------------
This was expected to save ~8 batches, not 2. The estimate came from measuring
`--no-text`, which hides GaugeLabels AND GaugeSpeedNumber — so the hero number
and unit caption's cost got attributed to the 18 labels. The labels were never
the expensive part; they all share one font size and Qt had already merged them
into ~2-3 batches.

The explanation that now fits the data (NOT yet isolated, so treat it as a
hypothesis): text batches track the number of distinct FONT SIZES, not the
number of Text items, because Qt keeps a glyph atlas per size and nodes
sampling different textures cannot merge. That would make this file's real
value modest, and the bigger wins elsewhere.

Kept regardless: the labels are fixed strings, so drawing them as one Image is
strictly cheaper than as 18 Text items, and it removes 16 nodes.

WHAT THIS DELIBERATELY DOES NOT BAKE
------------------------------------
Anything whose value is real data: the hero speed/rpm numbers, and the bottom
bar's TEMP / TOTAL KM / TIME readouts. Those stay live `Text`. They are about
six items and ~2 batches total, which is affordable — and they are the whole
point of the display.

The unit captions ("KM/H", "RPM x1000") are also left live even though they are
static, because their position depends on the hero number's font metrics
(anchored to its bottom edge), which cannot be reproduced here without
duplicating Qt's text layout. Two items is not worth that fragility.

COORDINATES
-----------
Baked in the gauge's OWN 450x450 coordinate system, the same space
GaugeLabels.qml works in, so the image simply fills the gauge Item and inherits
the same transform chain the live labels did. That avoids re-deriving the
scene's scale here — the transform (design 1024x600 -> screen, gaugeArea 0.9,
gauge 0.7) stays entirely in QML where it is already verified on hardware.

SCALE=2 supersamples so the image stays sharp after the ~0.76 downscale the
gauge transform applies.

Usage:
    python3 tools/gen_dial_labels.py
"""

import math
import os

from PIL import Image, ImageDraw, ImageFont

HERE = os.path.dirname(os.path.abspath(__file__))
ASSETS = os.path.normpath(os.path.join(HERE, "..", "assets"))
FONT_PATH = os.path.join(ASSETS, "fonts", "KdamThmorPro-Regular.ttf")

# Gauge-local geometry — must match GaugeLabels.qml exactly.
SIZE = 450             # the gauge Item is 450x450
LABEL_RADIUS = 160     # GaugeLabels.labelRadius
FONT_SIZE = 18         # GaugeLabels.fontSize
START_ANGLE = 135.0    # GaugeLabels.startAngle  (0 deg = right, +CW, y down)
SWEEP_ANGLE = 270.0    # GaugeLabels.sweepAngle

SCALE = 2              # supersample

# Baked labels cannot change colour, so the active/passive distinction the live
# labels had (bright once the needle passes, muted before) collapses to one
# colour. Theme.colorTextPrimary is chosen over colorTextMuted because a dial
# that is legible at rest matters more in a cluster than the dimming effect.
# Change this one constant to revisit that decision.
LABEL_COLOR = (0xCB, 0xC4, 0xCD, 0xFF)     # Theme.colorTextPrimary #CBC4CD


def build(values, out_name):
    img = Image.new("RGBA", (SIZE * SCALE, SIZE * SCALE), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    font = ImageFont.truetype(FONT_PATH, FONT_SIZE * SCALE)

    cx = cy = (SIZE * SCALE) / 2.0
    radius = LABEL_RADIUS * SCALE
    max_value = values[-1]

    for v in values:
        angle = math.radians(START_ANGLE + (v / max_value) * SWEEP_ANGLE)
        x = cx + math.cos(angle) * radius
        y = cy + math.sin(angle) * radius

        text = str(int(v)) if float(v).is_integer() else "%.1f" % v
        # "mm" centres the text box on the point, matching GaugeLabels.qml's
        # `x = centerX + cos*R - width/2` / `y = ... - height/2`.
        draw.text((x, y), text, font=font, fill=LABEL_COLOR, anchor="mm")

    out = os.path.join(ASSETS, out_name)
    img.save(out)
    print("wrote %s  (%dx%d, %d labels)"
          % (out, img.width, img.height, len(values)))
    return out


if __name__ == "__main__":
    # Speed dial: 0..240 step 30 (GaugeLabels labelStep 30 in Main.qml)
    build([v for v in range(0, 241, 30)], "DialLabelsSpeed.png")

    # RPM dial: 0..8 step 1
    build([v for v in range(0, 9, 1)], "DialLabelsRpm.png")
