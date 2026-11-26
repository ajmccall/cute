import Foundation

/// The saved file's format, version 3:
/// `{"version": 3, "position": "<FEN>", "result": <result>, "stake": 1, "nextDoubler": "white" | "black" | null,
/// "doublePending": false, "whiteTotal": 4.5, "blackTotal": 3}`, where `<result>` is
/// `{"winner": "white", "reason": "checkmate"}`, `{"draw": "stalemate"}` or `null`, and each total is a whole or
/// half number of points.
///
/// Version 2, from before matches, had no totals. It is still read, as the first game of a match: at no points
/// each, plus the game's award once it has finished.
/// Version 1, from before the cube, had only `version`, `position` and `result`. It is still read,
/// as a game with no stake, nobody named to double next, no pending offer and no points each.
nonisolated extension SavedGame: Codable {
    private enum CodingKeys: String, CodingKey {
        case version, position, result, stake, nextDoubler, doublePending, whiteTotal, blackTotal
    }

    private enum ResultKeys: String, CodingKey {
        case winner, reason, draw
    }

    static let formatVersion = 3
    private static let beforeMatchesVersion = 2
    private static let beforeTheCubeVersion = 1
    /// The stakes a game can be played for: one point, doubled up to six times.
    static let stakes: Set<Int> = [1, 2, 4, 8, 16, 32, maximumStake]

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let version = try container.decode(Int.self, forKey: .version)
        guard [Self.formatVersion, Self.beforeMatchesVersion, Self.beforeTheCubeVersion].contains(version) else {
            throw DecodingError.dataCorruptedError(
                forKey: .version, in: container, debugDescription: "Unsupported saved game version \(version)")
        }
        let fen = try container.decode(String.self, forKey: .position)
        guard let position = Position(fen: fen), position.isPlayable else {
            throw DecodingError.dataCorruptedError(
                forKey: .position, in: container, debugDescription: "Unreadable position")
        }
        self.position = position

        if try container.decodeNil(forKey: .result) {
            result = nil
        } else {
            let resultContainer = try container.nestedContainer(keyedBy: ResultKeys.self, forKey: .result)
            if let draw = try resultContainer.decodeIfPresent(DrawReason.self, forKey: .draw) {
                result = .draw(draw)
            } else {
                result = .win(
                    try resultContainer.decode(PieceColor.self, forKey: .winner),
                    try resultContainer.decode(WinReason.self, forKey: .reason))
            }
        }

        score = .zero
        guard version != Self.beforeTheCubeVersion else {
            // No game was declined before the cube.
            if case .win(_, .doubleDeclined) = result {
                throw DecodingError.dataCorruptedError(
                    forKey: .result, in: container, debugDescription: "A declined double before the cube")
            }
            stake = nil
            nextDoubler = nil
            doublePending = false
            return
        }
        let stake = try container.decode(Int.self, forKey: .stake)
        let nextDoubler = try container.decode(PieceColor?.self, forKey: .nextDoubler)
        let doublePending = try container.decode(Bool.self, forKey: .doublePending)
        // The stake rises only when a double is taken, which names the taker to double next.
        guard Self.stakes.contains(stake), (stake == 1) == (nextDoubler == nil) else {
            throw DecodingError.dataCorruptedError(
                forKey: .stake, in: container, debugDescription: "Stake \(stake) with next doubler \(String(describing: nextDoubler))")
        }
        self.stake = stake
        self.nextDoubler = nextDoubler
        self.doublePending = doublePending
        // Only the side to move, entitled to double, can have an offer waiting, in a game still being played.
        if doublePending {
            guard result == nil, position.automaticResult == nil, sideToMoveMayOffer else {
                throw DecodingError.dataCorruptedError(
                    forKey: .doublePending, in: container, debugDescription: "An offer no one could have made")
            }
        }

        guard version == Self.formatVersion else {
            // A game saved before matches is the first game of one.
            if let award { score = score.adding(award) }
            return
        }
        let score = MatchScore(white: try Self.decodeTotal(.whiteTotal, in: container),
                               black: try Self.decodeTotal(.blackTotal, in: container))
        // Only a finished game can take a total to the target, and only by its own award: before it, both
        // totals were below the target.
        let before = award.map { score.subtracting($0) } ?? score
        guard before.white >= 0, before.black >= 0, !before.reachesTarget else {
            throw DecodingError.dataCorruptedError(
                forKey: .whiteTotal, in: container, debugDescription: "Totals \(score) no match can reach")
        }
        self.score = score
    }

    /// A total of whole or half points, from 0.
    private static func decodeTotal(
        _ key: CodingKeys, in container: KeyedDecodingContainer<CodingKeys>
    ) throws -> Points {
        let total = try container.decode(Double.self, forKey: key)
        let halves = total * 2
        // Above any total a match can reach, so that no number is too large to count.
        let ceiling = Double((MatchScore.target.whole + maximumStake) * 2)
        guard halves >= 0, halves <= ceiling, halves.rounded() == halves else {
            throw DecodingError.dataCorruptedError(forKey: key, in: container, debugDescription: "Total \(total)")
        }
        return Points(halves: Int(halves))
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(Self.formatVersion, forKey: .version)
        try container.encode(position.fen, forKey: .position)
        switch result {
        case nil:
            try container.encodeNil(forKey: .result)
        case let .win(winner, reason):
            var resultContainer = container.nestedContainer(keyedBy: ResultKeys.self, forKey: .result)
            try resultContainer.encode(winner, forKey: .winner)
            try resultContainer.encode(reason, forKey: .reason)
        case let .draw(reason):
            var resultContainer = container.nestedContainer(keyedBy: ResultKeys.self, forKey: .result)
            try resultContainer.encode(reason, forKey: .draw)
        }
        try container.encode(stake, forKey: .stake)
        try container.encode(nextDoubler, forKey: .nextDoubler)
        try container.encode(doublePending, forKey: .doublePending)
        try container.encode(Double(score.white.halves) / 2, forKey: .whiteTotal)
        try container.encode(Double(score.black.halves) / 2, forKey: .blackTotal)
    }
}
