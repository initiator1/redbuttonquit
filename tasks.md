# RedButtonQuit Development Tasks

> Complete task checklist for building RedButtonQuit macOS menu bar utility
>
> **Target:** macOS Sequoia (14.0+) | **Distribution:** Direct, Homebrew, GitHub (NOT Mac App Store)
>
> **Last Updated:** 2026-01-01 (Login item path issue documented)

---

## Known Issues

### KI-001: Login Item Fails After Restart When Running From Xcode Debug Build

**Status:** Documented | **Severity:** Medium | **Discovered:** 2026-01-01

**Description:** If a user enables "Launch at Login" while running the app from Xcode's DerivedData debug build path, the login item will fail silently after macOS restart.

**Root Cause:** `SMAppService.mainApp.register()` registers the login item using the current running app's bundle path. When running from DerivedData, this path is ephemeral and may not exist after Xcode cleanup or rebuild.

**Workaround:**
1. Install the app to `/Applications` before enabling "Launch at Login"
2. If already broken: `defaults delete com.redbuttonquit.app com.redbuttonquit.launchAtLogin`
3. Re-enable Launch at Login from the properly installed app

**Planned Fix:** Add runtime validation in `PreferencesManager.updateLoginItem()` to detect non-production paths and warn users. See Phase 3.4 additional tasks.

---

## Phase 1: Foundation (Week 1-2)

### 1.1 Project Setup & Configuration

- [x] Create new Xcode project (macOS App, Swift, SwiftUI lifecycle)
- [x] Set deployment target to macOS 14.0 (Sequoia)
- [x] Configure for Universal Binary (arm64 + x86_64)
- [x] Set Swift language version to 5.9+
- [x] Create folder structure:
  - [x] App/ directory
  - [x] Core/ directory
  - [x] UI/ directory
  - [x] Resources/ directory
  - [x] Supporting/ directory
- [x] Configure Info.plist:
  - [x] Set LSUIElement to YES (menu bar app, no dock icon by default)
  - [x] Add NSAccessibilityUsageDescription with clear explanation
  - [x] Set LSApplicationCategoryType to public.app-category.utilities
  - [x] Configure CFBundleVersion (build number)
  - [x] Configure CFBundleShortVersionString (marketing version)
  - [x] Set bundle identifier (com.yourcompany.RedButtonQuit)
- [x] Configure Entitlements file:
  - [x] Set com.apple.security.app-sandbox to NO (required for Accessibility API)
  - [x] Set com.apple.security.hardened-runtime to YES (required for notarization)
  - [x] Add com.apple.security.automation.apple-events to YES (AppleScript fallback)
- [x] Set up Git repository
- [x] Create .gitignore for Xcode/Swift projects
- [x] Create initial README.md placeholder
- [x] Set up development signing (personal team or dev certificate)

### 1.2 App Lifecycle & Menu Bar Skeleton

- [x] Create RedButtonQuitApp.swift (SwiftUI App entry point)
- [x] Create AppDelegate.swift with NSApplicationDelegate
- [x] Connect AppDelegate to SwiftUI App using @NSApplicationDelegateAdaptor
- [x] Implement applicationDidFinishLaunching in AppDelegate
- [x] Create MenuBarController.swift skeleton
- [x] Initialize NSStatusItem in system status bar
- [x] Set status item length (NSStatusItem.squareLength or variable)
- [x] Create placeholder menu bar icon in Assets.xcassets
  - [x] Design icon for light mode
  - [x] Design icon for dark mode
  - [x] Create template image version
- [x] Implement basic NSMenu for status item
- [x] Add placeholder menu items:
  - [x] "RedButtonQuit" header (disabled)
  - [x] Separator
  - [x] "Quit RedButtonQuit" action
- [x] Verify app launches to menu bar without dock icon
- [x] Verify app does not show in Cmd+Tab switcher
- [x] Test menu appears on click

### 1.3 Accessibility Permission Foundation

- [x] Create AccessibilityMonitor.swift skeleton class
- [x] Implement AXIsProcessTrusted() check method
- [x] Implement AXIsProcessTrustedWithOptions() for prompting
- [x] Create permission status enum (notDetermined, denied, authorized)
- [x] Implement method to open System Settings accessibility pane
  - [x] Use x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility URL
