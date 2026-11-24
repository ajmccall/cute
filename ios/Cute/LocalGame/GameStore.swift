import Foundation

/// The one current game a device keeps: its committed position and any result.
nonisolated struct SavedGame: Equatable, Sendable {
    var position: Position
    var result: GameResult?

    static let opening = SavedGame(position: .opening, result: nil)
}

/// Keeps the current game. Errors mean the game couldn't be read or the change wasn't saved.
protocol GameStore {
    /// The saved game, or nil when none has been saved yet.
    func load() throws -> SavedGame?
    func save(_ game: SavedGame) throws
}

/// The current game as a small JSON file, replaced atomically on each save.
nonisolated struct FileGameStore: GameStore {
    let fileURL: URL

    func load() throws -> SavedGame? {
        let data: Data
        do {
            data = try Data(contentsOf: fileURL)
        } catch CocoaError.fileReadNoSuchFile {
            return nil
        }
        return try JSONDecoder().decode(SavedGame.self, from: data)
    }

    func save(_ game: SavedGame) throws {
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try JSONEncoder().encode(game).write(to: fileURL, options: .atomic)
    }
}
