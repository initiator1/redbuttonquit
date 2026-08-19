import SwiftUI

/// The main menu displayed in the menu bar
struct AppMenu: View {
    @ObservedObject private var preferences = PreferencesManager.shared
    @ObservedObject private var history = QuitHistoryStore.shared
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

        if preferences.recordHistory {
            Menu("Recent") {
                if recentEvents.isEmpty {
                    Button("No quits recorded yet") {}
                        .disabled(true)
                } else {
                    ForEach(recentEvents) { event in
                        Button(recentText(for: event)) {}
                            .disabled(true)
                    }
                }

                Divider()

                Button("Open History…") {
                    preferences.selectedTab = .history
                    openSettings()
                }
            }
        }

        Divider()

        // Quick actions
        Button("Excluded Apps...") {
            preferences.selectedTab = .exclusions
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
                AccessibilityMonitor.beginPermissionRecovery()
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

    private var recentEvents: [QuitEvent] {
        Array(history.events.filter {
            [.quit, .stillRunning, .failed].contains($0.outcome)
        }.prefix(10))
    }

    private func recentText(for event: QuitEvent) -> String {
        switch event.outcome {
        case .quit:
            return "\(event.appName) — \(recentDate(event.date))"
        case .stillRunning:
            return "\(event.appName) — still running"
        case .failed:
            return "\(event.appName) — failed"
        case .pending, .cancelled, .skippedExcluded:
            return event.appName
        }
    }

    private func recentDate(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) {
            return date.formatted(date: .omitted, time: .shortened)
        }
        return date.formatted(date: .abbreviated, time: .shortened)
    }

}

#Preview {
    AppMenu()
}