- [x] Create permission polling mechanism (Timer-based, 1 second interval)
- [x] Implement Combine publisher for permission state changes
- [x] Add observer for app becoming active (to recheck permissions)
- [x] Test permission detection on fresh app launch
- [x] Test permission change detection when granted in System Settings

### 1.4 Basic Window Observation Setup

- [x] Research AXObserver API requirements
- [x] Implement AXObserverCreate wrapper method
- [x] Implement AXObserverAddNotification for window events
- [x] Set up CFRunLoopAddSource integration
- [x] Create callback function for accessibility notifications
- [x] Implement observer cleanup (AXObserverRemoveNotification, CFRunLoopRemoveSource)
- [x] Test observing single hardcoded application (e.g., TextEdit)
- [x] Verify notifications received when windows open/close
- [x] Handle observer creation failures gracefully

---

## Phase 2: Core Functionality (Week 3-4)

### 2.1 Full Accessibility Monitor Implementation

- [x] Create dictionary to track observers per application (keyed by pid)
- [x] Implement method to get running applications (NSWorkspace.shared.runningApplications)
- [x] Filter to regular applications only (activationPolicy == .regular)
- [x] Create observer for each running application on startup
- [x] Register for NSWorkspace notifications:
  - [x] NSWorkspace.didLaunchApplicationNotification
  - [x] NSWorkspace.didTerminateApplicationNotification
- [x] Implement dynamic observer creation when apps launch
- [x] Implement observer cleanup when apps terminate
- [x] Register for required AX notifications:
  - [x] kAXWindowCreatedNotification
  - [x] kAXUIElementDestroyedNotification
  - [x] kAXFocusedWindowChangedNotification (for tracking)
- [ ] Implement retry logic for apps that launch before being observable
- [ ] Add logging for observer lifecycle events (debug builds)
- [ ] Test with multiple applications running
- [ ] Test rapid app launch/quit scenarios
- [ ] Verify no memory leaks in observer management

### 2.2 Window Event Handler

- [x] Create WindowEventHandler.swift class
- [x] Define delegate protocol for window events
- [x] Implement notification routing from AccessibilityMonitor
- [x] Create method to identify window type from AXUIElement:
  - [x] Standard window (kAXWindowRole)
  - [x] Sheet (filter out)
  - [x] Panel (filter out)
  - [x] Dialog (configurable)
- [x] Implement method to get window count for application:
  - [x] Get app's AXUIElement reference
  - [x] Query kAXWindowsAttribute
  - [x] Filter to standard windows only
- [x] Create "last window" detection logic
- [x] Implement window close event processing pipeline:
  - [x] Receive destroyed notification
  - [x] Identify source application
  - [x] Check if it was a standard window
  - [x] Check remaining window count
  - [x] Determine if quit should trigger
- [ ] Handle edge cases:
  - [ ] App with no windows at launch
  - [ ] App with only utility windows
  - [x] Transient fullscreen/playback window replacement before quit decision
  - [ ] Multiple windows closing simultaneously
- [ ] Test with single-window app (TextEdit)
- [ ] Test with multi-window app (Finder)
- [ ] Test with apps that have panels (Photoshop-style)

### 2.3 App Termination Service

- [x] Create AppTerminationService.swift class
- [x] Create protected apps list (cannot be terminated):
  - [x] Finder (com.apple.finder)
  - [x] Dock (com.apple.dock)
  - [x] SystemUIServer (com.apple.systemuiserver)
  - [x] System Settings (com.apple.systempreferences)
  - [x] Activity Monitor (com.apple.ActivityMonitor)
  - [x] SecurityAgent (com.apple.SecurityAgent)
  - [x] loginwindow (com.apple.loginwindow)
- [x] Implement primary termination method using NSRunningApplication.terminate()
- [x] Implement AppleScript fallback termination:
  - [x] Create NSAppleScript for quit command
  - [x] Handle script execution errors
- [x] Add termination result enum (success, cancelled, failed, protected)
- [ ] Implement termination with callback/completion handler
- [ ] Add configurable delay before termination (for future undo feature)
- [ ] Never implement force termination (forceTerminate)
- [ ] Log all termination attempts (debug builds)
- [ ] Test termination of TextEdit
- [ ] Test termination of Safari (multiple windows)
- [ ] Verify protected apps cannot be terminated
- [ ] Test AppleScript fallback by simulating primary failure

