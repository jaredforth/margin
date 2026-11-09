<p align="center"><img src="assets/logo.svg" width="128" alt="MDEditor logo"></p>

# MDEditor

A minimal, distraction-free markdown editor for macOS. Just you and the text.

- Plain-text markdown editing in a single full-width column, no toolbar, no preview, no title bar.
- **Word count**, quietly in the corner.
- **Typewriter mode** (View → Typewriter Mode, `⇧⌘T`) keeps the line you're writing vertically centered.
- Open, save, autosave, versions and recent files, like any Mac document app.

## Build

Needs macOS 14+ and the Swift toolchain (Xcode or just the Command Line Tools). No Xcode project, no dependencies.

```sh
./build.sh && open MDEditor.app
```

To open a file: `open -a MDEditor.app notes.md`.

The app icon is generated from `assets/logo.svg` with `assets/make-icon.sh`.

## License

[GPL-3.0-or-later](LICENSE). Derivative works must be released under the same license.
