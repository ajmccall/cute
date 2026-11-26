package md.alasdair.cute.chess

enum class Side {
    White,
    Black
    ;

    val opponent: Side get() = if (this == White) Black else White
}

enum class PieceType { King, Queen, Rook, Bishop, Knight, Pawn }

data class Piece(val side: Side, val type: PieceType)

/**
 * A board square by its coordinate, `a1` to `h8`, which never depends on how the board is drawn.
 * [file] 0 is the a-file and [rank] 0 is the first rank.
 */
data class Square(val file: Int, val rank: Int) {
    init {
        require(file in 0..7 && rank in 0..7) { "No square at file $file, rank $rank" }
    }

    val name: String get() = "${'a' + file}${rank + 1}"

    /** True for the light squares, such as h1 and a8. */
    val isLight: Boolean get() = (file + rank) % 2 == 1

    fun offset(files: Int, ranks: Int): Square? {
        val f = file + files
        val r = rank + ranks
        return if (f in 0..7 && r in 0..7) Square(f, r) else null
    }

    override fun toString() = name

    companion object {
        val all: List<Square> = (0..7).flatMap { rank -> (0..7).map { file -> Square(file, rank) } }

        fun of(name: String): Square {
            require(name.length == 2 && name[0] in 'a'..'h' && name[1] in '1'..'8') {
                "Not a square: $name"
            }
            return Square(name[0] - 'a', name[1] - '1')
        }
    }
}

data class CastlingRights(
    val whiteKingside: Boolean = false,
    val whiteQueenside: Boolean = false,
    val blackKingside: Boolean = false,
    val blackQueenside: Boolean = false
) {
    fun kingside(side: Side) = if (side == Side.White) whiteKingside else blackKingside

    fun queenside(side: Side) = if (side == Side.White) whiteQueenside else blackQueenside

    companion object {
        val All = CastlingRights(true, true, true, true)
    }
}

/** A move from one square to another, naming the piece a pawn becomes when it promotes. */
data class Move(val from: Square, val to: Square, val promotion: PieceType? = null)

/**
 * Everything that decides what can happen next: pieces on squares, the side to move, castling
 * rights and the square a pawn may capture en passant. The move counters only complete the
 * recorded position.
 */
data class Position(
    val board: Map<Square, Piece>,
    val sideToMove: Side,
    val castling: CastlingRights,
    val enPassant: Square?,
    val halfmoveClock: Int = 0,
    val fullmoveNumber: Int = 1
) {
    operator fun get(square: Square): Piece? = board[square]

    companion object {
        const val OPENING_FEN = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"

        val Opening: Position = positionFromFen(OPENING_FEN)
    }
}

/** Why a game ended. A [decisive] reason has a winner; the others are draws. */
enum class EndReason(val decisive: Boolean) {
    Checkmate(decisive = true),
    Resignation(decisive = true),
    DoubleDeclined(decisive = true),
    Stalemate(decisive = false),
    InsufficientMaterial(decisive = false),
    Agreement(decisive = false)
}

/** How a game ended: the [winner], or none for a draw, and why. */
data class GameResult(val winner: Side?, val reason: EndReason)
