import SwiftUI
import UniformTypeIdentifiers

struct WelcomeView: View {
    @EnvironmentObject var appState: AppState
    @State private var showConverter = false
    @State private var showFilePicker = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
                .frame(minHeight: 32) // room for hidden title bar

            // App icon and title
            VStack(spacing: 12) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 80, height: 80)

                Text("MacMark")
                    .font(.system(size: 28, weight: .semibold, design: .rounded))

                Text("Read, edit, and convert Markdown files")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer().frame(height: 48)

            // Action cards
            HStack(spacing: 16) {
                WelcomeCard(
                    icon: "doc.text.magnifyingglass",
                    title: "Open Document",
                    subtitle: "Read or edit a Markdown file",
                    color: .blue
                ) {
                    NSDocumentController.shared.openDocument(nil)
                }

                WelcomeCard(
                    icon: "arrow.triangle.2.circlepath.doc.on.clipboard",
                    title: "Prepare for AI",
                    subtitle: "Convert PDF, DOCX, XLSX to Markdown",
                    color: .purple
                ) {
                    showConverter = true
                }
            }
            .padding(.horizontal, 40)

            Spacer().frame(height: 32)

            // Recent files
            RecentFilesSection()

            Spacer()

            // Appearance toggle
            HStack {
                Spacer()
                Button {
                    appState.cycleAppearance()
                } label: {
                    Image(systemName: appState.appearance.icon)
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                        .frame(width: 28, height: 28)
                        .background(.quaternary, in: Circle())
                }
                .buttonStyle(.plain)
                .help("Appearance: \(appState.appearance.label)")
            }
            .padding(16)
        }
        .frame(width: 600, height: 480)
        .background(.background)
        .sheet(isPresented: $showConverter) {
            ConverterSheet()
                .environmentObject(appState)
        }
    }
}

// MARK: - Welcome Card

struct WelcomeCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 28, weight: .light))
                    .foregroundStyle(color)
                    .frame(height: 36)

                Text(title)
                    .font(.headline)
                    .foregroundStyle(.primary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isHovering ? color.opacity(0.06) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(.quaternary, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
    }
}

// MARK: - Recent Files

struct RecentFilesSection: View {
    var body: some View {
        let recentURLs = NSDocumentController.shared.recentDocumentURLs
            .filter { $0.pathExtension.lowercased() == "md" || $0.pathExtension.lowercased() == "markdown" }
            .prefix(3)

        if !recentURLs.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Text("Recent")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal, 44)

                ForEach(Array(recentURLs), id: \.self) { url in
                    Button {
                        NSDocumentController.shared.openDocument(
                            withContentsOf: url, display: true
                        ) { _, _, _ in }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "doc.text")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(url.deletingPathExtension().lastPathComponent)
                                .font(.callout)
                                .foregroundStyle(.primary)
                                .lineLimit(1)
                            Spacer()
                            Text(url.deletingLastPathComponent().lastPathComponent)
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.quaternary.opacity(0.001)) // hit area
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 32)
                }
            }
        }
    }
}
