import Foundation
import Markdown

/// Converts markdown text to styled HTML for preview and export.
enum MarkdownRenderer {

    /// Render markdown as an HTML page with embedded styles supporting light/dark mode.
    static func renderHTML(from markdown: String, darkMode: Bool? = nil) -> String {
        let body = markdownToHTML(markdown)
        return """
        <!DOCTYPE html>
        <html>
        <head>
        <meta charset="utf-8">
        <style>
        \(css(forceDark: darkMode))
        </style>
        </head>
        <body>
        \(body)
        </body>
        </html>
        """
    }

    /// Full standalone HTML for export (includes both themes via media query).
    static func renderFullHTML(from markdown: String) -> String {
        renderHTML(from: markdown, darkMode: nil)
    }

    // MARK: - Markdown → HTML using swift-markdown

    private static func markdownToHTML(_ source: String) -> String {
        let document = Document(parsing: source)
        var visitor = HTMLVisitor()
        let result = visitor.visit(document)

        // Fallback: if the AST visitor produced nothing, render plain text
        if result.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !source.isEmpty {
            return "<pre style=\"white-space:pre-wrap;font-family:inherit;\">"
                + source
                    .replacingOccurrences(of: "&", with: "&amp;")
                    .replacingOccurrences(of: "<", with: "&lt;")
                    .replacingOccurrences(of: ">", with: "&gt;")
                + "</pre>"
        }

        return result
    }

    // MARK: - CSS

    private static func css(forceDark: Bool?) -> String {
        let colorSchemeRule: String
        if let dark = forceDark {
            colorSchemeRule = dark
                ? ":root { --bg: #1e1e1e; --fg: #d4d4d4; --code-bg: #2d2d2d; --border: #444; --link: #6cb6ff; --blockquote: #888; }"
                : ":root { --bg: #ffffff; --fg: #1a1a1a; --code-bg: #f5f5f5; --border: #e0e0e0; --link: #0066cc; --blockquote: #666; }"
        } else {
            colorSchemeRule = """
            :root { --bg: #ffffff; --fg: #1a1a1a; --code-bg: #f5f5f5; --border: #e0e0e0; --link: #0066cc; --blockquote: #666; }
            @media (prefers-color-scheme: dark) {
                :root { --bg: #1e1e1e; --fg: #d4d4d4; --code-bg: #2d2d2d; --border: #444; --link: #6cb6ff; --blockquote: #888; }
            }
            """
        }

        return """
        \(colorSchemeRule)
        * { box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, "SF Pro Text", sans-serif;
            font-size: 15px; line-height: 1.65; color: var(--fg); background: var(--bg);
            max-width: 760px; margin: 0 auto; padding: 24px;
        }
        h1, h2, h3, h4, h5, h6 { margin-top: 1.4em; margin-bottom: 0.5em; font-weight: 600; }
        h1 { font-size: 1.8em; border-bottom: 1px solid var(--border); padding-bottom: 0.3em; }
        h2 { font-size: 1.4em; border-bottom: 1px solid var(--border); padding-bottom: 0.25em; }
        h3 { font-size: 1.15em; }
        code { font-family: "SF Mono", Menlo, monospace; font-size: 0.9em; background: var(--code-bg); padding: 2px 5px; border-radius: 4px; }
        pre { background: var(--code-bg); padding: 14px; border-radius: 8px; overflow-x: auto; }
        pre code { background: none; padding: 0; }
        blockquote { border-left: 3px solid var(--border); margin-left: 0; padding-left: 16px; color: var(--blockquote); }
        a { color: var(--link); text-decoration: none; }
        a:hover { text-decoration: underline; }
        img { max-width: 100%; border-radius: 8px; }
        table { border-collapse: collapse; width: 100%; margin: 1em 0; }
        th, td { border: 1px solid var(--border); padding: 8px 12px; text-align: left; }
        th { background: var(--code-bg); font-weight: 600; }
        hr { border: none; border-top: 1px solid var(--border); margin: 2em 0; }
        ul, ol { padding-left: 1.6em; }
        li { margin: 0.3em 0; }
        """
    }
}

// MARK: - HTML Visitor

/// Walks the swift-markdown AST and emits HTML.
private struct HTMLVisitor {
    private var html = ""

    mutating func visit(_ document: Document) -> String {
        html = ""
        for child in document.children {
            visitNode(child)
        }
        return html
    }

    private mutating func visitNode(_ markup: Markup) {
        switch markup {
        case let heading as Heading:
            let tag = "h\(heading.level)"
            html += "<\(tag)>"
            for child in heading.children { visitNode(child) }
            html += "</\(tag)>\n"

        case let paragraph as Paragraph:
            html += "<p>"
            for child in paragraph.children { visitNode(child) }
            html += "</p>\n"

        case let text as Markdown.Text:
            html += escapeHTML(text.string)

        case let strong as Strong:
            html += "<strong>"
            for child in strong.children { visitNode(child) }
            html += "</strong>"

        case let emphasis as Emphasis:
            html += "<em>"
            for child in emphasis.children { visitNode(child) }
            html += "</em>"

        case let code as InlineCode:
            html += "<code>\(escapeHTML(code.code))</code>"

        case let codeBlock as CodeBlock:
            let lang = codeBlock.language ?? ""
            html += "<pre><code class=\"language-\(lang)\">\(escapeHTML(codeBlock.code))</code></pre>\n"

        case let link as Markdown.Link:
            html += "<a href=\"\(link.destination ?? "")\">"
            for child in link.children { visitNode(child) }
            html += "</a>"

        case let image as Markdown.Image:
            html += "<img src=\"\(image.source ?? "")\" alt=\"\(image.plainText)\">"

        case let list as UnorderedList:
            html += "<ul>\n"
            for child in list.children { visitNode(child) }
            html += "</ul>\n"

        case let list as OrderedList:
            html += "<ol start=\"\(list.startIndex)\">\n"
            for child in list.children { visitNode(child) }
            html += "</ol>\n"

        case let item as ListItem:
            html += "<li>"
            for child in item.children { visitNode(child) }
            html += "</li>\n"

        case is ThematicBreak:
            html += "<hr>\n"

        case let quote as BlockQuote:
            html += "<blockquote>\n"
            for child in quote.children { visitNode(child) }
            html += "</blockquote>\n"

        case let table as Markdown.Table:
            html += "<table>\n"
            html += "<thead><tr>"
            for cell in table.head.cells {
                html += "<th>"
                for child in cell.children { visitNode(child) }
                html += "</th>"
            }
            html += "</tr></thead>\n"
            html += "<tbody>\n"
            for row in table.body.rows {
                html += "<tr>"
                for cell in row.cells {
                    html += "<td>"
                    for child in cell.children { visitNode(child) }
                    html += "</td>"
                }
                html += "</tr>\n"
            }
            html += "</tbody></table>\n"

        case let inlineHTML as InlineHTML:
            html += inlineHTML.rawHTML

        case let htmlBlock as HTMLBlock:
            html += htmlBlock.rawHTML

        case is SoftBreak:
            html += "\n"

        case is LineBreak:
            html += "<br>"

        default:
            // Recurse into children of any unhandled node
            for child in markup.children { visitNode(child) }
        }
    }

    private func escapeHTML(_ string: String) -> String {
        string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }
}
