import XCTest
@testable import RedButtonQuit

final class AccessibilityMonitorTests: XCTestCase {

    // MARK: - Permission Check Tests

    func testIsAccessibilityEnabledReturnsBoolean() {
        // This test verifies the method doesn't crash and returns a boolean
        let result = AccessibilityMonitor.isAccessibilityEnabled()

        // Result should be either true or false
        XCTAssertTrue(result == true || result == false)
    }

    // MARK: - Window Type Detection Tests
    // Note: These tests require running apps and accessibility permission

    func testGetWindowCountForFinderReturnsNonNegative() throws {
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
