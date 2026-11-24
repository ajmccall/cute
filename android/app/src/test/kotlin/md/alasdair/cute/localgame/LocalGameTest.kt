package md.alasdair.cute.localgame

import kotlinx.coroutines.test.runTest
import md.alasdair.cute.chess.Side
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Rule
import org.junit.Test

class LocalGameTest {
    @get:Rule val main = MainDispatcherRule()

    private val device = LocalGameHarness()

    @Test
    fun `opening without a game shows the standard opening position with White to move`() =
        runTest {
            val game = device.launch()

            assertEquals(OPENING, game.state.fen)
            assertEquals(Side.White, game.state.bottomSide)
            assertNull(game.state.game?.result)
            assertFalse(game.state.inCheck)
        }

    @Test
    fun `selecting a piece shows only its legal destinations and another can be selected`() =
        runTest {
            val game = device.launch()

            game.onSquareTapped(sq("e2"))
            assertEquals(sq("e2"), game.state.selection)
            assertEquals(squares("e3", "e4"), game.state.destinations)

            game.onSquareTapped(sq("g1"))
            assertEquals(sq("g1"), game.state.selection)
            assertEquals(squares("f3", "h3"), game.state.destinations)
        }

    @Test
    fun `an opponent's piece or an empty square can't be selected`() = runTest {
        val game = device.launch()

        game.onSquareTapped(sq("e7"))
        game.onSquareTapped(sq("e4"))

        assertNull(game.state.selection)
        assertEquals(emptySet<Any>(), game.state.destinations)
    }

    @Test
    fun `an illegal destination clears the selection and leaves position and turn unchanged`() =
        runTest {
            val game = device.launch()

            game.move("g1", "g3")

            assertEquals(OPENING, game.state.fen)
            assertEquals(Side.White, game.state.bottomSide)
            assertNull(game.state.selection)
            assertEquals(emptySet<Any>(), game.state.destinations)
        }

    @Test
    fun `tapping an empty square that isn't a destination clears the selection`() = runTest {
        val game = device.launch()

        game.move("g1", "d4")

        assertEquals(OPENING, game.state.fen)
        assertNull(game.state.selection)
        assertEquals(emptySet<Any>(), game.state.destinations)
    }

    @Test
    fun `tapping an opponent's piece that can't be taken clears the selection`() = runTest {
        val game = device.launch()

        game.move("g1", "e7")

        assertEquals(OPENING, game.state.fen)
        assertNull(game.state.selection)
        assertEquals(emptySet<Any>(), game.state.destinations)
    }

    @Test
    fun `tapping the selected piece again keeps it selected`() = runTest {
        val game = device.launch()

        game.move("g1", "g1")

        assertEquals(sq("g1"), game.state.selection)
        assertEquals(squares("f3", "h3"), game.state.destinations)
    }

    @Test
    fun `a legal destination commits the move at once and hands the board to the other side`() =
        runTest {
            val game = device.launch()

            game.move("g1", "f3")

            assertEquals(AFTER_NF3, game.state.fen)
            assertEquals(Side.Black, game.state.bottomSide)
            assertNull(game.state.selection)
            assertEquals(emptySet<Any>(), game.state.destinations)

            game.move("e7", "e5")
            assertEquals(
                "rnbqkbnr/pppp1ppp/8/4p3/8/5N2/PPPPPPPP/RNBQKB1R w KQkq e6 0 2",
                game.state.fen
            )
            assertEquals(Side.White, game.state.bottomSide)
        }

    @Test
    fun `reopening shows the last committed position and turn with the same continuations`() =
        runTest {
            device.launch().move("g1", "f3")

            val reopened = device.launch()

            assertEquals(AFTER_NF3, reopened.state.fen)
            assertEquals(Side.Black, reopened.state.bottomSide)
            reopened.onSquareTapped(sq("b8"))
            assertEquals(squares("a6", "c6"), reopened.state.destinations)
        }

    companion object {
        const val AFTER_NF3 = "rnbqkbnr/pppppppp/8/8/8/5N2/PPPPPPPP/RNBQKB1R b KQkq - 1 1"
        const val OPENING = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
    }
}
