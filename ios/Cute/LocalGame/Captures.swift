/// The opponent's pieces each colour has captured in the current game, in the order taken. Each is the piece that
/// stood on the captured square: a captured promoted piece is its promoted kind, and an en passant capture a pawn.
nonisolated struct Captures: Equatable, Sendable {
    /// A fresh game's: nothing captured by either colour.
    static let empty = Captures(white: [], black: [])

    /// The black pieces White has captured.
    var white: [PieceKind]
    /// The white pieces Black has captured.
    var black: [PieceKind]

    /// The pieces this colour has captured.
    subscript(color: PieceColor) -> [PieceKind] {
        get { color == .white ? white : black }
        set {
            switch color {
            case .white: white = newValue
            case .black: black = newValue
            }
        }
    }

    /// The kinds a colour has captured with how many of each, in the order pawn, knight, bishop, rook, queen,
    /// leaving out kinds it hasn't captured.
    func groups(by color: PieceColor) -> [(kind: PieceKind, count: Int)] {
        let captured = self[color]
        return Self.groupOrder.compactMap { kind in
            let count = captured.count(where: { $0 == kind })
            return count > 0 ? (kind, count) : nil
        }
    }

    private static let groupOrder: [PieceKind] = [.pawn, .knight, .bishop, .rook, .queen]
}
