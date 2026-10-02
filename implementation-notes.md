# Implementation Notes

## Optional support visibility (2026-10-02)

- Version 1.1.3 (build 6) adds `Support RedButtonQuit…` to the app menu and makes
  the About copy explicit that tips are optional. Both use the existing tagged
  Ko-fi link. There is no payment SDK, in-app network request, or usage prompt.
- The website offers `Leave a tip` beside the free download and explains what
  support funds. Source links stay available. The hero glow no longer causes
  horizontal overflow on a phone.
- The amount stays in Ko-fi settings. BOSS approves the shared $3 default on
  2026-10-02. The saved settings and public tip form confirm $3; the $1 minimum
  and one-time default remain. Stripe stays connected. No payment is submitted.
- Release archive/export and local installation pass. The app and DMG are
  notarized and stapled. macOS pre-distribution checks pass for the DMG.
- The installed app is 1.1.3 at `/Applications/RedButtonQuit.app`. Its signature
  passes, TCC reports `auth_value=2`, operational preferences match the saved
  pre-install values, and macOS lists its login item as enabled and allowed at
  that path. The previous app and preferences are preserved in ignored
  `build/support-review/previous/`.
- The browser check covers the normal desktop viewport and a measured 389 CSS
  pixel phone viewport. No horizontal overflow remains. The tip target is at
  least 44 CSS pixels tall. Clicking it reaches the existing Ko-fi tip form.
  A temporary copy with scripts removed verifies static content and support
  links remain available. That copy is removed after checking.
- Native Computer Use times out for RedButtonQuit, Control Center, and TextEdit.
  Installed-menu rendering, clicking the native support link, and the real
  last-window quit test remain unverified. Full-display capture was rejected
  by approval review; only the menu-bar strips were captured for diagnosis.
  An isolated harness renders the actual changed About view with the optional
  support copy visible. It does not verify installed-menu clicks or real quits.
  BOSS explicitly approves publication, release, the demo, and the launch on
  2026-10-02. The website is deployed and verified; private deployment files
  return 404. The public app release still waits for native acceptance.

### Launch copy for r/macapps' October App Pile

**[OS] RedButtonQuit: close the last window, and the app quits**

I'm the maker of RedButtonQuit, a small macOS menu bar utility.

**Problem:** Closing the last window often leaves a Mac app running. RedButtonQuit
asks it to quit, then checks that it exited. It keeps a local quit history, and you
can exclude apps that should stay open. Apps can still ask you to save unsaved work.

**Comparison:** Quitter quits or hides apps after a period of inactivity.
RedButtonQuit responds to closing windows, so you don't need an idle timer for
this behavior. Quitter is a better fit if you want apps to disappear after you stop
using them, even with windows open.

**Pricing:** $0. Free and MIT licensed, with every feature included. Tips are optional.
It needs macOS 14 or later and Accessibility permission. The download supports
Apple silicon and Intel, and is signed and notarized.

Download and source: https://redbuttonquit.com

Comparison verified against https://marco.org/apps on 2026-10-02. The launch can
point at the existing, verified v1.1.2 download while v1.1.3 awaits its final native
check. This does not promise the new menu link is already publicly released.

### Demo sequence (22 seconds; real capture pending)

- 0–5 seconds: Explain that closing the last window can leave the app running.
- 5–9 seconds: Introduce RedButtonQuit using the site's existing window design.
- 9–12 seconds: Show a labeled, real TextEdit capture of closing the last window
  and the app quitting. Do not substitute the website simulation for this proof.
- 12–17 seconds: Show the real quit-history entry and the exclusions control.
- 17–22 seconds: End with `Free and open source`, `redbuttonquit.com`, and
  `Optional tips support development`.

The actual capture and final trailer remain in the existing launch work. Native
control must work before capturing; do not record unrelated desktop content.

## Red close button icon (2026-09-27)

- Candidate 2 is the selected generated artwork. `AppIcon.icon` has separate close-button and graphite layers.
- Xcode 27 builds the icon as `AppIcon`; `CFBundleIconName` and the existing app-icon build setting use that name.
- An isolated `actool` build of `.icon` creates `AppIcon.icns` and `Assets.car`. The built ICNS matches it.
- The classic asset set and site PNGs use an 824-pixel body on a transparent 1024-pixel canvas.
- Menu ellipses use one Unicode character. The debug print string stays unchanged.

**Deviations**: None.

## Quit History Implementation Notes

## Scope

Fix two quit-history bugs for the planned 1.1.1 release, without changing quit decisions,
termination behavior, signing, install, or release targets.

## Architecture

The repository uses a small layered service graph. `AppDelegate` builds the core services.
`WindowEventHandler` owns the quit decision. `QuitHistoryStore` owns history persistence.
SwiftUI views observe the preference and history singletons.

Observer eligibility is centralized in `AccessibilityMonitor` and applies to startup and launch
notifications. Cancellation history uses the window snapshot captured at destruction time and
removes the destroyed window from counts when the AX and CoreGraphics APIs may still include it.

## Deviations

- `record` returns `UUID?`. The brief also requires a nil-equivalent result when
  recording is off. A non-optional `UUID` cannot represent that result.
- None for the 1.1.1 history fixes. The guard uses structural bundle metadata and paths, with no
  bundle-identifier list. Quit scheduling and its one-second grace period stay unchanged.
