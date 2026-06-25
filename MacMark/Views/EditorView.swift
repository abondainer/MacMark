import SwiftUI
import AppKit

struct EditorView: NSViewRepresentable {
    @Binding var text: String
    var fontSize: Double

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        let textView = scrollView.documentView as! NSTextView

        textView.isEditable = true
        textView.isSelectable = true
        textView.allowsUndo = true
        textView.isRichText = false
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.usesFindPanel = true
        textView.isIncrementalSearchingEnabled = true

        textView.font = NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        textView.textColor = NSColor.labelColor
        textView.backgroundColor = NSColor.textBackgroundColor
        textView.insertionPointColor = NSColor.controlAccentColor

        textView.textContainerInset = NSSize(width: 16, height: 16)
        textView.autoresizingMask = [.width]
        textView.isHorizontallyResizable = false
        textView.isVerticallyResizable = true
        textView.textContainer?.widthTracksTextView = true

        textView.delegate = context.coordinator
        textView.string = text

        context.coordinator.applyHighlighting(to: textView)

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }

        if textView.string != text {
            let selectedRanges = textView.selectedRanges
            textView.string = text
            textView.selectedRanges = selectedRanges
            context.coordinator.applyHighlighting(to: textView)
        }

        let newFont = NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)
        if textView.font != newFont {
            textView.font = newFont
            context.coordinator.applyHighlighting(to: textView)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: EditorView
        private var isUpdating = false

        init(_ parent: EditorView) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard !isUpdating, let textView = notification.object as? NSTextView else { return }
            isUpdating = true
            parent.text = textView.string
            applyHighlighting(to: textView)
            isUpdating = false
        }

        func applyHighlighting(to textView: NSTextView) {
            let text = textView.string
            let fullRange = NSRange(location: 0, length: (text as NSString).length)
            let storage = textView.textStorage!
            let fontSize = parent.fontSize

            storage.beginEditing()

            // Reset to default
            storage.addAttribute(.font, value: NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular), range: fullRange)
            storage.addAttribute(.foregroundColor, value: NSColor.labelColor, range: fullRange)

            let patterns: [(pattern: String, color: NSColor, font: NSFont?)] = [
                // Headers
                ("^#{1,6}\\s+.*$", .systemBlue, NSFont.monospacedSystemFont(ofSize: fontSize, weight: .bold)),
                // Bold
                ("\\*\\*[^*]+\\*\\*", .labelColor, NSFont.monospacedSystemFont(ofSize: fontSize, weight: .bold)),
                // Italic
                ("(?<!\\*)\\*[^*]+\\*(?!\\*)", .labelColor, NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)),
                // Code blocks
                ("```[\\s\\S]*?```", .systemOrange, NSFont.monospacedSystemFont(ofSize: fontSize, weight: .regular)),
                // Inline code
                ("`[^`]+`", .systemOrange, nil),
                // Links
                ("\\[([^\\]]+)\\]\\(([^)]+)\\)", .systemPurple, nil),
                // Lists
                ("^\\s*[-*+]\\s", .systemGreen, nil),
                // Numbered lists
                ("^\\s*\\d+\\.\\s", .systemGreen, nil),
                // Blockquotes
                ("^>\\s+.*$", .systemGray, nil),
                // Horizontal rule
                ("^(---+|\\*\\*\\*+|___+)\\s*$", .systemGray, nil),
            ]

            for (pattern, color, font) in patterns {
                guard let regex = try? NSRegularExpression(pattern: pattern, options: [.anchorsMatchLines]) else { continue }
                let matches = regex.matches(in: text, range: fullRange)
                for match in matches {
                    storage.addAttribute(.foregroundColor, value: color, range: match.range)
                    if let font = font {
                        storage.addAttribute(.font, value: font, range: match.range)
                    }
                }
            }

            storage.endEditing()
        }
    }
}
