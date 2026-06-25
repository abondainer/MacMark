import SwiftUI

struct DocumentContentView: View {
    @Binding var document: MarkdownDocument
    @EnvironmentObject var appState: AppState
    @State private var isEditing = false

    var body: some View {
        VStack(spacing: 0) {
            if isEditing {
                FormatToolbar(text: $document.text)
                Divider()
                EditorView(text: $document.text, fontSize: appState.editorFontSize)
            } else {
                MarkdownPreviewView(markdown: document.text)
            }
        }
        .toolbar(id: "main") {
            ToolbarItem(id: "mode", placement: .principal) {
                MacMarkModePicker(isEditing: $isEditing)
            }
            ToolbarItem(id: "appearance", placement: .automatic) {
                MacMarkAppearanceButton(appState: appState)
            }
            ToolbarItem(id: "export", placement: .automatic) {
                MacMarkExportMenu(text: document.text)
            }
        }
        .frame(minWidth: 600, minHeight: 400)
        .onReceive(NotificationCenter.default.publisher(for: .exportPDF)) { _ in
            exportPDF()
        }
        .onReceive(NotificationCenter.default.publisher(for: .exportHTML)) { _ in
            exportHTML()
        }
    }

    private func exportPDF() {
        let html = MarkdownRenderer.renderHTML(from: document.text, darkMode: false)
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.pdf]
        panel.nameFieldStringValue = "document.pdf"
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            HTMLExporter.exportPDF(html: html, to: url)
        }
    }

    private func exportHTML() {
        let html = MarkdownRenderer.renderFullHTML(from: document.text)
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.html]
        panel.nameFieldStringValue = "document.html"
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            try? html.data(using: .utf8)?.write(to: url)
        }
    }
}

// MARK: - Mode Picker (standalone view to avoid re-render issues)

struct MacMarkModePicker: View {
    @Binding var isEditing: Bool

    private let emerald = Color(red: 0.18, green: 0.69, blue: 0.47)

    var body: some View {
        Picker("Mode", selection: $isEditing) {
            Label("Read", systemImage: "book").tag(false)
            Label("Edit", systemImage: "pencil").tag(true)
        }
        .pickerStyle(.segmented)
        .frame(width: 180)
        .colorMultiply(isEditing ? emerald : emerald)
    }
}

// MARK: - Appearance Button (standalone)

struct MacMarkAppearanceButton: View {
    @ObservedObject var appState: AppState

    var body: some View {
        Button {
            appState.cycleAppearance()
        } label: {
            Image(systemName: appState.appearance.icon)
        }
        .help("Appearance: \(appState.appearance.label)")
    }
}

// MARK: - Export Menu (standalone)

struct MacMarkExportMenu: View {
    let text: String

    var body: some View {
        Menu {
            Button("Export as PDF") {
                NotificationCenter.default.post(name: .exportPDF, object: nil)
            }
            Button("Export as HTML") {
                NotificationCenter.default.post(name: .exportHTML, object: nil)
            }
            Divider()
            Button("Copy Raw Markdown") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(text, forType: .string)
            }
        } label: {
            Image(systemName: "square.and.arrow.up")
        }
        .help("Share & Export")
    }
}

// MARK: - Formatting Toolbar

struct FormatToolbar: View {
    @Binding var text: String

    var body: some View {
        HStack(spacing: 4) {
            Menu {
                Button("Heading 1") { append("\n# ") }
                Button("Heading 2") { append("\n## ") }
                Button("Heading 3") { append("\n### ") }
            } label: {
                Text("H")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
            }
            .menuStyle(.borderlessButton)
            .frame(width: 32)

            Divider().frame(height: 18)

            Button("B") { wrap("**") }
                .font(.system(size: 13, weight: .bold))
                .help("Bold")

            Button("I") { wrap("*") }
                .font(.system(size: 13, weight: .regular, design: .serif))
                .help("Italic")

            Divider().frame(height: 18)

            Button { append("\n> ") } label: {
                Image(systemName: "text.quote")
            }.help("Quote")

            Button { wrap("`") } label: {
                Image(systemName: "chevron.left.forwardslash.chevron.right")
            }.help("Code")

            Button { append("\n- ") } label: {
                Image(systemName: "list.bullet")
            }.help("List")

            Button { append("\n[link](url)") } label: {
                Image(systemName: "link")
            }.help("Link")

            Spacer()
        }
        .buttonStyle(.borderless)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.bar)
    }

    private func wrap(_ w: String) { text += "\(w)text\(w)" }
    private func append(_ s: String) { text += s }
}
