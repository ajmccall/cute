package md.alasdair.cute.localgame.data

import md.alasdair.cute.chess.EndReason
import md.alasdair.cute.chess.GameResult
import md.alasdair.cute.chess.Move
import md.alasdair.cute.chess.PieceType
import md.alasdair.cute.chess.Position
import md.alasdair.cute.chess.Side
import md.alasdair.cute.chess.automaticResult
import md.alasdair.cute.chess.captured
import md.alasdair.cute.chess.material
import md.alasdair.cute.chess.play

/**
 * White's and Black's points in the match, counted in half points so that a drawn game's split
 * stake of one point stays whole: [whiteHalves] 9 is 4½ points.
 */
data class MatchScore(val whiteHalves: Int = 0, val blackHalves: Int = 0) {
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
 * The opponent's pieces each side has captured in this game, in the order taken: [white] holds
 * the kinds of Black's pieces that White has taken, and [black] those of White's that Black has.
 */
data class Captures(
    val white: List<PieceType> = emptyList(),
    val black: List<PieceType> = emptyList()
) {
    fun of(side: Side): List<PieceType> = if (side == Side.White) white else black

    /** These captures with [type] added to [side]'s. */
    fun withCapture(side: Side, type: PieceType): Captures =
        if (side == Side.White) copy(white = white + type) else copy(black = black + type)

    companion object {
        val None = Captures()
    }
}

/** The side with more material on the board, and by how much. */
data class MaterialAdvantage(val side: Side, val amount: Int)

/**
 * The current game as last committed, with the match score: its position, its result once it
 * has ended, and its doubling cube. [stake] is the points the game is played for; it is null
 * only for a game that had already finished in a save from before the cube, which has no point
 * award. [nextDoubler] is the only side that may offer the next double, or null while either
 * may. While [doublePending], the side to move has offered a double and the other side must
 * answer it. [captures] are the pieces each side has taken in this game. [matchScore] includes
 * this game's award once it has ended.
 */
data class AutomaticDecision(val firstAnswer: Boolean? = null)

data class GameRecord(
    val position: Position,
    val result: GameResult?,
    val stake: Int? = 1,
    val nextDoubler: Side? = null,
    val doublePending: Boolean = false,
    val captures: Captures = Captures.None,
    val matchScore: MatchScore = MatchScore.Zero,
    val openingAvailable: Boolean = true,
    val endgameAvailable: Boolean = true,
    val automaticPending: AutomaticDecision? = null
) {
    /** This game's award once it has ended: the stake to the winner, or half to each on a draw. */
    val award: MatchScore get() = award(result, stake)

    /**
     * The side ahead in material on the board, counted from the pieces on it rather than from
     * the captures, so that a promotion counts; null while material is equal.
     */
    val materialAdvantage: MaterialAdvantage? get() {
        val difference = position.material(Side.White) - position.material(Side.Black)
        return when {
            difference > 0 -> MaterialAdvantage(Side.White, difference)
            difference < 0 -> MaterialAdvantage(Side.Black, -difference)
            else -> null
        }
    }

    /**
     * This game after the side to move plays [move], which must be legal: the new position,
     * any captured piece added to the mover's captures, and any automatic ending with its award.
     */
    fun played(move: Move, automaticDoubles: Boolean = false): GameRecord {
        val taken = position.captured(move)
        val next = copy(
            position = position.play(move),
            captures = taken?.let { captures.withCapture(position.sideToMove, it.type) } ?: captures
        )
        next.position.automaticResult()?.let { return next.ended(it) }
        if (!automaticDoubles) return next
        val endgame = next.endgameAvailable &&
            next.position.board.values.count {
                it.type != PieceType.King && it.type != PieceType.Pawn
            } <= 4
        val starting = mapOf(
            "b1" to md.alasdair.cute.chess.Piece(Side.White, PieceType.Knight),
            "g1" to md.alasdair.cute.chess.Piece(Side.White, PieceType.Knight),
            "c1" to md.alasdair.cute.chess.Piece(Side.White, PieceType.Bishop),
            "f1" to md.alasdair.cute.chess.Piece(Side.White, PieceType.Bishop),
            "b8" to md.alasdair.cute.chess.Piece(Side.Black, PieceType.Knight),
            "g8" to md.alasdair.cute.chess.Piece(Side.Black, PieceType.Knight),
            "c8" to md.alasdair.cute.chess.Piece(Side.Black, PieceType.Bishop),
            "f8" to md.alasdair.cute.chess.Piece(Side.Black, PieceType.Bishop)
        )
        val opening = next.openingAvailable &&
            starting.count { (square, piece) ->
                next.position[md.alasdair.cute.chess.Square.of(square)] != piece
            } >= 6
        if (!endgame && !opening) return next
        return next.copy(
            openingAvailable = false,
            endgameAvailable = if (endgame) false else next.endgameAvailable,
            automaticPending = if (next.stake != null && next.stake < MAX_STAKE) {
                AutomaticDecision()
            } else {
                null
            }
        )
    }

    /** Whether this game has ended and taken either total to the target, ending the match. */
    val matchOver: Boolean get() = result != null && matchScore.reachedTarget

    /**
     * Whether Next game can follow: this game has ended with the match still under way. False
     * both during play and once the match is over.
     */
    val canStartNextGame: Boolean get() = result != null && !matchOver

    /** This game ended with [result]: no offer pending, and its award added to the match score. */
    fun ended(result: GameResult): GameRecord = copy(
        result = result,
        doublePending = false,
        matchScore = matchScore + award(result, stake)
    )

    /**
     * This game after the responder declines a double: won by the offerer, the side to move,
     * without a move, at the stake as it was.
     */
    fun doubleDeclined(): GameRecord =
        ended(GameResult(position.sideToMove, EndReason.DoubleDeclined))

    /** Whether declining a double would end the match, by taking the offerer to the target. */
    val declineEndsMatch: Boolean get() = doubleDeclined().matchOver

    /**
     * The match's next game: the opening position at one point, with no captures, keeping the
     * match score.
     */
    fun nextGame(): GameRecord = New.copy(matchScore = matchScore)

    /**
     * Whether the side to move may offer a double now: during play, with no offer pending,
     * below the maximum stake, when either side may offer or the right is theirs. This
     * includes the opening turn and turns in check.
     */
    val canOfferDouble: Boolean get() =
        result == null &&
            !doublePending &&
            automaticPending == null &&
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
    suspend fun loadAutomaticDoubles(): Boolean = false
    suspend fun saveAutomaticDoubles(enabled: Boolean) = Unit

    /** The saved game, or null when none has been saved. Throws when it can't be read. */
    suspend fun load(): GameRecord?

    /** Replaces the saved game with [record], whole or not at all. Throws when it can't. */
    suspend fun save(record: GameRecord)
}
