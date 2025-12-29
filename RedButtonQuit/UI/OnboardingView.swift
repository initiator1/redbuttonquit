import SwiftUI

/// Onboarding flow for first-time users
struct OnboardingView: View {
    @ObservedObject private var preferences = PreferencesManager.shared
    @State private var currentStep = 0
    @State private var isCheckingPermission = false
    @Environment(\.dismiss) private var dismiss

    private let totalSteps = 6

    var body: some View {
        VStack(spacing: 0) {
            // Progress indicator - using SF Symbols for consistent rendering
            HStack(spacing: 12) {
                ForEach(0..<totalSteps, id: \.self) { step in
                    Image(systemName: step <= currentStep ? "circle.fill" : "circle")
                        .font(.system(size: 8))
                        .foregroundColor(step <= currentStep ? Color.accentColor : Color.secondary.opacity(0.4))
                }
            }
            .padding(.top, 20)
            .padding(.bottom, 8)

            // Content - using switch instead of TabView to avoid title bar indicator
            Group {
                switch currentStep {
                case 0:
                    WelcomeStep(onContinue: { withAnimation { currentStep = 1 } })
                case 1:
                    HowItWorksStep(onContinue: { withAnimation { currentStep = 2 } })
                case 2:
                    PermissionStep(
                        isChecking: $isCheckingPermission,
                        onPermissionGranted: { withAnimation { currentStep = 3 } }
                    )
                case 3:
                    ExclusionsSetupStep(onContinue: { withAnimation { currentStep = 4 } })
                case 4:
                    LaunchAtLoginStep(onContinue: { withAnimation { currentStep = 5 } })
                case 5:
                    CompletionStep(onFinish: completeOnboarding)
                default:
                    EmptyView()
                }
            }
            .transition(.opacity)
        }
        .frame(width: 520, height: 520)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private func completeOnboarding() {
        preferences.hasCompletedOnboarding = true
        dismiss()
    }
}

// MARK: - Welcome Step

struct WelcomeStep: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "xmark.circle.fill")
                .resizable()
                .frame(width: 80, height: 80)
                .foregroundColor(.red)

            Text("Welcome to RedButtonQuit")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Make the red close button actually quit apps.")
                .font(.title3)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Spacer()

            Button(action: onContinue) {
                Text("Get Started")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 40)
            .padding(.bottom, 30)
        }
        .padding()
    }
}

// MARK: - How It Works Step

struct HowItWorksStep: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("How It Works")
                .font(.title)
                .fontWeight(.bold)

            VStack(alignment: .leading, spacing: 16) {
                FeatureRow(
                    icon: "1.circle.fill",
                    title: "Close a Window",
                    description: "Click the red button like you normally would"
                )

                FeatureRow(
                    icon: "2.circle.fill",
                    title: "App Quits Automatically",
                    description: "When the last window closes, the app quits"
                )

                FeatureRow(
                    icon: "3.circle.fill",
                    title: "Exclude Apps",
                    description: "Keep your favorite apps running if you prefer"
                )
            }
            .padding(.horizontal)

            Spacer()

            Button(action: onContinue) {
                Text("Continue")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 40)
            .padding(.bottom, 30)
        }
        .padding()
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accentColor)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.callout)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Permission Checker (ObservableObject for proper timer lifecycle)

class PermissionChecker: ObservableObject {
    @Published var permissionGranted = false
    @Published var isChecking = false
    private var timer: Timer?
    private var pollCount = 0

    init() {
        // Check immediately on init
        checkPermission()
    }

    deinit {
        stopPolling()
    }

    func checkPermission() {
        let granted = AccessibilityMonitor.isAccessibilityEnabled()
        #if DEBUG
        pollCount += 1
        print("Permission check #\(pollCount): \(granted ? "GRANTED" : "denied")")
        #endif

        if granted && !permissionGranted {
            DispatchQueue.main.async {
                withAnimation {
                    self.permissionGranted = true
                }
                self.isChecking = false
                self.stopPolling()
            }
        }
    }

    func openSettings() {
        AccessibilityMonitor.openAccessibilitySettings()
        isChecking = true
        // Ensure polling continues
        if timer == nil {
            startPolling()
        }
    }

    func startPolling() {
        guard timer == nil else {
            #if DEBUG
            print("Polling already active")
            #endif
            return
        }

        #if DEBUG
        print("Starting permission polling...")
        #endif

        // Poll more frequently (every 0.5 seconds)
        let newTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkPermission()
        }
        // Ensure timer fires even when UI is being manipulated
        RunLoop.main.add(newTimer, forMode: .common)
        timer = newTimer
    }

    func stopPolling() {
        #if DEBUG
        print("Stopping permission polling")
        #endif
        timer?.invalidate()
        timer = nil
    }
}

// MARK: - Permission Step

