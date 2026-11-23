package md.alasdair.cute.localgame

import md.alasdair.cute.chess.Move
import md.alasdair.cute.chess.Side
import md.alasdair.cute.chess.Square
import md.alasdair.cute.chess.isInCheck
import md.alasdair.cute.localgame.data.GameRecord

/**
 * What the board shows. [game] is always the last committed game, never a change that hasn't
 * been saved; it is null while loading and when the saved game couldn't be read.
 */
data class LocalGameUiState(
    val loading: Boolean = true,
    val game: GameRecord? = null,
    val selection: Square? = null,
    val destinations: Set<Square> = emptySet(),
    /** A pawn move waiting for its promotion piece; nothing is committed until one is chosen. */
    val promotion: Move? = null,
    val confirmation: Confirmation? = null,
    val failure: Failure? = null
) {
    /** The side whose pieces are drawn at the bottom: the side to move. */
    val bottomSide: Side get() = game?.position?.sideToMove ?: Side.White

    val inCheck: Boolean get() = game?.let { it.result == null && it.position.isInCheck() } ?: false
}

enum class Failure { Read, Write }

/** An action waiting for the players at the board to confirm or cancel it. */
enum class Confirmation { Resign, Draw, Replace }
