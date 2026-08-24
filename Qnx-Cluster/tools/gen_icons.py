#!/usr/bin/env python3
"""
Downscale the UI icons from their source 512x512 to something proportionate to
how they are actually drawn.

WHY
---
Every icon in the original is a 512x512 RGBA PNG. They are displayed at 22x22
(top bar buttons), 24x24 (fuel/temp) and ~35x35 (turn arrows). That is roughly
1 MB of texture memory each, ~15 MB across the set, to fill a thumbnail — and
every draw samples a 512x512 texture down to 22 pixels.

This is not a speculative optimisation; it is the project's existing standing
rule ("every scaled Image gets sourceSize set to its display size") applied to
the source asset instead of only to the QML. 96x96 keeps roughly 4x the largest
display size, which is ample for mipmapped downscaling and still ~28x less
texture memory than the original.

The QML also sets `sourceSize`, which caps what Qt decodes into memory. Doing
both matters: `sourceSize` bounds the decode, and a smaller file bounds what
has to be shipped in the binary and read at startup.

Usage:
    python3 tools/gen_icons.py
"""

import os

from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
ICONS = os.path.normpath(os.path.join(HERE, "..", "assets", "icons"))

TARGET = 96


def main():
    total_before = total_after = 0
    for name in sorted(os.listdir(ICONS)):
        if not name.endswith(".png"):
            continue
        path = os.path.join(ICONS, name)
        before = os.path.getsize(path)
        img = Image.open(path)
        if max(img.size) <= TARGET:
            print("  skip %-34s already %dx%d" % (name, img.width, img.height))
            total_before += before
            total_after += before
            continue
        img = img.convert("RGBA").resize((TARGET, TARGET), Image.LANCZOS)
        img.save(path, optimize=True)
        after = os.path.getsize(path)
        total_before += before
        total_after += after
        print("  %-34s %7d -> %6d bytes" % (name, before, after))
    print("total: %d -> %d bytes (%.1fx smaller)"
          % (total_before, total_after,
             total_before / float(total_after) if total_after else 0))


if __name__ == "__main__":
    main()