### 2.4 Basic Exclusion List

- [x] Add excludedBundleIDs array to PreferencesManager (see 2.5)
- [x] Implement isExcluded(bundleIdentifier:) method
- [x] Integrate exclusion check into Window Event Handler
- [ ] Add default exclusions for problematic apps (if any discovered)
- [ ] Test adding app to exclusion list
- [ ] Test removing app from exclusion list
- [ ] Verify excluded apps don't quit on last window close

### 2.5 Preferences Manager Foundation

- [x] Create PreferencesManager.swift class
- [x] Implement as singleton or use dependency injection
- [x] Define UserDefaults keys as constants:
  - [x] isEnabled (Bool)
  - [x] quitMode (String/Enum: lastWindow, anyWindow)
  - [x] excludedBundleIDs ([String])
  - [x] launchAtLogin (Bool)
  - [x] showMenuBarIcon (Bool)
  - [x] playSound (Bool)
  - [x] hasCompletedOnboarding (Bool)
- [x] Set default values via registerDefaults
- [x] Implement property wrappers or @AppStorage for SwiftUI
- [x] Create Combine @Published properties for reactive updates
- [x] Implement save/load methods (if not using property wrappers)
- [x] Add method to reset to defaults
- [x] Add method to export settings (future backup feature)
- [ ] Test preferences persist across app relaunch
- [ ] Test default values on fresh install

### 2.6 Core Integration & End-to-End Testing

- [x] Connect AccessibilityMonitor to WindowEventHandler
- [x] Connect WindowEventHandler to AppTerminationService
- [x] Connect PreferencesManager to all components
- [x] Implement global enable/disable toggle:
  - [x] Stop observing when disabled
  - [x] Resume observing when enabled
- [x] Test complete flow: close TextEdit window -> TextEdit quits (tested with Photos app)
- [ ] Test exclusion: add TextEdit to exclusions -> does NOT quit
- [ ] Test disable: turn off globally -> no apps quit
- [ ] Test multiple apps simultaneously
- [ ] Performance test: verify low CPU usage when idle

---

## Phase 3: User Experience (Week 5-6)

### 3.1 Menu Bar Controller - Full Implementation

- [x] Design menu bar icon states:
  - [x] Enabled state (normal icon)
  - [x] Disabled state (dimmed or crossed icon)
  - [x] No permission state (warning badge or different icon)
- [x] Create all icon variants in Assets.xcassets
- [x] Implement icon state switching based on app state
- [x] Build complete NSMenu structure:
  - [x] Header: "RedButtonQuit" (disabled item showing state)
  - [x] Separator
  - [x] "Enable/Disable" toggle menu item
  - [x] "Quit Mode" submenu:
    - [x] "Quit on Last Window Close" (checkmark when selected)
    - [x] "Quit on Any Window Close" (checkmark when selected)
  - [x] Separator
  - [x] "Excluded Apps..." menu item (opens preferences)
  - [x] Separator
  - [x] "Launch at Login" toggle item
  - [x] "Preferences..." menu item (Cmd+,)
  - [x] Separator
  - [x] "About RedButtonQuit" menu item
  - [x] "Check for Updates..." menu item (placeholder for Sparkle)
  - [x] Separator
  - [x] "Quit RedButtonQuit" menu item (Cmd+Q)
- [x] Implement menu item action handlers
- [x] Bind menu item states to PreferencesManager
- [x] Update menu dynamically when preferences change
- [x] Add keyboard shortcuts to menu items
- [ ] Implement "About" window:
  - [ ] App icon
  - [ ] Version number
  - [ ] Copyright
  - [ ] Link to website/GitHub
- [ ] Test all menu items function correctly
- [ ] Test menu updates when preferences change externally
- [ ] Test VoiceOver reads menu items correctly

### 3.2 Onboarding Flow (SwiftUI)

- [x] Create OnboardingView.swift
- [x] Design onboarding flow structure (multi-step):
  - [x] Step 1: Welcome screen
  - [x] Step 2: How it works explanation
  - [x] Step 3: Permission request
  - [x] Step 4: Confirmation/completion
- [x] Implement Welcome screen:
  - [x] App icon/logo
  - [x] Headline: "Welcome to RedButtonQuit"
  - [x] Brief description of functionality
  - [x] "Get Started" button
