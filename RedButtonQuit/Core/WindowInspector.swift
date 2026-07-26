import AppKit
import ApplicationServices

/// Shared window inspection helpers for Accessibility and CoreGraphics state.
enum WindowInspector {
    enum WindowElementKind {
        case standard
        case otherWindow
        case nonWindow
        case unknown

        var isWindow: Bool {
            switch self {
            case .standard, .otherWindow:
                return true
            case .nonWindow, .unknown:
                return false
            }
        }

        var canRepresentClosedStandardWindow: Bool {
            switch self {
            case .standard, .unknown:
                return true
            case .otherWindow, .nonWindow:
                return false
            }
        }
    }

    struct AppWindowSnapshot {
        let accessibilityStandardWindowCount: Int?
        let onScreenWindowCount: Int?

        var hasUserFacingWindows: Bool {
            (accessibilityStandardWindowCount ?? 0) > 0 ||
                (onScreenWindowCount ?? 0) > 0
        }

        var canProveNoUserFacingWindows: Bool {
            accessibilityStandardWindowCount == 0 && onScreenWindowCount == 0
        }
    }

    static func snapshot(for app: NSRunningApplication) -> AppWindowSnapshot {
        AppWindowSnapshot(
            accessibilityStandardWindowCount: accessibilityStandardWindowCount(for: app),
            onScreenWindowCount: onScreenWindowCount(for: app)
        )
    }

    static func accessibilityStandardWindowCount(for app: NSRunningApplication) -> Int? {
        let appElement = AXUIElementCreateApplication(app.processIdentifier)

        var windowsRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(
            appElement,
            kAXWindowsAttribute as CFString,
            &windowsRef
        )

        guard result == .success,
              let windows = windowsRef as? [AXUIElement] else {
            return nil
        }

        return windows.filter { isStandardWindow($0) }.count
    }

    static func isStandardWindow(_ element: AXUIElement) -> Bool {
        windowElementKind(element) == .standard
    }

    static func windowElementKind(_ element: AXUIElement) -> WindowElementKind {
        var roleRef: CFTypeRef?
        let roleResult = AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &roleRef)

        guard roleResult == .success, let role = roleRef as? String else {
            return .unknown
        }

        if role == kAXApplicationRole as String {
            return .unknown
        }

        guard role == kAXWindowRole as String else {
            return .nonWindow
        }

        var subroleRef: CFTypeRef?
        let subroleResult = AXUIElementCopyAttributeValue(element, kAXSubroleAttribute as CFString, &subroleRef)

        if subroleResult == .success, let subrole = subroleRef as? String {
            return subrole == kAXStandardWindowSubrole as String ? .standard : .otherWindow
        }

        return .standard
    }

    static func onScreenWindowCount(for app: NSRunningApplication) -> Int? {
        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        guard let windows = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
            return nil
        }

        return windows.filter {
            isUserFacingOnScreenWindow($0, ownerPID: app.processIdentifier)
        }.count
    }

    static func isUserFacingOnScreenWindow(_ windowInfo: [String: Any], ownerPID: pid_t) -> Bool {
        guard let pid = windowInfo[kCGWindowOwnerPID as String] as? NSNumber,
              pid.int32Value == ownerPID else {
            return false
        }

        guard let layer = windowInfo[kCGWindowLayer as String] as? NSNumber,
              layer.intValue == 0 else {
            return false
        }

        if let isOnscreen = windowInfo[kCGWindowIsOnscreen as String] as? NSNumber,
           !isOnscreen.boolValue {
            return false
        }

        if let alpha = windowInfo[kCGWindowAlpha as String] as? NSNumber,
           alpha.doubleValue <= 0 {
            return false
        }

        guard let bounds = windowInfo[kCGWindowBounds as String] as? [String: Any],
              let width = bounds["Width"] as? NSNumber,
              let height = bounds["Height"] as? NSNumber else {
            return false
        }

        return width.doubleValue > 1 && height.doubleValue > 1
    }
}
