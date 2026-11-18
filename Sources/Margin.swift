// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI
import UniformTypeIdentifiers

let mdType = UTType("net.daringfireball.markdown") ?? .plainText

struct MarkdownDoc: FileDocument {
    static var readableContentTypes: [UTType] { [mdType, .plainText] }
    static var writableContentTypes: [UTType] { [mdType] }
    var text = ""
    init() {}
    init(configuration: ReadConfiguration) throws {
        text = String(decoding: configuration.file.regularFileContents ?? Data(), as: UTF8.self)
    }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: Data(text.utf8))
    }
}

// NSTextView with a centered 720pt column (48pt minimum side margins) and optional typewriter scrolling
// (caret line stays vertically centered).
final class TextView: NSTextView {
    var typewriter = false { didSet { updateInsets(); centerCaret() } }

    override func setFrameSize(_ s: NSSize) { super.setFrameSize(s); updateInsets() }

    // Live markdown styling: attributes only, the text itself is never touched.
    // ponytail: restyles the whole document per keystroke, fine for notes, switch to edited-paragraph-only for huge files.
    func highlight() {
        guard let ts = textStorage else { return }
        let base = NSFont(name: "Menlo", size: 16)!
        let fm = NSFontManager.shared
        let bold = fm.convert(base, toHaveTrait: .boldFontMask)
        let italic = fm.convert(base, toHaveTrait: .italicFontMask)
        let faint = NSColor.secondaryLabelColor
        let rules: [(String, [NSAttributedString.Key: Any])] = [
            ("^#{1,6}[ \\t].*$", [.font: fm.convert(bold, toSize: 20)]),
            ("\\*\\*[^*\\n]+\\*\\*|__[^_\\n]+__", [.font: bold]),
            ("(?<![*\\w])[*_][^*_\\n]+[*_](?!\\w)", [.font: italic]),
            ("\\[[^\\]\\n]+\\]\\([^)\\n]+\\)", [.foregroundColor: NSColor.linkColor]),
            ("`[^`\\n]+`", [.foregroundColor: faint, .backgroundColor: NSColor.quaternaryLabelColor]),
            ("^```[\\s\\S]*?^```", [.foregroundColor: faint]),
            ("^>.*$", [.foregroundColor: faint]),
        ]
        let all = NSRange(location: 0, length: ts.length)
        ts.beginEditing()
        ts.setAttributes([.font: base, .paragraphStyle: defaultParagraphStyle as Any, .foregroundColor: NSColor.textColor], range: all)
        for (pattern, attrs) in rules {
            let re = try! NSRegularExpression(pattern: pattern, options: .anchorsMatchLines)
            re.enumerateMatches(in: ts.string, range: all) { m, _, _ in
                if let r = m?.range { ts.addAttributes(attrs, range: r) }
            }
        }
        ts.endEditing()
    }

    func updateInsets() {
        guard let sv = enclosingScrollView else { return }
        let inset = NSSize(width: max(48, (sv.contentSize.width - 720) / 2),
                           height: typewriter ? sv.contentSize.height / 2 : 28)
        if textContainerInset != inset { textContainerInset = inset }
    }

    func centerCaret() {
        guard typewriter, let lm = layoutManager, let sv = enclosingScrollView else { return }
        let n = (string as NSString).length
        let loc = selectedRange().location
        var rect = lm.extraLineFragmentRect // empty doc, or caret after a trailing newline
        if n > 0, !(loc == n && string.hasSuffix("\n")) {
            let g = lm.glyphIndexForCharacter(at: min(loc, n - 1))
            rect = lm.lineFragmentRect(forGlyphAt: g, effectiveRange: nil)
        }
        let y = rect.midY + textContainerInset.height - sv.contentSize.height / 2
        sv.contentView.scroll(to: NSPoint(x: 0, y: max(0, y)))
        sv.reflectScrolledClipView(sv.contentView)
    }
}

struct EditorView: NSViewRepresentable {
    @Binding var text: String
    var typewriter: Bool

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeNSView(context: Context) -> NSScrollView {
        let sv = NSScrollView()
        sv.drawsBackground = false
        sv.hasVerticalScroller = true
        sv.autohidesScrollers = true

        let tv = TextView()
        tv.delegate = context.coordinator
        tv.autoresizingMask = [.width]
        tv.isVerticallyResizable = true
        tv.isHorizontallyResizable = false
        tv.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        tv.textContainer?.widthTracksTextView = true
        tv.drawsBackground = false
        tv.isRichText = false
        tv.allowsUndo = true
        tv.usesFindBar = true
        tv.isContinuousSpellCheckingEnabled = true
        tv.isAutomaticQuoteSubstitutionEnabled = false // keep markdown/code characters literal
        tv.isAutomaticDashSubstitutionEnabled = false
        tv.isAutomaticTextReplacementEnabled = false
        let para = NSMutableParagraphStyle(); para.lineSpacing = 6
        tv.font = NSFont(name: "Menlo", size: 16)
        tv.defaultParagraphStyle = para
        tv.typingAttributes = [.font: tv.font!, .paragraphStyle: para, .foregroundColor: NSColor.textColor]
        sv.documentView = tv
        return sv
    }

    func updateNSView(_ sv: NSScrollView, context: Context) {
        context.coordinator.parent = self
        guard let tv = sv.documentView as? TextView else { return }
        if tv.string != text { tv.string = text; tv.highlight() }
        tv.typewriter = typewriter
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        var parent: EditorView
        init(_ p: EditorView) { parent = p }
        func textDidChange(_ n: Notification) {
            guard let tv = n.object as? TextView else { return }
            parent.text = tv.string
            tv.highlight()
            tv.centerCaret()
        }
        func textViewDidChangeSelection(_ n: Notification) { (n.object as? TextView)?.centerCaret() }
    }
}

// Hide title bar chrome so only the text shows.
struct Chromeless: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let v = NSView()
        DispatchQueue.main.async {
            guard let w = v.window else { return }
            w.titlebarAppearsTransparent = true
            w.titleVisibility = .hidden
            w.styleMask.insert(.fullSizeContentView)
        }
        return v
    }
    func updateNSView(_: NSView, context: Context) {}
}

struct Editor: View {
    @Binding var doc: MarkdownDoc
    @AppStorage("typewriter") private var typewriter = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            EditorView(text: $doc.text, typewriter: typewriter)
            let words = doc.text.split(whereSeparator: \.isWhitespace).count
            Text("\(words) \(words == 1 ? "word" : "words")")
                .font(.caption).monospacedDigit()
                .foregroundStyle(.tertiary)
                .padding(12)
                .allowsHitTesting(false)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(nsColor: .textBackgroundColor))
        .background(Chromeless())
    }
}

// Square window, 90% of the screen's usable height.
let side = (NSScreen.main?.visibleFrame.height ?? 900) * 0.9

@main struct Margin: App {
    @AppStorage("typewriter") private var typewriter = false

    var body: some Scene {
        DocumentGroup(newDocument: MarkdownDoc()) { Editor(doc: $0.$document) }
            .defaultSize(width: side, height: side)
            .commands {
                CommandGroup(after: .toolbar) {
                    Toggle("Typewriter Mode", isOn: $typewriter)
                        .keyboardShortcut("t", modifiers: [.command, .shift])
                }
            }
    }
}
