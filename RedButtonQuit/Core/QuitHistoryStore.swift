import AppKit
import Combine
import Foundation

struct QuitEvent: Codable, Identifiable, Equatable {
    enum Outcome: String, Codable {
        case pending
        case quit
        case stillRunning
        case cancelled
        case skippedExcluded
        case failed
    }

    let id: UUID
    let date: Date
    let appName: String
    let bundleIdentifier: String
    var outcome: Outcome
    var detail: String?
    var confirmedAt: Date?
}

/// Stores RedButtonQuit's own quit decisions on this Mac.
final class QuitHistoryStore: ObservableObject {
    static let shared = QuitHistoryStore(
        directoryURL: FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("RedButtonQuit", isDirectory: true),
        preferences: .shared
    )

    @Published private(set) var events: [QuitEvent]

    private enum Constants {
        static let maximumEventCount = 200
        static let saveDelay: TimeInterval = 2
        static let fileName = "history.json"
    }

    private let directoryURL: URL
    private let fileURL: URL
    private let preferences: PreferencesManager
    private var saveWorkItem: DispatchWorkItem?
    private var willTerminateObserver: NSObjectProtocol?
    private var isDirty = false

    init(directoryURL: URL, preferences: PreferencesManager) {
        self.directoryURL = directoryURL
        self.fileURL = directoryURL.appendingPathComponent(Constants.fileName)
        self.preferences = preferences
        self.events = Self.loadEvents(from: fileURL)
        self.willTerminateObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.flush()
        }
    }

    deinit {
        saveWorkItem?.cancel()
        if let willTerminateObserver {
            NotificationCenter.default.removeObserver(willTerminateObserver)
        }
    }

    @discardableResult
    func record(
        appName: String,
        bundleIdentifier: String,
        outcome: QuitEvent.Outcome,
        detail: String? = nil
    ) -> UUID? {
        guard preferences.recordHistory else { return nil }

        let event = QuitEvent(
            id: UUID(),
            date: Date(),
            appName: appName,
            bundleIdentifier: bundleIdentifier,
            outcome: outcome,
            detail: detail,
            confirmedAt: Self.confirmationDate(for: outcome)
        )
        events.insert(event, at: 0)
        if events.count > Constants.maximumEventCount {
            events.removeLast(events.count - Constants.maximumEventCount)
        }
        isDirty = true
        scheduleSave()
        return event.id
    }

    func resolve(id: UUID, outcome: QuitEvent.Outcome, detail: String? = nil) {
        guard let index = events.firstIndex(where: { $0.id == id }) else { return }

        events[index].outcome = outcome
        events[index].detail = detail
        events[index].confirmedAt = Self.confirmationDate(for: outcome)
        isDirty = true
        scheduleSave()
    }

    func clear() {
        saveWorkItem?.cancel()
        saveWorkItem = nil
        events.removeAll()
        isDirty = true
        save()
    }

    /// Writes pending changes now. Tests use this to avoid waiting for the debounce.
    func flush() {
        saveWorkItem?.cancel()
        saveWorkItem = nil
        save()
    }

    private func scheduleSave() {
        saveWorkItem?.cancel()

        let workItem = DispatchWorkItem { [weak self] in
            self?.saveWorkItem = nil
            self?.save()
        }
        saveWorkItem = workItem
        DispatchQueue.main.asyncAfter(
            deadline: .now() + Constants.saveDelay,
            execute: workItem
        )
    }

    private func save() {
        guard isDirty else { return }

        do {
            try FileManager.default.createDirectory(
                at: directoryURL,
                withIntermediateDirectories: true
            )
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(events)
            try data.write(to: fileURL, options: .atomic)
            isDirty = false
        } catch {
            #if DEBUG
            print("Failed to save quit history: \(error)")
            #endif
        }
    }

    private static func loadEvents(from fileURL: URL) -> [QuitEvent] {
        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode([QuitEvent].self, from: data)
                // A .pending entry is resolved by a poll that lives in this
                // process. If the app stopped before that poll ran, nothing can
                // ever confirm the outcome, and the row would read "Quitting…"
                // forever. Drop those instead of showing a claim we cannot make.
                .filter { $0.outcome != .pending }
                .sorted { $0.date > $1.date }
                .prefix(Constants.maximumEventCount)
                .map { $0 }
        } catch {
            return []
        }
    }

    private static func confirmationDate(for outcome: QuitEvent.Outcome) -> Date? {
        switch outcome {
        case .quit, .stillRunning:
            return Date()
        case .pending, .cancelled, .skippedExcluded, .failed:
            return nil
        }
    }
}
