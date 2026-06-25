import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Form {
            Section("Appearance") {
                HStack(spacing: 12) {
                    ForEach(AppState.Appearance.allCases, id: \.self) { mode in
                        Button {
                            appState.cycleAppearance()
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: mode.icon)
                                    .font(.title3)
                                Text(mode.label)
                                    .font(.caption)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(
                                appState.appearance == mode
                                    ? Color.accentColor.opacity(0.15)
                                    : Color.clear,
                                in: RoundedRectangle(cornerRadius: 8)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(
                                        appState.appearance == mode
                                            ? Color.accentColor
                                            : Color.clear,
                                        lineWidth: 1
                                    )
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Section("Editor") {
                HStack {
                    Text("Font Size")
                    Slider(value: Binding(
                        get: { appState.editorFontSize },
                        set: { appState.setFontSize($0) }
                    ), in: 12...22, step: 1)
                    Text("\(Int(appState.editorFontSize))")
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                        .frame(width: 24)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 380, height: 200)
    }
}
