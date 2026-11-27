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

    /// What VoiceOver announces when the status changes: the status, any point award after it, and the match
    /// result once the match is over.
    static func announcement(of game: LocalGame) -> String {
        var lines = [status(of: game)]
        if let award = game.award { lines.append(self.award(award, spoken: true)) }
        if game.isMatchOver { lines.append(matchResult(game.matchScore, spoken: true)) }
        return lines.joined(separator: "\n")
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

    /// A match total with its unit: "0 points", "1 point", "½ point", "4½ points".
    /// Spoken, a half is in words: "half a point", "4 and a half points".
    static func total(_ total: Points, spoken: Bool) -> String {
        guard total.hasHalf else { return points(total.whole) }
        let whole = total.whole
        if whole == 0 { return halfOf(1, spoken: spoken) }
        return spoken ? String(localized: "\(whole) and a half points") : String(localized: "\(whole)½ points")
    }

    /// A match total without its unit, for the match result: "16", "16½", or "½" alone.
    /// Spoken, a half is in words: "16 and a half", or "a half" alone.
    static func bareTotal(_ total: Points, spoken: Bool) -> String {
        let whole = total.whole
        guard total.hasHalf else { return String(localized: "\(whole)") }
        if whole == 0 { return spoken ? String(localized: "a half") : String(localized: "½") }
        return spoken ? String(localized: "\(whole) and a half") : String(localized: "\(whole)½")
    }

    /// "White {White total} · Black {Black total} · first to 15", each with its unit.
    static func matchScore(_ matchScore: MatchScore, spoken: Bool) -> String {
        let white = total(matchScore.white, spoken: spoken)
        let black = total(matchScore.black, spoken: spoken)
        let target = points(MatchScore.target.whole)
        return String(localized: "White \(white) · Black \(black) · first to \(target)")
    }

    /// "{winner} wins the match, {winner's total} to {loser's total}", or "Match drawn, {total} to {total}".
    static func matchResult(_ matchScore: MatchScore, spoken: Bool) -> String {
        guard let winner = matchScore.leader else {
            let total = bareTotal(matchScore.white, spoken: spoken)
            return String(localized: "Match drawn, \(total) to \(total)")
        }
        let side = side(winner)
        let winnersTotal = bareTotal(matchScore[winner], spoken: spoken)
        let losersTotal = bareTotal(matchScore[winner.opponent], spoken: spoken)
        return String(localized: "\(side) wins the match, \(winnersTotal) to \(losersTotal)")
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

    /// What declining means, naming the match when the decline would end it.
    static func declineEffect(offerer: PieceColor, stake: Int, endsMatch: Bool) -> String {
        let side = side(offerer)
        let points = points(stake)
        return endsMatch
            ? String(localized: "Decline: \(side) wins \(points) and the match.")
            : String(localized: "Decline: \(side) wins \(points).")
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

    /// "Captured by {side}: {pieces}", such as "Captured by White: 2 pawns, 1 knight", or
    /// "Captured by {side}: none".
    static func captures(_ captures: Captures, by color: PieceColor) -> String {
        let side = side(color)
        let groups = captures.groups(by: color)
        guard !groups.isEmpty else { return String(localized: "Captured by \(side): none") }
        // A list of units, such as "2 pawns, 1 knight", joined as the locale joins one.
        let pieces = groups.map { pieceCount($0.kind, $0.count) }.formatted(.list(type: .and, width: .narrow))
        return String(localized: "Captured by \(side): \(pieces)")
    }

    /// "Captured by {side}:", shown before the captured pieces' icons, which stand in for their names.
    static func capturesHeading(_ color: PieceColor) -> String {
        let side = side(color)
        return String(localized: "Captured by \(side):")
    }

    /// The count shown beside a captured piece's icon: "×2".
    static func shownCount(_ count: Int) -> String {
        String(localized: "×\(count)")
    }

    /// A number of captured pieces of one kind: "1 pawn", "2 knights".
    static func pieceCount(_ kind: PieceKind, _ count: Int) -> String {
        switch kind {
        case .pawn: String(localized: "\(count) pawns")
        case .knight: String(localized: "\(count) knights")
        case .bishop: String(localized: "\(count) bishops")
        case .rook: String(localized: "\(count) rooks")
        case .queen: String(localized: "\(count) queens")
        case .king: String(localized: "\(count) kings")
        }
    }

    /// The material lead: shown as "+{N}", spoken as "{side} ahead by {N} in material". Never in points.
    static func advantage(_ lead: MaterialLead, spoken: Bool) -> String {
        let amount = lead.amount
        guard spoken else { return String(localized: "+\(amount)") }
        let side = side(lead.side)
        return String(localized: "\(side) ahead by \(amount) in material")
    }
}
