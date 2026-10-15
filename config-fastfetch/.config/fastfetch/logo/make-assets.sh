#!/usr/bin/env bash
# Turn the frames from render.py into the fastfetch logo assets:
#   arch-spin.webp  one 4 s turn (100 frames, 40 ms each), looping, with alpha
#   arch-front.png  the front-facing frame, for the static logo
# Usage: make-assets.sh FRAMES_DIR [OUT_DIR]
set -euo pipefail

frames=${1:?usage: make-assets.sh FRAMES_DIR [OUT_DIR]}
out=${2:-$(dirname "$0")}
size=256

# 000..099 is one full turn; 100.png only exists for the seam check.
magick -delay 4 -loop 0 -dispose Background "$frames"/0[0-9][0-9].png \
    -resize "${size}x$size" -quality 92 -define webp:alpha-quality=100 \
    "$out/arch-spin.webp"
magick "$frames/000.png" -resize "${size}x$size" "$out/arch-front.png"