- [x] Implement How It Works screen:
  - [x] Illustration or animation of the behavior
  - [x] Clear explanation of what the app does
  - [x] "Continue" button
- [x] Implement Permission Request screen:
  - [x] Explanation of why permission is needed
  - [x] Visual guide showing System Settings location
  - [x] "Open System Settings" button
  - [x] Permission status indicator
  - [x] Auto-advance when permission granted
- [x] Implement polling for permission status on permission screen
- [x] Implement Completion screen:
  - [x] Success message
  - [x] Quick settings overview
  - [x] "Finish" button
- [x] Create OnboardingWindowController to present as sheet or window
- [x] Store hasCompletedOnboarding in UserDefaults
- [x] Show onboarding on first launch only
- [x] Add "Show Onboarding" option in preferences (for re-running)
- [x] Test complete onboarding flow
- [x] Test permission polling detects grant
- [ ] Test onboarding only shows once
- [ ] Test accessibility with VoiceOver

### 3.3 Preferences Window (SwiftUI)

- [x] Create PreferencesView.swift
- [x] Design preferences layout using Form or Settings scene
- [x] Implement General tab/section:
  - [x] Global enable/disable toggle
  - [x] Quit mode picker (Last Window / Any Window)
  - [x] Launch at Login toggle
  - [x] Show menu bar icon toggle (with warning if hiding)
- [x] Implement Exclusions tab/section:
  - [x] List of excluded apps with icons
  - [x] Add app button (opens app picker)
  - [x] Remove app button (or swipe to delete)
  - [x] Implement app picker:
    - [x] Show running applications
    - [x] Option to browse /Applications
    - [x] Show app icon and name
    - [x] Search/filter capability
- [x] Implement Advanced tab/section (for future features):
  - [x] Placeholder for per-app delays
  - [x] Placeholder for undo grace period
  - [x] Placeholder for notifications toggle
  - [x] Debug logging toggle (debug builds only)
- [x] Implement About section:
  - [x] Version information
  - [x] Link to website
  - [x] Link to GitHub
  - [x] "Check for Updates" button
- [x] Create PreferencesWindowController
- [x] Use Settings scene for proper macOS preferences behavior (if SwiftUI App)
- [x] Or use NSWindowController with hosting controller (if AppDelegate)
- [x] Ensure Cmd+, shortcut opens preferences
- [x] Bind all controls to PreferencesManager
- [ ] Test all preference changes persist
- [ ] Test exclusion list add/remove
- [ ] Test preferences window reopens to last tab
- [ ] Test keyboard navigation through preferences

### 3.4 Launch at Login (ServiceManagement)

- [x] Import ServiceManagement framework
- [x] Implement SMAppService.mainApp for login item registration
- [x] Create method to enable login item
- [x] Create method to disable login item
- [x] Create method to check current login item status
- [x] Handle SMAppService.Status cases:
  - [x] enabled
  - [x] notRegistered
  - [x] notFound
  - [x] requiresApproval
- [x] Sync login item state with PreferencesManager.launchAtLogin
- [x] Update UI to reflect actual system state
- [x] Handle case where user disables in System Settings
- [ ] Test enabling login item via preferences
- [ ] Test disabling login item via preferences
- [ ] Test actual login item works on system restart
- [ ] Test state sync when changed in System Settings

#### 3.4.1 Login Item Path Validation (Fix for KI-001)

- [ ] Add method to detect if app is running from production location
  - [ ] Check if path starts with `/Applications` or `~/Applications`
  - [ ] Check if path contains `DerivedData` (Xcode debug build)
  - [ ] Check if path contains `Downloads` (not installed)
- [ ] Add warning UI when enabling Launch at Login from non-production path
- [ ] Consider: Disable toggle entirely if not in production location
- [ ] Add debug logging for registered login item path
- [ ] Test: Enable from DerivedData -> warning shown
- [ ] Test: Enable from /Applications -> works correctly

### 3.5 Settings Persistence & Sync

- [ ] Verify all preferences persist correctly
- [ ] Implement iCloud sync consideration (future feature flag)
- [ ] Handle preferences corruption gracefully
- [ ] Add migration support for future preference schema changes
- [ ] Test fresh install default values
- [ ] Test preferences survive app update
- [ ] Test reset to defaults functionality

