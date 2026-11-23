nonisolated enum CastlingRight: CaseIterable, Hashable, Sendable {
    case whiteKingside, whiteQueenside, blackKingside, blackQueenside

    var fenLetter: Character {
        switch self {
        case .whiteKingside: "K"
        case .whiteQueenside: "Q"
        case .blackKingside: "k"
        case .blackQueenside: "q"
        }
    }
}

/// Pieces on squares, side to move, castling rights and en passant availability.
nonisolated struct Position: Hashable, Sendable {
    private(set) var pieces: [Square: Piece]
    var sideToMove: PieceColor
    var castlingRights: Set<CastlingRight>
    /// The square a pawn passed over on the previous move, when one did.
    var enPassantTarget: Square?

    subscript(square: Square) -> Piece? {
        get { pieces[square] }
        set { pieces[square] = newValue }
    }

    static let opening = Position(fen: "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq -")!
}

// MARK: - FEN

nonisolated extension Position {
    /// The first four fields of Forsyth–Edwards Notation: placement, side to move, castling and en passant.
    var fen: String {
        let placement = (0..<8).reversed().map { rank in
            var row = ""
            var empty = 0
            for file in 0..<8 {
                if let piece = pieces[Square(file: file, rank: rank)!] {
                    if empty > 0 { row += String(empty); empty = 0 }
                    row.append(piece.fenLetter)
                } else {
                    empty += 1
                }
            }
            if empty > 0 { row += String(empty) }
            return row
        }.joined(separator: "/")
        let castling = CastlingRight.allCases.filter(castlingRights.contains).map { String($0.fenLetter) }.joined()
        return [
            placement,
            sideToMove == .white ? "w" : "b",
            castling.isEmpty ? "-" : castling,
            enPassantTarget?.coordinate ?? "-",
        ].joined(separator: " ")
    }

    /// Reads the first four FEN fields; any move counters after them are ignored.
    /// Returns nil for text that isn't a well-formed placement, side, castling and en passant.
    init?(fen: String) {
        let fields = fen.split(separator: " ", omittingEmptySubsequences: true)
        guard (4...6).contains(fields.count) else { return nil }

        let rows = fields[0].split(separator: "/", omittingEmptySubsequences: false)
        guard rows.count == 8 else { return nil }
        var pieces: [Square: Piece] = [:]
        for (index, row) in rows.enumerated() {
            let rank = 7 - index
            var file = 0
            for character in row {
                if let digit = character.wholeNumberValue, character.isASCII, (1...8).contains(digit) {
                    file += digit
                } else if let piece = Piece(fenLetter: character), let square = Square(file: file, rank: rank) {
                    pieces[square] = piece
                    file += 1
                } else {
                    return nil
                }
                guard file <= 8 else { return nil }
            }
            guard file == 8 else { return nil }
        }

        let sideToMove: PieceColor
        switch fields[1] {
        case "w": sideToMove = .white
        case "b": sideToMove = .black
        default: return nil
        }

        var castlingRights: Set<CastlingRight> = []
        if fields[2] != "-" {
            for character in fields[2] {
                guard let right = CastlingRight.allCases.first(where: { $0.fenLetter == character }),
                      castlingRights.insert(right).inserted
                else { return nil }
            }
        }

        var enPassantTarget: Square?
        if fields[3] != "-" {
            guard let square = Square(String(fields[3])) else { return nil }
            enPassantTarget = square
        }

        self.init(pieces: pieces, sideToMove: sideToMove, castlingRights: castlingRights, enPassantTarget: enPassantTarget)
    }
}
