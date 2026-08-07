import AppKit
import Combine

class AppDelegate: NSObject, NSApplicationDelegate {
    private var accessibilityMonitor: AccessibilityMonitor?
    private var windowEventHandler: WindowEventHandler?
    private var appTerminationService: AppTerminationService?
    private var cancellables = Set<AnyCancellable>()
    private var permissionPollTimer: Timer?

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
        stopPermissionPolling()
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

    /// True when this process is the XCTest host rather than a real launch.
    private var isRunningTests: Bool {
        let env = ProcessInfo.processInfo.environment
        return env["XCTestConfigurationFilePath"] != nil || env["XCTestBundlePath"] != nil
    }

    private func checkAccessibilityPermission() {
        // Never ask during a test run. The prompt adds a TCC row for the test host, which shows
        // up in System Settings under the same name as the real app — users delete the wrong one.
        guard !isRunningTests else { return }

        let trusted = AccessibilityMonitor.isAccessibilityEnabled()

        if trusted {
            startMonitoringIfEnabled()
        } else if CommandLine.arguments.contains(AccessibilityMonitor.permissionRequestArgument) {
            // Relaunched by the user asking to fix permission: register with TCC and take them
            // straight to the pane.
            AccessibilityMonitor.presentAccessibilityRequest()
        } else {
            // Ordinary launch: register and prompt, but never shove System Settings in the
            // user's face at every login.
            AccessibilityMonitor.requestAccessibilityPermission()
        }

        if !trusted {
            startPermissionPolling()
        }
        // Note: We do NOT reset hasCompletedOnboarding when permission is missing.
        // After a rebuild, macOS may not recognize the new code signature even though
        // permission was previously granted. The user can re-grant in System Settings
        // without going through onboarding again.
    }

    /// Watch for the permission being granted in System Settings and start working the moment
    /// it lands. Without this the user flips the toggle, the menu claims "Active", and nothing
    /// actually happens until the next launch.
    private func startPermissionPolling() {
        guard permissionPollTimer == nil else { return }

        let timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            guard AccessibilityMonitor.isAccessibilityEnabled() else { return }
            self?.stopPermissionPolling()
            self?.startMonitoringIfEnabled()
        }
        RunLoop.main.add(timer, forMode: .common)
        permissionPollTimer = timer
    }

    private func stopPermissionPolling() {
        permissionPollTimer?.invalidate()
        permissionPollTimer = nil
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
