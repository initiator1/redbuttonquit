# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

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
  ├─ AppTerminationService (no deps)
  ├─ QuitHistoryStore.shared (file-backed history)
  └─ WindowEventHandler (owns terminationService and history)
       └─ AccessibilityMonitor (weak ref to eventHandler)
```

All three services are retained by `AppDelegate`. The monitor is the only component that interacts with the OS accessibility layer. `AppDelegate` subscribes to `PreferencesManager.shared.$isEnabled` via Combine to start/stop monitoring dynamically.

### AX Callback Bridge (Critical Pattern)

`AccessibilityMonitor` uses a C function callback (`accessibilityCallback`) required by `AXObserverCreate`. The bridge works via `Unmanaged.passUnretained(self).toOpaque()` stored as context. The callback extracts the PID synchronously, then dispatches to main queue with `[weak monitor]` to avoid retain cycles. This is in `AccessibilityMonitor.swift:335-355`.

### Data Flow

1. `AccessibilityMonitor` sends startup apps and launched apps through the same eligibility check. It accepts only `.regular` apps with an `APPL` bundle outside extension, plug-in, XPC-service, and system-framework paths.
2. Each accepted app gets an `AXObserver` for `kAXUIElementDestroyedNotification` and `kAXWindowCreatedNotification`. `NSWorkspace` launch/terminate notifications add or remove observers dynamically.
3. On window destruction → `WindowEventHandler.handleWindowDestroyed()` checks: enabled? protected? quit mode?
4. Both quit modes wait one second for transient fullscreen/playback window replacement; a newly created real `AXWindow` cancels the pending quit. History records that cancellation in `anyWindow` mode, or in `lastWindow` mode only when `WindowInspector` proves no other user-facing window remained after accounting for the destroyed window
5. For `lastWindow`, `WindowInspector` requires both Accessibility and CoreGraphics to report zero user-facing windows
6. At the quit decision, the handler checks the current user exclusion list and records excluded decisions
7. If conditions are met → `AppTerminationService.terminateApp()` sends `NSRunningApplication.terminate()` with AppleScript fallback
8. `QuitHistoryStore` records the request as pending, then the handler polls `isTerminated` for up to ten seconds
9. The history reports a quit only after a poll confirms that the app terminated

### Window Counting

`WindowInspector` owns window classification and snapshots. Accessibility counts standard windows, while CoreGraphics provides a layer-zero on-screen fallback for fullscreen/playback windows that temporarily use a nonstandard AX subrole. Sheets, dialogs, panels, and overlay layers remain excluded.

### Singletons

- `PreferencesManager.shared` — all preferences via `UserDefaults`, `@Published` properties with Combine observation
- `QuitHistoryStore.shared` — up to 200 local quit decisions in `~/Library/Application Support/RedButtonQuit/history.json`
- `OnboardingWindowController.shared` — manages the onboarding NSWindow (wraps SwiftUI `OnboardingView` in `NSHostingView`)

### UI Structure

- **App scene**: `MenuBarExtra` with `.menu` style → `AppMenu` (SwiftUI view rendered as native menu)
- **Settings**: SwiftUI `Settings` scene → `PreferencesView` (4 tabs: General, Exclusions, History, About)
- **Recent history**: `AppMenu` shows up to ten confirmed quits, still-running results, or failures
- **Onboarding**: 6-step wizard shown via `OnboardingWindowController.showIfNeeded()` on first launch (0.5s delay)
- **Permission polling**: `PermissionChecker` (ObservableObject) polls `isAccessibilityEnabled()` every 0.5s during onboarding permission step

## Code Conventions

- **Debug logging**: `#if DEBUG print(...)` guards throughout — no logging framework
- **Preference keys**: Fully qualified reverse-domain format (`com.redbuttonquit.isEnabled`)
- **Protected apps**: Hardcoded in `PreferencesManager.systemProtectedApps` (static `Set<String>`)
- **App icon**: `Resources/AppIcon.icon` (Icon Composer layers) is the primary icon on macOS 26+; `Assets.xcassets/AppIcon.appiconset` is the classic fallback for macOS 14-15 and must keep transparent margins (824 px body on a 1024 canvas). Never bake a rounded tile into the artwork. `site/icon-*.png` export from the classic set
- **Error handling**: `AppTerminationService.TerminationError` enum with `LocalizedError` conformance

## Known Issues

