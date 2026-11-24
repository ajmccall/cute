/// How a finished game ended.
nonisolated enum GameResult: Equatable, Sendable {
    case win(PieceColor, WinReason)
    case draw(DrawReason)
}

nonisolated enum WinReason: String, Codable, Sendable {
    case checkmate, resignation, doubleDeclined
}

nonisolated enum DrawReason: String, Codable, Sendable {
    case stalemate, insufficientMaterial, agreement
}

/// The points a finished game awards for its stake.
nonisolated enum PointAward: Equatable, Sendable {
    /// The winner earns the whole stake.
    case win(PieceColor, Int)
    /// A draw: each player earns half of this stake.
    case split(Int)
}
