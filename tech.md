# RedButtonQuit - Technical Specification

**Version**: 1.0
**Last Updated**: December 2025
**Target Platform**: macOS Sequoia (15.x)

---

## Table of Contents

1. [Technical Overview](#1-technical-overview)
2. [System Requirements](#2-system-requirements)
3. [Architecture Diagram](#3-architecture-diagram)
4. [Core Components](#4-core-components)
5. [Key APIs and Frameworks](#5-key-apis-and-frameworks)
6. [Data Flow](#6-data-flow)
7. [Permission Model](#7-permission-model)
8. [Configuration Storage](#8-configuration-storage)
9. [Build and Distribution](#9-build-and-distribution)
10. [Testing Strategy](#10-testing-strategy)
11. [Security Considerations](#11-security-considerations)
12. [Performance Considerations](#12-performance-considerations)
13. [Compatibility](#13-compatibility)
14. [Dependencies](#14-dependencies)
15. [Known Limitations](#15-known-limitations)

---

## 1. Technical Overview

### Purpose

RedButtonQuit is a macOS utility application that modifies the default window-close behavior. When a user clicks the red close button (or presses Cmd+W) on a window, the application will quit the entire application instead of just closing the window. This mimics the behavior many users expect from other operating systems where closing the last window terminates the application.

### High-Level Architecture

The application operates as a menu bar agent (LSUIElement) that:

1. Runs persistently in the background with minimal resource footprint
2. Monitors window events system-wide via the Accessibility API
3. Intercepts window destruction events and determines appropriate action
4. Terminates target applications when their windows are closed (per user configuration)
5. Provides a preferences interface for customization

### Design Philosophy

- **Lightweight**: Minimal memory and CPU usage; event-driven, not polling
- **Non-intrusive**: Menu bar only, no Dock icon unless user preference
- **Respectful**: Allows graceful application termination, never force-kills
- **Configurable**: Users control which apps are affected and behavior modes

---

## 2. System Requirements

### Minimum Requirements

| Requirement | Specification |
|-------------|---------------|
| **Operating System** | macOS 14.0 Sonoma or later |
| **Recommended OS** | macOS 15.0 Sequoia or later |
| **Architecture** | Apple Silicon (arm64) or Intel (x86_64) |
| **Memory** | Negligible (< 50 MB typical) |
| **Disk Space** | < 10 MB |
| **Permissions** | Accessibility permission (mandatory) |

### Recommended Requirements

| Requirement | Specification |
|-------------|---------------|
| **Operating System** | macOS 15.0 Sequoia or later |
| **Architecture** | Apple Silicon (arm64) |

### Permission Requirements

| Permission | Purpose | Required |
|------------|---------|----------|
| **Accessibility** | Monitor window events, detect button clicks | Mandatory |
| **Automation** | AppleScript fallback for termination | Optional |

---

## 3. Architecture Diagram

```
+------------------------------------------------------------------+
|                        RedButtonQuit                              |
+------------------------------------------------------------------+
|                                                                  |
|  +------------------------+    +---------------------------+     |
|  |   Menu Bar Controller  |    |   Preferences Manager     |     |
|  |   - Status item        |    |   - UserDefaults          |     |
|  |   - Menu management    |    |   - App exclusion list    |     |
|  |   - Quick toggles      |    |   - Behavior settings     |     |
|  +----------+-------------+    +-------------+-------------+     |
|             |                                |                   |
|             v                                v                   |
|  +----------------------------------------------------------+   |
|  |                    App Coordinator                        |   |
|  |    - Lifecycle management                                 |   |
|  |    - Component orchestration                              |   |
|  |    - Permission state management                          |   |
|  +---------------------------+------------------------------+   |
|                              |                                   |
|          +-------------------+-------------------+                |
|          |                                       |                |
|          v                                       v                |
|  +--------------------+              +------------------------+  |
|  | Accessibility      |              | App Termination        |  |
|  | Monitor            |              | Service                |  |
|  | - AXObserver       |   triggers   | - NSRunningApplication |  |
|  | - Event detection  |------------->| - Graceful termination |  |
|  | - Window tracking  |              | - Exclusion checking   |  |
|  +--------------------+              +------------------------+  |
|          |                                       |                |
|          v                                       v                |
+------------------------------------------------------------------+
           |                                       |
           v                                       v
+--------------------+                  +----------------------+
|   macOS            |                  |   Target             |
|   Accessibility    |                  |   Applications       |
|   Framework        |                  |   (to be terminated) |
+--------------------+                  +----------------------+
```

### Component Relationships

```
User Action (clicks red button)
         |
         v
+------------------+
| macOS sends      |
| AX notification  |
+--------+---------+
         |
         v
+------------------+
| Accessibility    |
| Monitor receives |
| notification     |
+--------+---------+
         |
         v
+------------------+
| Window Event     |
| Handler analyzes |
| - Is last window?|
| - Is app excluded|
+--------+---------+
         |
    +----+----+
    |         |
    v         v
  [Skip]   [Terminate]
              |
              v
+------------------+
| App Termination  |
| Service sends    |
| terminate signal |
+------------------+
```

---

## 4. Core Components

### 4.1 Accessibility Monitor

**Purpose**: Observes system-wide window events using the macOS Accessibility API.

**Responsibilities**:
- Create and manage AXObserver instances for running applications
- Register for relevant accessibility notifications
- Track window creation and destruction events
- Maintain a map of applications to their window counts
- Handle observer lifecycle (creation, invalidation, cleanup)

**Key Technical Details**:
- Uses `AXObserverCreate` to create observers for each monitored application
- Registers for `kAXWindowCreatedNotification` and `kAXUIElementDestroyedNotification`
- Adds observers to the main run loop via `CFRunLoopAddSource`
- Must handle cases where applications launch/quit dynamically

**Observer Registration Strategy**:
- Option A: Global observer on system-wide element (limited notification types)
- Option B: Per-application observers (more reliable, higher overhead)
- Recommendation: Per-application observers for active applications only

**Window Tracking**:
- Query window list via `kAXWindowsAttribute` on application AXUIElement
- Track window count changes to detect "last window" scenarios
- Handle edge cases: sheets, panels, popovers (should not trigger quit)

### 4.2 Window Event Handler

**Purpose**: Processes accessibility notifications and determines appropriate action.

**Responsibilities**:
- Receive notifications from Accessibility Monitor
- Determine if the closed element was a standard window (not sheet/panel)
- Check if the window was the last window of the application
- Consult Preferences Manager for user settings
- Dispatch termination request to App Termination Service

**Decision Logic**:

```
on WindowClosed(app, window):
    if app in exclusionList:
        return NO_ACTION

    if mode == QUIT_ON_ANY_CLOSE:
        return TERMINATE_APP

    if mode == QUIT_ON_LAST_WINDOW:
        remainingWindows = getWindowCount(app)
        if remainingWindows == 0:
            return TERMINATE_APP
        else:
            return NO_ACTION
```

**Window Type Detection**:
- Standard windows: `kAXStandardWindowSubrole`
- Dialogs/Sheets: Should NOT trigger quit (query `kAXRoleAttribute`)
- Floating panels: Should NOT trigger quit
- Full-screen windows: Require special handling

### 4.3 App Termination Service

**Purpose**: Handles graceful application termination with fallback strategies.

**Responsibilities**:
- Receive termination requests from Window Event Handler
- Verify application is still running and not in exclusion list
- Attempt graceful termination via `NSRunningApplication.terminate()`
- Implement fallback termination via AppleScript if primary fails
- Handle termination failures gracefully

**Termination Hierarchy**:

1. **Primary Method**: `NSRunningApplication.terminate()`
   - Sends `NSApplicationTerminateReply` to target app
   - Allows app to show save dialogs, perform cleanup
   - Non-blocking, returns immediately

2. **Secondary Method** (if primary fails): AppleScript
   - `tell application "AppName" to quit`
   - Requires Automation permission
   - More reliable for some applications

3. **Never Used**: `forceTerminate()` / SIGKILL
   - Could cause data loss
   - Only expose as explicit user action (never automatic)

**System App Protection**:
- Maintain hardcoded list of protected bundle identifiers
- Finder: `com.apple.finder`
- System Settings: `com.apple.systempreferences`
- Dock: `com.apple.dock`
- Others as identified during testing

### 4.4 Preferences Manager

**Purpose**: Manages user preferences and application configuration.

**Responsibilities**:
- Store/retrieve preferences using UserDefaults
- Manage app exclusion list (apps that should never be quit)
- Manage app inclusion list (if using opt-in mode)
- Handle mode selection (quit on any vs quit on last)
- Provide reactive updates to other components

**Settings Schema**:

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `isEnabled` | Bool | true | Global enable/disable |
| `quitMode` | Enum | lastWindow | When to trigger quit |
| `excludedBundleIDs` | [String] | [system apps] | Apps to never quit |
| `launchAtLogin` | Bool | false | Start on login |
| `showInDock` | Bool | false | Show Dock icon |
| `showMenuBarIcon` | Bool | true | Show menu bar icon |
| `playSound` | Bool | false | Audio feedback |

**Quit Modes**:
- `lastWindow`: Only quit when the last window is closed
- `anyWindow`: Quit whenever any window is closed (aggressive)
- `disabled`: Temporarily disable functionality

### 4.5 Menu Bar Controller

**Purpose**: Provides user interface via the macOS menu bar.

**Responsibilities**:
- Display status item in menu bar
- Show current enabled/disabled state
- Provide quick toggles for enable/disable
- Open preferences window
- Show "About" information
- Provide "Quit RedButtonQuit" option

**Menu Structure**:

```
[Icon] RedButtonQuit
├── Enabled                    [checkbox]
├── ─────────────
├── Quit Mode                  [submenu]
│   ├── On Last Window Close   [radio]
│   └── On Any Window Close    [radio]
├── ─────────────
├── Excluded Apps...           [opens preferences]
├── ─────────────
├── Launch at Login            [checkbox]
├── Preferences...             [opens full preferences]
├── ─────────────
├── About RedButtonQuit
└── Quit RedButtonQuit
```

**Visual States**:
- Enabled: Normal icon appearance
- Disabled: Dimmed/slashed icon
- No Accessibility Permission: Warning badge

---

## 5. Key APIs and Frameworks

### Core Frameworks

| Framework | Purpose | Import |
|-----------|---------|--------|
| **ApplicationServices** | Accessibility API (AXUIElement) | `import ApplicationServices` |
| **AppKit** | NSRunningApplication, NSStatusBar | `import AppKit` |
| **SwiftUI** | Preferences UI (macOS 14+) | `import SwiftUI` |
| **ServiceManagement** | Launch at login | `import ServiceManagement` |
| **Combine** | Reactive preferences updates | `import Combine` |

### Accessibility API Elements

| API | Purpose |
|-----|---------|
| `AXIsProcessTrusted()` | Check if app has accessibility permission |
| `AXUIElementCreateApplication()` | Create element reference for an app |
| `AXUIElementCreateSystemWide()` | Create system-wide element |
| `AXObserverCreate()` | Create notification observer |
| `AXObserverAddNotification()` | Register for specific notifications |
| `AXObserverGetRunLoopSource()` | Get run loop source for observer |
| `AXUIElementCopyAttributeValue()` | Query element attributes |
| `kAXWindowsAttribute` | Get list of windows |
| `kAXRoleAttribute` | Get element role |
| `kAXSubroleAttribute` | Get element subrole |

### Relevant Notifications

| Notification | When Fired |
|--------------|------------|
| `kAXWindowCreatedNotification` | New window opened |
| `kAXUIElementDestroyedNotification` | UI element destroyed |
| `kAXFocusedWindowChangedNotification` | Focus changed |
| `kAXApplicationActivatedNotification` | App became active |
| `kAXApplicationDeactivatedNotification` | App became inactive |

### Application Lifecycle APIs

| API | Purpose |
|-----|---------|
| `NSWorkspace.shared.runningApplications` | List running apps |
| `NSRunningApplication.terminate()` | Request app termination |
| `NSWorkspace.didLaunchApplicationNotification` | App launched |
| `NSWorkspace.didTerminateApplicationNotification` | App terminated |

### ServiceManagement (Launch at Login)

| API | Purpose |
|-----|---------|
| `SMAppService.mainApp` | Reference to current app service |
| `SMAppService.status` | Current registration status |
| `SMAppService.register()` | Enable launch at login |
| `SMAppService.unregister()` | Disable launch at login |

---

## 6. Data Flow

### Startup Flow

```
1. App launches
   |
   v
2. Check accessibility permission (AXIsProcessTrusted)
   |
   +---> Not granted: Show onboarding UI
   |                  Guide user to System Settings
   |                  Poll for permission grant
   |
   +---> Granted: Continue
   |
   v
3. Load preferences from UserDefaults
   |
   v
4. Initialize Menu Bar Controller
   |
   v
5. Subscribe to NSWorkspace notifications
   |
   v
6. For each running application:
   |
   +---> Create AXUIElement reference
   |
   +---> Create AXObserver
   |
   +---> Register for window notifications
   |
   +---> Add observer to run loop
   |
   v
7. Enter main run loop (app is now active)
```

### Runtime Event Flow

```
1. User clicks red button on target app window
   |
   v
2. macOS closes the window
   |
   v
3. macOS sends kAXUIElementDestroyedNotification
   |
   v
4. AXObserver callback fires in RedButtonQuit
   |
   v
5. Accessibility Monitor passes event to Window Event Handler
   |
   v
6. Window Event Handler:
   a. Identifies source application (bundle ID, PID)
   b. Checks if app is in exclusion list --> [Skip if excluded]
   c. Checks quit mode setting
   d. If QUIT_ON_LAST_WINDOW:
      - Query remaining window count
      - Skip if windows remain
   |
   v
7. App Termination Service:
   a. Verify app still running
   b. Call NSRunningApplication.terminate()
   c. Handle failure with AppleScript fallback
   |
   v
8. Target application receives terminate signal
   |
   v
9. Target application quits (may show save dialogs)
```

### Preferences Change Flow

```
1. User modifies setting in Preferences UI
   |
   v
2. SwiftUI @AppStorage updates UserDefaults
   |
   v
3. Combine publisher emits new value
   |
   v
4. Subscribers receive update:
   - Menu Bar Controller updates state
   - Accessibility Monitor adjusts behavior
   - App Termination Service updates exclusion cache
```

---

## 7. Permission Model

### Accessibility Permission

**Why Required**:
The Accessibility API is the only official way to monitor window events across applications on macOS. Without this permission, the app cannot:
- Observe when windows open or close
- Determine which application owns a window
- Count remaining windows for an application

**User Experience Flow**:

```
1. First Launch
   |
   v
2. App checks AXIsProcessTrusted()
   |
   +---> Returns false (not trusted)
   |
   v
3. Display onboarding window explaining:
   - What the app does
   - Why accessibility permission is needed
   - That the app cannot function without it
   - Privacy assurance (no data collection)
   |
   v
4. User clicks "Open System Settings"
   |
   v
5. App opens: System Settings > Privacy & Security > Accessibility
   (using URL: x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility)
   |
   v
6. App enters permission polling loop:
   - Check AXIsProcessTrusted() every 1 second
   - Show "Waiting for permission..." indicator
   |
   v
7. User toggles switch for RedButtonQuit
   |
   v
8. AXIsProcessTrusted() returns true
   |
   v
9. Onboarding dismisses, app activates full functionality
```

**Permission Revocation Handling**:
- App should periodically verify permission (every 30 seconds)
- If revoked: Disable functionality, show notification, guide to re-enable
- Never crash or behave unexpectedly if permission is revoked

### Automation Permission (Optional)

**Purpose**: Fallback termination via AppleScript

**Acquisition**: Prompted automatically on first AppleScript execution

**If Denied**: Primary termination method still works; fallback unavailable

---

## 8. Configuration Storage

### Storage Mechanism

**Primary**: `UserDefaults.standard` with app-specific suite

**Sync**: NOT using iCloud sync (local-only preferences)

### Data Schema

```
UserDefaults Keys:
├── com.redbutton.quit.isEnabled          : Bool
├── com.redbutton.quit.quitMode           : String (enum raw value)
├── com.redbutton.quit.excludedBundleIDs  : [String]
├── com.redbutton.quit.launchAtLogin      : Bool
├── com.redbutton.quit.showInDock         : Bool
├── com.redbutton.quit.showMenuBarIcon    : Bool
├── com.redbutton.quit.playSound          : Bool
└── com.redbutton.quit.hasCompletedOnboarding : Bool
```

### Default Values

```
isEnabled: true
quitMode: "lastWindow"
excludedBundleIDs: [
    "com.apple.finder",
    "com.apple.systempreferences",
    "com.apple.ActivityMonitor"
]
launchAtLogin: false
showInDock: false
showMenuBarIcon: true
playSound: false
hasCompletedOnboarding: false
```

### Migration Strategy

If schema changes between versions:
1. Check for version key in UserDefaults
2. If missing or older, run migration
3. Update version key after migration

---

## 9. Build and Distribution

### Xcode Project Configuration

**Project Structure**:
```
RedButtonQuit/
├── RedButtonQuit.xcodeproj
├── RedButtonQuit/
│   ├── App/
│   │   ├── RedButtonQuitApp.swift
│   │   └── AppDelegate.swift
│   ├── Core/
│   │   ├── AccessibilityMonitor.swift
│   │   ├── WindowEventHandler.swift
│   │   ├── AppTerminationService.swift
│   │   └── PreferencesManager.swift
│   ├── UI/
│   │   ├── MenuBarController.swift
│   │   ├── PreferencesView.swift
│   │   └── OnboardingView.swift
│   ├── Resources/
│   │   ├── Assets.xcassets
│   │   └── Localizable.strings
│   └── Supporting/
│       ├── Info.plist
│       └── RedButtonQuit.entitlements
└── RedButtonQuitTests/
```

**Build Settings**:

| Setting | Value |
|---------|-------|
| Deployment Target | macOS 14.0 |
| Swift Language Version | Swift 5.9+ |
| Architectures | $(ARCHS_STANDARD) (arm64, x86_64) |
| Build Active Architecture Only | No (Release) |

**Info.plist Configuration**:

| Key | Value | Purpose |
|-----|-------|---------|
| `LSUIElement` | YES | Menu bar app, no Dock icon |
| `NSAccessibilityUsageDescription` | [Explanation text] | Accessibility permission prompt |
| `LSApplicationCategoryType` | public.app-category.utilities | App Store category |
| `CFBundleVersion` | Build number | Build identifier |
| `CFBundleShortVersionString` | Semantic version | User-facing version |

### Signing Requirements

**Development**:
- Personal Team or Apple Developer account
- Automatic signing for development

**Distribution**:
- Apple Developer Program membership required
- Developer ID Application certificate
- Developer ID Installer certificate (for PKG distribution)

### Entitlements

**RedButtonQuit.entitlements**:

| Entitlement | Value | Purpose |
|-------------|-------|---------|
| `com.apple.security.app-sandbox` | NO | Accessibility API requires no sandbox |
| `com.apple.security.hardened-runtime` | YES | Required for notarization |
| `com.apple.security.automation.apple-events` | YES | AppleScript fallback |

**Critical**: App Sandbox MUST be disabled. This prevents Mac App Store distribution.

### Notarization Process

1. **Archive**: Product > Archive in Xcode
2. **Export**: Distribute App > Developer ID > Upload (or Export Notarized App)
3. **Automatic Notarization**: Xcode submits to Apple's notarization service
4. **Stapling**: Xcode staples ticket to app after approval
5. **Result**: App can be distributed and will pass Gatekeeper

**Command Line Alternative**:
```
# Submit for notarization
xcrun notarytool submit RedButtonQuit.zip --apple-id <email> --team-id <team> --password <app-specific-password>

# Check status
xcrun notarytool info <submission-id> --apple-id <email> --team-id <team> --password <password>

# Staple ticket
xcrun stapler staple RedButtonQuit.app
```

### Distribution Channels

| Channel | Format | Notes |
|---------|--------|-------|
| **Direct Download** | DMG or ZIP | Website distribution |
| **Homebrew Cask** | Cask formula | `brew install --cask redbuttonquit` |
| **GitHub Releases** | ZIP + DMG | Open source distribution |
| **Mac App Store** | NOT POSSIBLE | Requires sandbox, which we cannot use |

**DMG Creation**:
- Include app bundle
- Include symbolic link to /Applications
- Optional: Custom background image
- Tool: `create-dmg` or `hdiutil`

---

## 10. Testing Strategy

### Unit Testing

**Testable Components**:
- PreferencesManager: UserDefaults read/write
- Exclusion list logic
- Quit mode decision logic

**Mocking Strategy**:
- Protocol-based dependency injection
- Mock NSRunningApplication for termination tests
- Mock AXUIElement responses

### Integration Testing

**Test Scenarios**:

| Scenario | Steps | Expected Result |
|----------|-------|-----------------|
| Basic quit on close | Open TextEdit, close window | TextEdit quits |
| Exclusion list | Add Finder to exclusions, close Finder window | Finder stays open |
| Last window mode | Open 2 windows, close 1 | App stays open |
| Last window mode | Open 2 windows, close both | App quits after 2nd |
| System app protection | Close Finder window | Finder never quits |
| Permission revoked | Revoke accessibility permission | App shows warning, disables |

### Manual Testing Checklist

- [ ] Fresh install on clean macOS
- [ ] Accessibility permission flow
- [ ] Menu bar icon appears
- [ ] Enable/disable toggle works
- [ ] Preferences window opens
- [ ] Exclusion list add/remove
- [ ] Quit mode switching
- [ ] Launch at login toggle
- [ ] App survives sleep/wake
- [ ] App survives fast user switching
- [ ] Multiple displays
- [ ] Mission Control / Spaces
- [ ] Full-screen apps

### Accessibility Testing

- VoiceOver compatibility for preferences UI
- Keyboard navigation in preferences
- Sufficient contrast in menu bar icon

### Performance Testing

- Memory usage over 24 hours
- CPU usage while idle
- CPU usage during rapid window open/close
- Observer cleanup (no memory leaks)

---

## 11. Security Considerations

### Hardened Runtime

Required for notarization. Restricts:
- JIT compilation
- Unsigned executable memory
- DYLD environment variables
- Library validation

**Exceptions Needed**:
- `com.apple.security.automation.apple-events` for AppleScript

### Privacy

**Data Collection**: None

**Network Access**: None required (app is offline-capable)

**Sensitive Access**:
- Accessibility API observes window titles (required for function)
- No data is stored, transmitted, or logged

### Code Signing

- All code must be signed with Developer ID
- Notarization verifies no malware
- Gatekeeper validates on first launch

### Attack Surface

| Vector | Mitigation |
|--------|------------|
| Malicious accessibility observer | Only monitors, never modifies |
| Termination of wrong app | Exclusion list, confirmation option |
| Privilege escalation | App runs as user, no elevated privileges |

---

## 12. Performance Considerations

### Resource Targets

| Metric | Target | Maximum |
|--------|--------|---------|
| Memory (idle) | < 30 MB | 50 MB |
| Memory (active) | < 40 MB | 75 MB |
| CPU (idle) | < 0.1% | 0.5% |
| CPU (event processing) | < 1% | 5% |
| Disk I/O | Minimal | Preferences only |

### Optimization Strategies

**Event-Driven Architecture**:
- No polling loops
- All work triggered by system notifications
- Run loop integration for efficient waiting

**Observer Management**:
- Only create observers for running applications
- Remove observers when applications quit
- Lazy observer creation (only when app becomes active)

**Memory Management**:
- Use weak references where appropriate
- Clean up AXUIElement references promptly
- Avoid retaining application references unnecessarily

**Efficient Data Structures**:
- Use Set<String> for exclusion list (O(1) lookup)
- Cache bundle ID to PID mappings
- Avoid repeated Accessibility API queries

### Battery Impact

- Minimal: Event-driven, no polling
- No background network activity
- No timers except permission polling (only when permission missing)

---

## 13. Compatibility

### macOS Version Support

| macOS Version | Support Level | Notes |
|---------------|---------------|-------|
| macOS 15 Sequoia | Full | Primary target |
| macOS 14 Sonoma | Full | Minimum requirement |
| macOS 13 Ventura | Untested | May work, not guaranteed |
| macOS 12 and earlier | Not Supported | Use older Accessibility APIs |

### Architecture Support

| Architecture | Support |
|--------------|---------|
| Apple Silicon (arm64) | Full, native |
| Intel (x86_64) | Full, native |
| Rosetta 2 | Works, but native preferred |

**Universal Binary**: Single app bundle contains both architectures.

### Application Compatibility

**Tested Compatible**:
- Standard AppKit applications
- Standard SwiftUI applications
- Electron apps (Chrome, VS Code, Slack)
- Catalyst apps

**Known Issues**:
- Some games: May not fire accessibility events properly
- Some virtualization apps: Complex window hierarchies
- JetBrains IDEs: Multiple window types require careful handling

---

## 14. Dependencies

### External Dependencies

**None**. The application uses only Apple system frameworks.

### Framework Dependencies (Apple-provided)

| Framework | Availability | Required |
|-----------|--------------|----------|
| Foundation | macOS 10.0+ | Yes |
| AppKit | macOS 10.0+ | Yes |
| ApplicationServices | macOS 10.0+ | Yes |
| SwiftUI | macOS 10.15+ | Yes |
| Combine | macOS 10.15+ | Yes |
| ServiceManagement | macOS 10.6+ | Yes |

### Why No External Dependencies?

- Simpler distribution (no dependency management)
- Smaller app size
- No supply chain security concerns
- Apple frameworks are stable and well-documented
- All required functionality available in system frameworks

---

## 15. Known Limitations

### Technical Limitations

| Limitation | Reason | Workaround |
|------------|--------|------------|
| Cannot distribute via Mac App Store | Requires disabled sandbox | Direct distribution, Homebrew |
| Requires manual permission grant | macOS security model | Clear onboarding UX |
| Cannot intercept close before it happens | AX notifications are post-event | Accept default close, then terminate |
| May miss rapid window events | Observer callback timing | Acceptable trade-off |
| Cannot quit system apps | Hardcoded protection | By design |

### Behavioral Limitations

| Limitation | Description |
|------------|-------------|
| Save dialogs still appear | App terminates gracefully, so save prompts show |
| Unsaved changes may be lost | If user dismisses save dialog, data lost |
| Multi-window apps may lose state | Closing one window quits app |
| Background-only apps unaffected | No windows to close |

### User Experience Limitations

| Limitation | Mitigation |
|------------|------------|
| Learning curve | Clear onboarding, documentation |
| Different from default macOS | User chose to install, explicit opt-in |
| Can quit apps accidentally | Exclusion list, confirmation option |

### Platform Limitations

| Limitation | Description |
|------------|-------------|
| macOS only | No iOS/iPadOS (different window model) |
| No remote management | Per-user installation only |
| Accessibility permission required | Cannot be deployed silently via MDM |

---

## Appendix A: Glossary

| Term | Definition |
|------|------------|
| **AXUIElement** | Accessibility UI element reference type |
| **AXObserver** | Object that receives accessibility notifications |
| **Bundle ID** | Unique reverse-DNS identifier for an app (e.g., com.apple.finder) |
| **Hardened Runtime** | macOS security feature restricting certain capabilities |
| **LSUIElement** | Info.plist key making app a background agent |
| **Notarization** | Apple's automated malware scanning for distribution |
| **PID** | Process identifier, unique numeric ID for running process |
| **SMAppService** | ServiceManagement API for login items |

---

## Appendix B: Reference Documents

- [Apple Accessibility Programming Guide](https://developer.apple.com/documentation/accessibility)
- [AXUIElement Reference](https://developer.apple.com/documentation/applicationservices/axuielement)
- [NSRunningApplication Documentation](https://developer.apple.com/documentation/appkit/nsrunningapplication)
- [ServiceManagement Framework](https://developer.apple.com/documentation/servicemanagement)
- [Notarizing macOS Software](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution)
- [Hardened Runtime Entitlements](https://developer.apple.com/documentation/security/hardened_runtime)

---

*Document Version: 1.0*
*Last Updated: December 2025*
