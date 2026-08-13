#!/usr/bin/env python3
"""
Bake the car's drop shadow into the car PNG, and trim/downscale the sprite.

WHY
---
The original draws the car as a full-resolution Image with a Qt Design Studio
`DesignEffect` drop shadow on top:

    DesignEffect {
        layerBlurRadius: 2
        effects: [ DesignDropShadow { color: "#a7000000"; offsetY: 110;
                                      blur: 25; showBehind: true } ]
    }

A DesignEffect is a `layer.enabled` render pass: Qt renders the item into an
offscreen texture, blurs it, and composites it back — every frame, forever,
for a shadow that never changes shape relative to the car. This board has
already shown it is punishing about extra blended coverage, and the ladder
puts every DesignEffect in S10 precisely so each one has to justify itself.

This shadow does not need to justify itself: it is static art. Baked into the
sprite it costs exactly zero extra draw calls and zero offscreen passes.

WHAT ELSE THIS FIXES
--------------------
The source is 830x750 with an opaque bounding box of only 583x622 — about 40%
of the pixels are fully transparent padding that still gets uploaded, sampled
and blended. And the QML draws it at `scale: 0.25`, so a ~300 px sprite was
being shipped and decoded at 830 px.

So: trim to the opaque bounds, add the shadow, then scale to roughly the size
it is actually drawn at (with headroom for the 1.25 CarView scale). The
standing image rules from S7.5 then apply in QML — `sourceSize` at display
size, `mipmap: false` so it can share Qt's texture atlas.

Usage:
    python3 tools/gen_car.py
"""

import os

from PIL import Image, ImageFilter

HERE = os.path.dirname(os.path.abspath(__file__))
SRC_DEFAULT = os.path.normpath(
    os.path.join(HERE, "..", "..", "02-Digital-Cluster",
                 "Digital_Cluster_DesignStudioContent", "assets", "Tesla_Car.png"))
OUT = os.path.normpath(os.path.join(HERE, "..", "assets", "CarWithShadow.png"))

# From the original DesignDropShadow, in SOURCE pixel units (the effect applies
# to the Image before its 0.25 scale, so these are source-space numbers).
SHADOW_COLOR = (0, 0, 0, 0xA7)
SHADOW_OFFSET_Y = 110
SHADOW_BLUR = 25

# The car draws at scale 0.25 inside a CarView that is itself scaled 1.25, so
# ~0.31 of source. Bake at 2x that for clean downscaling, capped to something
# sane for the atlas.
TARGET_W = 384


def main(src=SRC_DEFAULT):
    img = Image.open(src).convert("RGBA")

    # 1. Trim the transparent padding (830x750 -> ~583x622 of real content).
    bbox = img.getbbox()
    img = img.crop(bbox)
    print("  trimmed %s -> %s" % (Image.open(src).size, img.size))

    # 2. Build the shadow: the car's alpha, tinted, offset down and blurred.
    #    The canvas needs padding on ALL sides, not just the bottom — a first
    #    version padded only vertically, so the horizontal spread of the blur
    #    was clipped flat against the image edges and the car's own bounding
    #    box still filled the full width. The tell was `car_fraction = 1.0000`
    #    when it should have been < 1.
    pad_x = SHADOW_BLUR * 3
    pad_y = SHADOW_BLUR * 3 + SHADOW_OFFSET_Y
    canvas = Image.new("RGBA",
                       (img.width + pad_x * 2, img.height + pad_y * 2),
                       (0, 0, 0, 0))

    # The blur must be applied to a layer that is ALREADY the full padded size.
    # Blurring the shadow at the car's own size first, then compositing, clips
    # the spread flat against that smaller image's edges — which is what a
    # first version did, and it showed up as the shadow having no horizontal
    # spread at all (car_fraction stayed exactly 1.0000 instead of < 1).
    alpha = img.getchannel("A")
    silhouette = Image.new("RGBA", img.size, SHADOW_COLOR)
    silhouette.putalpha(alpha.point(lambda a: int(a * SHADOW_COLOR[3] / 255.0)))

    shadow_layer = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    shadow_layer.alpha_composite(silhouette, (pad_x, pad_y + SHADOW_OFFSET_Y))
    shadow_layer = shadow_layer.filter(ImageFilter.GaussianBlur(SHADOW_BLUR / 2.0))

    canvas.alpha_composite(shadow_layer, (0, 0))
    car_origin = (pad_x, pad_y)
    canvas.alpha_composite(img, car_origin)

    # 3. Trim the now-unused margins and scale down.
    bb2 = canvas.getbbox()
    canvas = canvas.crop(bb2)
    car_w_in_sprite = img.width
    ratio = TARGET_W / float(canvas.width)
    canvas = canvas.resize((TARGET_W, max(1, int(round(canvas.height * ratio)))),
                           Image.LANCZOS)

    canvas.save(OUT, optimize=True)

    # The car no longer fills the sprite (the shadow extends past it), so QML
    # cannot size the Image by the car's width directly. Report the fraction so
    # the call site can size the sprite such that the CAR matches the original.
    car_fraction = car_w_in_sprite / float(bb2[2] - bb2[0])
    print("  wrote %s  %s  %d bytes" % (OUT, canvas.size, os.path.getsize(OUT)))
    print("  car occupies %.4f of sprite width" % car_fraction)
    print("  original car display width = %.1f px (source %d x scale 0.25)"
          % (img.width * 0.25, img.width))
    print("  => set the QML Image width to %.1f px"
          % (img.width * 0.25 / car_fraction))


if __name__ == "__main__":
    main()
