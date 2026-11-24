package md.alasdair.cute.chess

private val knightSteps = listOf(
    1 to 2,
    2 to 1,
    2 to -1,
    1 to -2,
    -1 to -2,
    -2 to -1,
    -2 to 1,
    -1 to 2
)
private val kingSteps = listOf(1 to 0, 1 to 1, 0 to 1, -1 to 1, -1 to 0, -1 to -1, 0 to -1, 1 to -1)
private val rookDirections = listOf(1 to 0, -1 to 0, 0 to 1, 0 to -1)
private val bishopDirections = listOf(1 to 1, 1 to -1, -1 to 1, -1 to -1)

private val promotionTypes =
    listOf(PieceType.Queen, PieceType.Rook, PieceType.Bishop, PieceType.Knight)

/** Every legal move for the side to move. A promoting pawn has one move per promotion piece. */
fun Position.legalMoves(): List<Move> = board.keys.flatMap(::legalMovesFrom)

/** The legal moves of the side to move's piece on [from]; none for any other square. */
fun Position.legalMovesFrom(from: Square): List<Move> {
    val piece = get(from)?.takeIf { it.side == sideToMove } ?: return emptyList()
    return candidateMoves(from, piece).filter { !play(it).isInCheck(sideToMove) }
}

/**
 * The position after [move], which must be one of [legalMoves]. Moves the rook when the king
 * castles, removes the pawn taken en passant, and updates the rights and counters.
 */
fun Position.play(move: Move): Position {
    val piece = requireNotNull(get(move.from)) { "No piece on ${move.from}" }
    val next = board.toMutableMap()
    next.remove(move.from)
    val captured = next.put(move.to, move.promotion?.let { Piece(piece.side, it) } ?: piece)
    val home = move.from.rank
    var enPassantCapture = false
    when (piece.type) {
        PieceType.King -> if (kotlin.math.abs(move.to.file - move.from.file) == 2) {
            val kingside = move.to.file == 6
            val rookFrom = Square(if (kingside) 7 else 0, home)
            val rookTo = Square(if (kingside) 5 else 3, home)
            next.remove(rookFrom)?.let { next[rookTo] = it }
        }
        PieceType.Pawn -> if (move.to == enPassant && captured == null) {
            next.remove(Square(move.to.file, move.from.rank))
            enPassantCapture = true
        }
        else -> Unit
    }
    val doubleStep = piece.type == PieceType.Pawn &&
        kotlin.math.abs(move.to.rank - move.from.rank) == 2
    return Position(
        board = next,
        sideToMove = sideToMove.opponent,
        castling = castling.after(move),
        enPassant = if (doubleStep) {
            Square(
                move.from.file,
                (move.from.rank + move.to.rank) / 2
            )
        } else {
            null
        },
        halfmoveClock = if (piece.type == PieceType.Pawn || captured != null || enPassantCapture) {
            0
        } else {
            halfmoveClock + 1
        },
        fullmoveNumber = if (sideToMove == Side.Black) fullmoveNumber + 1 else fullmoveNumber
    )
}

/**
 * The ending this position reaches by itself, if any: checkmate wins for the side that just
 * moved, stalemate draws, and so do the insufficient-material cases the schema lists: kings
 * alone, one bishop or knight besides them, or only bishops, all on squares of one colour.
 */
fun Position.automaticResult(): GameResult? {
    if (legalMoves().isEmpty()) {
        return if (isInCheck()) {
            GameResult(sideToMove.opponent, EndReason.Checkmate)
        } else {
            GameResult(null, EndReason.Stalemate)
        }
    }
    val others = board.entries.filter { it.value.type != PieceType.King }
    val insufficient = when {
        others.size <= 1 -> others.all {
            it.value.type in setOf(PieceType.Bishop, PieceType.Knight)
        }
        else -> others.all { it.value.type == PieceType.Bishop } &&
            others.map { it.key.isLight }.distinct().size == 1
    }
    return if (insufficient) GameResult(null, EndReason.InsufficientMaterial) else null
}

/** A king or rook leaving its starting square, or a rook taken on it, ends that castling right. */
private fun CastlingRights.after(move: Move): CastlingRights {
    val touched = setOf(move.from, move.to)
    fun keeps(vararg squares: String) = squares.none { Square.of(it) in touched }
    return CastlingRights(
        whiteKingside = whiteKingside && keeps("e1", "h1"),
        whiteQueenside = whiteQueenside && keeps("e1", "a1"),
        blackKingside = blackKingside && keeps("e8", "h8"),
        blackQueenside = blackQueenside && keeps("e8", "a8")
    )
}

