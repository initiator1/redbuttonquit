# RedButtonQuit

**Make the red close button actually quit apps on macOS.**

[![macOS](https://img.shields.io/badge/macOS-14.0%2B-blue)](https://www.apple.com/macos/)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)
[![Download](https://img.shields.io/badge/download-latest-brightgreen)](https://github.com/initiator1/redbuttonquit/releases/latest)

---

## What is RedButtonQuit?

On macOS, clicking the red close button only closes the window—the app keeps running in the background. This is different from Windows, where closing the last window quits the application.

**RedButtonQuit changes this behavior.** When you close the last window of an app, RedButtonQuit automatically quits the app for you.

![Demo](docs/demo.gif)

## Features

- **Automatic app quitting** - Close the last window, and the app quits
- **Exclusion list** - Keep certain apps running (like Finder, Spotify, etc.)
- **Two modes:**
  - *Last Window* - Only quit when the last window closes (default)
  - *Any Window* - Quit whenever any window closes
- **Menu bar app** - Runs quietly in your menu bar
- **Launch at login** - Start automatically when you log in
- **Zero data collection** - Your privacy is respected

## Installation

### Direct Download (Recommended)

1. Download the latest `.dmg` from [Releases](https://github.com/initiator1/redbuttonquit/releases/latest)
2. Open the DMG and drag RedButtonQuit to your Applications folder
3. Launch RedButtonQuit from Applications
4. Grant Accessibility permission when prompted

### Homebrew

```bash
brew install --cask redbuttonquit
```

### Building from Source

Requires Xcode 15+ and macOS 14+.

```bash
git clone https://github.com/initiator1/redbuttonquit.git
cd redbuttonquit
open RedButtonQuit.xcodeproj
# Build with Cmd+B, Run with Cmd+R
```

## Usage

### First Launch

1. Launch RedButtonQuit
2. Follow the onboarding to grant Accessibility permission
3. The app will appear in your menu bar

### Menu Bar

Click the menu bar icon to:
- Enable/disable RedButtonQuit
- Change quit mode
- Access excluded apps
- Open preferences

### Adding Exclusions

Some apps you might want to keep running even after closing their windows:
- Music players (Spotify, Apple Music)
- Communication apps (Slack, Discord)
- Apps with system tray features

To exclude an app:
1. Click the menu bar icon
2. Select "Excluded Apps..."
3. Click "+" and select the app

## System Requirements

- **macOS 14.0 Sonoma** or later (macOS 15 Sequoia recommended)
- **Apple Silicon** or **Intel** Mac
- **Accessibility permission** (required)

## Privacy & Security

RedButtonQuit requires Accessibility permission to detect when you close windows. This is the only way to implement this functionality on macOS.

**We do not:**
- Collect any data
- Send any network requests (except for update checks)
- Log your activity
- Access your files

The app is [notarized by Apple](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution), ensuring it's free from malware.

## Why Not the Mac App Store?

Apps that use the Accessibility API cannot be distributed through the Mac App Store because they require disabling App Sandbox. This is a macOS security requirement, not a choice.

RedButtonQuit is distributed as notarized freeware directly from this repository.

## FAQ

### Why do I need to grant Accessibility permission?

macOS requires Accessibility permission for any app that needs to monitor or interact with other apps' windows. Without it, RedButtonQuit cannot detect when you close windows.

### Will this affect system apps?

No. System apps like Finder, Dock, and System Settings are protected and will never be quit by RedButtonQuit.

### Can I undo an accidental quit?

Currently, no. If you frequently accidentally close windows, consider:
1. Adding the app to your exclusion list
2. Using "Last Window" mode instead of "Any Window" mode

### Does this work with all apps?

Most apps work correctly. Some apps with unusual window management (certain games, virtualization apps) may not trigger correctly. You can always add these to the exclusion list.

### How do I uninstall?

1. Quit RedButtonQuit from the menu bar
2. Delete RedButtonQuit.app from Applications
3. (Optional) Remove preferences: `defaults delete com.redbuttonquit.app`

## Contributing

Contributions are welcome! Please read our [Contributing Guidelines](CONTRIBUTING.md) first.

```bash
# Clone the repo
git clone https://github.com/initiator1/redbuttonquit.git

# Open in Xcode
cd redbuttonquit
open RedButtonQuit.xcodeproj

# Build and run
# Cmd+B to build, Cmd+R to run
```

## License

MIT License - see [LICENSE](LICENSE) for details.

## Acknowledgments

- Inspired by [RedQuits](http://carsten-mielke.com/redquits.html) by Carsten Mielke
- Built with SwiftUI and the macOS Accessibility API

---

**Made with ❤️ for people who just want apps to quit when they close the window.**
