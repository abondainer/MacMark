import Foundation

/// Converts HTML files to Markdown.
enum HTMLConverter {
    static func convert(_ url: URL) throws -> String {
        let html = try String(contentsOf: url, encoding: .utf8)
        return htmlToMarkdown(html)
    }

    static func htmlToMarkdown(_ html: String) -> String {
        var text = html

        // Remove script and style blocks
        text = text.replacingOccurrences(of: "<script[^>]*>[\\s\\S]*?</script>", with: "", options: .regularExpression)
        text = text.replacingOccurrences(of: "<style[^>]*>[\\s\\S]*?</style>", with: "", options: .regularExpression)

        // Convert headings
        for level in 1...6 {
            let prefix = String(repeating: "#", count: level)
            text = text.replacingOccurrences(
                of: "<h\(level)[^>]*>(.*?)</h\(level)>",
                with: "\n\(prefix) $1\n",
                options: [.regularExpression, .caseInsensitive]
            )
        }

        // Convert common elements
        let replacements: [(String, String)] = [
            ("<br\\s*/?>", "\n"),
            ("<p[^>]*>(.*?)</p>", "\n$1\n"),
            ("<strong[^>]*>(.*?)</strong>", "**$1**"),
            ("<b[^>]*>(.*?)</b>", "**$1**"),
            ("<em[^>]*>(.*?)</em>", "*$1*"),
            ("<i[^>]*>(.*?)</i>", "*$1*"),
            ("<code[^>]*>(.*?)</code>", "`$1`"),
            ("<a[^>]*href=\"([^\"]+)\"[^>]*>(.*?)</a>", "[$2]($1)"),
            ("<li[^>]*>(.*?)</li>", "- $1"),
            ("<hr[^>]*/?>", "\n---\n"),
            ("<blockquote[^>]*>(.*?)</blockquote>", "> $1"),
        ]

        for (pattern, replacement) in replacements {
            text = text.replacingOccurrences(of: pattern, with: replacement,
                                            options: [.regularExpression, .caseInsensitive])
        }

        // Strip remaining HTML tags
        text = text.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)

        // Decode HTML entities
        text = text
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&lt;", with: "<")
            .replacingOccurrences(of: "&gt;", with: ">")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&nbsp;", with: " ")

        // Clean up excessive blank lines
        text = text.replacingOccurrences(of: "\n{3,}", with: "\n\n", options: .regularExpression)

        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
