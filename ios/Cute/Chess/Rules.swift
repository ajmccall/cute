nonisolated struct Move: Hashable, Sendable {
    let from: Square
    let to: Square
    /// The piece a pawn becomes on the last rank; nil for every other move.
    var promotion: PieceKind?
}

nonisolated extension Position {
    /// Every legal move for the side to move.
    var legalMoves: [Move] {
        (pseudoLegalMoves(for: sideToMove) + castlingMoves).filter { move in
            !applying(move).isInCheck(sideToMove)
        }
    }

    func legalMoves(from square: Square) -> [Move] {
        guard self[square]?.color == sideToMove else { return [] }
        return legalMoves.filter { $0.from == square }
    }

    /// Whether a game could stand in this position: one king each, no pawn on the first or last rank,
    /// the side that just moved not in check, and castling and en passant consistent with the pieces.
    var isPlayable: Bool {
        for color in PieceColor.allCases {
            guard pieces.values.count(where: { $0 == Piece(color: color, kind: .king) }) == 1 else { return false }
        }
        guard !pieces.contains(where: { $0.value.kind == .pawn && [0, 7].contains($0.key.rank) }),
              !isInCheck(sideToMove.opponent)
        else { return false }
        for castling in Castling.all where castlingRights.contains(castling.right) {
            guard self[castling.kingFrom] == Piece(color: castling.color, kind: .king),
                  self[castling.rookFrom] == Piece(color: castling.color, kind: .rook)
            else { return false }
        }
        if let enPassantTarget {
            // The opponent's pawn just passed over the target, and stands one rank beyond it.
            let passer = sideToMove.opponent
            let passedRank = passer.pawnStartRank + passer.forward
            guard enPassantTarget.rank == passedRank, self[enPassantTarget] == nil,
                  self[Square(file: enPassantTarget.file, rank: passedRank + passer.forward)!] == Piece(color: passer, kind: .pawn)
            else { return false }
        }
        return true
    }

    /// The result the rules end the game with in this position, if any.
    var automaticResult: GameResult? {
        if legalMoves.isEmpty {
            return isInCheck(sideToMove) ? .win(sideToMove.opponent, .checkmate) : .draw(.stalemate)
        }
        return hasInsufficientMaterial ? .draw(.insufficientMaterial) : nil
    }

    /// Kings alone, one bishop or knight besides the kings, or only bishops all on squares of one colour.
    /// Not a test of whether mate can be forced.
    var hasInsufficientMaterial: Bool {
        let others = pieces.filter { $0.value.kind != .king }
        if others.isEmpty { return true }
        if others.count == 1, let only = others.first, [.bishop, .knight].contains(only.value.kind) { return true }
        return others.allSatisfy { $0.value.kind == .bishop } && Set(others.keys.map(\.isLight)).count == 1
    }

    func isInCheck(_ color: PieceColor) -> Bool {
        guard let king = pieces.first(where: { $0.value == Piece(color: color, kind: .king) })?.key else {
            return false
        }
        return isAttacked(king, by: color.opponent)
    }

    /// The position after a move, with the other side to move. Assumes the move is legal.
    func applying(_ move: Move) -> Position {
        var next = self
        guard let piece = self[move.from] else { return next }
        next[move.from] = nil
        next[move.to] = move.promotion.map { Piece(color: piece.color, kind: $0) } ?? piece
        if piece.kind == .king, abs(move.to.file - move.from.file) == 2, let castling = Castling.all.first(where: {
            $0.kingFrom == move.from && $0.kingTo == move.to
        }) {
            next[castling.rookTo] = next[castling.rookFrom]
            next[castling.rookFrom] = nil
        }
        // A right goes once its king or rook leaves its square, or the rook is captured there.
        for castling in Castling.all where [move.from, move.to].contains(castling.kingFrom) || [move.from, move.to].contains(castling.rookFrom) {
            next.castlingRights.remove(castling.right)
        }
        next.enPassantTarget = nil
        if piece.kind == .pawn {
            if move.to == enPassantTarget, self[move.to] == nil {
                // The captured pawn stands beside the mover, behind the square it passed over.
                next[Square(file: move.to.file, rank: move.from.rank)!] = nil
            }
            if abs(move.to.rank - move.from.rank) == 2 {
                next.enPassantTarget = Square(file: move.from.file, rank: (move.from.rank + move.to.rank) / 2)
            }
        }
        next.sideToMove = sideToMove.opponent
        return next
    }

    func isAttacked(_ square: Square, by attacker: PieceColor) -> Bool {
        // Pawns attack diagonally forward, so look one rank behind the square from the attacker's side.
        let pawnRank = -attacker.forward
        for files in [-1, 1] {
            if let from = square.offset(files: files, ranks: pawnRank), self[from] == Piece(color: attacker, kind: .pawn) {
                return true
            }
        }
        for (files, ranks) in Self.knightSteps {
            if let from = square.offset(files: files, ranks: ranks), self[from] == Piece(color: attacker, kind: .knight) {
                return true
            }
        }
        for (files, ranks) in Self.kingSteps {
            if let from = square.offset(files: files, ranks: ranks), self[from] == Piece(color: attacker, kind: .king) {
                return true
            }
        }
        for (direction, kinds) in [(Self.straightDirections, [PieceKind.rook, .queen]), (Self.diagonalDirections, [.bishop, .queen])] {
            for (files, ranks) in direction {
                var current = square.offset(files: files, ranks: ranks)
                while let next = current {
                    if let piece = self[next] {
                        if piece.color == attacker, kinds.contains(piece.kind) { return true }
                        break
                    }
                    current = next.offset(files: files, ranks: ranks)
                }
            }
        }
        return false
    }
}

