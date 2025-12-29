import XCTest
@testable import RedButtonQuit

final class AppTerminationServiceTests: XCTestCase {
    var sut: AppTerminationService!

    override func setUpWithError() throws {
        sut = AppTerminationService()
    }

    override func tearDownWithError() throws {
        sut = nil
    }

    // MARK: - canTerminate Tests

    func testCanTerminateReturnsFalseForFinder() {
        // Create a mock or find Finder
        guard let finder = NSRunningApplication.runningApplications(
            withBundleIdentifier: "com.apple.finder"
        ).first else {
            XCTFail("Finder should be running")
            return
        }

        XCTAssertFalse(
            sut.canTerminate(finder),
            "Should not be able to terminate Finder"
        )
    }

    func testCanTerminateReturnsFalseForDock() {
        guard let dock = NSRunningApplication.runningApplications(
            withBundleIdentifier: "com.apple.dock"
        ).first else {
            XCTFail("Dock should be running")
            return
        }

        XCTAssertFalse(
            sut.canTerminate(dock),
            "Should not be able to terminate Dock"
        )
    }

    func testCanTerminateReturnsFalseForSystemPreferences() {
        // System Preferences may not be running, so this is a conditional test
        if let systemPrefs = NSRunningApplication.runningApplications(
            withBundleIdentifier: "com.apple.systempreferences"
        ).first {
            XCTAssertFalse(
                sut.canTerminate(systemPrefs),
                "Should not be able to terminate System Preferences"
            )
        }
    }

    // MARK: - Protected Apps List Tests

    func testProtectedAppsListIsNotEmpty() {
        XCTAssertFalse(
            PreferencesManager.systemProtectedApps.isEmpty,
            "Protected apps list should not be empty"
        )
    }

    func testProtectedAppsListContainsExpectedApps() {
        let expectedApps = [
            "com.apple.finder",
            "com.apple.dock",
            "com.apple.systemuiserver",
            "com.apple.systempreferences"
        ]

        for app in expectedApps {
            XCTAssertTrue(
                PreferencesManager.systemProtectedApps.contains(app),
                "\(app) should be in protected apps list"
            )
        }
    }
}
