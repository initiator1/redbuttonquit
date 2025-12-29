# RedButtonQuit - Product Plan

**Document Version:** 1.0
**Last Updated:** December 5, 2025
**Status:** Planning Phase

---

## 1. Executive Summary

RedButtonQuit is a lightweight macOS utility that changes the behavior of the red "close" button (the leftmost traffic light button) to quit applications entirely rather than just closing the current window. This addresses a fundamental UX difference between macOS and Windows that frustrates users transitioning between platforms.

---

## 2. Problem Statement

### The macOS Window Close Paradigm

On macOS, clicking the red close button only closes the current window—the application continues running in the background. This is by design: macOS treats windows and applications as separate concepts. Users can have an app running with no visible windows, and the app remains accessible via the Dock or Cmd+Tab.

### User Frustration Points

1. **Platform Switchers:** Users coming from Windows expect clicking the "X" button to quit the application. The macOS behavior feels inconsistent and wastes system resources in their mental model.

2. **Resource Consciousness:** Users see applications persisting in their Dock and assume they're consuming memory/CPU unnecessarily (even if macOS manages this efficiently).

3. **Muscle Memory:** The expectation that closing a window quits an app is deeply ingrained for many users and creates daily friction.

4. **Inconsistent Behavior:** Some macOS apps DO quit when closing the last window (Preview, Calculator, System Preferences), making the behavior feel arbitrary.

### The Underlying Need

Users want predictable, consistent behavior: "When I close all windows of an app, I'm done with that app—quit it."

---

## 3. Solution Overview

RedButtonQuit is a menu bar application that:

1. Runs quietly in the background
2. Monitors window close events system-wide via the macOS Accessibility API
3. When the last window of an application is closed (via red button click), automatically sends a quit command to that application
4. Provides user control over which applications this behavior applies to

### Technical Approach

- **Accessibility API (AXUIElement):** Monitor `AXUIElementDestroyed` notifications and `kAXWindowRole` changes
- **NSWorkspace Observation:** Track running applications and their window counts
- **CGWindowList:** Enumerate windows to detect when an app's last window closes
- **Menu Bar App:** Minimal UI footprint using SwiftUI with AppKit integration for the status item

---

## 4. Target Audience

### Primary Users

1. **Windows Converts:** Users who recently switched from Windows and find the macOS close button behavior unintuitive
2. **Cross-Platform Users:** People who regularly switch between macOS and Windows and want consistent behavior
3. **Minimalists:** Users who prefer a "clean" system with no background apps they didn't explicitly leave running

### Secondary Users

1. **Power Users:** Those who want fine-grained control over which apps auto-quit
2. **Developers:** Who may want certain apps (terminals, IDEs) to persist while others quit

### User Profile

- Comfortable granting Accessibility permissions (understands the system prompt)
- Willing to use non-App Store software
- Values utility over aesthetics
- Likely has tried similar tools or at least searched for solutions

---

## 5. Distribution Strategy

### Critical Constraint: Mac App Store Incompatibility

> **This application CANNOT be distributed through the Mac App Store.**

#### Why Not?

The Mac App Store requires all applications to be **sandboxed** (App Sandbox entitlement). However, RedButtonQuit requires the **Accessibility API** to monitor and respond to window events across ALL applications on the system.

The Accessibility API, by its nature, requires system-wide access to UI elements—this is fundamentally incompatible with sandboxing, which restricts apps to their own container.

**There is no workaround.** This is not a technical limitation we can engineer around; it's a policy enforcement by Apple for App Store apps.

#### Impact on Original Plans

If App Store distribution was the intended path, this constraint requires a complete pivot of the distribution strategy. This affects:

- **Discoverability:** No App Store search presence
- **Trust:** Users must trust a non-App Store download
- **Updates:** Must implement our own update mechanism
- **Revenue:** No Apple payment processing (if monetizing)

### Chosen Distribution Path: Direct Download + Homebrew

#### Primary: Direct Website Download

**Requirements:**
- Apple Developer Program membership ($99/year)
- Code signing with Developer ID certificate
- Notarization via Apple's notary service
- Stapling the notarization ticket to the app

**User Experience:**
1. Download `.dmg` from website
2. Open DMG, drag to Applications
3. On first launch, Gatekeeper verifies notarization
4. User prompted to grant Accessibility permission
5. App runs

#### Secondary: Homebrew Cask

```bash
brew install --cask redbuttonquit
```

**Benefits:**
- Familiar to technical users
- Automatic updates via `brew upgrade`
- Builds trust through community curation
- No cost to distribute

**Requirements:**
- Submit formula to homebrew-cask repository
- Host releases on GitHub with consistent versioning

