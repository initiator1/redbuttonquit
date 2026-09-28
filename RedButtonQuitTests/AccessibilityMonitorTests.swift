import XCTest
@testable import RedButtonQuit

final class AccessibilityMonitorTests: XCTestCase {

    func testObservationFilterAcceptsRegularApplicationBundle() {
        XCTAssertTrue(AccessibilityMonitor.isEligibleForObservation(
            activationPolicy: .regular,
            bundleURL: URL(fileURLWithPath: "/Applications/Example.app"),
            executableURL: URL(fileURLWithPath: "/Applications/Example.app/Contents/MacOS/Example"),
            packageType: "APPL"
        ))
    }

    func testObservationFilterRejectsNonRegularProcesses() {
        for policy in [NSApplication.ActivationPolicy.accessory, .prohibited] {
            XCTAssertFalse(AccessibilityMonitor.isEligibleForObservation(
                activationPolicy: policy,
                bundleURL: URL(fileURLWithPath: "/Applications/Example.app"),
                executableURL: URL(fileURLWithPath: "/Applications/Example.app/Contents/MacOS/Example"),
                packageType: "APPL"
            ))
        }
    }

    func testObservationFilterRejectsExtensionAndXPCBundleLocations() {
        let locations = [
            "/System/Library/ExtensionKit/Extensions/Settings.appex",
            "/Applications/Example.app/Contents/PlugIns/Widget.appex",
            "/System/Library/Frameworks/AppKit.framework/XPCServices/Panel.xpc"
        ]

        for path in locations {
            XCTAssertFalse(AccessibilityMonitor.isEligibleForObservation(
                activationPolicy: .regular,
                bundleURL: URL(fileURLWithPath: path),
                executableURL: URL(fileURLWithPath: path + "/Contents/MacOS/Helper"),
                packageType: "APPL"
            ), "Should reject helper bundle at \(path)")
        }
    }

    func testObservationFilterRejectsNonApplicationPackageAndFrameworkExecutable() {
        XCTAssertFalse(AccessibilityMonitor.isEligibleForObservation(
            activationPolicy: .regular,
            bundleURL: URL(fileURLWithPath: "/Applications/Example.app"),
            executableURL: URL(fileURLWithPath: "/Applications/Example.app/Contents/MacOS/Example"),
            packageType: "XPC!"
        ))
        XCTAssertFalse(AccessibilityMonitor.isEligibleForObservation(
            activationPolicy: .regular,
            bundleURL: URL(fileURLWithPath: "/Applications/Example.app"),
            executableURL: URL(fileURLWithPath: "/System/Library/Frameworks/WebKit.framework/XPCServices/WebContent.xpc/Contents/MacOS/WebContent"),
            packageType: "APPL"
        ))
        XCTAssertFalse(AccessibilityMonitor.isEligibleForObservation(
            activationPolicy: .regular,
            bundleURL: nil,
            executableURL: nil,
            packageType: nil
        ))
    }

    // MARK: - Permission Check Tests

    func testTestHostStaysOutOfAccessibilityByDefault() throws {
        try XCTSkipIf(AccessibilityMonitor.liveAccessibilityTestsEnabled, "Live Accessibility run")
        XCTAssertTrue(AccessibilityMonitor.isHostedByXcode)
        XCTAssertFalse(AccessibilityMonitor.isAccessibilityEnabled())
    }

    // MARK: - Window Type Detection Tests
    // Note: These tests require running apps and accessibility permission

    func testGetWindowCountForFinderReturnsNonNegative() throws {
        try XCTSkipUnless(
            AccessibilityMonitor.liveAccessibilityTestsEnabled,
            "Set TEST_RUNNER_RBQ_LIVE_AX_TESTS=1 to run against real Accessibility"
        )
        guard AccessibilityMonitor.isAccessibilityEnabled() else {
            throw XCTSkip("Accessibility permission not granted")
        }

        guard let finder = NSRunningApplication.runningApplications(
            withBundleIdentifier: "com.apple.finder"
        ).first else {
            XCTFail("Finder should be running")
            return
        }

        // Create a temporary monitor for testing
        let handler = WindowEventHandler(terminationService: AppTerminationService())
        let monitor = AccessibilityMonitor(eventHandler: handler)

        let windowCount = monitor.getWindowCount(for: finder)

        XCTAssertGreaterThanOrEqual(
            windowCount,
            0,
            "Window count should be non-negative"
        )
    }