/// Where the king and rook start and finish for one side of castling.
nonisolated struct Castling: Sendable {
    let right: CastlingRight
    let color: PieceColor
    let kingFrom: Square
    let kingTo: Square
    let rookFrom: Square
    let rookTo: Square
    /// Squares between king and rook that must be empty.
    let between: [Square]
    /// Squares the king stands on, crosses or reaches, which must not be attacked.
    let kingPath: [Square]

    static let all: [Castling] = [
        Castling(right: .whiteKingside, color: .white, kingFrom: "e1", kingTo: "g1", rookFrom: "h1", rookTo: "f1",
                 between: ["f1", "g1"], kingPath: ["e1", "f1", "g1"]),
        Castling(right: .whiteQueenside, color: .white, kingFrom: "e1", kingTo: "c1", rookFrom: "a1", rookTo: "d1",
                 between: ["b1", "c1", "d1"], kingPath: ["e1", "d1", "c1"]),
        Castling(right: .blackKingside, color: .black, kingFrom: "e8", kingTo: "g8", rookFrom: "h8", rookTo: "f8",
                 between: ["f8", "g8"], kingPath: ["e8", "f8", "g8"]),
        Castling(right: .blackQueenside, color: .black, kingFrom: "e8", kingTo: "c8", rookFrom: "a8", rookTo: "d8",
                 between: ["b8", "c8", "d8"], kingPath: ["e8", "d8", "c8"]),
    ]

    private init(right: CastlingRight, color: PieceColor, kingFrom: String, kingTo: String, rookFrom: String,
                 rookTo: String, between: [String], kingPath: [String]) {
        self.right = right
        self.color = color
        self.kingFrom = Square(kingFrom)!
        self.kingTo = Square(kingTo)!
        self.rookFrom = Square(rookFrom)!
        self.rookTo = Square(rookTo)!
        self.between = between.map { Square($0)! }
        self.kingPath = kingPath.map { Square($0)! }
    }
}

// MARK: - Move generation

nonisolated private extension Position {
    var castlingMoves: [Move] {
        Castling.all.compactMap { castling in
            guard castling.color == sideToMove,
                  castlingRights.contains(castling.right),
                  self[castling.kingFrom] == Piece(color: sideToMove, kind: .king),
                  self[castling.rookFrom] == Piece(color: sideToMove, kind: .rook),
                  castling.between.allSatisfy({ self[$0] == nil }),
                  castling.kingPath.allSatisfy({ !isAttacked($0, by: sideToMove.opponent) })
            else { return nil }
            return Move(from: castling.kingFrom, to: castling.kingTo)
        }
    }

    static let knightSteps = [(1, 2), (2, 1), (2, -1), (1, -2), (-1, -2), (-2, -1), (-2, 1), (-1, 2)]
    static let kingSteps = [(0, 1), (1, 1), (1, 0), (1, -1), (0, -1), (-1, -1), (-1, 0), (-1, 1)]
    static let straightDirections = [(0, 1), (1, 0), (0, -1), (-1, 0)]
    static let diagonalDirections = [(1, 1), (1, -1), (-1, -1), (-1, 1)]

    func pseudoLegalMoves(for color: PieceColor) -> [Move] {
        pieces.filter { $0.value.color == color }.flatMap { square, piece in
            switch piece.kind {
            case .pawn: pawnMoves(from: square, color: color)
            case .knight: steps(from: square, color: color, offsets: Self.knightSteps)
            case .king: steps(from: square, color: color, offsets: Self.kingSteps)
            case .bishop: slides(from: square, color: color, directions: Self.diagonalDirections)
            case .rook: slides(from: square, color: color, directions: Self.straightDirections)
            case .queen: slides(from: square, color: color, directions: Self.straightDirections + Self.diagonalDirections)
            }
        }
    }

    func steps(from square: Square, color: PieceColor, offsets: [(Int, Int)]) -> [Move] {
        offsets.compactMap { files, ranks in
            guard let to = square.offset(files: files, ranks: ranks), self[to]?.color != color else { return nil }
            return Move(from: square, to: to)
        }
    }

    func slides(from square: Square, color: PieceColor, directions: [(Int, Int)]) -> [Move] {
        var moves: [Move] = []
        for (files, ranks) in directions {
            var current = square.offset(files: files, ranks: ranks)
            while let to = current {
                if let occupant = self[to] {
                    if occupant.color != color { moves.append(Move(from: square, to: to)) }
                    break
                }
                moves.append(Move(from: square, to: to))
                current = to.offset(files: files, ranks: ranks)
            }
        }
        return moves
    }

    func pawnMoves(from square: Square, color: PieceColor) -> [Move] {
        pawnSteps(from: square, color: color).flatMap { move in
            move.to.rank == color.promotionRank
                ? PieceKind.promotionChoices.map { Move(from: move.from, to: move.to, promotion: $0) }
                : [move]
        }
    }

    func pawnSteps(from square: Square, color: PieceColor) -> [Move] {
        let forward = color.forward
        let startRank = color.pawnStartRank
        var moves: [Move] = []
        if let one = square.offset(files: 0, ranks: forward), self[one] == nil {
            moves.append(Move(from: square, to: one))
            if square.rank == startRank, let two = one.offset(files: 0, ranks: forward), self[two] == nil {
                moves.append(Move(from: square, to: two))
            }
        }
        for files in [-1, 1] {
            guard let to = square.offset(files: files, ranks: forward) else { continue }
            if let occupant = self[to], occupant.color != color {
                moves.append(Move(from: square, to: to))
            } else if to == enPassantTarget, self[to] == nil,
                      self[Square(file: to.file, rank: square.rank)!] == Piece(color: color.opponent, kind: .pawn) {
                moves.append(Move(from: square, to: to))
            }
        }
        return moves
    }
}
