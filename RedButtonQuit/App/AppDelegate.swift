import AppKit
import Combine

class AppDelegate: NSObject, NSApplicationDelegate {
    private var accessibilityMonitor: AccessibilityMonitor?
    private var windowEventHandler: WindowEventHandler?
    private var appTerminationService: AppTerminationService?
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        #if DEBUG
        print("AppDelegate: applicationDidFinishLaunching started")
        #endif

        // Initialize core services
        setupServices()

        // Check accessibility permission on launch
        checkAccessibilityPermission()

        // Subscribe to preference changes
        setupPreferenceObservers()

        // Show onboarding if needed
        #if DEBUG
        print("AppDelegate: hasCompletedOnboarding = \(PreferencesManager.shared.hasCompletedOnboarding)")
        #endif

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            #if DEBUG
            print("AppDelegate: Checking if onboarding should show...")
            #endif
            OnboardingWindowController.shared.showIfNeeded()
        }

        #if DEBUG
        print("AppDelegate: applicationDidFinishLaunching completed")
        #endif
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Cleanup observers
        accessibilityMonitor?.stopMonitoring()
    }

    // MARK: - Private Methods

    private func setupServices() {
        let terminationService = AppTerminationService()
        let eventHandler = WindowEventHandler(terminationService: terminationService)
        let monitor = AccessibilityMonitor(eventHandler: eventHandler)

        self.appTerminationService = terminationService
        self.windowEventHandler = eventHandler
        self.accessibilityMonitor = monitor
    }

    private func checkAccessibilityPermission() {
        let trusted = AccessibilityMonitor.isAccessibilityEnabled()

        if trusted {
            startMonitoringIfEnabled()
        }
        // Note: We do NOT reset hasCompletedOnboarding when permission is missing.
        // After a rebuild, macOS may not recognize the new code signature even though
        // permission was previously granted. The user can re-grant in System Settings
        // without going through onboarding again.
    }

    private func startMonitoringIfEnabled() {
        guard PreferencesManager.shared.isEnabled else { return }
        guard AccessibilityMonitor.isAccessibilityEnabled() else { return }

        accessibilityMonitor?.startMonitoring()
    }

    private func setupPreferenceObservers() {
        // React to enable/disable changes
        PreferencesManager.shared.$isEnabled
            .dropFirst()
            .sink { [weak self] isEnabled in
                if isEnabled {
                    self?.startMonitoringIfEnabled()
                } else {
                    self?.accessibilityMonitor?.stopMonitoring()
                }
            }
            .store(in: &cancellables)
    }
}
