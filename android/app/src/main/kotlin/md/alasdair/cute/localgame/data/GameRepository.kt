package md.alasdair.cute.localgame.data

import md.alasdair.cute.chess.GameResult
import md.alasdair.cute.chess.Position
import md.alasdair.cute.chess.Side

/**
 * The current game as last committed: its position, its result once it has ended, and its
 * doubling cube. [stake] is the points the game is played for; it is null only for a game that
 * had already finished in a save from before the cube, which has no point award. [nextDoubler]
 * is the only side that may offer the next double, or null while either may. While
 * [doublePending], the side to move has offered a double and the other side must answer it.
 */
data class GameRecord(
    val position: Position,
    val result: GameResult?,
    val stake: Int? = 1,
    val nextDoubler: Side? = null,
    val doublePending: Boolean = false
) {
    /**
     * Whether the side to move may offer a double now: during play, with no offer pending,
     * below the maximum stake, when either side may offer or the right is theirs. This
     * includes the opening turn and turns in check.
     */
    val canOfferDouble: Boolean get() =
        result == null &&
            !doublePending &&
            stake != null &&
            stake < MAX_STAKE &&
            (nextDoubler == null || nextDoubler == position.sideToMove)

    /** The stake a double offers, and a take plays for: twice [stake]. */
    val doubledStake: Int? get() = stake?.times(2)

    companion object {
        val New = GameRecord(Position.Opening, result = null)

        /** The highest stake: no double is offered at it. */
        const val MAX_STAKE = 64
    }
}

/** The single source of truth for the device's one current game. */
interface GameRepository {
    /** The saved game, or null when none has been saved. Throws when it can't be read. */
    suspend fun load(): GameRecord?

    /** Replaces the saved game with [record], whole or not at all. Throws when it can't. */
    suspend fun save(record: GameRecord)
}
