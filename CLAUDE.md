# CLAUDE.md

## Keeping this file current

Update this file in the same change whenever you add or change commands, structure, conventions, or decisions that a future session needs. Remove entries that are no longer true.

## Project

Minimal, distraction-free macOS markdown editor, open source under GPL-3.0-or-later. SwiftUI `DocumentGroup` wrapping an `NSTextView`: plain-text editing, no preview, no toolbar, hidden title bar, full-width text with 48pt side margins. Open/save/autosave/recents come free from `DocumentGroup`.

Features: word count (bottom-right, faint) and typewriter mode (View menu, `⇧⌘T`, persisted via `@AppStorage("typewriter")`; keeps the caret line vertically centered by padding the text view with half the window height and scrolling on selection change).

- `Sources/MDEditor.swift` — the whole app (document type, `TextView`, `EditorView`, chromeless window hook, `Editor`, `App`).
- `Info.plist` — registers the app as a Markdown editor, sets the icon.
- `build.sh` — builds `MDEditor.app` with `swiftc` (only Command Line Tools installed, no Xcode, so no `.xcodeproj`).
- `assets/logo.svg` — logo source. `assets/make-icon.sh` (uses `assets/svg2png.swift`) regenerates the committed `assets/AppIcon.icns`.
- `LICENSE` (GPL-3.0 text), `README.md`.

## Commands

- Build and run: `./build.sh && open MDEditor.app`
- Open a file: `open -a MDEditor.app file.md`
- Regenerate icon after editing the logo: `./assets/make-icon.sh`

## Conventions

- Keep it minimal: no extra UI, settings, or dependencies unless asked.
- `swiftc` needs `-parse-as-library` because of `@main`.
- Source files carry `// SPDX-License-Identifier: GPL-3.0-or-later`; no copyright holder name is written anywhere yet.
- Databricks: follow the global rules in `~/.claude/CLAUDE.md` (SQL warehouse, external tables only).
