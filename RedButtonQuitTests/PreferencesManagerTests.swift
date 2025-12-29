import XCTest
@testable import RedButtonQuit

final class PreferencesManagerTests: XCTestCase {
    var sut: PreferencesManager!

    override func setUpWithError() throws {
        // Clear UserDefaults before each test
        let defaults = UserDefaults.standard
        defaults.removePersistentDomain(forName: Bundle.main.bundleIdentifier ?? "com.redbuttonquit.app")
        defaults.synchronize()

        sut = PreferencesManager.shared
    }

    override func tearDownWithError() throws {
        sut.resetToDefaults()
    }

    // MARK: - Default Values Tests

    func testDefaultIsEnabled() {
        XCTAssertTrue(sut.isEnabled, "App should be enabled by default")
    }

    func testDefaultQuitMode() {
        XCTAssertEqual(sut.quitMode, .lastWindow, "Default quit mode should be lastWindow")
    }

    func testDefaultLaunchAtLogin() {
        XCTAssertFalse(sut.launchAtLogin, "Launch at login should be disabled by default")
    }

    func testDefaultShowMenuBarIcon() {
        XCTAssertTrue(sut.showMenuBarIcon, "Menu bar icon should be shown by default")
    }

    func testDefaultPlaySound() {
        XCTAssertFalse(sut.playSound, "Sound should be disabled by default")
    }

    func testDefaultHasCompletedOnboarding() {
        XCTAssertFalse(sut.hasCompletedOnboarding, "Onboarding should not be completed by default")
    }

    // MARK: - System Protected Apps Tests

    func testSystemProtectedAppsContainsFinder() {
        XCTAssertTrue(
            PreferencesManager.systemProtectedApps.contains("com.apple.finder"),
            "Finder should be in protected apps"
        )
    }

    func testSystemProtectedAppsContainsDock() {
        XCTAssertTrue(
            PreferencesManager.systemProtectedApps.contains("com.apple.dock"),
            "Dock should be in protected apps"
        )
    }

    func testSystemProtectedAppsContainsSystemPreferences() {
        XCTAssertTrue(
            PreferencesManager.systemProtectedApps.contains("com.apple.systempreferences"),
            "System Preferences should be in protected apps"
        )
    }

    // MARK: - Exclusion List Tests

    func testIsExcludedReturnsTrueForSystemApps() {
        XCTAssertTrue(
            sut.isExcluded(bundleIdentifier: "com.apple.finder"),
            "Finder should be excluded"
        )
    }

    func testIsExcludedReturnsFalseForRegularApps() {
        XCTAssertFalse(
            sut.isExcluded(bundleIdentifier: "com.example.testapp"),
            "Regular apps should not be excluded by default"
        )
    }

    func testAddExclusion() {
        let testBundleID = "com.example.testapp"

        sut.addExclusion(testBundleID)

        XCTAssertTrue(
            sut.isExcluded(bundleIdentifier: testBundleID),
            "Added app should be excluded"
        )
    }

    func testRemoveExclusion() {
        let testBundleID = "com.example.testapp"
        sut.addExclusion(testBundleID)

        sut.removeExclusion(testBundleID)

        XCTAssertFalse(
            sut.isExcluded(bundleIdentifier: testBundleID),
            "Removed app should not be excluded"
        )
    }

    func testCannotRemoveSystemProtectedApp() {
        let finderBundleID = "com.apple.finder"

        sut.removeExclusion(finderBundleID)

        XCTAssertTrue(
            sut.isExcluded(bundleIdentifier: finderBundleID),
            "System protected apps should not be removable"
        )
    }

    // MARK: - Quit Mode Tests

    func testQuitModeLastWindowDisplayName() {
        XCTAssertEqual(
            PreferencesManager.QuitMode.lastWindow.displayName,
            "Quit on Last Window Close"
        )
    }

    func testQuitModeAnyWindowDisplayName() {
        XCTAssertEqual(
            PreferencesManager.QuitMode.anyWindow.displayName,
            "Quit on Any Window Close"
        )
    }

    func testSetQuitMode() {
        sut.quitMode = .anyWindow

        XCTAssertEqual(sut.quitMode, .anyWindow)
    }

    // MARK: - Reset Tests

    func testResetToDefaults() {
        // Modify settings
        sut.isEnabled = false
        sut.quitMode = .anyWindow
        sut.launchAtLogin = true
        sut.addExclusion("com.example.testapp")

        // Reset
        sut.resetToDefaults()

        // Verify defaults restored
        XCTAssertTrue(sut.isEnabled)
        XCTAssertEqual(sut.quitMode, .lastWindow)
        XCTAssertFalse(sut.launchAtLogin)
        XCTAssertFalse(sut.isExcluded(bundleIdentifier: "com.example.testapp"))
    }

    // MARK: - Persistence Tests

    func testIsEnabledPersists() {
        sut.isEnabled = false

        let persistedValue = UserDefaults.standard.bool(forKey: "com.redbuttonquit.isEnabled")

        XCTAssertFalse(persistedValue, "isEnabled should persist to UserDefaults")
    }

    func testQuitModePersists() {
        sut.quitMode = .anyWindow

        let persistedValue = UserDefaults.standard.string(forKey: "com.redbuttonquit.quitMode")

        XCTAssertEqual(persistedValue, "anyWindow", "quitMode should persist to UserDefaults")
    }
}
