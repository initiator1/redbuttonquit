import AppKit
import SwiftUI

struct HistoryView: View {
    private enum HistoryFilter: String, CaseIterable, Identifiable {
        case all = "All"
        case quits = "Quits"
        case nearMisses = "Near misses"

        var id: String { rawValue }
    }

    @ObservedObject private var history = QuitHistoryStore.shared
    @ObservedObject private var preferences = PreferencesManager.shared
    @State private var filter: HistoryFilter = .all
    @State private var isConfirmingClear = false

    private var filteredEvents: [QuitEvent] {
        history.events.filter { event in
            switch filter {
            case .all:
                return true
            case .quits:
                return event.outcome == .quit
            case .nearMisses:
                return [.cancelled, .skippedExcluded, .stillRunning, .failed]
                    .contains(event.outcome)
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("History filter", selection: $filter) {
                ForEach(HistoryFilter.allCases) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .padding()

            if filteredEvents.isEmpty {
                ContentUnavailableView(
                    emptyTitle,
                    systemImage: "clock.arrow.circlepath",
                    description: Text(emptyDescription)
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(filteredEvents) { event in
                    QuitHistoryRow(event: event)
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
            }

            Divider()

            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Toggle("Record quit history", isOn: $preferences.recordHistory)
                    Spacer()
                    Button("Clear History", role: .destructive) {
                        isConfirmingClear = true
                    }
                    .disabled(history.events.isEmpty)
                }

                Text("This history is kept on this Mac only. It is never uploaded anywhere.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
        }
        .confirmationDialog(
            "Clear all quit history?",
            isPresented: $isConfirmingClear,
            titleVisibility: .visible
        ) {
            Button("Clear History", role: .destructive) {
                history.clear()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action permanently removes every history entry from this Mac.")
        }
    }

    private var emptyTitle: String {
        switch filter {
        case .all:
            return "No history yet"
        case .quits:
            return "No confirmed quits"
        case .nearMisses:
            return "No near misses"
        }
    }

    private var emptyDescription: String {
        if !preferences.recordHistory {
            return "History recording is off. Turn it on below to record future quit decisions."
        }

        switch filter {
        case .all:
            return "Confirmed quits, cancelled quits, exclusions, and failures will appear here."
        case .quits:
            return "Apps that RedButtonQuit confirms as terminated will appear here."
        case .nearMisses:
            return "Cancelled quits, exclusions, apps still running, and failures will appear here."
        }
    }
}

private struct QuitHistoryRow: View {
    let event: QuitEvent

    var body: some View {
        HStack(spacing: 12) {
            appIcon
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(event.appName)
                    .font(.headline)
                    .lineLimit(1)

                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(outcomeText)
                        .font(.caption)
                        .foregroundStyle(outcomeColor)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(outcomeColor.opacity(0.12))
                        .clipShape(Capsule())

                    if let detail = event.detail, event.outcome == .failed {
                        Text(detail)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
            }

            Spacer(minLength: 12)

            Text(formattedDate)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var appIcon: some View {
        if let icon = AppIconCache.shared.icon(for: event.bundleIdentifier) {
            Image(nsImage: icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
        } else {
            Image(systemName: "app")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundColor(.secondary)
                .padding(4)
        }
    }

    private var outcomeText: String {
        switch event.outcome {
        case .quit:
            return "Quit"
        case .stillRunning:
            return "Asked to quit — still running"
        case .cancelled:
            return "Quit cancelled — a new window opened"
        case .skippedExcluded:
            return "Skipped — on your exclusion list"
        case .failed:
            return "Could not quit"
        case .pending:
            return "Quitting…"
        }
    }

    private var outcomeColor: Color {
        switch event.outcome {
        case .quit:
            return .green
        case .pending:
            return .blue
        case .cancelled, .skippedExcluded:
            return .secondary
        case .stillRunning, .failed:
            return .orange
        }
    }

    private var formattedDate: String {
        if Calendar.current.isDateInToday(event.date) {
            return event.date.formatted(date: .omitted, time: .shortened)
        }
        return event.date.formatted(date: .abbreviated, time: .shortened)
    }
}

private final class AppIconCache {
    static let shared = AppIconCache()

    private var icons: [String: NSImage] = [:]
    private var missingBundleIdentifiers: Set<String> = []

    func icon(for bundleIdentifier: String) -> NSImage? {
        if let icon = icons[bundleIdentifier] {
            return icon
        }
        guard !missingBundleIdentifiers.contains(bundleIdentifier) else { return nil }
        guard let url = NSWorkspace.shared.urlForApplication(
            withBundleIdentifier: bundleIdentifier
        ) else {
            missingBundleIdentifiers.insert(bundleIdentifier)
            return nil
        }

        let icon = NSWorkspace.shared.icon(forFile: url.path)
        icons[bundleIdentifier] = icon
        return icon
    }
}
