#!/bin/sh
# Builds Margin.app (no Xcode needed). Run: ./build.sh && open Margin.app
set -e
cd "$(dirname "$0")"
rm -rf Margin.app
mkdir -p Margin.app/Contents/MacOS
for a in arm64 x86_64; do swiftc -O -parse-as-library -target $a-apple-macos14.0 Sources/Margin.swift -o "$TMPDIR/Margin-$a"; done
lipo -create "$TMPDIR"/Margin-arm64 "$TMPDIR"/Margin-x86_64 -output Margin.app/Contents/MacOS/Margin
cp Info.plist Margin.app/Contents/
mkdir -p Margin.app/Contents/Resources
cp assets/AppIcon.icns Margin.app/Contents/Resources/
codesign --force --deep -s - Margin.app # ad-hoc: no Developer ID, so Gatekeeper still prompts on first open
