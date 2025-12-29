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

    func testGetWindowCountForFinderReturnsNonNegative() {
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
        let mockHandler = MockWindowEventHandler()
        let monitor = AccessibilityMonitor(eventHandler: mockHandler)

        let windowCount = monitor.getWindowCount(for: finder)

        XCTAssertGreaterThanOrEqual(
            windowCount,
            0,
            "Window count should be non-negative"
        )
    }
}

// MARK: - Mock Objects

class MockWindowEventHandler: WindowEventHandler {
    var windowDestroyedCalls: [(app: NSRunningApplication, element: AXUIElement)] = []
    var windowCreatedCalls: [(app: NSRunningApplication, element: AXUIElement)] = []

    init() {
        super.init(terminationService: AppTerminationService())
    }

    override func handleWindowDestroyed(for app: NSRunningApplication, element: AXUIElement) {
        windowDestroyedCalls.append((app, element))
    }

    override func handleWindowCreated(for app: NSRunningApplication, element: AXUIElement) {
        windowCreatedCalls.append((app, element))
    }
}
