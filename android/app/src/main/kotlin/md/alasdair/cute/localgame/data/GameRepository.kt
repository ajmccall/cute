package md.alasdair.cute.localgame.data

import md.alasdair.cute.chess.GameResult
import md.alasdair.cute.chess.Position
import md.alasdair.cute.chess.Side

/**
 * White's and Black's points in the match, counted in half points so that a drawn game's split
 * stake of one point stays whole: [whiteHalves] 9 is 4½ points.
 */
data class MatchScore(val whiteHalves: Int = 0, val blackHalves: Int = 0) {
    fun halvesOf(side: Side): Int = if (side == Side.White) whiteHalves else blackHalves

    operator fun plus(other: MatchScore) =
        MatchScore(whiteHalves + other.whiteHalves, blackHalves + other.blackHalves)

    /** The side with the higher total, or null while the totals are equal. */
    val leader: Side? get() = when {
        whiteHalves > blackHalves -> Side.White
        blackHalves > whiteHalves -> Side.Black
        else -> null
    }

    /** Whether either total has reached the target, 15 points, which ends the match. */
    val reachedTarget: Boolean get() = maxOf(whiteHalves, blackHalves) >= TARGET_HALVES

    companion object {
        /** The target: a match ends once either total is 15 points or more. */
        const val TARGET = 15
        const val TARGET_HALVES = TARGET * 2
        val Zero = MatchScore()
    }
}

/**
 * The current game as last committed, with the match score: its position, its result once it
 * has ended, and its doubling cube. [stake] is the points the game is played for; it is null
 * only for a game that had already finished in a save from before the cube, which has no point
 * award. [nextDoubler] is the only side that may offer the next double, or null while either
 * may. While [doublePending], the side to move has offered a double and the other side must
 * answer it. [score] includes this game's award once it has ended.
 */
data class GameRecord(
    val position: Position,
    val result: GameResult?,
    val stake: Int? = 1,
    val nextDoubler: Side? = null,
    val doublePending: Boolean = false,
    val score: MatchScore = MatchScore.Zero
) {
    /** This game's award once it has ended: the stake to the winner, or half to each on a draw. */
    val award: MatchScore get() = award(result, stake)

    /** Whether this game has ended and taken either total to the target, ending the match. */
    val matchOver: Boolean get() = result != null && score.reachedTarget

    /** Whether this game has ended with the match still under way, so Next game can follow. */
    val finished: Boolean get() = result != null && !score.reachedTarget

    /** This game ended with [result]: no offer pending, and its award added to the score. */
    fun ended(result: GameResult): GameRecord =
        copy(result = result, doublePending = false, score = score + award(result, stake))

    /** The match's next game: the opening position at one point, keeping the score. */
    fun nextGame(): GameRecord = New.copy(score = score)

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
        /** The first game of a new match, at 0 to 0. */
        val New = GameRecord(Position.Opening, result = null)

        /** The highest stake: no double is offered at it. */
        const val MAX_STAKE = 64

        /** What a game ending in [result] at [stake] awards; nothing without either. */
        fun award(result: GameResult?, stake: Int?): MatchScore {
            if (result == null || stake == null) return MatchScore.Zero
            return when (result.winner) {
                null -> MatchScore(stake, stake)
                Side.White -> MatchScore(whiteHalves = stake * 2)
                Side.Black -> MatchScore(blackHalves = stake * 2)
            }
        }
    }
}

/** The single source of truth for the device's one current game. */
interface GameRepository {
    /** The saved game, or null when none has been saved. Throws when it can't be read. */
    suspend fun load(): GameRecord?

    /** Replaces the saved game with [record], whole or not at all. Throws when it can't. */
    suspend fun save(record: GameRecord)
}
