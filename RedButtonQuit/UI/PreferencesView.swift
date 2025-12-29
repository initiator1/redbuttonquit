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

            AboutTab()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
                .tag(PreferencesManager.PreferencesTab.about)
        }
        .frame(width: 450, height: 450)
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
                            AccessibilityMonitor.openAccessibilitySettings()
                        }
                    }
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

struct AppPickerView: View {
    let onSelect: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    private var runningApps: [NSRunningApplication] {
        NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular }
            .filter { $0.bundleIdentifier != Bundle.main.bundleIdentifier }
            .filter { app in
                if searchText.isEmpty { return true }
                let name = app.localizedName ?? ""
                return name.localizedCaseInsensitiveContains(searchText)
            }
            .sorted { ($0.localizedName ?? "") < ($1.localizedName ?? "") }
    }

    var body: some View {
        VStack {
            Text("Select an App to Exclude")
                .font(.headline)
                .padding(.top)

            TextField("Search", text: $searchText)
                .textFieldStyle(.roundedBorder)
                .padding(.horizontal)

            List(runningApps, id: \.processIdentifier) { app in
                Button(action: {
                    if let bundleID = app.bundleIdentifier {
                        onSelect(bundleID)
                    }
                }) {
                    HStack {
                        if let icon = app.icon {
                            Image(nsImage: icon)
                                .resizable()
                                .frame(width: 24, height: 24)
                        }
                        VStack(alignment: .leading) {
                            Text(app.localizedName ?? "Unknown")
                            Text(app.bundleIdentifier ?? "")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
            .listStyle(.plain)

            HStack {
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
            }
            .padding()
        }
        .frame(width: 350, height: 400)
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