**KI-001: Login Item Path Registration**
When "Launch at Login" is enabled while running from a non-production location (e.g., Xcode DerivedData), the login item silently fails after macOS restart. The app must be installed to `/Applications` before enabling this feature. See README FAQ for user-facing fix instructions.

**KI-002: TCC Grant Broke On Every Rebuild — RESOLVED by Developer ID signing**
While the app was ad-hoc signed, TCC had no stable identity to key on and pinned the grant to
the exact code hash. Each rebuild produced a new hash, so the System Settings toggle kept
reading **on** while the app was denied at runtime — windows closed, nothing quit, no error
anywhere.

Release is now signed with `Developer ID Application: INITIATOR LLC (MDWFZC6396)`, and the
stored TCC requirement is identity-based:

```
anchor apple generic and identifier "com.redbuttonquit.app" and (... certificate leaf[subject.OU] = MDWFZC6396)
```

Verified end to end: rebuilt with a different cdhash, reinstalled without any reset, permission
stayed granted and the app still quit TextEdit on last-window close.

**Do not reintroduce a `tccutil reset` into `make install`.** It was scaffolding for the ad-hoc
era and now just forces pointless re-granting. `make reset-permission` exists for the rare cases
(switching signing identity, or a TCC record macOS has corrupted).

`isAccessibilityEnabled()` still probes Finder rather than trusting `AXIsProcessTrusted()`.
Keep it — it is what makes the Debug build and any future identity change fail honestly.

**KI-003: Deleted Accessibility Entry Leaves No Recovery Path (fixed in-app)**
Removing RedButtonQuit's row from System Settings → Privacy & Security → Accessibility while
the app is running leaves it unable to recover on its own. macOS pins a process's accessibility
verdict for the process lifetime, and opening the pane shows no row to toggle.

The trigger is two rows that look identical. See KI-004.

**Fix:** the UI exposes exactly one action, "Grant Accessibility Permission…", wired to
`AccessibilityMonitor.beginPermissionRecovery()`. It always relaunches, passing
`--request-accessibility`; the fresh process calls `AXIsProcessTrustedWithOptions` (recreating
the row) and opens the pane. Relaunching unconditionally is what lets one button work from
every state, so **do not add a separate "restart" affordance** — the user can't be asked to
diagnose which state they're in.

Ordinary launches without the flag prompt but never open System Settings, so a user who
declines isn't ambushed at every login. Onboarding keeps `presentAccessibilityRequest()`
without a relaunch: that process just started, so its row already exists, and relaunching
would throw the user back to step 1 of the wizard.

The shell relaunch waits for the current PID to exit before calling `open -n`. Without the
wait, `open` reactivates the dying instance and the user is left with no app at all.

**KI-004: Test Host Appeared as a Second "RedButtonQuit.app"**
The Debug product used to be named `RedButtonQuit.app` too, so the test host
(`com.redbuttonquit.app.debug`) showed up in the Accessibility list under a label identical to
the real app's. Users delete the wrong one — that is how KI-003 gets triggered in practice.

**Fix:** the Debug configuration sets `PRODUCT_NAME = RedButtonQuitDebug` (with
`PRODUCT_MODULE_NAME = RedButtonQuit` so `@testable import RedButtonQuit` still resolves), and
the Debug `TEST_HOST` points at `RedButtonQuitDebug.app`. Any row labeled `RedButtonQuit.app` is
now unambiguously the real app.

**KI-007: Test runs re-prompted for the Debug app — fixed 2026-09-28.** The Debug app was
ad-hoc signed, so TCC pinned its grant to one cdhash and every rebuild asked again, while the
toggle still read on. Two fixes, both needed: Debug (app and test targets) is signed with
`Apple Development: Douglas Baker (PHQ74HFWFP)`, team `MDWFZC6396`, so the grant is
identity-based; and Xcode-hosted processes never touch TCC. That means the XCTest host **and the
SwiftUI preview host** (`XCODE_RUNNING_FOR_PREVIEWS=1`), which Xcode relaunches as a full app
after every edit while the project is open; the preview host was the source of the prompts that
survived the first fix. `AppDelegate` returns immediately when `isHostedByXcode` (no services, no
onboarding window), and `AccessibilityMonitor.isAccessibilityEnabled()` returns false there
without calling any AX API. Verified: a test run starting with no
Debug row leaves no row. Live AX tests opt in with `TEST_RUNNER_RBQ_LIVE_AX_TESTS=1`. `make test`
no longer runs `tccutil reset`; it would only wipe a Debug grant given on purpose. The Apple
Development certificate expires 2027-02-03.