---

## Phase 4: Polish & Distribution (Week 7-8)

### 4.1 Enhanced Features (P1)

- [ ] Implement Inclusion List Mode (inverse of exclusion):
  - [ ] Add quitListMode preference (exclusion/inclusion)
  - [ ] Modify WindowEventHandler to check mode
  - [ ] Update Preferences UI for mode selection
  - [ ] Test inclusion mode with few apps
- [ ] Implement Per-App Delay (future-ready):
  - [ ] Add data structure for app-specific delays
  - [ ] UI for setting delay per excluded/included app
  - [ ] Integrate delay into termination service
- [ ] Implement Undo Quit feature:
  - [ ] Add grace period setting (default 3 seconds)
  - [ ] Show brief notification or HUD before quitting
  - [ ] Allow cancel via keyboard shortcut or menu
  - [ ] Implement timer-based quit dispatch
- [ ] Implement optional notification on quit:
  - [ ] Add notification preference toggle
  - [ ] Request notification permission if needed
  - [ ] Send notification when app is quit
- [ ] Implement Statistics tracking (optional):
  - [ ] Track number of apps quit
  - [ ] Track apps quit per day/week
  - [ ] Simple stats view in preferences

### 4.2 Sparkle Auto-Updates Integration

- [ ] Add Sparkle framework via Swift Package Manager
- [ ] Configure SUFeedURL in Info.plist
- [ ] Set up appcast.xml hosting location (GitHub releases or website)
- [ ] Implement SUUpdater integration:
  - [ ] Initialize updater on app launch
  - [ ] Configure automatic update checks
  - [ ] Set check interval (daily)
- [ ] Add "Check for Updates..." menu item action
- [ ] Configure Sparkle for non-sandboxed app
- [ ] Create signing keys for Sparkle (EdDSA)
- [ ] Add SUPublicEDKey to Info.plist
- [ ] Create initial appcast.xml template
- [ ] Test update check mechanism
- [ ] Document appcast update process

### 4.3 Code Signing Setup

- [ ] Log into Apple Developer Portal
- [ ] Create/verify Developer ID Application certificate
- [ ] Create/verify Developer ID Installer certificate (if using pkg)
- [ ] Download and install certificates in Keychain
- [ ] Configure Xcode project signing:
  - [ ] Set team to Apple Developer account
  - [ ] Set signing identity to Developer ID Application
  - [ ] Enable Hardened Runtime
- [ ] Verify entitlements file is properly configured
- [ ] Create exportOptions.plist for command-line builds
- [ ] Test local signed build:
  - [ ] Build and sign
  - [ ] Verify signature with codesign -dv --verbose
  - [ ] Check entitlements with codesign -d --entitlements -
- [ ] Test signed app launches on another Mac (Gatekeeper check)

### 4.4 Notarization Pipeline

- [ ] Set up app-specific password for notarytool (or use keychain profile)
- [ ] Store credentials in keychain:
  - [ ] xcrun notarytool store-credentials
- [ ] Create notarization script/makefile target:
  - [ ] Archive app
  - [ ] Create zip for notarization
  - [ ] Submit with xcrun notarytool submit
  - [ ] Wait for completion with --wait flag
  - [ ] Check status
- [ ] Implement stapling: xcrun stapler staple
- [ ] Verify notarization: xcrun stapler validate
- [ ] Test notarized app on clean Mac (different Apple ID)
- [ ] Document notarization process for CI/CD
- [ ] Handle notarization failures:
  - [ ] Check logs with notarytool log
  - [ ] Common issues: hardened runtime, entitlements, unsigned frameworks

### 4.5 DMG Creation

- [ ] Design DMG window layout:
  - [ ] Background image with instructions
  - [ ] App icon on left
  - [ ] Applications folder alias on right
  - [ ] Window size and position
- [ ] Create DMG background image (Retina resolution)
- [ ] Choose DMG creation tool:
  - [ ] Option A: create-dmg (npm package)
  - [ ] Option B: hdiutil + AppleScript
- [ ] Create DMG build script:
  - [ ] Create temporary folder structure
  - [ ] Copy app bundle
  - [ ] Create Applications symlink
  - [ ] Create DMG with proper settings
  - [ ] Set window appearance (folder background, icon positions)
  - [ ] Compress DMG
