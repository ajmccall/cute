import Foundation

/// The saved file's format, version 4:
/// `{"version": 4, "position": "<FEN>", "result": <result>, "stake": 1, "nextDoubler": "white" | "black" | null,
/// "doublePending": false, "whiteTotal": 4.5, "blackTotal": 3, "captures": {"white": ["pawn", "queen"], "black": []}}`,
/// where `<result>` is `{"winner": "white", "reason": "checkmate"}`, `{"draw": "stalemate"}` or `null`, each total is
/// a whole or half number of points, and each colour's captures are the kinds of the opponent's pieces it has taken,
/// in the order taken: "pawn", "knight", "bishop", "rook" or "queen".
///
/// Version 3, from before captures, had no captures. It is still read, as a game with nothing captured.
/// Version 2, from before matches, had no totals. It is still read, as the first game of a match: at no points
/// each, plus the game's award once it has finished.
/// Version 1, from before the cube, had only `version`, `position` and `result`. It is still read,
/// as a game with no stake, nobody named to double next, no pending offer and no points each.
nonisolated extension SavedGame: Codable {
    private enum CodingKeys: String, CodingKey {
        case version, position, result, stake, nextDoubler, doublePending, whiteTotal, blackTotal, captures
        case openingMilestoneUsed, endgameMilestoneUsed, automaticPending, firstAutomaticAnswer
    }

    private enum CapturesKeys: String, CodingKey {
        case white, black
    }

    private enum ResultKeys: String, CodingKey {
        case winner, reason, draw
    }

    static let formatVersion = 5
    private static let beforeAutomaticVersion = 4
    private static let beforeCapturesVersion = 3
    private static let beforeMatchesVersion = 2
    private static let beforeTheCubeVersion = 1
    /// The stakes a game can be played for: one point, doubled up to six times.
    static let stakes: Set<Int> = [1, 2, 4, 8, 16, 32, maximumStake]

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let version = try container.decode(Int.self, forKey: .version)
        guard [Self.formatVersion, Self.beforeAutomaticVersion, Self.beforeCapturesVersion, Self.beforeMatchesVersion, Self.beforeTheCubeVersion]
            .contains(version)
        else {
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

        matchScore = .zero
        captures = .empty
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
        guard Self.stakes.contains(stake),
              version >= Self.formatVersion ? (stake != 1 || nextDoubler == nil) : ((stake == 1) == (nextDoubler == nil)) else {
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

        guard version >= Self.beforeCapturesVersion else {
            // A game saved before matches is the first game of one.
            if let award { matchScore = matchScore.adding(award) }
            return
        }
        let totals = MatchScore(white: try Self.decodeTotal(.whiteTotal, in: container),
                                black: try Self.decodeTotal(.blackTotal, in: container))
        // Only a finished game can take a total to the target, and only by its own award: before it, both
        // totals were below the target.
        let before = award.map { totals.subtracting($0) } ?? totals
        guard before.white >= 0, before.black >= 0, !before.reachesTarget else {
            throw DecodingError.dataCorruptedError(
                forKey: .whiteTotal, in: container, debugDescription: "Totals \(totals) no match can reach")
        }
        matchScore = totals

        guard version >= Self.beforeAutomaticVersion else {
            // A game saved before captures has nothing captured.
            return
        }
        let capturesContainer = try container.nestedContainer(keyedBy: CapturesKeys.self, forKey: .captures)
        let captures = Captures(white: try capturesContainer.decode([PieceKind].self, forKey: .white),
                                black: try capturesContainer.decode([PieceKind].self, forKey: .black))
        for color in PieceColor.allCases {
            guard captures.isPossible(by: color, leaving: position) else {
                throw DecodingError.dataCorruptedError(
                    forKey: .captures, in: container, debugDescription: "Captures \(captures) no game can reach")
            }
        }
        self.captures = captures
        if version >= Self.formatVersion {
            openingMilestoneUsed = try container.decode(Bool.self, forKey: .openingMilestoneUsed)
            endgameMilestoneUsed = try container.decode(Bool.self, forKey: .endgameMilestoneUsed)
            automaticPending = try container.decode(Bool.self, forKey: .automaticPending)
            firstAutomaticAnswer = try container.decodeIfPresent(Bool.self, forKey: .firstAutomaticAnswer)
            guard (!endgameMilestoneUsed || openingMilestoneUsed),
                  (automaticPending || firstAutomaticAnswer == nil),
                  (!automaticPending || (result == nil && !doublePending && stake < Self.maximumStake
                      && position.automaticResult == nil && (openingMilestoneUsed || endgameMilestoneUsed))) else {
                throw DecodingError.dataCorruptedError(
                    forKey: .automaticPending, in: container, debugDescription: "Impossible automatic decision")
            }
        }
    }

    /// A total of whole or half points, from 0.
    private static func decodeTotal(
        _ key: CodingKeys, in container: KeyedDecodingContainer<CodingKeys>
    ) throws -> Points {
        let total = try container.decode(Double.self, forKey: key)
        // No higher than any total a match can reach.
        let ceiling = MatchScore.target + Points(maximumStake)
        guard let points = Points(exactly: total), points >= 0, points <= ceiling else {
            throw DecodingError.dataCorruptedError(forKey: key, in: container, debugDescription: "Total \(total)")
        }
        return points
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(Self.formatVersion, forKey: .version)
        try container.encode(openingMilestoneUsed, forKey: .openingMilestoneUsed)
        try container.encode(endgameMilestoneUsed, forKey: .endgameMilestoneUsed)
        try container.encode(automaticPending, forKey: .automaticPending)
        try container.encodeIfPresent(firstAutomaticAnswer, forKey: .firstAutomaticAnswer)
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
        try container.encode(Double(matchScore.white.halves) / 2, forKey: .whiteTotal)
        try container.encode(Double(matchScore.black.halves) / 2, forKey: .blackTotal)
        var capturesContainer = container.nestedContainer(keyedBy: CapturesKeys.self, forKey: .captures)
        try capturesContainer.encode(captures.white, forKey: .white)
        try capturesContainer.encode(captures.black, forKey: .black)
    }
}

nonisolated private extension Captures {
    /// Whether a colour could have captured these pieces from an opponent that has these left on the board:
    /// never a king, and no more pieces, or pawns, than the opponent started with.
    func isPossible(by color: PieceColor, leaving position: Position) -> Bool {
        let captured = self[color]
        let remaining = position.pieces.values.filter { $0.color == color.opponent }
        return !captured.contains(.king)
            && captured.count + remaining.count <= Self.piecesPerSide
            && captured.count(where: { $0 == .pawn }) + remaining.count(where: { $0.kind == .pawn }) <= Self.pawnsPerSide
    }

    /// The pieces, and the pawns among them, each colour starts a game with.
    static let piecesPerSide = 16
    static let pawnsPerSide = 8
}
