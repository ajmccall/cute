import Foundation

/// The saved file's format, version 1:
/// `{"version": 1, "position": "<FEN>", "result": {"winner": "white", "reason": "checkmate"} | {"draw": "stalemate"} | null}`.
nonisolated extension SavedGame: Codable {
    private enum CodingKeys: String, CodingKey {
        case version, position, result
    }

    private enum ResultKeys: String, CodingKey {
        case winner, reason, draw
    }

    static let formatVersion = 1

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let version = try container.decode(Int.self, forKey: .version)
        guard version == Self.formatVersion else {
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
    }
}
