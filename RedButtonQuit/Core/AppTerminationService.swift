import AppKit
import Foundation

/// Handles graceful termination of applications
final class AppTerminationService {
    // MARK: - Types

    enum TerminationError: Error, LocalizedError {
        case appNotRunning
        case protectedApp
        case terminationFailed
        case appleScriptFailed(String)

        var errorDescription: String? {
            switch self {
            case .appNotRunning:
                return "Application is not running"
            case .protectedApp:
                return "Cannot terminate protected system application"
            case .terminationFailed:
                return "Failed to terminate application"
            case .appleScriptFailed(let message):
                return "AppleScript failed: \(message)"
            }
        }
    }

    // MARK: - Public Methods

    /// Terminate an application gracefully
    /// - Parameters:
    ///   - app: The application to terminate
    ///   - completion: Callback with result
    func terminateApp(
        _ app: NSRunningApplication,
        completion: @escaping (Result<Void, TerminationError>) -> Void
    ) {
        // Check if app is still running
        guard !app.isTerminated else {
            completion(.failure(.appNotRunning))
            return
        }

        // Check if app is protected
        if let bundleID = app.bundleIdentifier,
           PreferencesManager.systemProtectedApps.contains(bundleID) {
            completion(.failure(.protectedApp))
            return
        }

        // Try primary termination method
        let success = app.terminate()

        if success {
            completion(.success(()))
        } else {
            // Try AppleScript fallback
            terminateViaAppleScript(app, completion: completion)
        }
    }

    /// Check if an app can be terminated (not protected)
    func canTerminate(_ app: NSRunningApplication) -> Bool {
        guard let bundleID = app.bundleIdentifier else { return true }
        return !PreferencesManager.systemProtectedApps.contains(bundleID)
    }

    // MARK: - Private Methods

    private func terminateViaAppleScript(
        _ app: NSRunningApplication,
        completion: @escaping (Result<Void, TerminationError>) -> Void
    ) {
        guard let appName = app.localizedName else {
            completion(.failure(.terminationFailed))
            return
        }

        // Escape the app name for AppleScript
        let escapedName = appName.replacingOccurrences(of: "\"", with: "\\\"")

        let script = """
        tell application "\(escapedName)"
            quit
        end tell
        """

        var error: NSDictionary?
        if let appleScript = NSAppleScript(source: script) {
            appleScript.executeAndReturnError(&error)

            if let error = error,
               let message = error[NSAppleScript.errorMessage] as? String {
                completion(.failure(.appleScriptFailed(message)))
            } else {
                completion(.success(()))
            }
        } else {
            completion(.failure(.appleScriptFailed("Failed to create AppleScript")))
        }
    }
}
