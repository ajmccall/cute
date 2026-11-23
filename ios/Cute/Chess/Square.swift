/// A board square by its coordinate, independent of how the board is drawn.
nonisolated struct Square: Hashable, Comparable, Sendable, CustomStringConvertible {
    /// 0 is file a, 7 is file h.
    let file: Int
    /// 0 is rank 1, 7 is rank 8.
    let rank: Int

    init?(file: Int, rank: Int) {
        guard (0..<8).contains(file), (0..<8).contains(rank) else { return nil }
        self.file = file
        self.rank = rank
    }

    /// A square from its coordinate, such as "e4".
    init?(_ coordinate: String) {
        let characters = Array(coordinate)
        guard characters.count == 2,
              let fileValue = characters[0].asciiValue, let rankValue = characters[1].asciiValue,
              let square = Square(file: Int(fileValue) - 97, rank: Int(rankValue) - 49)
        else { return nil }
        self = square
    }

    var coordinate: String {
        let fileLetter = Character(UnicodeScalar(UInt8(97 + file)))
        return "\(fileLetter)\(rank + 1)"
    }

    var description: String { coordinate }

    var isLight: Bool { (file + rank) % 2 == 1 }

    func offset(files: Int, ranks: Int) -> Square? {
        Square(file: file + files, rank: rank + ranks)
    }

    static let all: [Square] = (0..<8).flatMap { rank in (0..<8).map { Square(file: $0, rank: rank)! } }

    static func < (lhs: Square, rhs: Square) -> Bool {
        (lhs.rank, lhs.file) < (rhs.rank, rhs.file)
    }
}
