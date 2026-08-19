import XCTest
@testable import RedButtonQuit

final class QuitHistoryStoreTests: XCTestCase {
    private var directoryURL: URL!
    private var testDefaults: UserDefaults!
    private var testSuiteName: String!
    private var preferences: PreferencesManager!
    private var store: QuitHistoryStore!

    override func setUpWithError() throws {
        directoryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("QuitHistoryStoreTests-\(UUID().uuidString)", isDirectory: true)
        testSuiteName = "com.redbuttonquit.history-tests.\(UUID().uuidString)"
        testDefaults = UserDefaults(suiteName: testSuiteName)
        testDefaults.removePersistentDomain(forName: testSuiteName)
        preferences = PreferencesManager(
            userDefaults: testDefaults,
            managesLoginItem: false
        )
        store = QuitHistoryStore(
            directoryURL: directoryURL,
            preferences: preferences
        )
    }

    override func tearDownWithError() throws {
        store = nil
        preferences = nil
        testDefaults.removePersistentDomain(forName: testSuiteName)
        testDefaults = nil
        testSuiteName = nil
        try? FileManager.default.removeItem(at: directoryURL)
        directoryURL = nil
    }

    func testRecordThenResolveUpdatesEntryInPlace() throws {
        let id = try XCTUnwrap(store.record(
            appName: "Pages",
            bundleIdentifier: "com.apple.iWork.Pages",
            outcome: .pending
        ))

        store.resolve(id: id, outcome: .quit)

        XCTAssertEqual(store.events.count, 1)
        XCTAssertEqual(store.events[0].id, id)
        XCTAssertEqual(store.events[0].outcome, .quit)
        XCTAssertNotNil(store.events[0].confirmedAt)
    }

    func testEventCapTrimsOldestAndKeepsNewestFirst() throws {
        var identifiers: [UUID] = []

        for index in 0..<201 {
            let id = try XCTUnwrap(store.record(
                appName: "App \(index)",
                bundleIdentifier: "com.example.app\(index)",
                outcome: .quit
            ))
            identifiers.append(id)
        }

        XCTAssertEqual(store.events.count, 200)
        XCTAssertEqual(store.events.first?.id, identifiers.last)
        XCTAssertEqual(store.events.last?.id, identifiers[1])
        XCTAssertFalse(store.events.contains { $0.id == identifiers[0] })
    }

    func testPersistenceRoundTrip() throws {
        let id = try XCTUnwrap(store.record(
            appName: "Safari",
            bundleIdentifier: "com.apple.Safari",
            outcome: .pending
        ))
        store.resolve(id: id, outcome: .stillRunning)
        store.flush()

        let reloadedStore = QuitHistoryStore(
            directoryURL: directoryURL,
            preferences: preferences
        )
        let event = try XCTUnwrap(reloadedStore.events.first)

        XCTAssertEqual(reloadedStore.events.count, 1)
        XCTAssertEqual(event.id, id)
        XCTAssertEqual(event.appName, "Safari")
        XCTAssertEqual(event.bundleIdentifier, "com.apple.Safari")
        XCTAssertEqual(event.outcome, .stillRunning)
        XCTAssertNotNil(event.confirmedAt)
        XCTAssertEqual(
            event.date.timeIntervalSince1970,
            store.events[0].date.timeIntervalSince1970,
            accuracy: 1
        )
    }

    func testCorruptJSONLoadsAsEmpty() throws {
        try FileManager.default.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true
        )
        try Data("not valid JSON".utf8).write(
            to: directoryURL.appendingPathComponent("history.json")
        )

        let reloadedStore = QuitHistoryStore(
            directoryURL: directoryURL,
            preferences: preferences
        )

        XCTAssertTrue(reloadedStore.events.isEmpty)
    }

    func testDisabledRecordingWritesNothing() {
        preferences.recordHistory = false

        let id = store.record(
            appName: "Mail",
            bundleIdentifier: "com.apple.mail",
            outcome: .quit
        )
        store.flush()

        XCTAssertNil(id)
        XCTAssertTrue(store.events.isEmpty)
        XCTAssertFalse(
            FileManager.default.fileExists(
                atPath: directoryURL.appendingPathComponent("history.json").path
            )
        )
    }

    func testClearEmptiesMemoryAndFile() throws {
        _ = store.record(
            appName: "Mail",
            bundleIdentifier: "com.apple.mail",
            outcome: .quit
        )
        store.flush()

        store.clear()

        XCTAssertTrue(store.events.isEmpty)
        let data = try Data(
            contentsOf: directoryURL.appendingPathComponent("history.json")
        )
        let decoded = try JSONDecoder().decode([QuitEvent].self, from: data)
        XCTAssertTrue(decoded.isEmpty)
    }
}
