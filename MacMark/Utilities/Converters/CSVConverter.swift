import Foundation

/// Converts CSV files to Markdown tables.
enum CSVConverter {
    static func convert(_ url: URL) throws -> String {
        let content = try String(contentsOf: url, encoding: .utf8)
        let title = url.deletingPathExtension().lastPathComponent
        let rows = parseCSV(content)

        guard !rows.isEmpty else { return "# \(title)\n\n*Empty file*\n" }

        var lines = ["# \(title)", ""]
        let colCount = rows.map(\.count).max() ?? 0

        // Header
        let header = rows[0]
        let headerCells = (0..<colCount).map { i in i < header.count ? header[i] : "" }
        lines.append("| " + headerCells.joined(separator: " | ") + " |")
        lines.append("| " + headerCells.map { _ in "---" }.joined(separator: " | ") + " |")

        // Data
        for row in rows.dropFirst() {
            let cells = (0..<colCount).map { i in i < row.count ? row[i] : "" }
            lines.append("| " + cells.joined(separator: " | ") + " |")
        }

        return lines.joined(separator: "\n") + "\n"
    }

    private static func parseCSV(_ text: String) -> [[String]] {
        var rows: [[String]] = []
        var currentRow: [String] = []
        var currentField = ""
        var inQuotes = false

        for char in text {
            if inQuotes {
                if char == "\"" {
                    inQuotes = false
                } else {
                    currentField.append(char)
                }
            } else {
                switch char {
                case "\"":
                    inQuotes = true
                case ",":
                    currentRow.append(currentField.trimmingCharacters(in: .whitespaces))
                    currentField = ""
                case "\n", "\r\n":
                    currentRow.append(currentField.trimmingCharacters(in: .whitespaces))
                    if !currentRow.allSatisfy({ $0.isEmpty }) {
                        rows.append(currentRow)
                    }
                    currentRow = []
                    currentField = ""
                default:
                    currentField.append(char)
                }
            }
        }

        // Last field/row
        currentRow.append(currentField.trimmingCharacters(in: .whitespaces))
        if !currentRow.allSatisfy({ $0.isEmpty }) {
            rows.append(currentRow)
        }

        return rows
    }
}
