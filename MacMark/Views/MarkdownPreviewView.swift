import SwiftUI
import AppKit

/// Renders markdown as styled HTML using native NSTextView.
/// Avoids WKWebView entirely — no external WebProcess needed, works in sandbox.
struct MarkdownPreviewView: NSViewRepresentable {
    let markdown: String

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        let textView = scrollView.documentView as! NSTextView

        textView.isEditable = false
        textView.isSelectable = true
        textView.textContainerInset = NSSize(width: 24, height: 24)
        textView.drawsBackground = true
        textView.backgroundColor = .textBackgroundColor
        textView.isAutomaticLinkDetectionEnabled = true

        // Allow flexible width
        textView.textContainer?.widthTracksTextView = true
        textView.isHorizontallyResizable = false

        context.coordinator.textView = textView
        context.coordinator.loadMarkdown(markdown)

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        context.coordinator.loadMarkdown(markdown)
    }

    class Coordinator {
        weak var textView: NSTextView?
        private var currentMarkdown: String?

        func loadMarkdown(_ markdown: String) {
            guard markdown != currentMarkdown, let textView = textView else { return }
            currentMarkdown = markdown

            let html = MarkdownRenderer.renderHTML(from: markdown)
            guard let data = html.data(using: .utf8) else { return }

            let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue
            ]

            // Parse HTML on background, apply on main thread
            DispatchQueue.global(qos: .userInitiated).async {
                guard let attrStr = try? NSAttributedString(
                    data: data,
                    options: options,
                    documentAttributes: nil
                ) else { return }

                DispatchQueue.main.async { [weak textView] in
                    textView?.textStorage?.setAttributedString(attrStr)
                }
            }
        }
    }
}
