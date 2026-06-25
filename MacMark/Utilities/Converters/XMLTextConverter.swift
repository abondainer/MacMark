import Foundation

/// Converts XML files to Markdown with code block formatting.
enum XMLTextConverter {
    static func convert(_ url: URL) throws -> String {
        let content = try String(contentsOf: url, encoding: .utf8)
        let title = url.deletingPathExtension().lastPathComponent
        return "# \(title)\n\n```xml\n\(content)\n```\n"
    }
}
