# Changelog

All notable changes to RedButtonQuit will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Planned
- Undo quit feature with grace period
- Per-app delay settings
- Keyboard shortcut for quick toggle

## [1.1.0] - 2026-08-19

### Added
- **Quit history.** RedButtonQuit now keeps a record of its own decisions, so you
  can see it working instead of guessing. A **Recent** submenu in the menu bar
  shows the last ten, and a new **History** tab in Preferences shows the full list.
- An entry is marked "Quit" only after the app is confirmed to have exited. An app
  that stops to ask about unsaved work is recorded as "asked to quit, still
  running" rather than claimed as a success.
- Near misses are recorded too: quits cancelled because a new window opened, apps
  skipped because they are on your exclusion list, and terminations that failed.
- History can be switched off, and cleared, from the History tab. It holds the
  last 200 events in `~/Library/Application Support/RedButtonQuit/history.json`,
  on your Mac only.

### Changed
- The exclusion list is now checked at the moment a quit would happen, so a skip
  can be recorded when it is meaningful. Excluded apps still can never be quit.

### Fixed
- The "Buy me a coffee" link in Preferences → About pointed at a Ko-fi page that
  did not exist. It now points at the real one.
- Documentation claimed a Homebrew cask and an update-check network request.
  Neither exists. The app contains no networking code at all.

### Notes
- Quits you perform yourself, with Cmd-Q or an app's Quit menu item, are never
  recorded. The history is only RedButtonQuit's own work.

## [1.0.0] - 2026-08-12

### Added
- Initial release
- Quit apps when their last window is closed
- Two quit modes: "Last Window" and "Any Window"
- App exclusion list with easy management
- System app protection (Finder, Dock, System Settings, etc.)
- Menu bar interface with quick toggles
- Preferences window with General, Exclusions, and About tabs
- Onboarding flow for first-time users
- Accessibility permission detection and guidance
- Launch at Login support via ServiceManagement
- Optional sound feedback when apps are quit
- Universal Binary support (Apple Silicon + Intel)
- Notarized for Gatekeeper compatibility

### Security
- Hardened Runtime enabled
- No App Sandbox (required for Accessibility API)
- No data collection or network requests
- Apple notarization for malware verification

---

[Unreleased]: https://github.com/initiator1/redbuttonquit/compare/v1.1.0...HEAD
[1.1.0]: https://github.com/initiator1/redbuttonquit/releases/tag/v1.1.0
[1.0.0]: https://github.com/initiator1/redbuttonquit/releases/tag/v1.0.0
