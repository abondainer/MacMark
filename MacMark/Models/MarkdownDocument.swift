import SwiftUI
import UniformTypeIdentifiers

extension UTType {
    static var markdownText: UTType {
        UTType(importedAs: "net.daringfireball.markdown", conformingTo: .plainText)
    }
}

struct MarkdownDocument: FileDocument {
    var text: String

    static var readableContentTypes: [UTType] {
        [.markdownText, .plainText]
    }

    static var writableContentTypes: [UTType] {
        [.markdownText, .plainText]
    }

    init(text: String = "# New Document\n\nStart writing here...\n") {
        self.text = text
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let string = String(data: data, encoding: .utf8)
        else {
            throw CocoaError(.fileReadCorruptFile)
        }
        text = string
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        guard let data = text.data(using: .utf8) else {
            throw CocoaError(.fileWriteUnknown)
        }
        return FileWrapper(regularFileWithContents: data)
    }
}
