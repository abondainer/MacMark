import Foundation

/// Converts .docx files to Markdown by parsing the XML inside the ZIP archive.
/// DOCX is a ZIP containing word/document.xml with the content.
enum DocxConverter {
    static func convert(_ url: URL) throws -> String {
        // DOCX is a ZIP file
        guard let archive = try? ZipReader.readFile(at: url, entryName: "word/document.xml") else {
            throw FileConverter.ConversionError.parseFailed("Cannot read document.xml from .docx")
        }

        let parser = DocxXMLParser(data: archive)
        return parser.parse()
    }
}

// MARK: - DOCX XML Parser

private class DocxXMLParser: NSObject, XMLParserDelegate {
    private let data: Data
    private var markdown = ""
    private var currentText = ""
    private var isBold = false
    private var isItalic = false
    private var inParagraph = false
    private var paragraphStyle = ""
    private var listLevel = 0
    private var isListItem = false

    init(data: Data) {
        self.data = data
    }

    func parse() -> String {
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()
        return markdown.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func parser(_ parser: XMLParser, didStartElement element: String,
                namespaceURI: String?, qualifiedName: String?,
                attributes: [String: String] = [:]) {
        switch element {
        case "w:p":
            inParagraph = true
            currentText = ""
            paragraphStyle = ""
            isBold = false
            isItalic = false
            isListItem = false

        case "w:pStyle":
            paragraphStyle = attributes["w:val"] ?? ""

        case "w:b":
            isBold = (attributes["w:val"] ?? "true") != "false"

        case "w:i":
            isItalic = (attributes["w:val"] ?? "true") != "false"

        case "w:numPr":
            isListItem = true

        case "w:ilvl":
            listLevel = Int(attributes["w:val"] ?? "0") ?? 0

        default:
            break
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if inParagraph {
            var text = string
            if isBold { text = "**\(text)**" }
            if isItalic { text = "*\(text)*" }
            currentText += text
        }
    }

    func parser(_ parser: XMLParser, didEndElement element: String,
                namespaceURI: String?, qualifiedName: String?) {
        guard element == "w:p" else { return }

        let trimmed = currentText.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            markdown += "\n"
            return
        }

        // Detect heading styles
        if paragraphStyle.hasPrefix("Heading") || paragraphStyle.hasPrefix("heading") {
            let level = Int(String(paragraphStyle.last ?? "1")) ?? 1
            let prefix = String(repeating: "#", count: min(level, 6))
            markdown += "\(prefix) \(trimmed)\n\n"
        } else if isListItem {
            let indent = String(repeating: "  ", count: listLevel)
            markdown += "\(indent)- \(trimmed)\n"
        } else {
            markdown += "\(trimmed)\n\n"
        }

        inParagraph = false
    }
}
