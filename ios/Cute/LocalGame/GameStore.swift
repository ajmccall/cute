import Foundation

/// The one current game a device keeps: its committed position, any result, and the doubling cube.
nonisolated struct SavedGame: Equatable, Sendable {
    /// The highest stake: once a game is played for this, neither side can offer.
    static let maximumStake = 64

    var position: Position
    var result: GameResult?
    /// The points the game is played for. Nil only in a game saved before the cube.
    var stake: Int? = 1
    /// The side that took the last double and alone may offer the next; nil before the first take.
    var nextDoubler: PieceColor? = nil
    /// An offer the side to move made, waiting for the other side to take or decline.
    var doublePending = false

    static let opening = SavedGame(position: .opening, result: nil)

    /// Whether the side to move is entitled to offer a double: below the maximum stake, and either before
    /// the first take or as the side that took the last double.
    var sideToMoveMayOffer: Bool {
        guard let stake else { return false }
        return stake < Self.maximumStake && (nextDoubler == nil || nextDoubler == position.sideToMove)
    }
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
