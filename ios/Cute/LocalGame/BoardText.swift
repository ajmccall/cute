import Foundation

/// The local game's interface text (docs/schema/local-game.md, Interface text), from the String Catalog.
enum BoardText {
    static func side(_ color: PieceColor) -> String {
        switch color {
        case .white: String(localized: "White")
        case .black: String(localized: "Black")
        }
    }

    static func status(of game: LocalGame) -> String {
        switch game.result {
        case let .win(winner, reason):
            let side = side(winner)
            let reasonText = switch reason {
            case .checkmate: String(localized: "Checkmate")
            case .resignation: String(localized: "Resignation")
            }
            return String(localized: "\(side) wins · \(reasonText)")
        case let .draw(reason):
            let reasonText = switch reason {
            case .stalemate: String(localized: "Stalemate")
            case .insufficientMaterial: String(localized: "Insufficient material")
            case .agreement: String(localized: "Agreement")
            }
            return String(localized: "Draw · \(reasonText)")
        case nil:
            let side = side(game.position.sideToMove)
            return game.isInCheck
                ? String(localized: "\(side) to move · Check")
                : String(localized: "\(side) to move")
        }
    }

    static func pieceName(_ piece: Piece) -> String {
        let side = side(piece.color)
        return switch piece.kind {
        case .king: String(localized: "\(side) king")
        case .queen: String(localized: "\(side) queen")
        case .rook: String(localized: "\(side) rook")
        case .bishop: String(localized: "\(side) bishop")
        case .knight: String(localized: "\(side) knight")
        case .pawn: String(localized: "\(side) pawn")
        }
    }

    /// The name of a piece a pawn can become (`PieceKind.promotionChoices`).
    static func promotionChoice(_ kind: PieceKind) -> String {
        switch kind {
        case .queen: String(localized: "Queen")
        case .rook: String(localized: "Rook")
        case .bishop: String(localized: "Bishop")
        default: String(localized: "Knight")
        }
    }

    /// "{coordinate}, {occupant}", where the occupant is Empty or the piece's colour and name.
    static func squareLabel(_ square: Square, occupant: Piece?) -> String {
        let occupantText = occupant.map(pieceName) ?? String(localized: "Empty")
        let coordinate = square.coordinate
        return String(localized: "\(coordinate), \(occupantText)")
    }

    static func confirmResign(_ color: PieceColor) -> String {
        let side = side(color)
        return String(localized: "Resign as \(side)?")
    }
}
