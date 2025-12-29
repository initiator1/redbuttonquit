import SwiftUI

/// The main menu displayed in the menu bar
struct AppMenu: View {
    @ObservedObject private var preferences = PreferencesManager.shared
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        // Header showing status
        Text(statusText)
            .font(.headline)

        Divider()

        // Enable/Disable toggle
        Toggle(isOn: $preferences.isEnabled) {
            Text("Enabled")
        }
        .toggleStyle(.checkbox)

        Divider()

        // Quit Mode submenu
        Menu("Quit Mode") {
            ForEach(PreferencesManager.QuitMode.allCases) { mode in
                Button(action: { preferences.quitMode = mode }) {
                    HStack {
                        Text(mode.displayName)
                        if preferences.quitMode == mode {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        }

        Divider()

        // Quick actions
        Button("Excluded Apps...") {
            openSettings()
        }
        .keyboardShortcut("e", modifiers: .command)

        Divider()

        // Launch at Login
        Toggle(isOn: $preferences.launchAtLogin) {
            Text("Launch at Login")
        }
        .toggleStyle(.checkbox)

        Button("Preferences...") {
            openSettings()
        }
        .keyboardShortcut(",", modifiers: .command)

        Divider()

        // Info section
        Button("About RedButtonQuit") {
            preferences.selectedTab = .about
            openSettings()
        }

        if !AccessibilityMonitor.isAccessibilityEnabled() {
            Button("Grant Accessibility Permission...") {
                AccessibilityMonitor.openAccessibilitySettings()
            }
        }

        Divider()

        Button("Quit RedButtonQuit") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q", modifiers: .command)
    }

    // MARK: - Computed Properties

    private var statusText: String {
        if !AccessibilityMonitor.isAccessibilityEnabled() {
            return "Permission Required"
        }
        return preferences.isEnabled ? "Active" : "Disabled"
    }

}

#Preview {
    AppMenu()
}
