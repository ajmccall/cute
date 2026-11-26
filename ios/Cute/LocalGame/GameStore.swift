import Foundation

/// The one current game a device keeps: its committed position, any result, and the doubling cube,
/// saved together with the match score so a game's result and its award are written in one save.
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
    /// White's and Black's totals in this match, including this game's award once it has finished.
    var score: MatchScore = .zero

    /// The first game of a new match: the opening position at one point, at no points each.
    static let opening = SavedGame(position: .opening, result: nil)

    /// What the game awards once finished: nothing while it is played, or for a game finished before the cube.
    var award: PointAward? {
        guard let stake else { return nil }
        return switch result {
        case let .win(winner, _): .win(winner, stake)
        case .draw: .split(stake)
        case nil: nil
        }
    }

    /// The game ended with this result, and its award added to the match score, as one change.
    func ending(with result: GameResult) -> SavedGame {
        var ended = self
        ended.result = result
        ended.doublePending = false
        if let award = ended.award { ended.score = score.adding(award) }
        return ended
    }

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
