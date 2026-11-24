import Foundation

/// The saved file's format, version 2:
/// `{"version": 2, "position": "<FEN>", "result": <result>, "stake": 1, "nextDoubler": "white" | "black" | null,
/// "doublePending": false}`, where `<result>` is `{"winner": "white", "reason": "checkmate"}`,
/// `{"draw": "stalemate"}` or `null`.
///
/// Version 1, from before the cube, had only `version`, `position` and `result`. It is still read,
/// as a game with no stake, nobody named to double next and no pending offer.
nonisolated extension SavedGame: Codable {
    private enum CodingKeys: String, CodingKey {
        case version, position, result, stake, nextDoubler, doublePending
    }

    private enum ResultKeys: String, CodingKey {
        case winner, reason, draw
    }

    static let formatVersion = 2
    private static let beforeTheCubeVersion = 1
    /// The stakes a game can be played for: one point, doubled up to six times.
    static let stakes: Set<Int> = [1, 2, 4, 8, 16, 32, maximumStake]

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let version = try container.decode(Int.self, forKey: .version)
        guard version == Self.formatVersion || version == Self.beforeTheCubeVersion else {
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

        guard version == Self.formatVersion else {
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
    }
}
