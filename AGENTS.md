# AGENTS.md

This file provides guidance to Codex (Codex.ai/code) when working with code in this repository.

## Project Overview

RedButtonQuit is a macOS menu bar utility that quits applications when their last window is closed (mimicking Windows behavior). It uses the macOS Accessibility API to monitor window events system-wide.

- **Bundle ID:** `com.redbuttonquit.app`
- **Requirements:** Xcode 15+, macOS 14+
- **Key constraint:** Cannot be distributed via Mac App Store because Accessibility API requires disabling App Sandbox.

## Build & Development Commands

```bash
# Build release version
make build          # or: make release

# Build debug version
make debug

# Build and run debug version
make run

# Run tests
make test
# Or full command:
xcodebuild test -project RedButtonQuit.xcodeproj -scheme RedButtonQuit -destination 'platform=macOS'

# Debug and test-host builds intentionally use com.redbuttonquit.app.debug so
# local tests cannot invalidate the installed app's Accessibility authorization.

# Clean build artifacts
make clean

# Distribution pipeline
make archive        # Create xcarchive
make export         # Export app from archive
make notarize       # Notarize (requires credentials)
make staple         # Staple notarization ticket
make dmg            # Create DMG
make release-full   # Full distribution pipeline

# Version bumping (edits Info.plist via PlistBuddy)
make bump-patch     # 1.0.0 → 1.0.1
make bump-minor     # 1.0.x → 1.1.0
make bump-major     # 1.x.x → 2.0.0
make bump-build     # Increment build number
```

Open in Xcode: `open RedButtonQuit.xcodeproj`

## Architecture

### Service Initialization Chain

`RedButtonQuitApp` (SwiftUI `@main`) → `AppDelegate` (via `@NSApplicationDelegateAdaptor`) → constructs the service graph:

```
AppDelegate.setupServices()
  └─ AppTerminationService (no deps)
       └─ WindowEventHandler (owns terminationService)
            └─ AccessibilityMonitor (weak ref to eventHandler)
```

All three services are retained by `AppDelegate`. The monitor is the only component that interacts with the OS accessibility layer. `AppDelegate` subscribes to `PreferencesManager.shared.$isEnabled` via Combine to start/stop monitoring dynamically.

### AX Callback Bridge (Critical Pattern)

`AccessibilityMonitor` uses a C function callback (`accessibilityCallback`) required by `AXObserverCreate`. The bridge works via `Unmanaged.passUnretained(self).toOpaque()` stored as context. The callback extracts the PID synchronously, then dispatches to main queue with `[weak monitor]` to avoid retain cycles. This is in `AccessibilityMonitor.swift:335-355`.

### Data Flow

1. `AccessibilityMonitor` creates `AXObserver` per running app (`.regular` activation policy only), listens for `kAXUIElementDestroyedNotification` and `kAXWindowCreatedNotification`
2. Also watches `NSWorkspace` notifications for app launch/terminate to add/remove observers dynamically
3. On window destruction → `WindowEventHandler.handleWindowDestroyed()` checks: enabled? excluded? quit mode?
4. Both quit modes wait one second for transient fullscreen/playback window replacement; a newly created real `AXWindow` cancels the pending quit
5. For `lastWindow`, `WindowInspector` requires both Accessibility and CoreGraphics to report zero user-facing windows
6. If conditions are met → `AppTerminationService.terminateApp()` sends `NSRunningApplication.terminate()` with AppleScript fallback

### Window Counting

`WindowInspector` owns window classification and snapshots. Accessibility counts standard windows, while CoreGraphics provides a layer-zero on-screen fallback for fullscreen/playback windows that temporarily use a nonstandard AX subrole. Sheets, dialogs, panels, and overlay layers remain excluded.

### Singletons

- `PreferencesManager.shared` — all preferences via `UserDefaults`, `@Published` properties with Combine observation
- `OnboardingWindowController.shared` — manages the onboarding NSWindow (wraps SwiftUI `OnboardingView` in `NSHostingView`)

### UI Structure

- **App scene**: `MenuBarExtra` with `.menu` style → `AppMenu` (SwiftUI view rendered as native menu)
- **Settings**: SwiftUI `Settings` scene → `PreferencesView` (3 tabs: General, Exclusions, About)
- **Onboarding**: 6-step wizard shown via `OnboardingWindowController.showIfNeeded()` on first launch (0.5s delay)
- **Permission polling**: `PermissionChecker` (ObservableObject) polls `isAccessibilityEnabled()` every 0.5s during onboarding permission step

## Code Conventions

- **Debug logging**: `#if DEBUG print(...)` guards throughout — no logging framework
- **Preference keys**: Fully qualified reverse-domain format (`com.redbuttonquit.isEnabled`)
- **Protected apps**: Hardcoded in `PreferencesManager.systemProtectedApps` (static `Set<String>`)
- **Error handling**: `AppTerminationService.TerminationError` enum with `LocalizedError` conformance

## Known Issues

**KI-001: Login Item Path Registration**
When "Launch at Login" is enabled while running from a non-production location (e.g., Xcode DerivedData), the login item silently fails after macOS restart. The app must be installed to `/Applications` before enabling this feature. See README FAQ for user-facing fix instructions.

**KI-002: TCC Database Stale After Rebuild**
Each Xcode rebuild changes the app's code signature, causing macOS TCC (Transparency, Consent, and Control) to treat it as a new/untrusted app. The accessibility permission toggle in System Settings may appear enabled but the underlying database is stale. `AXIsProcessTrusted()` returns cached/incorrect values.

**Symptoms:** App shows "Accessibility Permission: Not Granted" even after toggling permission in System Settings.

**Fix:** Reset TCC for this app and relaunch:
```bash
sudo tccutil reset Accessibility com.redbuttonquit.app
pkill -f RedButtonQuit
open /Applications/RedButtonQuit.app
```
Then re-grant permission when prompted.

## Testing Notes

- The Debug app/test host uses `com.redbuttonquit.app.debug`, keeping its TCC record separate from the installed Release app
- Tests use isolated `UserDefaults` suites and never alter the live app's preferences or login item
- The real Finder Accessibility test is skipped when the test host lacks permission; the remaining window-classification tests still run
- `AppTerminationServiceTests` validates protected apps cannot be terminated (uses real `NSRunningApplication` instances — Finder, Dock)
- `PreferencesManagerTests` and `AccessibilityMonitorTests` also exist
- Real window monitoring tests are difficult to automate; manual testing recommended for accessibility features

## Post-Build Protocol

**IMPORTANT:** After any build that gets installed to `/Applications`, remind the user:

> "After rebuilding, macOS may not recognize the new code signature for accessibility permissions. If the app shows 'Not Granted' even after toggling in System Settings, run:
> ```bash
> sudo tccutil reset Accessibility com.redbuttonquit.app
> pkill -f RedButtonQuit
> open /Applications/RedButtonQuit.app
> ```
> Then re-grant permission when prompted."

This is a known macOS limitation with TCC database caching (see KI-002).