- [ ] Sign DMG: codesign -s "Developer ID Application"
- [ ] Notarize DMG (submit DMG, not just app)
- [ ] Staple DMG
- [ ] Test DMG:
  - [ ] Opens with correct appearance
  - [ ] Drag-and-drop install works
  - [ ] App runs after install from DMG
- [ ] Create versioned DMG naming scheme: RedButtonQuit-1.0.0.dmg

### 4.6 Homebrew Cask Distribution

- [ ] Research Homebrew Cask submission requirements
- [ ] Create Cask formula file:
  - [ ] cask "redbuttonquit"
  - [ ] version
  - [ ] sha256
  - [ ] url (GitHub releases)
  - [ ] name
  - [ ] desc
  - [ ] homepage
  - [ ] app "RedButtonQuit.app"
  - [ ] zap stanza for cleanup
- [ ] Set up GitHub releases for hosting
- [ ] Calculate sha256 of DMG
- [ ] Test local Cask installation:
  - [ ] brew install --cask ./redbuttonquit.rb
  - [ ] Verify app installs correctly
  - [ ] Test uninstall
- [ ] Submit PR to homebrew-cask repository (after public release)
- [ ] Alternative: Create personal tap (homebrew-redbuttonquit)

### 4.7 GitHub Release Setup

- [ ] Create GitHub repository (if not already)
- [ ] Configure repository settings:
  - [ ] Description
  - [ ] Topics/tags
  - [ ] Website link
- [ ] Create release workflow:
  - [ ] Manual or tag-triggered
  - [ ] Build universal binary
  - [ ] Sign and notarize
  - [ ] Create DMG
  - [ ] Generate release notes
  - [ ] Upload assets
- [ ] Create release template:
  - [ ] Version number
  - [ ] What's new section
  - [ ] Download links
  - [ ] System requirements
  - [ ] Installation instructions
- [ ] Create initial v1.0.0 release (draft)
- [ ] Test release download and installation
- [ ] Set up GitHub Actions for automated builds (optional)

---

## Phase 5: Testing

### 5.1 Unit Tests

- [ ] Set up XCTest target in project
- [ ] Create test plan
- [ ] PreferencesManager tests:
  - [ ] Test default values
  - [ ] Test saving/loading each preference type
  - [ ] Test exclusion list add/remove
  - [ ] Test reset to defaults
- [ ] Exclusion logic tests:
  - [ ] Test bundle ID matching
  - [ ] Test case sensitivity
  - [ ] Test empty exclusion list
  - [ ] Test inclusion mode logic
- [ ] Quit mode tests:
  - [ ] Test last window mode logic
  - [ ] Test any window mode logic
- [ ] App Termination Service tests:
  - [ ] Test protected apps list
  - [ ] Test isProtected method
  - [ ] Mock NSRunningApplication for termination tests
- [ ] Window type detection tests:
  - [ ] Test window role identification (mock AXUIElement)

### 5.2 Integration Tests

- [ ] Create integration test target
- [ ] Test full flow with TextEdit:
  - [ ] Launch TextEdit
  - [ ] Open document (creates window)
  - [ ] Close window
  - [ ] Verify TextEdit terminates
- [ ] Test exclusion list integration:
  - [ ] Add TextEdit to exclusions
  - [ ] Close TextEdit window
  - [ ] Verify TextEdit does NOT terminate
  - [ ] Remove from exclusions
  - [ ] Verify behavior returns to normal
- [ ] Test last window mode with multi-window app:
  - [ ] Open Safari with multiple tabs/windows
  - [ ] Close one window
  - [ ] Verify Safari stays running
  - [ ] Close last window
  - [ ] Verify Safari terminates
- [ ] Test enable/disable toggle:
  - [ ] Disable globally
  - [ ] Close app windows
  - [ ] Verify no terminations
  - [ ] Re-enable
  - [ ] Verify terminations resume
- [ ] Test with apps that have background processes
- [ ] Test with apps that have detached windows
- [ ] Test fullscreen/playback transitions:
  - [ ] YouTube fullscreen enter/exit while video is playing
  - [ ] YouTube fullscreen enter/exit after video ends
  - [ ] VLC fullscreen enter/exit while media is playing

### 5.3 Manual Testing Checklist

