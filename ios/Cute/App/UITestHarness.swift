#if DEBUG
import Foundation

/// Debug builds only: lets UI tests give each scenario its own current-game file, seed a position,
/// and make reads or saves fail. Release builds contain none of this, and the app shows no debug controls.
struct UITestHarness {
    /// The scenario's own file name in Application Support.
    static let fileKey = "CUTE_UITEST_GAME_FILE"
    /// A FEN position written to the scenario's file at launch, replacing what was there.
    static let seedKey = "CUTE_UITEST_SEED_FEN"
    /// Comma-separated `Fault` raw values, such as "read,write": those store operations fail for this launch.
    static let faultKey = "CUTE_UITEST_FAULT"

    enum Fault: String {
        case read, write
    }

    let fileURL: URL
    let seed: Position?
    let faults: Set<Fault>

    init?(environment: [String: String], folder: URL) {
        guard let fileName = environment[Self.fileKey], !fileName.contains("/") else { return nil }
        fileURL = folder.appending(path: fileName)
        seed = environment[Self.seedKey].flatMap(Position.init(fen:))
        faults = Set((environment[Self.faultKey] ?? "").split(separator: ",").compactMap { Fault(rawValue: String($0)) })
    }

    func makeStore() -> GameStore {
        let store = FileGameStore(fileURL: fileURL)
        if let seed {
            try? store.save(SavedGame(position: seed, result: nil))
        }
        return FailingGameStore(wrapped: store, failsReads: faults.contains(.read), failsWrites: faults.contains(.write))
    }
}

private struct FailingGameStore: GameStore {
    struct InjectedFailure: Error {}

    let wrapped: GameStore
    let failsReads: Bool
    let failsWrites: Bool

    func load() throws -> SavedGame? {
        if failsReads { throw InjectedFailure() }
        return try wrapped.load()
    }

    func save(_ game: SavedGame) throws {
        if failsWrites { throw InjectedFailure() }
        try wrapped.save(game)
    }
}
#endif
