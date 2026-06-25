import Foundation
import UniformTypeIdentifiers

/// Converts various file formats to Markdown, inspired by Microsoft's markitdown.
/// All conversions are native Swift — no external dependencies.
enum FileConverter {

    static let supportedTypes: [UTType] = [
        .pdf, .html,
        UTType("org.openxmlformats.wordprocessingml.document") ?? .data,  // .docx
        UTType("org.openxmlformats.spreadsheetml.sheet") ?? .data,        // .xlsx
        .commaSeparatedText, .json, .plainText, .xml
    ]

    enum ConversionError: LocalizedError {
        case unsupportedFormat(String)
        case readFailed
        case parseFailed(String)

        var errorDescription: String? {
            switch self {
            case .unsupportedFormat(let ext): return "Unsupported format: .\(ext)"
            case .readFailed: return "Could not read file"
            case .parseFailed(let msg): return "Parse failed: \(msg)"
            }
        }
    }

    static func convert(fileAt url: URL) throws -> String {
        let ext = url.pathExtension.lowercased()

        switch ext {
        case "pdf":
            return try PDFConverter.convert(url)
        case "docx":
            return try DocxConverter.convert(url)
        case "xlsx":
            return try XlsxConverter.convert(url)
        case "html", "htm":
            return try HTMLConverter.convert(url)
        case "csv":
            return try CSVConverter.convert(url)
        case "json":
            return try JSONConverter.convert(url)
        case "txt", "text":
            return try String(contentsOf: url, encoding: .utf8)
        case "xml":
            return try XMLTextConverter.convert(url)
        default:
            throw ConversionError.unsupportedFormat(ext)
        }
    }
}