struct PermissionStep: View {
    @Binding var isChecking: Bool
    let onPermissionGranted: () -> Void
    @StateObject private var checker = PermissionChecker()

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: checker.permissionGranted ? "checkmark.shield.fill" : "lock.shield")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 60, height: 60)
                .foregroundColor(checker.permissionGranted ? .green : .orange)

            Text("Permission Required")
                .font(.title)
                .fontWeight(.bold)

            Text("RedButtonQuit needs Accessibility permission to detect when you close windows.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            if checker.permissionGranted {
                Label("Permission Granted!", systemImage: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.headline)
            } else {
                VStack(spacing: 12) {
                    Button(action: {
                        checker.openSettings()
                        isChecking = true
                    }) {
                        Label("Open System Settings", systemImage: "gear")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)

                    VStack(spacing: 4) {
                        Text("Toggle ON for RedButtonQuit, then return here.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("Already listed? Toggle OFF then ON again to refresh.")
                            .font(.caption2)
                            .foregroundColor(.secondary.opacity(0.8))
                    }

                    if checker.isChecking || isChecking {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.7)
                            Text("Waiting for permission...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }

            Spacer()

            if checker.permissionGranted {
                Button(action: onPermissionGranted) {
                    Text("Continue")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.horizontal, 40)
                .padding(.bottom, 30)
            } else {
                Button(action: onPermissionGranted) {
                    Text("Skip for Now")
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
                .padding(.bottom, 30)
            }
        }
        .padding()
        .onAppear {
            checker.startPolling()
        }
        .onDisappear {
            checker.stopPolling()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            // When app becomes active again, check immediately and ensure polling
            checker.checkPermission()
            if !checker.permissionGranted {
                checker.startPolling()
            }
        }
    }
}

// MARK: - Exclusions Info Step

struct ExclusionsSetupStep: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "shield.lefthalf.filled")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 60, height: 60)
                .foregroundColor(.blue)

            Text("App Exclusions")
                .font(.title)
                .fontWeight(.bold)

            Text("Some apps you may want to keep running even after closing their windows—like music players or chat apps.")
                .font(.callout)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .frame(width: 24)
                    Text("System apps like Finder are always protected")
                        .font(.callout)
                }
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.accentColor)
                        .frame(width: 24)
                    Text("Add exclusions anytime from the menu bar icon")
                        .font(.callout)
                }
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "gearshape.fill")
                        .foregroundColor(.secondary)
                        .frame(width: 24)
                    Text("Or manage them in Preferences > Exclusions")
                        .font(.callout)
                }
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(10)
            .padding(.horizontal)

            Spacer()

            Button(action: onContinue) {
                Text("Continue")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 40)
            .padding(.bottom, 24)
        }
        .padding(.horizontal)
    }
}

// MARK: - Launch at Login Step

struct LaunchAtLoginStep: View {
    let onContinue: () -> Void
    @ObservedObject private var preferences = PreferencesManager.shared

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "sunrise.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 60, height: 60)
                .foregroundColor(.orange)

            Text("Start Automatically?")
                .font(.title)
                .fontWeight(.bold)

            Text("RedButtonQuit works best when it starts automatically with your Mac.")
                .font(.callout)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Toggle(isOn: $preferences.launchAtLogin) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Launch at Login")
                        .font(.headline)
                    Text("Start RedButtonQuit when you log in")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .toggleStyle(.switch)
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(10)
            .padding(.horizontal, 40)

            HStack(spacing: 8) {
                Image(systemName: "menubar.rectangle")
                    .foregroundColor(.secondary)
                Text("Find RedButtonQuit in your menu bar")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: onContinue) {
                Text("Continue")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 40)
            .padding(.bottom, 24)
        }
        .padding(.horizontal)
    }
}

// MARK: - Completion Step

struct CompletionStep: View {
    let onFinish: () -> Void
    @ObservedObject private var preferences = PreferencesManager.shared

    var body: some View {
        VStack(spacing: 16) {
            Spacer()
                .frame(maxHeight: 20)

            Image(systemName: "checkmark.circle.fill")
                .resizable()
                .frame(width: 60, height: 60)
                .foregroundColor(.green)

            Text("You're All Set!")
                .font(.title)
                .fontWeight(.bold)

            Text("RedButtonQuit is now running in your menu bar.")
                .font(.callout)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            // Configuration summary
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Enabled")
                }
                HStack {
                    Image(systemName: preferences.launchAtLogin ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(preferences.launchAtLogin ? .green : .secondary)
                    Text("Launch at Login")
                }
                HStack {
                    Image(systemName: "xmark.app")
                        .foregroundColor(.orange)
                    Text("\(preferences.excludedBundleIDs.count) apps excluded")
                }
            }
            .font(.callout)
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(8)
            .padding(.horizontal)

            // Hidden Bar tip
            VStack(spacing: 8) {
                Text("Tip: Keep your menu bar tidy")
                    .font(.caption)
                    .fontWeight(.medium)
                Text("Use Hidden Bar (free on App Store) to hide the icon when not needed.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)

            Spacer()

            Button(action: onFinish) {
                Text("Start Using RedButtonQuit")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 40)
            .padding(.bottom, 20)
        }
        .padding(.horizontal)
    }
}

// MARK: - Onboarding Window Controller

class OnboardingWindowController: NSWindowController {
    static let shared = OnboardingWindowController()

    private init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 520, height: 520),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Welcome to RedButtonQuit"
        window.center()
        window.contentView = NSHostingView(rootView: OnboardingView())

        super.init(window: window)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func showIfNeeded() {
        if !PreferencesManager.shared.hasCompletedOnboarding {
            showWindow(nil)
            window?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}

#Preview {
    OnboardingView()
}
