import Foundation

/// Converts .xlsx files to Markdown tables by parsing the XML inside the ZIP archive.
/// XLSX is a ZIP containing xl/sharedStrings.xml and xl/worksheets/sheet1.xml.
enum XlsxConverter {
    static func convert(_ url: URL) throws -> String {
        // Read shared strings (text values are stored separately in XLSX)
        let sharedStrings: [String]
        if let ssData = try? ZipReader.readFile(at: url, entryName: "xl/sharedStrings.xml") {
            sharedStrings = SharedStringsParser.parse(data: ssData)
        } else {
            sharedStrings = []
        }

        // Read sheet1
        guard let sheetData = try? ZipReader.readFile(at: url, entryName: "xl/worksheets/sheet1.xml") else {
            throw FileConverter.ConversionError.parseFailed("Cannot read sheet1 from .xlsx")
        }

        let rows = SheetParser.parse(data: sheetData, sharedStrings: sharedStrings)
        return rowsToMarkdownTable(rows, title: url.deletingPathExtension().lastPathComponent)
    }

    private static func rowsToMarkdownTable(_ rows: [[String]], title: String) -> String {
        guard !rows.isEmpty else { return "# \(title)\n\n*Empty spreadsheet*\n" }

        var lines = ["# \(title)", ""]

        // Determine column count
        let colCount = rows.map(\.count).max() ?? 0
        guard colCount > 0 else { return "# \(title)\n\n*Empty spreadsheet*\n" }

        // Header row
        let header = rows[0]
        let headerCells = (0..<colCount).map { i in i < header.count ? header[i] : "" }
        lines.append("| " + headerCells.joined(separator: " | ") + " |")
        lines.append("| " + headerCells.map { _ in "---" }.joined(separator: " | ") + " |")

        // Data rows
        for row in rows.dropFirst() {
            let cells = (0..<colCount).map { i in i < row.count ? row[i] : "" }
            lines.append("| " + cells.joined(separator: " | ") + " |")
        }

        lines.append("")
        return lines.joined(separator: "\n")
    }
}

// MARK: - Shared Strings Parser

private class SharedStringsParser: NSObject, XMLParserDelegate {
    private var strings: [String] = []
    private var currentString = ""
    private var inSI = false

    static func parse(data: Data) -> [String] {
        let parser = SharedStringsParser()
        let xmlParser = XMLParser(data: data)
        xmlParser.delegate = parser
        xmlParser.parse()
        return parser.strings
    }

    func parser(_ parser: XMLParser, didStartElement element: String,
                namespaceURI: String?, qualifiedName: String?,
                attributes: [String: String] = [:]) {
        if element == "si" {
            inSI = true
            currentString = ""
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if inSI { currentString += string }
    }

    func parser(_ parser: XMLParser, didEndElement element: String,
                namespaceURI: String?, qualifiedName: String?) {
        if element == "si" {
            strings.append(currentString)
            inSI = false
        }
    }
}

// MARK: - Sheet Parser

private class SheetParser: NSObject, XMLParserDelegate {
    private var rows: [[String]] = []
    private var currentRow: [String] = []
    private var currentValue = ""
    private var cellType = ""
    private var inValue = false
    private let sharedStrings: [String]

    init(sharedStrings: [String]) {
        self.sharedStrings = sharedStrings
    }

    static func parse(data: Data, sharedStrings: [String]) -> [[String]] {
        let parser = SheetParser(sharedStrings: sharedStrings)
        let xmlParser = XMLParser(data: data)
        xmlParser.delegate = parser
        xmlParser.parse()
        return parser.rows
    }

    func parser(_ parser: XMLParser, didStartElement element: String,
                namespaceURI: String?, qualifiedName: String?,
                attributes: [String: String] = [:]) {
        switch element {
        case "row":
            currentRow = []
        case "c":
            cellType = attributes["t"] ?? ""
            currentValue = ""
        case "v":
            inValue = true
            currentValue = ""
        default:
            break
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if inValue { currentValue += string }
    }

    func parser(_ parser: XMLParser, didEndElement element: String,
                namespaceURI: String?, qualifiedName: String?) {
        switch element {
        case "v":
            inValue = false
        case "c":
            if cellType == "s", let idx = Int(currentValue), idx < sharedStrings.count {
                currentRow.append(sharedStrings[idx])
            } else {
                currentRow.append(currentValue)
            }
        case "row":
            if !currentRow.isEmpty { rows.append(currentRow) }
        default:
            break
        }
    }
}
