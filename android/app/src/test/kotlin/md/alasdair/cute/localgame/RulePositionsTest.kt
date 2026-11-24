package md.alasdair.cute.localgame

import kotlinx.coroutines.test.runTest
import md.alasdair.cute.chess.Move
import md.alasdair.cute.chess.PieceType
import md.alasdair.cute.chess.Side
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test

class RulePositionsTest {
    @get:Rule val main = MainDispatcherRule()

    private val device = LocalGameHarness()

    @Test
    fun `a pinned piece can only move along the pin`() = runTest {
        device.seed("4k3/4r3/8/8/1b6/8/3NR3/4K3 w - - 0 1")
        val game = device.launch()

        game.onSquareTapped(sq("d2"))
        assertEquals(emptySet<Any>(), game.state.destinations)

        game.onSquareTapped(sq("e2"))
        assertEquals(squares("e3", "e4", "e5", "e6", "e7"), game.state.destinations)
    }

    @Test
    fun `a move that gives check names it and leaves only moves out of check`() = runTest {
        device.seed("4k3/8/8/8/8/8/1p6/4K2R w K - 0 1")
        val game = device.launch()

        game.move("h1", "h8")

        assertTrue(game.state.inCheck)
        assertEquals(Side.Black, game.state.bottomSide)
        game.onSquareTapped(sq("b2"))
        assertEquals(emptySet<Any>(), game.state.destinations)
        game.onSquareTapped(sq("e8"))
        assertEquals(squares("d7", "e7", "f7"), game.state.destinations)
    }

    @Test
    fun `the king can't castle through an attacked square`() = runTest {
        device.seed("4kr2/8/8/8/8/8/8/R3K2R w KQ - 0 1")
        val game = device.launch()

        game.onSquareTapped(sq("e1"))

        assertEquals(squares("d1", "d2", "e2", "c1"), game.state.destinations)
    }

    @Test
    fun `the king can't castle out of check`() = runTest {
        device.seed("4k3/8/8/8/8/8/4r3/R3K2R w KQ - 0 1")
        val game = device.launch()

        game.onSquareTapped(sq("e1"))

        assertFalse(sq("g1") in game.state.destinations)
        assertFalse(sq("c1") in game.state.destinations)
    }

    @Test
    fun `castling moves king and rook and ends both of that side's rights`() = runTest {
        device.seed("r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1")
        val game = device.launch()

        game.move("e1", "g1")

        assertEquals("r3k2r/8/8/8/8/8/8/R4RK1 b kq - 1 1", game.state.fen)
        game.move("e8", "c8")
        assertEquals("2kr3r/8/8/8/8/8/8/R4RK1 w - - 2 2", game.state.fen)
    }

    @Test
    fun `castling rights restored after reopening still allow castling`() = runTest {
        device.seed("r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1")
        device.launch().move("h1", "h2")

        val reopened = device.launch()

        reopened.onSquareTapped(sq("e8"))
        assertTrue(sq("g8") in reopened.state.destinations)
        assertTrue(sq("c8") in reopened.state.destinations)
        reopened.move("h8", "h7")
        reopened.onSquareTapped(sq("e1"))
        assertEquals(squares("d1", "d2", "e2", "f1", "f2", "c1"), reopened.state.destinations)
    }

    @Test
    fun `en passant is offered just after the double step, survives reopening, then expires`() =
        runTest {
            device.seed("4k3/4p3/8/3P4/8/8/8/4K3 b - - 0 1")
            device.launch().move("e7", "e5")

            val reopened = device.launch()
            reopened.onSquareTapped(sq("d5"))
            assertEquals(squares("d6", "e6"), reopened.state.destinations)

            reopened.move("e1", "e2")
            reopened.move("e8", "e7")
            reopened.onSquareTapped(sq("d5"))
            assertEquals(squares("d6"), reopened.state.destinations)
        }

    @Test
    fun `a promotion waits for the choice of piece and cancelling changes nothing`() = runTest {
        device.seed(PROMOTION)
        val game = device.launch()

        game.move("b7", "b8")

        assertEquals(Move(sq("b7"), sq("b8")), game.state.promotion)
        assertEquals(PROMOTION, game.state.fen)

        game.onPromotionCancelled()

        assertNull(game.state.promotion)
        assertEquals(PROMOTION, game.state.fen)
        assertEquals(Side.White, game.state.bottomSide)
    }

    @Test
    fun `choosing a piece completes an underpromotion`() = runTest {
        device.seed(PROMOTION)
        val game = device.launch()

        game.move("b7", "b8")
        game.onPromotionChosen(PieceType.Knight)

        assertNull(game.state.promotion)
        assertEquals("1N2k3/8/8/8/8/8/8/4K3 b - - 0 1", game.state.fen)
    }

    @Test
    fun `an unfinished promotion never becomes a move on relaunch`() = runTest {
        device.seed(PROMOTION)
        device.launch().move("b7", "b8")

        val relaunched = device.launch()

        assertNull(relaunched.state.promotion)
        assertEquals(PROMOTION, relaunched.state.fen)
    }

    @Test
    fun `capturing en passant removes the passed pawn`() = runTest {
        device.seed("4k3/8/8/3Pp3/8/8/8/4K3 w - e6 0 2")
        val game = device.launch()

        game.move("d5", "e6")

        assertEquals("4k3/8/4P3/8/8/8/8/4K3 b - - 0 2", game.state.fen)
    }

    companion object {
        const val PROMOTION = "4k3/1P6/8/8/8/8/8/4K3 w - - 0 1"
    }
}