    func testFullscreenReplacementCountsAsUserFacingWindow() {
        let snapshot = WindowInspector.AppWindowSnapshot(
            accessibilityStandardWindowCount: 0,
            onScreenWindowCount: 1
        )

        XCTAssertTrue(snapshot.hasUserFacingWindows)
        XCTAssertFalse(snapshot.canProveNoUserFacingWindows)
    }

    func testUnavailableWindowAPIStateCannotProveLastWindowClosed() {
        let snapshot = WindowInspector.AppWindowSnapshot(
            accessibilityStandardWindowCount: nil,
            onScreenWindowCount: 0
        )

        XCTAssertFalse(snapshot.canProveNoUserFacingWindows)
    }

    func testOnlyConfirmedZeroWindowCountsProveLastWindowClosed() {
        let snapshot = WindowInspector.AppWindowSnapshot(
            accessibilityStandardWindowCount: 0,
            onScreenWindowCount: 0
        )

        XCTAssertTrue(snapshot.canProveNoUserFacingWindows)
    }

    func testDestroyedWindowIsRemovedFromSnapshotBeforeCancellationDecision() {
        let snapshot = WindowInspector.AppWindowSnapshot(
            accessibilityStandardWindowCount: 1,
            onScreenWindowCount: 1
        )

        XCTAssertTrue(snapshot.canProveNoOtherUserFacingWindows(afterDestroying: .standard))
    }

    func testOtherWindowsPreventMeaningfulCancellationRecord() {
        let snapshot = WindowInspector.AppWindowSnapshot(
            accessibilityStandardWindowCount: 2,
            onScreenWindowCount: 2
        )

        XCTAssertFalse(snapshot.canProveNoOtherUserFacingWindows(afterDestroying: .standard))
    }

    func testUnavailableWindowSnapshotDoesNotRecordCancellation() {
        let snapshot = WindowInspector.AppWindowSnapshot(
            accessibilityStandardWindowCount: nil,
            onScreenWindowCount: 0
        )

        XCTAssertFalse(snapshot.canProveNoOtherUserFacingWindows(afterDestroying: .standard))
    }

    func testOtherAXWindowCancelsFullscreenReplacementQuit() {
        XCTAssertTrue(WindowInspector.WindowElementKind.standard.isWindow)
        XCTAssertTrue(WindowInspector.WindowElementKind.otherWindow.isWindow)
        XCTAssertFalse(WindowInspector.WindowElementKind.nonWindow.isWindow)
        XCTAssertFalse(WindowInspector.WindowElementKind.unknown.isWindow)
    }

    func testCoreGraphicsLayerZeroWindowIsUserFacing() {
        let ownerPID = pid_t(4242)
        let window: [String: Any] = [
            kCGWindowOwnerPID as String: NSNumber(value: ownerPID),
            kCGWindowLayer as String: NSNumber(value: 0),
            kCGWindowIsOnscreen as String: NSNumber(value: true),
            kCGWindowAlpha as String: NSNumber(value: 1.0),
            kCGWindowBounds as String: [
                "Width": NSNumber(value: 1496),
                "Height": NSNumber(value: 967)
            ]
        ]

        XCTAssertTrue(
            WindowInspector.isUserFacingOnScreenWindow(window, ownerPID: ownerPID)
        )
    }

    func testCoreGraphicsOverlayIsNotUserFacing() {
        let ownerPID = pid_t(4242)
        let window: [String: Any] = [
            kCGWindowOwnerPID as String: NSNumber(value: ownerPID),
            kCGWindowLayer as String: NSNumber(value: 8),
            kCGWindowIsOnscreen as String: NSNumber(value: true),
            kCGWindowAlpha as String: NSNumber(value: 1.0),
            kCGWindowBounds as String: [
                "Width": NSNumber(value: 483),
                "Height": NSNumber(value: 84)
            ]
        ]

        XCTAssertFalse(
            WindowInspector.isUserFacingOnScreenWindow(window, ownerPID: ownerPID)
        )
    }
}
