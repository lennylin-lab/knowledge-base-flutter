#!/usr/bin/env bash
# Regenerate every launcher/web icon from assets/icon/app_icon.svg.
# Requires rsvg-convert and ImageMagick (magick); run from anywhere.
#
# Why not flutter_launcher_icons: its resizer corrupts alpha on thin
# details over transparency (the robot's eyes/mouth dropped to ~20%
# opacity) and its Windows ico is a single 48px layer. Everything here is
# rendered straight from the vector instead.
#
# Art: glyph #333 on a white circle. App icon glyph at 85% of the canvas;
# adaptive foreground at 76% (the platform's 16% inset then lands it at
# ~85% of the launcher's visible circle); web maskable at 58% safe zone.
set -euo pipefail
cd "$(dirname "$0")/.."

SVG=assets/icon/app_icon.svg
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

# App icon (Android legacy mipmap + Windows ico source).
rsvg-convert -w 870 -h 870 "$SVG" -o "$WORK/glyph.png"
magick -size 1024x1024 xc:none -fill white -draw 'circle 512,512 512,0' "$WORK/circle.png"
magick "$WORK/circle.png" "$WORK/glyph.png" -gravity center -composite assets/icon/app_icon.png

# Android adaptive foreground (transparent; white comes from the bg layer).
rsvg-convert -w 778 -h 778 "$SVG" -o "$WORK/fg.png"
magick "$WORK/fg.png" -background none -gravity center -extent 1024x1024 assets/icon/adaptive_foreground.png

# Android densities: legacy mipmap and adaptive drawable foreground use
# different size tables (108dp adaptive canvas: 108/162/216/324/432).
legacy_density() { # density size
  magick assets/icon/app_icon.png -resize "$2x$2" "android/app/src/main/res/mipmap-$1/ic_launcher.png"
}
adaptive_density() { # density size
  local g=$(( $2 * 76 / 100 ))
  rsvg-convert -w $g -h $g "$SVG" -o "$WORK/fg.png"
  magick "$WORK/fg.png" -background none -gravity center -extent "$2x$2" "android/app/src/main/res/drawable-$1/ic_launcher_foreground.png"
}
legacy_density mdpi 48
legacy_density hdpi 72
legacy_density xhdpi 96
legacy_density xxhdpi 144
legacy_density xxxhdpi 192
adaptive_density mdpi 108
adaptive_density hdpi 162
adaptive_density xhdpi 216
adaptive_density xxhdpi 324
adaptive_density xxxhdpi 432

# Windows: multi-size ico (16-256).
magick assets/icon/app_icon.png -define icon:auto-resize=256,128,64,48,32,24,16 windows/runner/resources/app_icon.ico

# Web favicon set: per-size vector renders on the white circle, glyph 85%.
python3 - "$SVG" web/favicon.svg << 'PYEOF'
import sys

src, dst = sys.argv[1], sys.argv[2]
s = open(src).read()
marker = 'viewBox="0 0 1024 1024">'
circle = (
    '<circle cx="512" cy="512" r="512" fill="#FFFFFF"/>'
    '<g transform="translate(76.8 76.8) scale(.85)">'
)
s = s.replace(marker, marker + circle, 1).replace('</svg>', '</g></svg>')
open(dst, 'w').write(s)
PYEOF
web_icon() { # size output glyph_size
  rsvg-convert -w $3 -h $3 "$SVG" -o "$WORK/g.png"
  local half=$(( $1 / 2 ))
  magick -size ${1}x${1} xc:none -fill white -draw "circle $half,$half $half,0" "$WORK/c.png"
  magick "$WORK/c.png" "$WORK/g.png" -gravity center -composite "$2"
}
web_icon 32 web/favicon.png 27
web_icon 192 web/icons/Icon-192.png 163
web_icon 512 web/icons/Icon-512.png 435
web_icon 192 web/icons/Icon-maskable-192.png 111
web_icon 512 web/icons/Icon-maskable-512.png 297

echo "icons regenerated from $SVG"
