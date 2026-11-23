package md.alasdair.cute.chess

/**
 * Reads a position in Forsyth–Edwards Notation. Throws [IllegalArgumentException] for text that
 * isn't a complete, playable position: one king per side, no pawn on a back rank, castling
 * rights that match the kings and rooks, an en passant square that a double step just passed,
 * and the side that just moved not left in check.
 */
fun positionFromFen(fen: String): Position {
    val fields = fen.trim().split(' ')
    require(fields.size == 6) { "Expected 6 FEN fields, got ${fields.size}" }
    val board = parseBoard(fields[0])
    val side = when (fields[1]) {
        "w" -> Side.White
        "b" -> Side.Black
        else -> throw IllegalArgumentException("Bad side to move: ${fields[1]}")
    }
    val castling = parseCastling(fields[2])
    val enPassant = if (fields[3] == "-") null else Square.of(fields[3])
    val halfmove = requireNotNull(fields[4].toIntOrNull()?.takeIf { it >= 0 }) {
        "Bad halfmove clock: ${fields[4]}"
    }
    val fullmove = requireNotNull(fields[5].toIntOrNull()?.takeIf { it >= 1 }) {
        "Bad fullmove number: ${fields[5]}"
    }
    val position = Position(board, side, castling, enPassant, halfmove, fullmove)
    validate(position)
    return position
}

fun Position.toFen(): String {
    val ranks = (7 downTo 0).joinToString("/") { rank ->
        buildString {
            var empty = 0
            for (file in 0..7) {
                val piece = board[Square(file, rank)]
                if (piece == null) {
                    empty++
                } else {
                    if (empty > 0) append(empty).also { empty = 0 }
                    append(piece.letter)
                }
            }
            if (empty > 0) append(empty)
        }
    }
    val castlingText = buildString {
        if (castling.whiteKingside) append('K')
        if (castling.whiteQueenside) append('Q')
        if (castling.blackKingside) append('k')
        if (castling.blackQueenside) append('q')
    }.ifEmpty { "-" }
    val side = if (sideToMove == Side.White) "w" else "b"
    return "$ranks $side $castlingText ${enPassant?.name ?: "-"} $halfmoveClock $fullmoveNumber"
}

private val Piece.letter: Char
    get() {
        val letter = when (type) {
            PieceType.King -> 'k'
            PieceType.Queen -> 'q'
            PieceType.Rook -> 'r'
            PieceType.Bishop -> 'b'
            PieceType.Knight -> 'n'
            PieceType.Pawn -> 'p'
        }
        return if (side == Side.White) letter.uppercaseChar() else letter
    }

private fun parseBoard(text: String): Map<Square, Piece> {
    val rows = text.split('/')
    require(rows.size == 8) { "Expected 8 ranks, got ${rows.size}" }
    val board = mutableMapOf<Square, Piece>()
    rows.forEachIndexed { index, row ->
        val rank = 7 - index
        var file = 0
        for (char in row) {
            if (char in '1'..'8') {
                file += char - '0'
            } else {
                require(file <= 7) { "Rank ${rank + 1} is too long" }
                board[Square(file, rank)] = pieceFor(char)
                file++
            }
            require(file <= 8) { "Rank ${rank + 1} is too long" }
        }
        require(file == 8) { "Rank ${rank + 1} has $file squares" }
    }
    return board
}

private fun pieceFor(char: Char): Piece {
    val side = if (char.isUpperCase()) Side.White else Side.Black
    val type = when (char.lowercaseChar()) {
        'k' -> PieceType.King
        'q' -> PieceType.Queen
        'r' -> PieceType.Rook
        'b' -> PieceType.Bishop
        'n' -> PieceType.Knight
        'p' -> PieceType.Pawn
        else -> throw IllegalArgumentException("Not a piece: $char")
    }
    return Piece(side, type)
}

private fun parseCastling(text: String): CastlingRights {
    if (text == "-") return CastlingRights()
    require(text.isNotEmpty() && text.all { it in "KQkq" } && text.toSet().size == text.length) {
        "Bad castling rights: $text"
    }
    return CastlingRights(
        whiteKingside = 'K' in text,
        whiteQueenside = 'Q' in text,
        blackKingside = 'k' in text,
        blackQueenside = 'q' in text
    )
}

private fun validate(position: Position) {
    for (side in Side.entries) {
        val kings = position.board.values.count { it == Piece(side, PieceType.King) }
        require(kings == 1) { "$side has $kings kings" }
    }
    require(
        position.board.none { (square, piece) ->
            piece.type == PieceType.Pawn && (square.rank == 0 || square.rank == 7)
        }
    ) { "A pawn stands on a back rank" }
    for (side in Side.entries) {
        val home = if (side == Side.White) 0 else 7
        val kingHome = position[Square(4, home)] == Piece(side, PieceType.King)
        if (position.castling.kingside(side)) {
            require(kingHome && position[Square(7, home)] == Piece(side, PieceType.Rook)) {
                "$side can't castle kingside from this position"
            }
        }
        if (position.castling.queenside(side)) {
            require(kingHome && position[Square(0, home)] == Piece(side, PieceType.Rook)) {
                "$side can't castle queenside from this position"
            }
        }
    }
    position.enPassant?.let { target ->
        val mover = position.sideToMove
        val expectedRank = if (mover == Side.White) 5 else 2
        val pawnRank = if (mover == Side.White) 4 else 3
        require(
            target.rank == expectedRank &&
                position[target] == null &&
                position[Square(target.file, pawnRank)] == Piece(mover.opponent, PieceType.Pawn)
        ) { "No double step passed $target" }
    }
    require(!position.isInCheck(position.sideToMove.opponent)) {
        "The side that just moved is in check"
    }
}
