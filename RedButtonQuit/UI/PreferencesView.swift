import SwiftUI

/// Main preferences window view
struct PreferencesView: View {
    @ObservedObject private var preferences = PreferencesManager.shared

    var body: some View {
        TabView(selection: $preferences.selectedTab) {
            GeneralTab()
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }
                .tag(PreferencesManager.PreferencesTab.general)

            ExclusionsTab()
                .tabItem {
                    Label("Exclusions", systemImage: "xmark.app")
                }
                .tag(PreferencesManager.PreferencesTab.exclusions)

            HistoryView()
                .tabItem {
                    Label("History", systemImage: "clock.arrow.circlepath")
                }
                .tag(PreferencesManager.PreferencesTab.history)

            AboutTab()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
                .tag(PreferencesManager.PreferencesTab.about)
        }
        .frame(width: 560, height: 500)
    }
}

// MARK: - General Tab

struct GeneralTab: View {
    @ObservedObject private var preferences = PreferencesManager.shared

    var body: some View {
        Form {
            Section("Behavior") {
                Toggle("Enable RedButtonQuit", isOn: $preferences.isEnabled)
                    .help("When enabled, closing an app's last window will quit the app")

                Picker("Quit Mode", selection: $preferences.quitMode) {
                    ForEach(PreferencesManager.QuitMode.allCases) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .pickerStyle(.radioGroup)

                Text(preferences.quitMode.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("Startup") {
                Toggle("Launch at Login", isOn: $preferences.launchAtLogin)
                    .help("Start RedButtonQuit automatically when you log in")

                Toggle("Play Sound on Quit", isOn: $preferences.playSound)
                    .help("Play a sound when an app is automatically quit")
            }

            Section("Status") {
                HStack {
                    Text("Accessibility Permission:")
                    Spacer()
                    if AccessibilityMonitor.isAccessibilityEnabled() {
                        Label("Granted", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    } else {
                        Label("Not Granted", systemImage: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Button("Grant Permission") {
                            AccessibilityMonitor.beginPermissionRecovery()
                        }
                    }
                }

                if !AccessibilityMonitor.isAccessibilityEnabled() {
                    Text("RedButtonQuit will restart, then show you where to turn the permission on.")
                        .font(.callout)
                        .foregroundColor(.secondary)
                }
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - Exclusions Tab

struct ExclusionsTab: View {
    @ObservedObject private var preferences = PreferencesManager.shared
    @State private var selectedApp: String?
    @State private var showingAppPicker = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Apps in this list will not be quit when their windows are closed.")
                .font(.callout)
                .foregroundColor(.secondary)
                .padding(.horizontal)
                .padding(.top, 8)

            // Exclusion list
            List(selection: $selectedApp) {
                Section("System Protected (cannot remove)") {
                    ForEach(Array(PreferencesManager.systemProtectedApps).sorted(), id: \.self) { bundleID in
                        ExclusionRow(bundleID: bundleID, isSystem: true)
                    }
                }

                Section("User Excluded") {
                    let userExcluded = preferences.excludedBundleIDs.subtracting(PreferencesManager.systemProtectedApps)
                    if userExcluded.isEmpty {
                        Text("No user exclusions added")
                            .foregroundColor(.secondary)
                            .italic()
                    } else {
                        ForEach(Array(userExcluded).sorted(), id: \.self) { bundleID in
                            ExclusionRow(bundleID: bundleID, isSystem: false)
                        }
                        .onDelete { indexSet in
                            let sorted = Array(userExcluded).sorted()
                            for index in indexSet {
                                preferences.removeExclusion(sorted[index])
                            }
                        }
                    }
                }
            }
            .listStyle(.inset(alternatesRowBackgrounds: true))
            .frame(minHeight: 250)

            // Add/Remove buttons
            HStack {
                Button(action: { showingAppPicker = true }) {
                    Image(systemName: "plus")
                }
                .help("Add app to exclusion list")

                Button(action: removeSelected) {
                    Image(systemName: "minus")
                }
                .disabled(selectedApp == nil || PreferencesManager.systemProtectedApps.contains(selectedApp ?? ""))
                .help("Remove selected app from exclusion list")

                Spacer()

                Button("Reset to Defaults") {
                    preferences.excludedBundleIDs = PreferencesManager.systemProtectedApps
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .sheet(isPresented: $showingAppPicker) {
            AppPickerView { bundleID in
                preferences.addExclusion(bundleID)
                showingAppPicker = false
            }
        }
    }

    private func removeSelected() {
        if let selected = selectedApp {
            preferences.removeExclusion(selected)
            selectedApp = nil
        }
    }
}

// MARK: - Exclusion Row

struct ExclusionRow: View {
    let bundleID: String
    let isSystem: Bool

    var body: some View {
        HStack {
            if let icon = appIcon {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 20, height: 20)
            } else {
                Image(systemName: "app")
                    .frame(width: 20, height: 20)
            }

            VStack(alignment: .leading) {
                Text(appName)
                    .lineLimit(1)
                Text(bundleID)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            if isSystem {
                Text("System")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.2))
                    .cornerRadius(4)
            }
        }
    }

    private var appName: String {
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID),
           let bundle = Bundle(url: url),
           let name = bundle.object(forInfoDictionaryKey: "CFBundleName") as? String {
            return name
        }
        // Fallback to extracting name from bundle ID
        return bundleID.components(separatedBy: ".").last ?? bundleID
    }

    private var appIcon: NSImage? {
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
            return NSWorkspace.shared.icon(forFile: url.path)
        }
        return nil
    }
}

// MARK: - App Picker View

private struct InstalledApp: Identifiable {
    let bundleID: String
    let name: String
    let icon: NSImage?
    let appPath: String?

    var id: String { bundleID }
}

private struct InstalledAppDescriptor: Sendable {
    let bundleID: String
    let name: String
    let path: String
}

private enum AppSource: String, CaseIterable {
    case running = "Running"
    case installed = "Installed"
}

struct AppPickerView: View {
    let onSelect: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var preferences = PreferencesManager.shared
    @State private var searchText = ""
    @State private var selectedSource: AppSource = .running
    @State private var cachedInstalledApps: [InstalledApp] = []
    @State private var isLoadingInstalledApps = false
    @State private var manualBundleID = ""

    private var runningApps: [InstalledApp] {
        NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular || $0.activationPolicy == .accessory }
            .compactMap { app -> InstalledApp? in
                guard let bundleID = app.bundleIdentifier,
                      bundleID != Bundle.main.bundleIdentifier,
                      !preferences.excludedBundleIDs.contains(bundleID) else { return nil }
                return InstalledApp(bundleID: bundleID, name: app.localizedName ?? bundleID, icon: app.icon, appPath: nil)
            }
            .filtered(by: searchText)
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    private var filteredInstalledApps: [InstalledApp] {
        cachedInstalledApps
            .filter { !preferences.excludedBundleIDs.contains($0.bundleID) }
            .filtered(by: searchText)
    }

    private var displayedApps: [InstalledApp] {
        selectedSource == .running ? runningApps : filteredInstalledApps
    }

    private var normalizedManualBundleID: String {
        manualBundleID.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canAddManualBundleID: Bool {
        !normalizedManualBundleID.isEmpty &&
            !preferences.excludedBundleIDs.contains(normalizedManualBundleID)
    }

    private var manualBundleIDHelpText: String {
        if normalizedManualBundleID.isEmpty {
            return "Use this only when the app is not shown above."
        }
        if preferences.excludedBundleIDs.contains(normalizedManualBundleID) {
            return "This app is already excluded."
        }
        if !normalizedManualBundleID.contains(".") {
            return "Bundle IDs usually look like com.example.app."
        }
        if NSWorkspace.shared.urlForApplication(withBundleIdentifier: normalizedManualBundleID) == nil {
            return "Unknown bundle ID; it will still be saved."
        }
        return "Ready to add."
    }

    var body: some View {
        VStack {
            Text("Select an App to Exclude")
                .font(.headline)
                .padding(.top)

            Picker("", selection: $selectedSource) {
                ForEach(AppSource.allCases, id: \.self) { source in
                    Text(source.rawValue).tag(source)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            TextField("Search", text: $searchText)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)

            if selectedSource == .installed && isLoadingInstalledApps {
                ProgressView("Scanning Applications...")
                    .controlSize(.small)
                    .padding(.horizontal)
            }

            List(displayedApps) { app in
                Button(action: { onSelect(app.bundleID) }) {
                    HStack {
                        if let icon = app.icon {
                            Image(nsImage: icon)
                                .resizable()
                                .frame(width: 24, height: 24)
                        } else if let appPath = app.appPath {
                            Image(nsImage: NSWorkspace.shared.icon(forFile: appPath))
                                .resizable()
                                .frame(width: 24, height: 24)
                        } else {
                            Image(systemName: "app")
                                .frame(width: 24, height: 24)
                        }
                        VStack(alignment: .leading) {
                            Text(app.name)
                            Text(app.bundleID)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            .listStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                Text("Advanced")
                    .font(.caption)
                    .foregroundColor(.secondary)
                HStack {
                    TextField("Manual Bundle ID", text: $manualBundleID)
                        .textFieldStyle(.roundedBorder)
                    Button("Add") {
                        guard canAddManualBundleID else { return }
                        onSelect(normalizedManualBundleID)
                    }
                    .disabled(!canAddManualBundleID)
                }
                Text(manualBundleIDHelpText)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal)

            HStack {
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .frame(width: 400, height: 500)
        .task(id: selectedSource) {
            guard selectedSource == .installed else { return }
            await loadInstalledAppsIfNeeded()
        }
    }

    @MainActor
    private func loadInstalledAppsIfNeeded() async {
        guard cachedInstalledApps.isEmpty, !isLoadingInstalledApps else { return }

        isLoadingInstalledApps = true
        let apps = await Task.detached(priority: .userInitiated) {
            Self.scanInstalledAppDescriptors()
        }.value
        cachedInstalledApps = apps.map {
            InstalledApp(bundleID: $0.bundleID, name: $0.name, icon: nil, appPath: $0.path)
        }
        isLoadingInstalledApps = false
    }

    nonisolated private static func scanInstalledAppDescriptors() -> [InstalledAppDescriptor] {
        let fileManager = FileManager.default
        var apps: [InstalledAppDescriptor] = []
        var seenBundleIDs: Set<String> = []

        let directories = [
            URL(fileURLWithPath: "/Applications"),
            URL(fileURLWithPath: "/System/Applications"),
            fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Applications"),
        ]

        for directory in directories {
            guard fileManager.fileExists(atPath: directory.path),
                  let enumerator = fileManager.enumerator(
                      at: directory,
                      includingPropertiesForKeys: [.isDirectoryKey],
                      options: [.skipsHiddenFiles]
                  ) else { continue }

            for case let url as URL in enumerator {
                guard url.pathExtension == "app" else { continue }
                // Don't descend into .app bundles
                enumerator.skipDescendants()

                guard let bundle = Bundle(url: url),
                      let bundleID = bundle.bundleIdentifier,
                      !seenBundleIDs.contains(bundleID) else { continue }

                seenBundleIDs.insert(bundleID)
                let name = bundle.object(forInfoDictionaryKey: "CFBundleName") as? String
                    ?? bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
                    ?? url.deletingPathExtension().lastPathComponent
                apps.append(InstalledAppDescriptor(bundleID: bundleID, name: name, path: url.path))
            }
        }

        return apps.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
}

private extension Array where Element == InstalledApp {
    func filtered(by searchText: String) -> [InstalledApp] {
        guard !searchText.isEmpty else { return self }
        return filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.bundleID.localizedCaseInsensitiveContains(searchText)
        }
    }
}

// MARK: - About Tab

struct AboutTab: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Spacer()
                    .frame(height: 24)

                Image(systemName: "xmark.circle.fill")
                    .resizable()
                    .frame(width: 64, height: 64)
                    .foregroundColor(.red)

                Text("RedButtonQuit")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Version \(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0")")
                    .foregroundColor(.secondary)

                Text("Quit apps when you close their last window.")
                    .multilineTextAlignment(.center)

                Divider()
                    .padding(.horizontal)

                VStack(spacing: 8) {
                    Link("Website", destination: URL(string: "https://redbuttonquit.com")!)
                    Link("View on GitHub", destination: URL(string: "https://github.com/initiator1/redbuttonquit")!)
                    Link("Report an Issue", destination: URL(string: "https://github.com/initiator1/redbuttonquit/issues")!)
                }
                .font(.callout)

                Divider()
                    .padding(.horizontal)

                // Support link
                VStack(spacing: 6) {
                    Text("Like this app?")
                        .font(.caption)
                        .fontWeight(.medium)
                    Link("Buy me a coffee", destination: URL(string: "https://ko-fi.com/initiator1")!)
                        .font(.caption)
                }

                Spacer()
                    .frame(height: 16)

                // Hidden Bar recommendation
                VStack(spacing: 4) {
                    Text("Tip: Use Hidden Bar (free) to hide menu bar icons")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }

                Spacer()
                    .frame(height: 12)

                Text("Distributed as freeware")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity)
        }
    }
}

#Preview {
    PreferencesView()
}
