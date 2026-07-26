import Foundation
import Combine
import ServiceManagement

/// Manages all user preferences for RedButtonQuit
final class PreferencesManager: ObservableObject {
    static let shared = PreferencesManager(
        userDefaults: .standard,
        managesLoginItem: true
    )

    private let userDefaults: UserDefaults
    private let managesLoginItem: Bool

    // MARK: - UserDefaults Keys

    private enum Keys {
        static let isEnabled = "com.redbuttonquit.isEnabled"
        static let quitMode = "com.redbuttonquit.quitMode"
        static let excludedBundleIDs = "com.redbuttonquit.excludedBundleIDs"
        static let launchAtLogin = "com.redbuttonquit.launchAtLogin"
        static let playSound = "com.redbuttonquit.playSound"
        static let hasCompletedOnboarding = "com.redbuttonquit.hasCompletedOnboarding"
    }

    // MARK: - Preferences Tab

    enum PreferencesTab: String, CaseIterable, Identifiable {
        case general
        case exclusions
        case about

        var id: String { rawValue }
    }

    // MARK: - Quit Mode

    enum QuitMode: String, CaseIterable, Identifiable {
        case lastWindow = "lastWindow"
        case anyWindow = "anyWindow"

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .lastWindow: return "Quit on Last Window Close"
            case .anyWindow: return "Quit on Any Window Close"
            }
        }

        var description: String {
            switch self {
            case .lastWindow: return "Only quit when the last window is closed"
            case .anyWindow: return "Quit whenever any window is closed"
            }
        }
    }

    // MARK: - Published Properties

    @Published var isEnabled: Bool {
        didSet { userDefaults.set(isEnabled, forKey: Keys.isEnabled) }
    }

    @Published var quitMode: QuitMode {
        didSet { userDefaults.set(quitMode.rawValue, forKey: Keys.quitMode) }
    }

    @Published var excludedBundleIDs: Set<String> {
        didSet {
            userDefaults.set(Array(excludedBundleIDs), forKey: Keys.excludedBundleIDs)
        }
    }

    @Published var launchAtLogin: Bool {
        didSet {
            userDefaults.set(launchAtLogin, forKey: Keys.launchAtLogin)
            if managesLoginItem {
                updateLoginItem()
            }
        }
    }

    @Published var playSound: Bool {
        didSet { userDefaults.set(playSound, forKey: Keys.playSound) }
    }

    @Published var hasCompletedOnboarding: Bool {
        didSet { userDefaults.set(hasCompletedOnboarding, forKey: Keys.hasCompletedOnboarding) }
    }

    /// Currently selected tab in Preferences (runtime state, not persisted)
    @Published var selectedTab: PreferencesTab = .general

    // MARK: - Default Excluded Apps

    /// System apps that should never be quit
    static let systemProtectedApps: Set<String> = [
        "com.apple.finder",
        "com.apple.dock",
        "com.apple.systemuiserver",
        "com.apple.systempreferences",
        "com.apple.ActivityMonitor",
        "com.apple.SecurityAgent",
        "com.apple.loginwindow",
        "com.apple.Spotlight"
    ]

    // MARK: - Initialization

    init(userDefaults: UserDefaults, managesLoginItem: Bool) {
        self.userDefaults = userDefaults
        self.managesLoginItem = managesLoginItem

        // Register defaults
        let defaultExcluded = Array(Self.systemProtectedApps)
        userDefaults.register(defaults: [
            Keys.isEnabled: true,
            Keys.quitMode: QuitMode.lastWindow.rawValue,
            Keys.excludedBundleIDs: defaultExcluded,
            Keys.launchAtLogin: false,
            Keys.playSound: false,
            Keys.hasCompletedOnboarding: false
        ])

        // Load values
        self.isEnabled = userDefaults.bool(forKey: Keys.isEnabled)

        let modeRaw = userDefaults.string(forKey: Keys.quitMode) ?? QuitMode.lastWindow.rawValue
        self.quitMode = QuitMode(rawValue: modeRaw) ?? .lastWindow

        let excludedArray = userDefaults.stringArray(forKey: Keys.excludedBundleIDs) ?? defaultExcluded
        self.excludedBundleIDs = Set(excludedArray)

        self.launchAtLogin = userDefaults.bool(forKey: Keys.launchAtLogin)
        self.playSound = userDefaults.bool(forKey: Keys.playSound)
        self.hasCompletedOnboarding = userDefaults.bool(forKey: Keys.hasCompletedOnboarding)
    }

    // MARK: - Public Methods

    /// Check if an app is excluded from auto-quit behavior
    func isExcluded(bundleIdentifier: String) -> Bool {
        return excludedBundleIDs.contains(bundleIdentifier) ||
               Self.systemProtectedApps.contains(bundleIdentifier)
    }

    /// Add an app to the exclusion list
    func addExclusion(_ bundleIdentifier: String) {
        excludedBundleIDs.insert(bundleIdentifier)
    }

    /// Remove an app from the exclusion list
    func removeExclusion(_ bundleIdentifier: String) {
        // Don't allow removing system protected apps
        guard !Self.systemProtectedApps.contains(bundleIdentifier) else { return }
        excludedBundleIDs.remove(bundleIdentifier)
    }

    /// Reset all preferences to defaults
    func resetToDefaults() {
        isEnabled = true
        quitMode = .lastWindow
        excludedBundleIDs = Self.systemProtectedApps
        launchAtLogin = false
        playSound = false
    }

    // MARK: - Login Item Management

    private func updateLoginItem() {
        do {
            if launchAtLogin {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            #if DEBUG
            print("Failed to update login item: \(error)")
            #endif
        }
    }

    /// Get the current login item status from the system
    var loginItemStatus: SMAppService.Status {
        return SMAppService.mainApp.status
    }
}
