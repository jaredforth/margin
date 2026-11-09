#!/bin/sh
# Regenerates assets/AppIcon.icns from assets/logo.svg (macOS built-ins only).
set -e
cd "$(dirname "$0")"
T=$(mktemp -d); S="$T/AppIcon.iconset"; mkdir "$S"
swift svg2png.swift logo.svg "$T/logo.svg.png"
for n in 16 32 128 256 512; do
  sips -z $n $n "$T/logo.svg.png" --out "$S/icon_${n}x${n}.png" >/dev/null
  sips -z $((n*2)) $((n*2)) "$T/logo.svg.png" --out "$S/icon_${n}x${n}@2x.png" >/dev/null
done
iconutil -c icns "$S" -o AppIcon.icns
rm -rf "$T"
