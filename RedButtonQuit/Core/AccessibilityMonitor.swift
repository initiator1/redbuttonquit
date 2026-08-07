import AppKit
import ApplicationServices
import Combine

/// Monitors window events across all applications using the Accessibility API
final class AccessibilityMonitor {
    // MARK: - Types

    /// Represents an observer for a specific application
    private struct AppObserver {
        let pid: pid_t
        let observer: AXObserver
        let element: AXUIElement
    }

    // MARK: - Properties

    private weak var eventHandler: WindowEventHandler?
    private var appObservers: [pid_t: AppObserver] = [:]
    private var workspaceObservers: [NSObjectProtocol] = []
    private var isMonitoring = false

    // MARK: - Initialization

    init(eventHandler: WindowEventHandler) {
        self.eventHandler = eventHandler
    }

    deinit {
        stopMonitoring()
    }

    // MARK: - Static Methods

    /// Check if accessibility permission is granted
    /// Uses actual API test instead of AXIsProcessTrusted() which can return stale cached results
    static func isAccessibilityEnabled() -> Bool {
        // First try the real functionality test - this is the most reliable
        if isAccessibilityActuallyWorking() {
            return true
        }
        // Fall back to system check (may be stale but better than nothing)
        return AXIsProcessTrusted()
    }

    /// Tests actual accessibility functionality by attempting to query Finder's UI elements
    /// This provides real-time verification instead of relying on cached AXIsProcessTrusted() results
    static func isAccessibilityActuallyWorking() -> Bool {
        // Get Finder process - it's always running on macOS
        guard let finder = NSRunningApplication.runningApplications(
            withBundleIdentifier: "com.apple.finder"
        ).first else {
            #if DEBUG
            print("AccessibilityMonitor: Finder not found, falling back to AXIsProcessTrusted")
            #endif
            return AXIsProcessTrusted()
        }

        let finderPID = finder.processIdentifier
        guard finderPID > 0 else {
            return AXIsProcessTrusted()
        }

        // Create AXUIElement for Finder and try to read its attributes
        // This will fail if accessibility permission is not granted
        let finderElement = AXUIElementCreateApplication(finderPID)

        // Try to read attribute names - this is a lightweight operation
        // that requires actual accessibility permission to succeed
        var attributeNames: CFArray?
        let result = AXUIElementCopyAttributeNames(finderElement, &attributeNames)

        #if DEBUG
        if result == .success {
            print("AccessibilityMonitor: Real AX test PASSED (queried Finder attributes)")
        } else {
            print("AccessibilityMonitor: Real AX test FAILED with error: \(result.rawValue)")
        }
        #endif

        // .success means we have permission
        // .apiDisabled or .cannotComplete means permission denied
        return result == .success
    }

