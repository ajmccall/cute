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
        private const val HEADER = "cute-game 1"
        private const val PLAYING = "playing"

        fun encode(record: GameRecord): String {
            val result = record.result?.let { "${it.winner?.name ?: "Draw"} ${it.reason.name}" }
            return "$HEADER\n${record.position.toFen()}\n${result ?: PLAYING}\n"
        }

        /** Throws [IllegalArgumentException] for text that isn't a whole saved game. */
        fun decode(text: String): GameRecord {
            val lines = text.split('\n')
            require(lines.size == 4 && lines[0] == HEADER && lines[3].isEmpty()) {
                "Not a saved game"
            }
            val position = positionFromFen(lines[1])
            val result = if (lines[2] == PLAYING) null else decodeResult(lines[2])
            require(result != null || position.automaticResult() == null) {
                "A game in play can't already have ended"
            }
            return GameRecord(position, result)
        }

        private fun decodeResult(text: String): GameResult {
            val parts = text.split(' ')
            require(parts.size == 2) { "Bad result: $text" }
            val winner = if (parts[0] == "Draw") null else Side.valueOf(parts[0])
            val reason = EndReason.valueOf(parts[1])
            val decisive = reason == EndReason.Checkmate || reason == EndReason.Resignation
            require(decisive == (winner != null)) { "Bad result: $text" }
            return GameResult(winner, reason)
        }
    }
}