- [ ] Fresh installation testing:
  - [ ] Install on clean user account
  - [ ] Verify onboarding appears
  - [ ] Complete permission flow
  - [ ] Verify basic functionality works
- [ ] Permission flow testing:
  - [ ] Launch without accessibility permission
  - [ ] Verify appropriate UI state
  - [ ] Grant permission in System Settings
  - [ ] Verify app detects permission
  - [ ] Verify monitoring starts
- [ ] Menu bar testing:
  - [ ] Verify icon appears in menu bar
  - [ ] Verify menu opens on click
  - [ ] Test all menu items
  - [ ] Verify icon states update correctly
- [ ] System state testing:
  - [ ] Test behavior after sleep/wake
  - [ ] Test behavior after screen lock/unlock
  - [ ] Test with multiple displays connected
  - [ ] Test with display disconnected
  - [ ] Test in Mission Control
  - [ ] Test with full-screen apps
  - [ ] Test in Split View
  - [ ] Test with Stage Manager enabled
- [ ] App compatibility testing:
  - [ ] Safari
  - [ ] Mail
  - [ ] Notes
  - [ ] Preview
  - [ ] TextEdit
  - [ ] Xcode
  - [ ] VS Code
  - [ ] Slack
  - [ ] Spotify
  - [ ] Chrome
  - [ ] Firefox
  - [ ] Microsoft Office apps
  - [ ] Adobe apps (if available)
- [ ] Edge case testing:
  - [ ] App with no windows at launch
  - [ ] App that creates windows on demand
  - [ ] Apps with multiple window types
  - [ ] Document-based apps with unsaved changes
  - [ ] Apps that intercept termination

### 5.4 Performance Testing

- [ ] Measure idle memory usage (target: <30MB)
- [ ] Measure idle CPU usage (target: <0.1%)
- [ ] Profile with Instruments:
  - [ ] Time Profiler for CPU usage
  - [ ] Allocations for memory
  - [ ] Leaks for memory leaks
  - [ ] System Trace for system impact
- [ ] Test with 20+ applications running
- [ ] Test rapid window open/close cycles
- [ ] Measure impact on system responsiveness
- [ ] Verify no energy impact when idle (Activity Monitor)

### 5.5 Accessibility Testing

- [ ] Test complete VoiceOver workflow:
  - [ ] Menu bar navigation
  - [ ] Menu item announcement
  - [ ] Preferences window navigation
  - [ ] Onboarding flow
- [ ] Test keyboard-only navigation:
  - [ ] All menu items accessible
  - [ ] Preferences navigable with Tab
  - [ ] All buttons activatable with Space/Enter
- [ ] Verify proper accessibility labels on all UI elements
- [ ] Test with reduced motion enabled
- [ ] Test with increased contrast enabled
- [ ] Test with different text sizes

### 5.6 Localization Testing (if applicable)

- [ ] Extract all user-facing strings to Localizable.strings
- [ ] Test with pseudo-localization (long strings)
- [ ] Verify UI doesn't break with longer text
- [ ] Test RTL layout (if supporting Arabic/Hebrew)

---

## Phase 6: Documentation

### 6.1 User Documentation

- [x] Create comprehensive README.md:
  - [x] App description and purpose
  - [x] Screenshots/GIFs of functionality
  - [x] Installation instructions (DMG, Homebrew)
  - [x] Configuration guide
  - [x] FAQ section
  - [x] Troubleshooting section
  - [x] System requirements
  - [x] Privacy policy summary
- [x] Create CHANGELOG.md:
  - [x] Follow Keep a Changelog format
  - [x] Document v1.0.0 initial features
- [x] Create LICENSE file (choose appropriate license)
- [ ] Create privacy policy document:
  - [ ] What data is collected (none)
  - [ ] What permissions are needed and why
  - [ ] Contact information
- [ ] Create support documentation:
  - [ ] How to grant accessibility permission
  - [ ] How to add apps to exclusion list
  - [ ] How to troubleshoot common issues

### 6.2 Developer Documentation

- [ ] Add code comments to all public interfaces
- [ ] Create architecture overview document
- [ ] Document build process
- [ ] Document release process
- [ ] Create CONTRIBUTING.md (if open source)
- [ ] Document testing procedures

### 6.3 Website/Landing Page (Optional)

