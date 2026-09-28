# Implementation Notes

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
