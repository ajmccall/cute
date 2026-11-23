package md.alasdair.cute.localgame

import kotlinx.coroutines.test.runTest
import md.alasdair.cute.chess.Side
import org.junit.After
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Rule
import org.junit.Test

class StorageFailureTest {
    @get:Rule val main = MainDispatcherRule()

    private val device = LocalGameHarness()

    @After
    fun restoreAccess() {
        device.folder.setWritable(true)
        device.gameFile.setReadable(true)
    }

    @Test
    fun `a saved game that can't be read is reported and no fresh game is shown`() = runTest {
        device.seed(SAVED)
        device.gameFile.setReadable(false)

        val game = device.launch()

        assertEquals(Failure.Read, game.state.failure)
        assertNull(game.state.game)
        assertFalse(game.state.loading)
    }

    @Test
    fun `retrying once the saved game can be read again shows it`() = runTest {
        device.seed(SAVED)
        device.gameFile.setReadable(false)
        val game = device.launch()

        device.gameFile.setReadable(true)
        game.onRetry()

        assertNull(game.state.failure)
        assertEquals(SAVED, game.state.fen)
    }

    @Test
    fun `damaged saved data is reported and left as it was`() = runTest {
        for (damaged in DAMAGED) {
            device.gameFile.writeText(damaged)

            val game = device.launch()

            assertEquals("for <$damaged>", Failure.Read, game.state.failure)
            assertNull("for <$damaged>", game.state.game)
            assertEquals(damaged, device.gameFile.readText())
        }
    }

    @Test
    fun `starting a new game in place of an unreadable one asks first`() = runTest {
        device.gameFile.writeText("damaged")
        val game = device.launch()

        game.onNewGameRequested()
        assertEquals(Confirmation.Replace, game.state.confirmation)
        game.onConfirmed()

        assertNull(game.state.failure)
        assertEquals(OPENING, game.state.fen)
        assertEquals(OPENING, device.launch().state.fen)
    }

    @Test
    fun `a move that can't be saved is reported and the saved position stays on the board`() =
        runTest {
            device.seed(SAVED)
            val saved = device.gameFile.readBytes()
            val game = device.launch()
            device.folder.setWritable(false)

            game.move("g1", "f3")

            assertEquals(Failure.Write, game.state.failure)
            assertEquals(SAVED, game.state.fen)
            assertNull(game.state.selection)
            assertEquals(emptySet<Any>(), game.state.destinations)
            assertEquals(Side.White, game.state.bottomSide)
            assertArrayEquals(saved, device.gameFile.readBytes())
            assertEquals(SAVED, device.launch().state.fen)
        }

    @Test
    fun `retrying a change once it can be saved commits it`() = runTest {
        device.seed(SAVED)
        val game = device.launch()
        device.folder.setWritable(false)
        game.move("g1", "f3")

        device.folder.setWritable(true)
        game.onRetry()

        assertNull(game.state.failure)
        assertEquals(AFTER_NF3, game.state.fen)
        assertEquals(AFTER_NF3, device.launch().state.fen)
    }

    @Test
    fun `a resignation that can't be saved leaves the game in play`() = runTest {
        device.seed(SAVED)
        val game = device.launch()
        device.folder.setWritable(false)

        game.onResignRequested()
        game.onConfirmed()

        assertEquals(Failure.Write, game.state.failure)
        assertNull(game.state.game?.result)
    }

    companion object {
        const val OPENING = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
        const val SAVED = "rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq e6 0 2"
        const val AFTER_NF3 = "rnbqkbnr/pppp1ppp/8/4p3/4P3/5N2/PPPP1PPP/RNBQKB1R b KQkq - 1 2"
        private const val GOOD_FEN = "4k3/8/8/8/8/8/8/4K3 w - - 0 1"

        /** Saved files that aren't a whole, playable game, each of which must be refused. */
        val DAMAGED = listOf(
            "",
            "cute-game 1\n",
            "cute-game 2\n$GOOD_FEN\nplaying\n",
            "cute-game 1\n$GOOD_FEN\nplaying",
            "cute-game 1\n$GOOD_FEN\nplaying\nextra\n",
            "cute-game 1\n4k3/8/8/8/8/8/8/4K3 w - -\nplaying\n",
            "cute-game 1\n4k3/8/8/8/8/8/8/4KK2 w - - 0 1\nplaying\n",
            "cute-game 1\n4k3/8/8/8/8/8/8/8 w - - 0 1\nplaying\n",
            "cute-game 1\n4k3/8/8/8/8/8/8/4K2P w - - 0 1\nplaying\n",
            "cute-game 1\n4k3/8/8/8/8/8/8/4K3/8 w - - 0 1\nplaying\n",
            "cute-game 1\n4k3/9/8/8/8/8/8/4K3 w - - 0 1\nplaying\n",
            "cute-game 1\n4k3/8/8/8/8/8/8/4K3x w - - 0 1\nplaying\n",
            "cute-game 1\n4k3/8/8/8/8/8/8/4K3 x - - 0 1\nplaying\n",
            "cute-game 1\n4k3/8/8/8/8/8/8/4K3 w K - 0 1\nplaying\n",
            "cute-game 1\n4k3/8/8/8/8/8/8/4K3 w KK - 0 1\nplaying\n",
            "cute-game 1\n4k3/8/8/8/8/8/8/4K3 w - e3 0 1\nplaying\n",
            "cute-game 1\n4k3/8/8/8/8/8/8/4K3 w - z9 0 1\nplaying\n",
            "cute-game 1\n4k3/8/8/8/8/8/8/4K3 w - - -1 1\nplaying\n",
            "cute-game 1\n4k3/8/8/8/8/8/8/4K3 w - - 0 0\nplaying\n",
            "cute-game 1\n4k3/8/8/8/8/8/8/4K2r b - - 0 1\nplaying\n",
            "cute-game 1\n4k2R/8/8/8/8/8/8/4K3 w - - 0 1\nplaying\n",
            "cute-game 1\n$GOOD_FEN\nWhite\n",
            "cute-game 1\n$GOOD_FEN\nWhite Agreement\n",
            "cute-game 1\n$GOOD_FEN\nDraw Checkmate\n",
            "cute-game 1\n$GOOD_FEN\nGreen Checkmate\n",
            "cute-game 1\n$GOOD_FEN\nWhite Timeout\n",
            "\u0000\u0001binary"
        )
    }
}