#### Tertiary: GitHub Releases

- Source code available for inspection
- Pre-built notarized binaries attached to releases
- Appeals to security-conscious users who want to verify

### Update Mechanism

Since we cannot use App Store automatic updates, we must implement:

- **Sparkle Framework:** Industry-standard update framework for macOS apps
- Update feed hosted on GitHub releases or dedicated endpoint
- User-configurable: automatic updates, check on launch, or manual only

---

## 6. Key Features

### Core Features (MVP)

| Feature | Description | Priority |
|---------|-------------|----------|
| Quit on Last Window Close | When user closes the last window of an app, quit the app | P0 |
| Menu Bar Presence | Minimal menu bar icon for access and status | P0 |
| Accessibility Permission Flow | Clear guidance for granting required permissions | P0 |
| Global Enable/Disable | Quick toggle to disable the behavior entirely | P0 |
| Exclusion List | Specify apps that should NOT auto-quit | P0 |
| Login Item Support | Option to start at system boot | P0 |

### Enhanced Features (v1.x)

| Feature | Description | Priority |
|---------|-------------|----------|
| Inclusion List Mode | Inverse of exclusion: ONLY listed apps auto-quit | P1 |
| Per-App Delay | Wait X seconds before quitting (in case of accidental close) | P1 |
| Undo Quit | Brief grace period to undo an auto-quit | P1 |
| Notification Option | Optional notification when an app is auto-quit | P2 |
| Statistics | Track how many times the feature triggered | P2 |
| Keyboard Shortcut | Quick toggle via global hotkey | P2 |

### Non-Features (Explicitly Out of Scope)

- **Modifying other apps' behavior permanently:** We observe and react; we don't patch apps
- **Requiring SIP disabled:** Must work on stock macOS
- **Universal quit (Cmd+Q replacement):** Only affects red button behavior
- **Cross-platform:** macOS only, no iOS/iPadOS

---

## 7. User Experience

### First Launch Flow

```
1. User opens RedButtonQuit.app
   │
2. Welcome Screen
   ├── Brief explanation of what the app does
   ├── Explanation that Accessibility permission is required
   └── "Grant Permission" button
   │
3. System Accessibility prompt appears
   ├── User opens System Settings > Privacy & Security > Accessibility
   ├── Enables RedButtonQuit in the list
   └── Returns to app
   │
4. Permission Confirmed Screen
   ├── "You're all set!"
   ├── Brief tutorial on menu bar icon
   └── Option to enable "Start at Login"
   │
5. App minimizes to menu bar
   └── Ready to work
```

### Ongoing Usage

**Menu Bar Icon:**
- Click: Opens dropdown menu
- Right-click: Same as click (no distinction)

**Menu Bar Menu:**
```
┌─────────────────────────┐
│ ✓ Enabled               │
├─────────────────────────┤
│   Excluded Apps...      │
│   Preferences...        │
├─────────────────────────┤
│   About RedButtonQuit   │
│   Check for Updates...  │
├─────────────────────────┤
│   Quit RedButtonQuit    │
└─────────────────────────┘
```

### The Core Behavior (Invisible When Working)

1. User clicks red close button on an app's window
2. If it's the last window of that app:
   - RedButtonQuit detects window closure
   - Checks if app is in exclusion list
   - If not excluded: sends quit command to the app
   - App quits gracefully (can show "save changes" dialogs)
3. User perceives: "Closing the window quit the app" (desired behavior)

### Edge Cases Handled

