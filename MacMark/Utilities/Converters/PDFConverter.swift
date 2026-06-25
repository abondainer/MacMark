import Foundation
import PDFKit

/// Extracts text from PDF files and converts to Markdown.
enum PDFConverter {
    static func convert(_ url: URL) throws -> String {
        guard let document = PDFDocument(url: url) else {
            throw FileConverter.ConversionError.readFailed
        }

        let title = url.deletingPathExtension().lastPathComponent
        var lines = ["# \(title)", ""]

        for i in 0..<document.pageCount {
            guard let page = document.page(at: i) else { continue }
            guard let text = page.string else { continue }

            if document.pageCount > 1 {
                lines.append("---")
                lines.append("")
                lines.append("<!-- Page \(i + 1) -->")
                lines.append("")
            }

            // Clean up text: normalize whitespace, preserve paragraph breaks
            let paragraphs = text
                .components(separatedBy: "\n\n")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }

            for paragraph in paragraphs {
                let cleaned = paragraph
                    .replacingOccurrences(of: "\n", with: " ")
                    .replacingOccurrences(of: "  +", with: " ", options: .regularExpression)
                lines.append(cleaned)
                lines.append("")
            }
        }

        return lines.joined(separator: "\n")
    }
}
