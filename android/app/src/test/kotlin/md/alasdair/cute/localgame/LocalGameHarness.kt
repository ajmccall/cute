package md.alasdair.cute.localgame

import java.io.File
import java.nio.file.Files
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.UnconfinedTestDispatcher
import md.alasdair.cute.chess.Square
import md.alasdair.cute.chess.positionFromFen
import md.alasdair.cute.chess.toFen
import md.alasdair.cute.localgame.data.FileGameRepository
import md.alasdair.cute.localgame.data.GameRecord

/**
 * One isolated device for local-game tests: its own folder holding the current game, opened
 * through the real file repository. [launch] starts the app's game on it, as a cold start does.
 */
@OptIn(ExperimentalCoroutinesApi::class)
class LocalGameHarness(
    val folder: File = Files.createTempDirectory("local-game").toFile(),
    private val dispatcher: CoroutineDispatcher = UnconfinedTestDispatcher()
) {
    val gameFile: File get() = File(folder, FileGameRepository.FILE_NAME)

    fun repository() = FileGameRepository(gameFile, dispatcher)

    /** Saves [fen] as the current game, as an earlier session that reached it would have. */
    suspend fun seed(fen: String) {
        repository().save(GameRecord(positionFromFen(fen), result = null))
    }

    fun launch() = LocalGameViewModel(repository())
}

val LocalGameViewModel.state: LocalGameUiState get() = uiState.value

val LocalGameUiState.fen: String? get() = game?.position?.toFen()

fun sq(name: String) = Square.of(name)

fun squares(vararg names: String) = names.map(Square::of).toSet()

/** Taps the piece on [from], then the square [to], as a player does. */
fun LocalGameViewModel.move(from: String, to: String) {
    onSquareTapped(sq(from))
    onSquareTapped(sq(to))
}