| Scenario | Behavior |
|----------|----------|
| App has multiple windows, close one | Nothing special—app remains running |
| App is in exclusion list | Normal macOS behavior (window closes, app persists) |
| App was hidden, user closes last visible window | Quit (hidden doesn't mean "in use") |
| App is document-based with unsaved changes | App's own "save?" dialog appears normally |
| User Cmd+Q quits app normally | No interference |
| App crashes | No interference—we only act on clean window closure |

---

## 8. Success Criteria

### Functional Requirements

| ID | Requirement | Verification Method |
|----|-------------|---------------------|
| F1 | App correctly identifies when last window closes | Automated testing + manual verification |
| F2 | App quits target application within 500ms of window close | Timing measurement |
| F3 | Excluded apps are never auto-quit | Regression testing |
| F4 | App survives sleep/wake cycles | Manual testing |
| F5 | App works on both Apple Silicon and Intel | Test on both architectures |
| F6 | App works on macOS Sequoia (15.x) | Primary test platform |
| F7 | Accessibility permission request flow is clear | User testing |

### Non-Functional Requirements

| ID | Requirement | Target |
|----|-------------|--------|
| NF1 | Memory usage | < 30 MB resident |
| NF2 | CPU usage at idle | < 0.1% |
| NF3 | CPU usage during event | < 1% spike |
| NF4 | Startup time | < 1 second to menu bar |
| NF5 | No UI lag introduced | 0ms added to window close |

### User Acceptance Criteria

- [ ] Windows convert users report the behavior "feels natural"
- [ ] No false positives (apps quitting when they shouldn't)
- [ ] Permission setup takes < 60 seconds for typical user
- [ ] Update mechanism works seamlessly

---

## 9. Risks and Mitigations

### High Priority Risks

#### Risk 1: Accessibility Permission Friction

**Description:** Users may be unwilling to grant Accessibility permissions due to security concerns or may not understand the process.

**Likelihood:** High
**Impact:** High (app is useless without permission)

**Mitigations:**
- Crystal-clear explanation of WHY the permission is needed
- Visual guide with screenshots of System Settings
- Link to Apple's documentation on Accessibility permissions
- Explanation that Accessibility permissions are auditable and revocable
- Consider: helper tool that opens System Settings to correct pane

#### Risk 2: macOS Updates Break Functionality

**Description:** Apple may change Accessibility API behavior, window management, or security model in future macOS versions.

**Likelihood:** Medium
**Impact:** High (could break core functionality)

**Mitigations:**
- Test on macOS betas during Apple's preview period
- Abstract Accessibility API usage to isolate changes
- Monitor Apple developer forums and release notes
- Build automated tests that catch behavioral changes
- Maintain responsive update cadence

#### Risk 3: Distribution Trust Issues

**Description:** Users may not trust software downloaded outside the App Store.

**Likelihood:** Medium
**Impact:** Medium (reduces adoption)

**Mitigations:**
- Notarization (mandatory for Gatekeeper anyway)
- Open source the application (builds trust)
- Homebrew distribution (community vetted)
- Clear privacy policy (we collect no data)
- Code signing with verified Developer ID

#### Risk 4: App-Specific Incompatibilities

**Description:** Some applications may have unusual window management that causes false positives or failures.

**Likelihood:** Medium
**Impact:** Low (can be addressed per-app)

**Mitigations:**
- Pre-populate exclusion list with known problem apps
- Make it trivial to add apps to exclusion list
- Community-contributed exclusion list updates
- Document known incompatible apps

### Medium Priority Risks

#### Risk 5: Performance Impact

**Description:** Monitoring all window events could impact system performance.

**Likelihood:** Low
**Impact:** Medium

**Mitigations:**
- Event-driven architecture (no polling)
- Minimal processing in event handlers
- Profile and optimize during development
- Set hard limits on memory/CPU usage

#### Risk 6: Conflict with Similar Apps

**Description:** Users may have RedQuits, Swift Quit, or similar installed, causing conflicts.

**Likelihood:** Low
**Impact:** Low

**Mitigations:**
- Detect other apps and warn user
- Document that only one such app should run
- Graceful handling of duplicate quit commands

---

## 10. Prior Art & Differentiation

### Competitive Landscape

#### RedQuits (by Carsten Mielke)

**Status:** Legacy, Intel-only
**Approach:** Accessibility API
**Limitations:**
- Not updated for Apple Silicon (runs via Rosetta)
- No native ARM build
- Minimal UI/configuration options
- Unclear maintenance status

**Our Differentiation:**
- Native Universal Binary (Apple Silicon + Intel)
- Modern SwiftUI interface
- Active maintenance commitment
- Enhanced configuration options

#### Swift Quit

**Status:** Active, Modern
**Approach:** Accessibility API
**Features:**
- Configurable app lists
- Modern UI
- Active development

**Our Differentiation:**
- Fully open source (trust through transparency)
- Homebrew distribution
- Focus on simplicity (Swift Quit may have feature bloat)
- Potentially different UX philosophy

#### Goodbye (SIMBL-based)

**Status:** Obsolete/Broken
**Approach:** Code injection via SIMBL framework
**Limitations:**
- Requires disabling System Integrity Protection (SIP)
- Breaks with every macOS update
- Security nightmare
- Effectively dead

**Our Differentiation:**
- Works with SIP enabled (100% stock macOS)
- Uses supported APIs only
- No code injection

### Our Unique Positioning

1. **Open Source:** Full transparency, community contributions welcome
2. **Modern Stack:** Swift 5.9+, SwiftUI, targeting current macOS
3. **Universal Binary:** Native on all Macs
4. **Minimal Footprint:** No resource bloat
5. **Simple Distribution:** Homebrew and direct download
6. **Privacy First:** No analytics, no network calls except updates

---

## 11. Technical Architecture Overview

### Component Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                      RedButtonQuit                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐  │
│  │   Menu Bar   │    │  Preferences │    │   Onboarding │  │
│  │     View     │    │    Window    │    │     Flow     │  │
│  │  (SwiftUI)   │    │  (SwiftUI)   │    │  (SwiftUI)   │  │
│  └──────┬───────┘    └──────┬───────┘    └──────────────┘  │
│         │                   │                               │
│  ┌──────┴───────────────────┴───────┐                       │
│  │         App Coordinator          │                       │
│  │    (State Management, Logic)     │                       │
│  └──────────────┬───────────────────┘                       │
│                 │                                           │
│  ┌──────────────┴───────────────────┐                       │
│  │      Window Observer Service     │◄──── Accessibility    │
│  │  (AXObserver, CGWindowList)      │      API Events       │
│  └──────────────┬───────────────────┘                       │
│                 │                                           │
│  ┌──────────────┴───────────────────┐                       │
│  │      App Lifecycle Service       │                       │
│  │  (NSWorkspace, quit commands)    │                       │
│  └──────────────────────────────────┘                       │
│                                                             │
│  ┌────────────────┐  ┌─────────────────┐                    │
│  │  Exclusions    │  │   Preferences   │                    │
│  │   Storage      │  │    Storage      │                    │
│  │  (UserDefaults)│  │  (UserDefaults) │                    │
│  └────────────────┘  └─────────────────┘                    │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Technology Choices

| Component | Technology | Rationale |
|-----------|------------|-----------|
| UI Framework | SwiftUI | Modern, declarative, less code |
| Menu Bar | AppKit NSStatusItem + SwiftUI | SwiftUI alone can't do menu bar |
| Accessibility | AXUIElement APIs | Only way to observe window events |
| Window Enumeration | CGWindowListCopyWindowInfo | Fast, reliable |
| App Lifecycle | NSWorkspace + NSRunningApplication | Standard approach |
| Storage | UserDefaults | Simple, sufficient for preferences |
| Updates | Sparkle | Industry standard |
| Distribution | Notarized .dmg + Homebrew | Best reach without App Store |

---

## 12. Development Phases

### Phase 1: Foundation (Week 1-2)

- [ ] Project setup with Swift Package Manager
- [ ] Menu bar app skeleton
- [ ] Accessibility permission detection and request flow
- [ ] Basic window observation (proof of concept)

### Phase 2: Core Functionality (Week 3-4)

- [ ] Window close detection for all apps
- [ ] "Last window" detection logic
- [ ] Quit command dispatch
- [ ] Basic exclusion list (hardcoded)

### Phase 3: User Experience (Week 5-6)

- [ ] Preferences window (exclusion list management)
- [ ] Onboarding flow
- [ ] Login item support
- [ ] Settings persistence

### Phase 4: Polish & Distribution (Week 7-8)

- [ ] Sparkle integration for updates
- [ ] Code signing and notarization pipeline
- [ ] DMG creation automation
- [ ] Homebrew cask formula
- [ ] Documentation and website

### Phase 5: Launch & Iterate

- [ ] Public release
- [ ] Monitor for compatibility issues
- [ ] Respond to user feedback
- [ ] Plan v1.1 features

---

## 13. Open Questions

1. **Monetization:** Free? Paid? Donation-ware? (Affects effort investment)
2. **Open Source License:** MIT? GPL? Apache 2.0? (Affects contribution model)
3. **App Name:** "RedButtonQuit" vs alternatives (trademark search needed)
4. **Website:** Need a landing page for direct download?
5. **Support:** GitHub Issues sufficient, or need email support?

---

## 14. Appendix: Accessibility API Reference

### Key APIs Used

```swift
// Observing window events
AXObserverCreate(pid, callback, &observer)
AXObserverAddNotification(observer, element, kAXUIElementDestroyedNotification, nil)

// Getting window list
CGWindowListCopyWindowInfo(.optionOnScreenOnly, kCGNullWindowID)

// Checking running apps
NSWorkspace.shared.runningApplications

// Quitting an app
app.terminate() // Graceful
// or
NSRunningApplication(processIdentifier: pid)?.terminate()
```

### Required Entitlements

```xml
<!-- Info.plist -->
<key>NSAccessibilityUsageDescription</key>
<string>RedButtonQuit needs Accessibility access to detect when you close application windows, so it can automatically quit apps when their last window is closed.</string>
```

**Note:** Cannot use App Sandbox entitlement—mutually exclusive with Accessibility system-wide access.

---

*Document prepared for RedButtonQuit project planning. This is a living document and will be updated as decisions are made and implementation progresses.*
