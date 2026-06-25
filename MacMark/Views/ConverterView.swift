import SwiftUI
import UniformTypeIdentifiers

struct ConverterSheet: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    enum Step {
        case selectFile
        case converting
        case result
    }

    @State private var step: Step = .selectFile
    @State private var inputURL: URL?
    @State private var outputMarkdown: String = ""
    @State private var errorMessage: String?
    @State private var showFilePicker = false
    @State private var showSavePanel = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(headerTitle)
                    .font(.headline)
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
            }
            .padding(20)

            Divider()

            // Content
            Group {
                switch step {
                case .selectFile:
                    selectFileStep
                case .converting:
                    convertingStep
                case .result:
                    resultStep
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 520, height: 420)
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: FileConverter.supportedTypes
        ) { result in
            if case .success(let url) = result {
                convertFile(at: url)
            }
        }
    }

    private var headerTitle: String {
        switch step {
        case .selectFile: return "Prepare for AI"
        case .converting: return "Converting..."
        case .result: return "Conversion Complete"
        }
    }

    // MARK: - Steps

    private var selectFileStep: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "arrow.triangle.2.circlepath.doc.on.clipboard")
                .font(.system(size: 44, weight: .thin))
                .foregroundStyle(.purple)

            Text("Select a file to convert to Markdown")
                .font(.body)
                .foregroundStyle(.secondary)

            Text("Supports PDF, DOCX, XLSX, CSV, JSON, HTML, XML")
                .font(.caption)
                .foregroundStyle(.tertiary)

            Button {
                showFilePicker = true
            } label: {
                Text("Choose File...")
                    .frame(width: 160)
            }
            .controlSize(.large)
            .buttonStyle(.borderedProminent)

            // Drop zone
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(style: StrokeStyle(lineWidth: 1.5, dash: [6]))
                    .foregroundStyle(.quaternary)
                    .frame(height: 60)

                Text("or drop a file here")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 60)
            .onDrop(of: [.fileURL], isTargeted: nil) { providers in
                handleDrop(providers)
            }

            Spacer()
        }
        .padding(20)
    }

    private var convertingStep: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView()
                .scaleEffect(1.2)
            Text("Converting \(inputURL?.lastPathComponent ?? "file")...")
                .font(.callout)
                .foregroundStyle(.secondary)
            Spacer()
        }
    }

    private var resultStep: some View {
        VStack(spacing: 16) {
            if let error = errorMessage {
                Spacer()
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 36))
                    .foregroundStyle(.red)
                Text(error)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Button("Try Another File") {
                    step = .selectFile
                    errorMessage = nil
                }
                .buttonStyle(.borderedProminent)
                Spacer()
            } else {
                // Success
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text(inputURL?.lastPathComponent ?? "")
                        .font(.callout.bold())
                    Image(systemName: "arrow.right")
                        .foregroundStyle(.tertiary)
                    Text("Markdown")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 16)

                // Preview of result
                ScrollView {
                    Text(outputMarkdown.prefix(2000))
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(12)
                }
                .background(Color.gray.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .padding(.horizontal, 20)

                HStack(spacing: 12) {
                    Button("Copy to Clipboard") {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(outputMarkdown, forType: .string)
                    }
                    .buttonStyle(.bordered)

                    Button("Save as .md") {
                        saveMarkdown()
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Open in MacMark") {
                        openInApp()
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.bottom, 20)
            }
        }
    }

    // MARK: - Actions

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        provider.loadItem(forTypeIdentifier: "public.file-url") { item, _ in
            guard let data = item as? Data,
                  let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
            DispatchQueue.main.async { convertFile(at: url) }
        }
        return true
    }

    private func convertFile(at url: URL) {
        inputURL = url
        step = .converting
        errorMessage = nil

        DispatchQueue.global(qos: .userInitiated).async {
            let accessing = url.startAccessingSecurityScopedResource()
            defer { if accessing { url.stopAccessingSecurityScopedResource() } }

            do {
                let md = try FileConverter.convert(fileAt: url)
                DispatchQueue.main.async {
                    outputMarkdown = md
                    step = .result
                }
            } catch {
                DispatchQueue.main.async {
                    errorMessage = error.localizedDescription
                    step = .result
                }
            }
        }
    }

    private func saveMarkdown() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [UTType.markdownText]
        panel.nameFieldStringValue = (inputURL?.deletingPathExtension().lastPathComponent ?? "converted") + ".md"
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            try? outputMarkdown.data(using: .utf8)?.write(to: url)
        }
    }

    private func openInApp() {
        // Create a temp file and open it
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = (inputURL?.deletingPathExtension().lastPathComponent ?? "converted") + ".md"
        let tempURL = tempDir.appendingPathComponent(fileName)
        try? outputMarkdown.data(using: .utf8)?.write(to: tempURL)
        NSDocumentController.shared.openDocument(withContentsOf: tempURL, display: true) { _, _, _ in }
        dismiss()
    }
}