private fun Position.candidateMoves(from: Square, piece: Piece): List<Move> = when (piece.type) {
    PieceType.Pawn -> pawnMoves(from, piece.side)
    PieceType.Knight -> steps(from, piece.side, knightSteps)
    PieceType.King -> steps(from, piece.side, kingSteps) + castlingMoves(from, piece.side)
    PieceType.Rook -> slides(from, piece.side, rookDirections)
    PieceType.Bishop -> slides(from, piece.side, bishopDirections)
    PieceType.Queen -> slides(from, piece.side, rookDirections + bishopDirections)
}

private fun Position.steps(from: Square, side: Side, offsets: List<Pair<Int, Int>>) =
    offsets.mapNotNull { (f, r) -> from.offset(f, r) }
        .filter { get(it)?.side != side }
        .map { Move(from, it) }

private fun Position.slides(from: Square, side: Side, directions: List<Pair<Int, Int>>) =
    directions.flatMap { (f, r) ->
        buildList {
            var next = from.offset(f, r)
            while (next != null) {
                val occupant = get(next)
                if (occupant?.side == side) break
                add(Move(from, next))
                if (occupant != null) break
                next = next.offset(f, r)
            }
        }
    }

private fun Position.pawnMoves(from: Square, side: Side): List<Move> {
    val forward = if (side == Side.White) 1 else -1
    val startRank = if (side == Side.White) 1 else 6
    val targets = buildList {
        val one = from.offset(0, forward)
        if (one != null && get(one) == null) {
            add(one)
            val two = from.offset(0, 2 * forward)
            if (from.rank == startRank && two != null && get(two) == null) add(two)
        }
        for (files in listOf(-1, 1)) {
            val diagonal = from.offset(files, forward) ?: continue
            val occupant = get(diagonal)
            if ((occupant != null && occupant.side != side) || diagonal == enPassant) add(diagonal)
        }
    }
    return targets.flatMap { to ->
        if (to.rank == 0 || to.rank == 7) {
            promotionTypes.map { Move(from, to, it) }
        } else {
            listOf(Move(from, to))
        }
    }
}

private fun Position.castlingMoves(from: Square, side: Side): List<Move> {
    val home = if (side == Side.White) 0 else 7
    if (from != Square(4, home) || isInCheck(side)) return emptyList()
    val enemy = side.opponent
    return buildList {
        if (castling.kingside(side) &&
            get(Square(7, home)) == Piece(side, PieceType.Rook) &&
            listOf(5, 6).all {
                get(Square(it, home)) == null && !isAttacked(Square(it, home), enemy)
            }
        ) {
            add(Move(from, Square(6, home)))
        }
        if (castling.queenside(side) &&
            get(Square(0, home)) == Piece(side, PieceType.Rook) &&
            listOf(1, 2, 3).all { get(Square(it, home)) == null } &&
            listOf(2, 3).none { isAttacked(Square(it, home), enemy) }
        ) {
            add(Move(from, Square(2, home)))
        }
    }
}

/** Whether [side]'s king is attacked. */
fun Position.isInCheck(side: Side = sideToMove): Boolean {
    val king = board.entries.firstOrNull { it.value == Piece(side, PieceType.King) }?.key
        ?: return false
    return isAttacked(king, by = side.opponent)
}

internal fun Position.isAttacked(square: Square, by: Side): Boolean {
    val pawnRank = if (by == Side.White) -1 else 1
    for (files in listOf(-1, 1)) {
        if (square.offset(files, pawnRank)?.let(::get) == Piece(by, PieceType.Pawn)) return true
    }
    if (knightSteps.any { (f, r) ->
            square.offset(f, r)?.let(::get) == Piece(by, PieceType.Knight)
        }
    ) {
        return true
    }
    if (kingSteps.any { (f, r) -> square.offset(f, r)?.let(::get) == Piece(by, PieceType.King) }) {
        return true
    }
    val straight = setOf(PieceType.Rook, PieceType.Queen)
    val diagonal = setOf(PieceType.Bishop, PieceType.Queen)
    return rookDirections.any {
        firstPieceFrom(square, it)?.let { p ->
            p.side == by &&
                p.type in straight
        } ==
            true
    } ||
        bishopDirections.any {
            firstPieceFrom(square, it)?.let { p ->
                p.side == by &&
                    p.type in diagonal
            } ==
                true
        }
}

private fun Position.firstPieceFrom(square: Square, direction: Pair<Int, Int>): Piece? {
    var next = square.offset(direction.first, direction.second)
    while (next != null) {
        get(next)?.let { return it }
        next = next.offset(direction.first, direction.second)
    }
    return null
}