    /// Prompt user for accessibility permission
    static func requestAccessibilityPermission() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }

    /// Open System Settings to Accessibility pane
    static func openAccessibilitySettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else {
            return
        }
        NSWorkspace.shared.open(url)
    }

    /// Launch argument telling a relaunched instance to walk the user through granting permission.
    static let permissionRequestArgument = "--request-accessibility"

    /// Re-register with TCC, then open the Accessibility pane.
    ///
    /// Opening the pane on its own strands the user whenever the app has no row in the
    /// Accessibility list — deleted by hand, or dropped when a rebuild changed the signature.
    /// The trusted-check call is what recreates the row, so it has to run first.
    static func presentAccessibilityRequest() {
        requestAccessibilityPermission()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            openAccessibilitySettings()
        }
    }

    /// The single recovery path offered to the user: relaunch, then request permission.
    ///
    /// macOS pins a process's accessibility verdict for its lifetime, so an app that lost its
    /// entry while running can never recover in place — asking again from the same process is
    /// silently ignored. Relaunching first makes one action work from every state, which is why
    /// the UI offers no separate "restart" choice.
    static func beginPermissionRecovery() {
        let bundlePath = Bundle.main.bundlePath
        let pid = ProcessInfo.processInfo.processIdentifier

        // Wait for this process to actually exit before relaunching. `open` would otherwise
        // just reactivate the dying instance and leave the user with no app at all.
        let script = """
        for _ in $(seq 1 50); do
            kill -0 \(pid) 2>/dev/null || break
            sleep 0.1
        done
        /usr/bin/open -n "\(bundlePath)" --args \(permissionRequestArgument)
        """

        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/sh")
        task.arguments = ["-c", script]
        try? task.run()

        NSApplication.shared.terminate(nil)
    }

    // MARK: - Public Methods

    /// Start monitoring window events for all applications
    func startMonitoring() {
        guard !isMonitoring else { return }
        guard Self.isAccessibilityEnabled() else {
            #if DEBUG
            print("Accessibility permission not granted")
            #endif
            return
        }

        isMonitoring = true

        // Create observers for all currently running apps
        for app in NSWorkspace.shared.runningApplications {
            guard app.activationPolicy == .regular else { continue }
            createObserver(for: app)
        }

        // Subscribe to app launch/terminate notifications
        setupWorkspaceObservers()
    }

    /// Stop all monitoring
    func stopMonitoring() {
        guard isMonitoring else { return }
        isMonitoring = false

        // Remove all app observers
        for (_, appObserver) in appObservers {
            removeObserver(appObserver)
        }
        appObservers.removeAll()

        // Remove workspace observers
        for observer in workspaceObservers {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
        workspaceObservers.removeAll()
    }

    // MARK: - Private Methods

    private func setupWorkspaceObservers() {
        let center = NSWorkspace.shared.notificationCenter

        // App launched
        let launchObserver = center.addObserver(
            forName: NSWorkspace.didLaunchApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else {
                return
            }
            self?.createObserver(for: app)
        }
        workspaceObservers.append(launchObserver)

        // App terminated
        let terminateObserver = center.addObserver(
            forName: NSWorkspace.didTerminateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else {
                return
            }
            self?.removeObserver(for: app.processIdentifier)
        }
        workspaceObservers.append(terminateObserver)
    }

    private func createObserver(for app: NSRunningApplication) {
        let pid = app.processIdentifier
        guard pid > 0 else { return }
        guard appObservers[pid] == nil else { return }

        // Skip our own app
        if app.bundleIdentifier == Bundle.main.bundleIdentifier { return }

        // Create AXUIElement for the application
        let appElement = AXUIElementCreateApplication(pid)

        // Create observer
        var observer: AXObserver?
        let result = AXObserverCreate(pid, accessibilityCallback, &observer)

        guard result == .success, let observer = observer else {
            #if DEBUG
            print("Failed to create observer for \(app.localizedName ?? "unknown"): \(result)")
            #endif
            return
        }

        // Store context pointer for callback
        let context = Unmanaged.passUnretained(self).toOpaque()

        // Register for notifications
        let notifications: [String] = [
            kAXUIElementDestroyedNotification as String,
            kAXWindowCreatedNotification as String
        ]

        for notification in notifications {
            AXObserverAddNotification(observer, appElement, notification as CFString, context)
        }

        // Add to run loop
        CFRunLoopAddSource(
            CFRunLoopGetMain(),
            AXObserverGetRunLoopSource(observer),
            .defaultMode
        )

        // Store observer
        appObservers[pid] = AppObserver(pid: pid, observer: observer, element: appElement)
    }

    private func removeObserver(for pid: pid_t) {
        guard let appObserver = appObservers.removeValue(forKey: pid) else { return }
        removeObserver(appObserver)
    }

    private func removeObserver(_ appObserver: AppObserver) {
        // Remove from run loop
        CFRunLoopRemoveSource(
            CFRunLoopGetMain(),
            AXObserverGetRunLoopSource(appObserver.observer),
            .defaultMode
        )

        // Remove notifications
        let notifications: [String] = [
            kAXUIElementDestroyedNotification as String,
            kAXWindowCreatedNotification as String
        ]

        for notification in notifications {
            AXObserverRemoveNotification(
                appObserver.observer,
                appObserver.element,
                notification as CFString
            )
        }
    }

    // MARK: - Callback Handling

    fileprivate func handleNotification(
        _ notification: String,
        element: AXUIElement,
        pid: pid_t
    ) {
        // Ensure we're on the main thread
        dispatchPrecondition(condition: .onQueue(.main))

        // Find the running application
        guard let app = NSRunningApplication(processIdentifier: pid) else {
            #if DEBUG
            print("AccessibilityMonitor: Could not find app for PID \(pid)")
            #endif
            return
        }

        guard let handler = eventHandler else {
            #if DEBUG
            print("AccessibilityMonitor: eventHandler is nil, ignoring notification")
            #endif
            return
        }

        switch notification {
        case String(kAXUIElementDestroyedNotification):
            handler.handleWindowDestroyed(for: app, element: element)

        case String(kAXWindowCreatedNotification):
            handler.handleWindowCreated(for: app, element: element)

        default:
            break
        }
    }

    /// Get the current window count for an application
    func getWindowCount(for app: NSRunningApplication) -> Int {
        WindowInspector.snapshot(for: app).accessibilityStandardWindowCount ?? 0
    }

    /// Check if an AXUIElement is a standard window
    func isStandardWindow(_ element: AXUIElement) -> Bool {
        WindowInspector.isStandardWindow(element)
    }
}

// MARK: - C Callback

private func accessibilityCallback(
    observer: AXObserver,
    element: AXUIElement,
    notification: CFString,
    context: UnsafeMutableRawPointer?
) {
    guard let context = context else { return }

    let monitor = Unmanaged<AccessibilityMonitor>.fromOpaque(context).takeUnretainedValue()

    // Get the PID from the element synchronously before async dispatch
    var pid: pid_t = 0
    AXUIElementGetPid(element, &pid)

    // Capture notification as String before async
    let notificationName = notification as String

    DispatchQueue.main.async { [weak monitor] in
        monitor?.handleNotification(notificationName, element: element, pid: pid)
    }
}
