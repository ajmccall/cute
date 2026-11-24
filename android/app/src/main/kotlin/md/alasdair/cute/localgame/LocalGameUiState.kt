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
    val sideToMove: Side get() = game?.position?.sideToMove ?: Side.White

    /**
     * The side whose pieces are drawn at the bottom: the side to move, or, while a double
     * awaits an answer, the side that must answer it. The chess turn doesn't change.
     */
    val bottomSide: Side get() {
        val pending = game?.doublePending ?: false
        return if (pending) sideToMove.opponent else sideToMove
    }

    val inCheck: Boolean get() = game?.let { it.result == null && it.position.isInCheck() } ?: false

    /** Whether the side to move may offer a double now (GameRecord.canOfferDouble). */
    val canOfferDouble: Boolean get() = game?.canOfferDouble ?: false
}

enum class Failure { Read, Write }

/** An action waiting for the players at the board to confirm or cancel it. */
enum class Confirmation { Resign, Draw, Replace, OfferDouble }
