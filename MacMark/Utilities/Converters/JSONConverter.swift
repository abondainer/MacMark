import Foundation

/// Converts JSON files to Markdown with code block formatting.
enum JSONConverter {
    static func convert(_ url: URL) throws -> String {
        let data = try Data(contentsOf: url)
        let title = url.deletingPathExtension().lastPathComponent

        // Pretty-print the JSON
        let json = try JSONSerialization.jsonObject(with: data)
        let prettyData = try JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted, .sortedKeys])
        let prettyJSON = String(data: prettyData, encoding: .utf8) ?? ""

        return "# \(title)\n\n```json\n\(prettyJSON)\n```\n"
    }
}
