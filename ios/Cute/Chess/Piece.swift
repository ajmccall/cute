nonisolated enum PieceColor: String, Codable, CaseIterable, Sendable {
    case white, black

    var opponent: PieceColor { self == .white ? .black : .white }

    /// The rank direction this colour's pawns advance in.
    var forward: Int { self == .white ? 1 : -1 }

    /// The rank this colour's pawns start on, 0 being rank 1.
    var pawnStartRank: Int { self == .white ? 1 : 6 }

    /// The rank this colour's pawns promote on.
    var promotionRank: Int { self == .white ? 7 : 0 }
}

nonisolated enum PieceKind: String, Codable, CaseIterable, Sendable {
    case king, queen, rook, bishop, knight, pawn

    /// The pieces a pawn can become, in the order a choice offers them.
    static let promotionChoices: [PieceKind] = [.queen, .rook, .bishop, .knight]
}

nonisolated struct Piece: Hashable, Sendable {
    let color: PieceColor
    let kind: PieceKind
}

nonisolated extension Piece {
    /// The piece's letter in FEN: upper case for White, lower case for Black.
    var fenLetter: Character {
        let letter: Character = switch kind {
        case .king: "k"
        case .queen: "q"
        case .rook: "r"
        case .bishop: "b"
        case .knight: "n"
        case .pawn: "p"
        }
        return color == .white ? Character(letter.uppercased()) : letter
    }

    init?(fenLetter: Character) {
        let kind: PieceKind? = switch fenLetter.lowercased() {
        case "k": .king
        case "q": .queen
        case "r": .rook
        case "b": .bishop
        case "n": .knight
        case "p": .pawn
        default: nil
        }
        guard let kind, fenLetter.isASCII else { return nil }
        self.init(color: fenLetter.isUppercase ? .white : .black, kind: kind)
    }
}