**KI-005: Helper Processes Entered Quit History — fixed for 1.1.1**
Startup observer setup filtered by activation policy, but the workspace launch path called
`createObserver` without that filter. macOS 27 reports the inspected settings extensions and
Open/Save panel XPC service as accessory processes, and WebKit content processes as prohibited.
The shared eligibility check now rejects non-regular processes and helper bundle structure,
package types, and system framework paths before observer creation. Do not replace this with
a bundle-identifier list.

**KI-006: Routine Window Replacements Filled History — fixed for 1.1.1**
In `lastWindow` mode, a replacement window cancels a pending check even when other windows
remain open. The app still cancels the check as before, but it records the cancellation only
when the destroyed window was the last user-facing window. `anyWindow` mode still records each
cancelled pending quit.

## Testing Notes

- The Debug app/test host builds as `RedButtonQuitDebug.app` with bundle ID `com.redbuttonquit.app.debug`, keeping both its TCC record and its Accessibility-list label distinct from the installed Release app
- The test host never calls the Accessibility API, so test runs create no TCC row and never prompt (KI-007)
- Tests use isolated `UserDefaults` suites and never alter the live app's preferences or login item
- The real Finder Accessibility test runs only with `TEST_RUNNER_RBQ_LIVE_AX_TESTS=1 xcodebuild test ...` and a granted Debug app; the remaining window-classification tests always run
- `AppTerminationServiceTests` validates protected apps cannot be terminated (uses real `NSRunningApplication` instances — Finder, Dock)
- `PreferencesManagerTests` and `AccessibilityMonitorTests` also exist
- `QuitHistoryStoreTests` use temporary directories and isolated `UserDefaults` suites
- `AccessibilityMonitorTests` cover helper-process eligibility and destroyed-window accounting for cancellation history
- Real window monitoring tests are difficult to automate; manual testing recommended for accessibility features

## Code Signing

Release builds are signed manually with `Developer ID Application: INITIATOR LLC (MDWFZC6396)`
(`CODE_SIGN_STYLE = Manual`, `DEVELOPMENT_TEAM = MDWFZC6396`, hardened runtime on). Two
Developer ID certificates share team `MDWFZC6396` — one for Douglas Baker, one for INITIATOR
LLC — so both the project's `CODE_SIGN_IDENTITY[sdk=macosx*]` and `exportOptions.plist`
`signingCertificate` name the LLC identity in full. Naming only the team would pick either one.

Debug is signed with `Apple Development: Douglas Baker (PHQ74HFWFP)` (team `MDWFZC6396`), named in
full, so its Accessibility grant survives rebuilds (KI-007). Xcode adds `get-task-allow` to Debug,
so the debugger still attaches.

`make export` produces the distributable: hardened runtime, secure timestamp, and a signature
that satisfies its own designated requirement. Verify with `codesign --verify --strict -vv`
and confirm `Timestamp=` is present — notarization rejects builds without one.

**Notarization works.** `make notarize` submits through the keychain profile `RedButtonQuit`,
created by BOSS on 2026-08-11. First accepted submission: `765ffb63-7a0e-4d88-b68b-0e295974bab2`.
`make staple` attaches the ticket. Confirm the result with `syspolicy_check distribution
<app>` — `spctl` is blocked by the `redline_guard.py` hook because it can disable Gatekeeper.

If the profile ever needs recreating, that requires an app-specific password only the account
holder can generate and type — **never handle that value**.

This repo is **public**. Keep the Apple ID out of it; it is recorded in agent memory instead.

## Child DOX Index

| Subtree | Owner doc | Covers |
| --- | --- | --- |
| `site/` | [site/CLAUDE.md](site/CLAUDE.md) | The public marketing site at redbuttonquit.com: no-build contract, design direction, the claims that must be verified before they go on the page, and Cloudflare Pages deployment. |

## Post-Build Protocol

**Install with `make install`, never by copying the bundle into `/Applications` yourself.** It
kills the running app, replaces it, verifies the signature before launching, and relaunches.
Accessibility permission carries over — no reset, no re-grant.

Report an install as done only after checking it, not from a successful build:
`sqlite3 "/Library/Application Support/com.apple.TCC/TCC.db" "select auth_value from access
where client='com.redbuttonquit.app'"` must return `2`. The stronger check is functional: open
TextEdit, close its last window, confirm TextEdit quits. A build that compiles and installs
proves nothing about whether the app is actually authorized.
