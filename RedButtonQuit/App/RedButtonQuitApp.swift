import SwiftUI

@main
struct RedButtonQuitApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Menu bar extra - this is our primary (and only) scene
        MenuBarExtra("RedButtonQuit", systemImage: "xmark.circle.fill") {
            AppMenu()
        }
        .menuBarExtraStyle(.menu)

        // Settings window
        Settings {
            PreferencesView()
        }
    }
}