- [ ] Create simple landing page:
  - [ ] Hero section with app description
  - [ ] Feature highlights
  - [ ] Download button (DMG)
  - [ ] Homebrew installation command
  - [ ] Screenshot gallery
  - [ ] FAQ
  - [ ] Footer with links
- [ ] Set up hosting (GitHub Pages or similar)
- [ ] Configure custom domain (optional)
- [ ] Add analytics (privacy-respecting)

---

## Phase 7: Launch Preparation

### 7.1 Pre-Launch Checklist

- [ ] Final code review
- [ ] All tests passing
- [ ] No compiler warnings
- [ ] No memory leaks
- [ ] Performance targets met
- [ ] All documentation complete
- [ ] DMG tested on multiple Macs
- [ ] Notarization verified working
- [ ] Homebrew formula tested
- [ ] GitHub release prepared
- [ ] Website live (if applicable)
- [ ] Backup of signing certificates and keys

### 7.2 Launch Activities

- [ ] Publish GitHub release (remove draft status)
- [ ] Update Homebrew formula with final sha256
- [ ] Submit Homebrew Cask PR
- [ ] Announce on relevant forums/communities:
  - [ ] Reddit (r/macapps, r/MacOS)
  - [ ] Hacker News
  - [ ] Product Hunt (optional)
  - [ ] Twitter/X
  - [ ] Mastodon
- [ ] Monitor for initial user feedback

---

## Phase 8: Post-Launch

### 8.1 Monitoring

- [ ] Set up crash reporting (Sentry or similar, optional)
- [ ] Monitor GitHub issues
- [ ] Monitor Homebrew issues
- [ ] Track download statistics
- [ ] Collect user feedback

### 8.2 Maintenance Tasks

- [ ] Create process for handling bug reports
- [ ] Plan regular maintenance updates
- [ ] Monitor macOS beta releases for compatibility
- [ ] Keep dependencies updated (Sparkle)
- [ ] Renew Developer ID certificate before expiration

### 8.3 Future Enhancements (v1.x Backlog)

- [ ] Keyboard shortcut for global toggle
- [ ] Touch Bar support (for supported Macs)
- [ ] Shortcuts app integration
- [ ] Menu bar icon customization
- [ ] Detailed statistics dashboard
- [ ] iCloud settings sync
- [ ] Localization (additional languages)
- [ ] Widget for Control Center

---

## Appendix: Quick Reference

### Key File Paths
```
RedButtonQuit/
├── RedButtonQuit/App/RedButtonQuitApp.swift
├── RedButtonQuit/App/AppDelegate.swift
├── RedButtonQuit/Core/AccessibilityMonitor.swift
├── RedButtonQuit/Core/WindowEventHandler.swift
├── RedButtonQuit/Core/AppTerminationService.swift
├── RedButtonQuit/Core/PreferencesManager.swift
├── RedButtonQuit/UI/MenuBarController.swift
├── RedButtonQuit/UI/PreferencesView.swift
├── RedButtonQuit/UI/OnboardingView.swift
├── RedButtonQuit/Supporting/Info.plist
└── RedButtonQuit/Supporting/RedButtonQuit.entitlements
```

### Important Bundle IDs (Protected Apps)
- com.apple.finder
- com.apple.dock
- com.apple.systemuiserver
- com.apple.systempreferences
- com.apple.ActivityMonitor
- com.apple.SecurityAgent
- com.apple.loginwindow

### Key URLs
- System Settings Accessibility: `x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility`
- Apple notarytool docs: https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution

### Build Commands Reference
```bash
# Build for release
xcodebuild -scheme RedButtonQuit -configuration Release -archivePath build/RedButtonQuit.xcarchive archive

# Export app
xcodebuild -exportArchive -archivePath build/RedButtonQuit.xcarchive -exportPath build/ -exportOptionsPlist exportOptions.plist

# Notarize
xcrun notarytool submit RedButtonQuit.zip --keychain-profile "AC_PASSWORD" --wait

# Staple
xcrun stapler staple RedButtonQuit.app

# Verify
codesign -dv --verbose=4 RedButtonQuit.app
xcrun stapler validate RedButtonQuit.app
```

---

**Total Estimated Tasks:** ~300+
**Estimated Duration:** 8 weeks (part-time) / 4 weeks (full-time)

> Mark tasks complete with `[x]` as you progress. Update Last Updated date when making changes.
