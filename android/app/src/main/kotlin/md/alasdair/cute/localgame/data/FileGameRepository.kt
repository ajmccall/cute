package md.alasdair.cute.localgame.data

import java.io.File
import java.io.FileOutputStream
import java.nio.file.Files
import java.nio.file.StandardCopyOption
import javax.inject.Inject
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.withContext
import md.alasdair.cute.chess.EndReason
import md.alasdair.cute.chess.GameResult
import md.alasdair.cute.chess.Position
import md.alasdair.cute.chess.Side
import md.alasdair.cute.chess.automaticResult
import md.alasdair.cute.chess.positionFromFen
import md.alasdair.cute.chess.toFen

/**
 * Keeps the current game in one small text file. A save writes a sibling file, flushes it to
 * the disk and renames it over the old one, so the file always holds either the previous game
 * or the new one, never part of either.
 */
class FileGameRepository @Inject constructor(
    @GameFile private val file: File,
    @IoDispatcher private val ioDispatcher: CoroutineDispatcher
) : GameRepository {

    override suspend fun load(): GameRecord? = withContext(ioDispatcher) {
        // Only a file known to be absent means no game: one that can't be checked is a failure.
        if (Files.notExists(file.toPath())) null else decode(file.readText())
    }

    override suspend fun save(record: GameRecord) = withContext(ioDispatcher) {
        val temporary = File(file.parentFile, "${file.name}.saving")
        FileOutputStream(temporary).use { stream ->
            stream.write(encode(record).toByteArray())
            stream.fd.sync()
        }
        Files.move(
            temporary.toPath(),
            file.toPath(),
            StandardCopyOption.ATOMIC_MOVE,
            StandardCopyOption.REPLACE_EXISTING
        )
        Unit
    }

    companion object {
        const val FILE_NAME = "current-game.txt"

        /** Saves from before the doubling cube: position and result only. Read, never written. */
        private const val HEADER_V1 = "cute-game 1"

        /** Saves from before matches: the game and its cube. Read, never written. */
        private const val HEADER_V2 = "cute-game 2"
        private const val HEADER_V3 = "cute-game 3"
        private const val PLAYING = "playing"
        private const val NO_STAKE = "none"
        private const val EITHER = "Either"
        private const val PENDING = "pending"
        private const val ANSWERED = "answered"

        /**
         * Version 3: the header, then one line each for the position as FEN, the result or
         * `playing`, the stake or `none`, the next doubler or `Either`, whether a double is
         * `pending` or `answered`, and White's and Black's match totals in half points. The
         * game and the score are one record, so a game's result and its award are saved
         * together.
         */
        fun encode(record: GameRecord): String {
            val result = record.result?.let { "${it.winner?.name ?: "Draw"} ${it.reason.name}" }
            return listOf(
                HEADER_V3,
                record.position.toFen(),
                result ?: PLAYING,
                record.stake?.toString() ?: NO_STAKE,
                record.nextDoubler?.name ?: EITHER,
                if (record.doublePending) PENDING else ANSWERED,
                record.score.whiteHalves.toString(),
                record.score.blackHalves.toString(),
                ""
            ).joinToString("\n")
        }

        /** Throws [IllegalArgumentException] for text that isn't a whole saved game. */
        fun decode(text: String): GameRecord {
            val lines = text.split('\n')
            require(lines.isNotEmpty() && lines.last().isEmpty()) { "Not a saved game" }
            return when (lines[0]) {
                HEADER_V1 -> decodeV1(lines)
                HEADER_V2 -> decodeV2(lines)
                HEADER_V3 -> decodeV3(lines)
                else -> throw IllegalArgumentException("Not a saved game")
            }
        }

        /**
         * A save from before the cube, opened as the first game of a match at 0 to 0. A game
         * still in play takes up the cube at one point, with either side free to offer; a
         * finished one keeps its result and has no stake, so no award.
         */
        private fun decodeV1(lines: List<String>): GameRecord {
            require(lines.size == 4) { "Not a saved game" }
            val (position, result) = decodeGame(lines[1], lines[2])
            require(result?.reason != EndReason.DoubleDeclined) { "No double before the cube" }
            return GameRecord(position, result, stake = if (result == null) 1 else null)
        }

        /**
         * A save from before matches, opened as the first game of a match: an ongoing game at
         * 0 to 0, and a finished one with its award as the score.
         */
        private fun decodeV2(lines: List<String>): GameRecord {
            require(lines.size == 7) { "Not a saved game" }
            val game = decodeCube(lines)
            return game.copy(score = game.award)
        }

        /**
         * A save of a match. Each total is whole or half points from 0. The match is under way
         * before this game's award, so a game in play has both totals below the target, and a
         * finished one has each total, less its award, below the target.
         */
        private fun decodeV3(lines: List<String>): GameRecord {
            require(lines.size == 9) { "Not a saved game" }
            val game = decodeCube(lines)
            val score = MatchScore(decodeHalves(lines[6]), decodeHalves(lines[7]))
            val award = game.award
            require(
                score.whiteHalves >= award.whiteHalves &&
                    score.blackHalves >= award.blackHalves &&
                    !MatchScore(
                        score.whiteHalves - award.whiteHalves,
                        score.blackHalves - award.blackHalves
                    ).reachedTarget
            ) { "Bad score: ${lines[6]} to ${lines[7]}" }
            return game.copy(score = score)
        }

        /** A total in half points, written plainly: digits only, without leading zeros. */
        private fun decodeHalves(text: String): Int =
            requireNotNull(text.toIntOrNull()?.takeIf { it >= 0 && it.toString() == text }) {
                "Bad total: $text"
            }

        /**
         * The game and its cube, lines 1 to 5. The stake is one of 1 to 64 points, doubling
         * each time, or none only for a finished game from before the cube; a side holds the
         * right to offer exactly when a double has been taken; and a double can only be
         * pending in play, offered by a side to move that may offer it.
         */
        private fun decodeCube(lines: List<String>): GameRecord {
            val (position, result) = decodeGame(lines[1], lines[2])
            val stake = if (lines[3] == NO_STAKE && result != null) {
                null
            } else {
                requireNotNull(lines[3].toIntOrNull()?.takeIf { it in STAKES }) {
                    "Bad stake: ${lines[3]}"
                }
            }
            val nextDoubler = if (lines[4] == EITHER) null else Side.valueOf(lines[4])
            require((stake ?: 1) > 1 == (nextDoubler != null)) {
                "Bad right to offer: ${lines[4]}"
            }
            val pending = when (lines[5]) {
                PENDING -> true
                ANSWERED -> false
                else -> throw IllegalArgumentException("Bad offer: ${lines[5]}")
            }
            val record = GameRecord(position, result, stake, nextDoubler, pending)
            require(!pending || record.copy(doublePending = false).canOfferDouble) {
                "A pending double the side to move couldn't offer"
            }
            return record
        }

        /** 1, 2, 4, … 64. */
        private val STAKES = generateSequence(1) { it * 2 }
            .takeWhile { it <= GameRecord.MAX_STAKE }.toSet()

        private fun decodeGame(fen: String, resultText: String): Pair<Position, GameResult?> {
            val position = positionFromFen(fen)
            val result = if (resultText == PLAYING) null else decodeResult(resultText)
            require(result != null || position.automaticResult() == null) {
                "A game in play can't already have ended"
            }
            return position to result
        }

        private fun decodeResult(text: String): GameResult {
            val parts = text.split(' ')
            require(parts.size == 2) { "Bad result: $text" }
            val winner = if (parts[0] == "Draw") null else Side.valueOf(parts[0])
            val reason = EndReason.valueOf(parts[1])
            require(reason.decisive == (winner != null)) { "Bad result: $text" }
            return GameResult(winner, reason)
        }
    }
}
