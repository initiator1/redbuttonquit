import AppKit
import ApplicationServices

/// Handles window events and determines whether to quit applications
final class WindowEventHandler {
    // MARK: - Properties

    private let terminationService: AppTerminationService
    private var pendingQuitTokens: [pid_t: UUID] = [:]

    private enum Constants {
        static let windowReplacementGracePeriod: TimeInterval = 1.0
    }

    // MARK: - Initialization

    init(terminationService: AppTerminationService) {
        self.terminationService = terminationService
    }

    // MARK: - Public Methods

    /// Handle a window being destroyed
    func handleWindowDestroyed(for app: NSRunningApplication, element: AXUIElement) {
        // Check if globally enabled
        guard PreferencesManager.shared.isEnabled else { return }

        // Get bundle identifier
        guard let bundleID = app.bundleIdentifier else { return }

        // Check if app is excluded
        guard !PreferencesManager.shared.isExcluded(bundleIdentifier: bundleID) else { return }

        // Check quit mode
        let mode = PreferencesManager.shared.quitMode

        switch mode {
        case .anyWindow:
            // Quit on any real window close, but allow fullscreen/window-mode
            // transitions to recreate their window first.
            scheduleQuitAfterWindowReplacementGracePeriod(for: app, mode: mode)

        case .lastWindow:
            // Only quit if this was the last window after transient
            // fullscreen/window-mode replacements have had time to settle.
            scheduleQuitAfterWindowReplacementGracePeriod(for: app, mode: mode)
        }
    }

    /// Handle a window being created
    func handleWindowCreated(for app: NSRunningApplication, element: AXUIElement) {
        if isStandardWindow(element) {
            cancelPendingQuitCheck(for: app)
        }

        // Track window creation for potential undo feature
        // Currently just logging for debugging
        #if DEBUG
        print("Window created for: \(app.localizedName ?? "unknown")")
        #endif
    }

    // MARK: - Private Methods

    private func scheduleQuitAfterWindowReplacementGracePeriod(
        for app: NSRunningApplication,
        mode: PreferencesManager.QuitMode
    ) {
        let pid = app.processIdentifier
        let token = UUID()
        pendingQuitTokens[pid] = token

        DispatchQueue.main.asyncAfter(deadline: .now() + Constants.windowReplacementGracePeriod) { [weak self] in
            guard let self else { return }
            guard self.pendingQuitTokens[pid] == token else { return }
            self.pendingQuitTokens[pid] = nil

            switch mode {
            case .anyWindow:
                self.quitApp(app)

            case .lastWindow:
                self.checkAndQuitIfLastWindow(app)
            }
        }
    }

    private func cancelPendingQuitCheck(for app: NSRunningApplication) {
        let pid = app.processIdentifier
        pendingQuitTokens[pid] = nil
    }

    private func checkAndQuitIfLastWindow(_ app: NSRunningApplication) {
        // Get current window count
        let windowCount = getWindowCount(for: app)

        #if DEBUG
        print("Window count for \(app.localizedName ?? "unknown"): \(windowCount)")
        #endif

        // If no windows left, quit the app
        if windowCount == 0 {
            quitApp(app)
        }
    }

    private func quitApp(_ app: NSRunningApplication) {
        guard let bundleID = app.bundleIdentifier else { return }

        #if DEBUG
        print("Quitting app: \(app.localizedName ?? bundleID)")
        #endif

        terminationService.terminateApp(app) { result in
            switch result {
            case .success:
                #if DEBUG
                print("Successfully quit: \(app.localizedName ?? bundleID)")
                #endif

                // Play sound if enabled
                if PreferencesManager.shared.playSound {
                    NSSound(named: .init("Funk"))?.play()
                }

            case .failure(let error):
                #if DEBUG
                print("Failed to quit \(app.localizedName ?? bundleID): \(error)")
                #endif
            }
        }
    }

    private func getWindowCount(for app: NSRunningApplication) -> Int {
        let appElement = AXUIElementCreateApplication(app.processIdentifier)

        var windowsRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(
            appElement,
            kAXWindowsAttribute as CFString,
            &windowsRef
        )

        guard result == .success,
              let windows = windowsRef as? [AXUIElement] else {
            return 0
        }

        // Filter to standard windows only
        return windows.filter { isStandardWindow($0) }.count
    }

    private func isStandardWindow(_ element: AXUIElement) -> Bool {
        var roleRef: CFTypeRef?
        let roleResult = AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &roleRef)

        guard roleResult == .success,
              let role = roleRef as? String,
              role == kAXWindowRole as String else {
            return false
        }

        var subroleRef: CFTypeRef?
        let subroleResult = AXUIElementCopyAttributeValue(element, kAXSubroleAttribute as CFString, &subroleRef)

        if subroleResult == .success, let subrole = subroleRef as? String {
            // Only count standard windows
            return subrole == kAXStandardWindowSubrole as String
        }

        return true
    }
}
