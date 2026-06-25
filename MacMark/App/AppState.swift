import SwiftUI
import Combine

final class AppState: ObservableObject {
    enum Appearance: String, CaseIterable {
        case system, light, dark

        var icon: String {
            switch self {
            case .system: return "circle.lefthalf.filled"
            case .light: return "sun.max"
            case .dark: return "moon"
            }
        }

        var label: String {
            switch self {
            case .system: return "Auto"
            case .light: return "Light"
            case .dark: return "Dark"
            }
        }

        var next: Appearance {
            switch self {
            case .system: return .light
            case .light: return .dark
            case .dark: return .system
            }
        }

        var nsAppearance: NSAppearance? {
            switch self {
            case .system: return nil
            case .light: return NSAppearance(named: .aqua)
            case .dark: return NSAppearance(named: .darkAqua)
            }
        }
    }

    @Published var appearance: Appearance
    @Published var editorFontSize: Double

    init() {
        let saved = UserDefaults.standard.string(forKey: "mmAppearance") ?? "system"
        self.appearance = Appearance(rawValue: saved) ?? .system
        self.editorFontSize = UserDefaults.standard.double(forKey: "mmFontSize").clamped(to: 12...22, default: 15)

        // Apply immediately
        NSApp.appearance = self.appearance.nsAppearance
    }

    func cycleAppearance() {
        let next = appearance.next
        UserDefaults.standard.set(next.rawValue, forKey: "mmAppearance")
        NSApp.appearance = next.nsAppearance

        // Force UI update on main thread
        DispatchQueue.main.async { [weak self] in
            self?.appearance = next
            // Refresh all windows to pick up the new appearance
            for window in NSApp.windows {
                window.appearance = next.nsAppearance
                window.invalidateShadow()
            }
        }
    }

    func setFontSize(_ size: Double) {
        editorFontSize = size
        UserDefaults.standard.set(size, forKey: "mmFontSize")
    }
}

private extension Double {
    func clamped(to range: ClosedRange<Double>, default defaultValue: Double) -> Double {
        if self == 0 { return defaultValue }
        return Swift.min(Swift.max(self, range.lowerBound), range.upperBound)
    }
}
