import SwiftUI

@main
struct MacMarkApp: App {
    @StateObject private var appState = AppState()
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Welcome window
        WindowGroup("MacMark", id: "welcome") {
            WelcomeView()
                .environmentObject(appState)
        }
        .windowStyle(.hiddenTitleBar)
        .defaultSize(width: 600, height: 480)
        .windowResizability(.contentSize)

        // Document windows (open as tabs)
        DocumentGroup(newDocument: MarkdownDocument()) { file in
            DocumentContentView(document: file.$document)
                .environmentObject(appState)
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Document") {
                    NSDocumentController.shared.newDocument(nil)
                }
                .keyboardShortcut("n")

                Button("Open...") {
                    NSDocumentController.shared.openDocument(nil)
                }
                .keyboardShortcut("o")
            }

            CommandMenu("Export") {
                Button("Export as PDF...") {
                    NotificationCenter.default.post(name: .exportPDF, object: nil)
                }
                .keyboardShortcut("e", modifiers: [.command])

                Button("Export as HTML...") {
                    NotificationCenter.default.post(name: .exportHTML, object: nil)
                }
                .keyboardShortcut("e", modifiers: [.command, .shift])
            }
        }

        Settings {
            SettingsView()
                .environmentObject(appState)
        }
    }
}

// MARK: - App Delegate

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillFinishLaunching(_ notification: Notification) {
        // Force tab behavior BEFORE any window opens
        NSWindow.allowsAutomaticWindowTabbing = true
        UserDefaults.standard.set("always", forKey: "AppleWindowTabbingMode")
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Merge all existing document windows into tabs
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.mergeWindowsIntoTabs()
        }
    }

    private func mergeWindowsIntoTabs() {
        // Find all document windows and tab them together
        let windows = NSApp.windows.filter { window in
            window.isVisible && window.tabbingMode != .disallowed
        }

        guard let first = windows.first else { return }
        for window in windows.dropFirst() {
            first.addTabbedWindow(window, ordered: .above)
        }
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let exportPDF = Notification.Name("exportPDF")
    static let exportHTML = Notification.Name("exportHTML")
}
