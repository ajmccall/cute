/// A number of points that may end in a half, as a drawn game's split stake can. Counted in half points,
/// so totals add exactly.
nonisolated struct Points: Comparable, Hashable, Sendable, ExpressibleByIntegerLiteral, ExpressibleByFloatLiteral {
    /// The number of half points.
    var halves: Int

    init(halves: Int) {
        self.halves = halves
    }

    init(integerLiteral points: Int) {
        halves = points * 2
    }

    /// Whole or half points only, such as 4.5.
    init(floatLiteral points: Double) {
        precondition((points * 2).rounded() == points * 2, "Not a whole or half number of points: \(points)")
        halves = Int(points * 2)
    }

    /// The whole points, leaving out any half.
    var whole: Int { halves / 2 }
    /// Whether the points end in a half.
    var hasHalf: Bool { halves % 2 != 0 }

    static func + (lhs: Points, rhs: Points) -> Points { Points(halves: lhs.halves + rhs.halves) }
    static func - (lhs: Points, rhs: Points) -> Points { Points(halves: lhs.halves - rhs.halves) }
    static func < (lhs: Points, rhs: Points) -> Bool { lhs.halves < rhs.halves }
}

/// White's and Black's points in the current match: the sum of the points awarded to each colour in its games,
/// including the current game once it has finished. Colours stay fixed for the whole match.
nonisolated struct MatchScore: Equatable, Sendable {
    /// The total that ends the match once either colour reaches it or goes past it.
    static let target: Points = 15
    static let zero = MatchScore(white: 0, black: 0)

    var white: Points
    var black: Points

    subscript(color: PieceColor) -> Points {
        switch color {
        case .white: white
        case .black: black
        }
    }

    /// The totals with a finished game's award added: the whole stake to the winner, or half to each on a draw.
    func adding(_ award: PointAward) -> MatchScore {
        switch award {
        case let .win(.white, stake): MatchScore(white: white + Points(stake), black: black)
        case let .win(.black, stake): MatchScore(white: white, black: black + Points(stake))
        case let .split(stake): MatchScore(white: white + Points(halves: stake), black: black + Points(halves: stake))
        }
    }

    /// The totals as they were before a finished game's award was added.
    func subtracting(_ award: PointAward) -> MatchScore {
        let added = MatchScore.zero.adding(award)
        return MatchScore(white: white - added.white, black: black - added.black)
    }

    /// Either total is at the target or past it, so the match is over once its game has finished.
    var reachesTarget: Bool { white >= Self.target || black >= Self.target }

    /// The colour with the higher total, or nil when the totals are equal.
    var leader: PieceColor? {
        if white > black { return .white }
        if black > white { return .black }
        return nil
    }
}

nonisolated extension Points {
    init(_ whole: Int) {
        halves = whole * 2
    }
}
