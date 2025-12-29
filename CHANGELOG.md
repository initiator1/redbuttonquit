# Changelog

All notable changes to RedButtonQuit will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Planned
- Undo quit feature with grace period
- Per-app delay settings
- Keyboard shortcut for quick toggle
- Statistics tracking

## [1.0.0] - 2025-XX-XX

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
- Homebrew Cask distribution

### Security
- Hardened Runtime enabled
- No App Sandbox (required for Accessibility API)
- No data collection or network requests
- Apple notarization for malware verification

---

[Unreleased]: https://github.com/yourusername/redbuttonquit/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/yourusername/redbuttonquit/releases/tag/v1.0.0
