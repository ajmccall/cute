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
            case .doubleDeclined: String(localized: "Double declined")
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
            if game.isAwaitingDoubleResponse {
                let responder = side(game.responder)
                return String(localized: "\(responder), answer the double")
            }
            let side = side(game.position.sideToMove)
            return game.isInCheck
                ? String(localized: "\(side) to move · Check")
                : String(localized: "\(side) to move")
        }
    }

    /// What VoiceOver announces when the status changes: the status, and any point award after it.
    static func announcement(of game: LocalGame) -> String {
        guard let award = game.award else { return status(of: game) }
        return status(of: game) + "\n" + self.award(award, spoken: true)
    }

    /// A number of whole points, with its unit: "1 point", "2 points".
    static func points(_ count: Int) -> String {
        String(localized: "\(count) points")
    }

    /// Half of a stake, with its unit. Half of one point is "½ point", or "half a point" when spoken.
    static func halfOf(_ stake: Int, spoken: Bool) -> String {
        guard stake == 1 else { return points(stake / 2) }
        return spoken ? String(localized: "half a point") : String(localized: "½ point")
    }

    static func stake(_ stake: Int) -> String {
        let points = points(stake)
        return String(localized: "Stake: \(points)")
    }

    /// Who may offer the next double on their own turn.
    static func doubleRight(of game: LocalGame) -> String {
        if let stake = game.stake, stake >= SavedGame.maximumStake {
            return String(localized: "Maximum stake reached")
        }
        guard let nextDoubler = game.nextDoubler else { return String(localized: "Either player can offer") }
        let side = side(nextDoubler)
        return String(localized: "Only \(side) can offer")
    }

    static func takeEffect(stake: Int) -> String {
        let doubled = points(stake * 2)
        return String(localized: "Take: play for \(doubled).")
    }

    static func declineEffect(offerer: PieceColor, stake: Int) -> String {
        let side = side(offerer)
        let points = points(stake)
        return String(localized: "Decline: \(side) wins \(points).")
    }

    /// "{winner} earns {stake}." or "Each player earns {half stake}.", with half a point in words when spoken.
    static func award(_ award: PointAward, spoken: Bool) -> String {
        switch award {
        case let .win(winner, stake):
            let side = side(winner)
            let points = points(stake)
            return String(localized: "\(side) earns \(points).")
        case let .split(stake):
            let half = halfOf(stake, spoken: spoken)
            return String(localized: "Each player earns \(half).")
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
