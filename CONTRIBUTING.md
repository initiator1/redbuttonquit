# Contributing to RedButtonQuit

Thank you for your interest in contributing to RedButtonQuit!

## Getting Started

1. **Fork the repository** on GitHub
2. **Clone your fork** locally:
   ```bash
   git clone https://github.com/yourusername/redbuttonquit.git
   cd redbuttonquit
   ```
3. **Open in Xcode**:
   ```bash
   open RedButtonQuit.xcodeproj
   ```

## Development Setup

### Requirements

- macOS 14.0 Sonoma or later
- Xcode 15.0 or later
- Apple Developer account (for code signing)

### Building

1. Open `RedButtonQuit.xcodeproj` in Xcode
2. Select your development team in Signing & Capabilities
3. Build with `Cmd+B`
4. Run with `Cmd+R`

### Testing

The app requires Accessibility permission to function. When running from Xcode:
1. Grant permission in System Settings > Privacy & Security > Accessibility
2. You may need to remove and re-add the app if you rebuild

Run tests with `Cmd+U` in Xcode.

## Code Style

- Use Swift's standard naming conventions
- Keep functions focused and small
- Add comments for complex logic
- Use `#if DEBUG` for debug-only code

## Submitting Changes

1. **Create a branch** for your feature:
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes** and commit:
   ```bash
   git add .
   git commit -m "Add: description of your change"
   ```

3. **Push to your fork**:
   ```bash
   git push origin feature/your-feature-name
   ```

4. **Open a Pull Request** on GitHub

### Commit Messages

Use clear, descriptive commit messages:
- `Add: new feature description`
- `Fix: bug description`
- `Update: what was updated`
- `Remove: what was removed`
- `Refactor: what was refactored`

## Reporting Issues

When reporting issues, please include:
- macOS version
- App version
- Steps to reproduce
- Expected vs actual behavior
- Any error messages

## Feature Requests

Feature requests are welcome! Please:
- Check existing issues first
- Describe the use case
- Explain why it would benefit users

## Code of Conduct

Be respectful and constructive in all interactions.

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
