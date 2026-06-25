import Cocoa
import QuickLookUI
import WebKit
import Markdown

class PreviewViewController: NSViewController, QLPreviewingController {

    private var webView: WKWebView!

    override func loadView() {
        webView = WKWebView()
        webView.setValue(false, forKey: "drawsBackground")
        self.view = webView
    }

    func preparePreviewOfFile(at url: URL) async throws {
        let text = try String(contentsOf: url, encoding: .utf8)
        let html = renderHTML(from: text)
        await MainActor.run {
            webView.loadHTMLString(html, baseURL: nil)
        }
    }

    // MARK: - Lightweight Markdown → HTML

    private func renderHTML(from markdown: String) -> String {
        let document = Document(parsing: markdown)
        var visitor = QuickLookHTMLVisitor()
        let body = visitor.visit(document)

        return """
        <!DOCTYPE html>
        <html>
        <head>
        <meta charset="utf-8">
        <style>
        :root { --bg: #fff; --fg: #1a1a1a; --code-bg: #f5f5f5; --border: #e0e0e0; --link: #0066cc; }
        @media (prefers-color-scheme: dark) {
            :root { --bg: #1e1e1e; --fg: #d4d4d4; --code-bg: #2d2d2d; --border: #444; --link: #6cb6ff; }
        }
        body {
            font-family: -apple-system, BlinkMacSystemFont, sans-serif;
            font-size: 14px; line-height: 1.6; color: var(--fg); background: var(--bg);
            max-width: 700px; margin: 0 auto; padding: 20px;
        }
        h1,h2,h3 { margin-top: 1.2em; }
        h1 { font-size: 1.6em; border-bottom: 1px solid var(--border); padding-bottom: 0.2em; }
        h2 { font-size: 1.3em; }
        code { font-family: "SF Mono", Menlo, monospace; font-size: 0.88em; background: var(--code-bg); padding: 1px 4px; border-radius: 3px; }
        pre { background: var(--code-bg); padding: 12px; border-radius: 6px; overflow-x: auto; }
        pre code { background: none; padding: 0; }
        blockquote { border-left: 3px solid var(--border); margin-left: 0; padding-left: 14px; color: #888; }
        a { color: var(--link); }
        table { border-collapse: collapse; width: 100%; }
        th, td { border: 1px solid var(--border); padding: 6px 10px; }
        th { background: var(--code-bg); }
        img { max-width: 100%; }
        </style>
        </head>
        <body>\(body)</body>
        </html>
        """
    }
}

// MARK: - Minimal HTML Visitor for QuickLook

private struct QuickLookHTMLVisitor {
    private var html = ""

    mutating func visit(_ document: Document) -> String {
        html = ""
        for child in document.children { node(child) }
        return html
    }

    private mutating func node(_ markup: Markup) {
        switch markup {
        case let h as Heading:
            let t = "h\(h.level)"
            html += "<\(t)>"; for c in h.children { node(c) }; html += "</\(t)>"
        case let p as Paragraph:
            html += "<p>"; for c in p.children { node(c) }; html += "</p>"
        case let t as Markdown.Text:
            html += esc(t.string)
        case let s as Strong:
            html += "<strong>"; for c in s.children { node(c) }; html += "</strong>"
        case let e as Emphasis:
            html += "<em>"; for c in e.children { node(c) }; html += "</em>"
        case let c as InlineCode:
            html += "<code>\(esc(c.code))</code>"
        case let cb as CodeBlock:
            html += "<pre><code>\(esc(cb.code))</code></pre>"
        case let l as Markdown.Link:
            html += "<a href=\"\(l.destination ?? "")\">"
            for c in l.children { node(c) }
            html += "</a>"
        case let ul as UnorderedList:
            html += "<ul>"; for c in ul.children { node(c) }; html += "</ul>"
        case let ol as OrderedList:
            html += "<ol>"; for c in ol.children { node(c) }; html += "</ol>"
        case let li as ListItem:
            html += "<li>"; for c in li.children { node(c) }; html += "</li>"
        case is ThematicBreak:
            html += "<hr>"
        case let bq as BlockQuote:
            html += "<blockquote>"; for c in bq.children { node(c) }; html += "</blockquote>"
        case let t as Markdown.Table:
            html += "<table><thead><tr>"
            for cell in t.head.cells { html += "<th>"; for c in cell.children { node(c) }; html += "</th>" }
            html += "</tr></thead><tbody>"
            for row in t.body.rows {
                html += "<tr>"
                for cell in row.cells { html += "<td>"; for c in cell.children { node(c) }; html += "</td>" }
                html += "</tr>"
            }
            html += "</tbody></table>"
        case is SoftBreak:
            html += "\n"
        case is LineBreak:
            html += "<br>"
        default:
            for c in markup.children { node(c) }
        }
    }

    private func esc(_ s: String) -> String {
        s.replacingOccurrences(of: "&", with: "&amp;")
         .replacingOccurrences(of: "<", with: "&lt;")
         .replacingOccurrences(of: ">", with: "&gt;")
    }
}
