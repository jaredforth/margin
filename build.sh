#!/bin/sh
# Builds MDEditor.app (no Xcode needed). Run: ./build.sh && open MDEditor.app
set -e
cd "$(dirname "$0")"
rm -rf MDEditor.app
mkdir -p MDEditor.app/Contents/MacOS
swiftc -O -parse-as-library Sources/MDEditor.swift -o MDEditor.app/Contents/MacOS/MDEditor
cp Info.plist MDEditor.app/Contents/
mkdir -p MDEditor.app/Contents/Resources
cp assets/AppIcon.icns MDEditor.app/Contents/Resources/
