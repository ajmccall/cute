#if DEBUG
import Foundation

/// Debug builds only: lets UI tests give each scenario its own current-game file, seed a position,
/// and make reads or saves fail. Release builds contain none of this, and the app shows no debug controls.
struct UITestHarness {
    /// The scenario's own file name in Application Support.
    static let fileKey = "CUTE_UITEST_GAME_FILE"
    /// A FEN position written to the scenario's file at launch, replacing what was there.
    static let seedKey = "CUTE_UITEST_SEED_FEN"
    /// A whole saved file's text, written as it is to the scenario's file at launch, replacing what was there:
    /// for a game saved by an earlier version, or one with a stake or an offer waiting.
    static let seedFileKey = "CUTE_UITEST_SEED_FILE"
    /// Comma-separated `Fault` raw values, such as "read,write": those store operations fail for this launch.
    static let faultKey = "CUTE_UITEST_FAULT"

    enum Fault: String {
        case read, write
    }

    let fileURL: URL
    let seed: Position?
    let seedFile: String?
    let faults: Set<Fault>

    init?(environment: [String: String], folder: URL) {
        guard let fileName = environment[Self.fileKey], !fileName.contains("/") else { return nil }
        fileURL = folder.appending(path: fileName)
        seed = environment[Self.seedKey].flatMap(Position.init(fen:))
        seedFile = environment[Self.seedFileKey]
        faults = Set((environment[Self.faultKey] ?? "").split(separator: ",").map { name in
            guard let fault = Fault(rawValue: String(name)) else {
                preconditionFailure("Unknown \(Self.faultKey) value: \(name)")
            }
            return fault
        })
    }

    func makeStore() -> GameStore {
        let store = FileGameStore(fileURL: fileURL)
        if let seed {
            try? store.save(SavedGame(position: seed, result: nil))
        }
        if let seedFile {
            try? FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try? Data(seedFile.utf8).write(to: fileURL, options: .atomic)
        }
        return FailingGameStore(wrapped: store, faults: faults)
    }
}

private struct FailingGameStore: GameStore {
    struct InjectedFailure: Error {}

    let wrapped: GameStore
    let faults: Set<UITestHarness.Fault>

    func load() throws -> SavedGame? {
        if faults.contains(.read) { throw InjectedFailure() }
        return try wrapped.load()
    }

    func save(_ game: SavedGame) throws {
        if faults.contains(.write) { throw InjectedFailure() }
        try wrapped.save(game)
    }
}
#endif
