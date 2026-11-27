nonisolated extension PieceKind {
    /// What the piece counts for in material: pawn 1, knight 3, bishop 3, rook 5, queen 9, and the king nothing.
    var materialValue: Int {
        switch self {
        case .pawn: 1
        case .knight, .bishop: 3
        case .rook: 5
        case .queen: 9
        case .king: 0
        }
    }
}

nonisolated extension Position {
    /// The total value of a colour's pieces on the board.
    func material(of color: PieceColor) -> Int {
        pieces.values.filter { $0.color == color }.reduce(0) { $0 + $1.kind.materialValue }
    }
}

/// The colour with more material on the board, and by how much. Never points: points belong to the match.
nonisolated struct MaterialLead: Equatable, Sendable {
    let side: PieceColor
    let amount: Int

    /// The lead in a position, or nil when both colours have equal material.
    init?(in position: Position) {
        let difference = position.material(of: .white) - position.material(of: .black)
        guard difference != 0 else { return nil }
        side = difference > 0 ? .white : .black
        amount = abs(difference)
    }

    init(side: PieceColor, amount: Int) {
        self.side = side
        self.amount = amount
    }
}
