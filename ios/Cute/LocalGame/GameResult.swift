/// How a finished game ended.
nonisolated enum GameResult: Equatable, Sendable {
    case win(PieceColor, WinReason)
    case draw(DrawReason)
}

nonisolated enum WinReason: String, Codable, Sendable {
    case checkmate, resignation
}

nonisolated enum DrawReason: String, Codable, Sendable {
    case stalemate, insufficientMaterial, agreement
}
