package md.alasdair.cute.localgame.data

import md.alasdair.cute.chess.GameResult
import md.alasdair.cute.chess.Position

/** The current game as last committed: its position and, once it has ended, its result. */
data class GameRecord(val position: Position, val result: GameResult?) {
    companion object {
        val New = GameRecord(Position.Opening, result = null)
    }
}

/** The single source of truth for the device's one current game. */
interface GameRepository {
    /** The saved game, or null when none has been saved. Throws when it can't be read. */
    suspend fun load(): GameRecord?

    /** Replaces the saved game with [record], whole or not at all. Throws when it can't. */
    suspend fun save(record: GameRecord)
}
