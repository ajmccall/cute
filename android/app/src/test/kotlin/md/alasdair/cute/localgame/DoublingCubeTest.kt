package md.alasdair.cute.localgame

import kotlinx.coroutines.test.runTest
import md.alasdair.cute.chess.EndReason
import md.alasdair.cute.chess.GameResult
import md.alasdair.cute.chess.Side
import md.alasdair.cute.chess.positionFromFen
import md.alasdair.cute.localgame.data.GameRecord
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test

class DoublingCubeTest {
    @get:Rule val main = MainDispatcherRule()

    private val device = LocalGameHarness()

    @Test
    fun `a fresh game is played for one point and either player can offer`() = runTest {
        val game = device.launch()

        assertEquals(1, game.state.game?.stake)
        assertNull(game.state.game?.nextDoubler)
        assertTrue(game.state.canOfferDouble)
    }

    @Test
    fun `tapping Offer double makes the offer at once, with nothing to confirm`() = runTest {
        val game = device.launch()
        game.onSquareTapped(sq("g1"))

        game.onOfferDoubleRequested()

        assertNull(game.state.confirmation)
        assertTrue(game.state.game!!.doublePending)
        assertNull(game.state.selection)
        assertEquals(OPENING, game.state.fen)
        assertEquals(1, game.state.game?.stake)
        assertTrue(device.launch().state.game!!.doublePending)
    }

    @Test
    fun `an offer is saved and the board faces the responder until it is answered`() =
        runTest {
            val game = device.launch()
            game.move("e2", "e4")
            game.onSquareTapped(sq("g8"))

            game.onOfferDoubleRequested()

            assertTrue(game.state.game!!.doublePending)
            assertEquals(AFTER_E4, game.state.fen)
            assertEquals(Side.Black, game.state.sideToMove)
            assertEquals(Side.White, game.state.bottomSide)
            assertEquals(1, game.state.game?.stake)
            assertNull(game.state.selection)
            assertEquals(emptySet<Any>(), game.state.destinations)

            val reopened = device.launch()
            assertTrue(reopened.state.game!!.doublePending)
            assertEquals(AFTER_E4, reopened.state.fen)
            assertEquals(Side.White, reopened.state.bottomSide)
            assertEquals(1, reopened.state.game?.stake)
        }

    @Test
    fun `while an offer awaits an answer no other game action is accepted`() = runTest {
        val game = device.launch()
        game.onOfferDoubleRequested()

        game.tap("e2", "g1")
        game.move("e7", "e5")
        game.onResignRequested()
        game.onDrawRequested()
        game.onNewGameRequested()
        game.onOfferDoubleRequested()

        assertNull(game.state.confirmation)
        assertNull(game.state.selection)
        assertEquals(OPENING, game.state.fen)
        assertNull(game.state.game?.result)
        assertTrue(game.state.game!!.doublePending)
        assertFalse(game.state.canOfferDouble)
    }

    @Test
    fun `taking doubles the stake, the offerer moves on and only the taker may offer next`() =
        runTest {
            val game = device.launch()
            game.onOfferDoubleRequested()

            game.onDoubleTaken()

            assertFalse(game.state.game!!.doublePending)
            assertEquals(2, game.state.game?.stake)
            assertEquals(Side.Black, game.state.game?.nextDoubler)
            assertEquals(OPENING, game.state.fen)
            assertEquals(Side.White, game.state.bottomSide)
            assertFalse(game.state.canOfferDouble)

            game.move("e2", "e4")
            assertEquals(AFTER_E4, game.state.fen)
            assertTrue(game.state.canOfferDouble)

            val reopened = device.launch()
            assertEquals(2, reopened.state.game?.stake)
            assertEquals(Side.Black, reopened.state.game?.nextDoubler)
            assertTrue(reopened.state.canOfferDouble)
        }

    @Test
    fun `declining ends the game without a move, won by the offerer at the old stake`() = runTest {
        val game = device.launch()
        game.onOfferDoubleRequested()
        game.onDoubleTaken()
        game.move("e2", "e4")
        game.onOfferDoubleRequested()

        game.onDoubleDeclined()

        val declined = GameResult(Side.Black, EndReason.DoubleDeclined)
        assertEquals(declined, game.state.game?.result)
        assertFalse(game.state.game!!.doublePending)
        assertEquals(2, game.state.game?.stake)
        assertEquals(AFTER_E4, game.state.fen)
        game.onSquareTapped(sq("e7"))
        assertNull(game.state.selection)

        val reopened = device.launch()
        assertEquals(declined, reopened.state.game?.result)
        assertEquals(2, reopened.state.game?.stake)
        assertEquals(AFTER_E4, reopened.state.fen)
    }

    @Test
    fun `no double is offered at 64 points`() = runTest {
        device.gameFile.writeText("cute-game 2\n$OPENING\nplaying\n32\nWhite\nanswered\n")
        val game = device.launch()
        assertTrue(game.state.canOfferDouble)

        game.onOfferDoubleRequested()
        game.onDoubleTaken()

        assertEquals(64, game.state.game?.stake)
        assertEquals(Side.Black, game.state.game?.nextDoubler)
        game.move("e2", "e4")
        assertFalse(game.state.canOfferDouble)
        game.onOfferDoubleRequested()
        assertFalse(game.state.game!!.doublePending)
        assertFalse(device.launch().state.game!!.doublePending)
    }

    @Test
    fun `only the holder of the right may offer, and only on their own turn`() = runTest {
        device.gameFile.writeText("cute-game 2\n$OPENING\nplaying\n4\nBlack\nanswered\n")
        val game = device.launch()

        assertFalse(game.state.canOfferDouble)
        game.onOfferDoubleRequested()
        assertFalse(game.state.game!!.doublePending)
        assertFalse(device.launch().state.game!!.doublePending)

        game.move("e2", "e4")
        assertTrue(game.state.canOfferDouble)
    }

    @Test
    fun `a side in check may offer`() = runTest {
        device.seed("4k3/8/8/8/8/8/8/4K2R w K - 0 1")
        val game = device.launch()
        game.move("h1", "h8")
        assertTrue(game.state.inCheck)

        game.onOfferDoubleRequested()

        assertTrue(game.state.game!!.doublePending)
        assertEquals(Side.White, game.state.bottomSide)
    }

    @Test
    fun `an ongoing game saved before the cube goes on at one point, either side free to offer`() =
        runTest {
            device.gameFile.writeText("cute-game 1\n$AFTER_E4\nplaying\n")

            val game = device.launch()

            assertEquals(AFTER_E4, game.state.fen)
            assertEquals(Side.Black, game.state.bottomSide)
            assertEquals(1, game.state.game?.stake)
            assertNull(game.state.game?.nextDoubler)
            assertFalse(game.state.game!!.doublePending)
            assertTrue(game.state.canOfferDouble)
        }

    @Test
    fun `a finished game saved before the cube keeps its result and has no stake`() = runTest {
        device.gameFile.writeText("cute-game 1\n$AFTER_E4\nBlack Resignation\n")

        val game = device.launch()

        assertEquals(GameResult(Side.Black, EndReason.Resignation), game.state.game?.result)
        assertNull(game.state.game?.stake)
        assertFalse(game.state.canOfferDouble)

        game.onNewGameRequested()
        assertEquals(1, game.state.game?.stake)
    }

    @Test
    fun `a draw after a take keeps the stake, and a new game starts at one point`() = runTest {
        val game = device.launch()
        game.onOfferDoubleRequested()
        game.onDoubleTaken()

        game.onDrawRequested()
        game.onConfirmed()
        assertEquals(GameResult(null, EndReason.Agreement), game.state.game?.result)
        assertEquals(2, game.state.game?.stake)

        game.onNewGameRequested()
        assertEquals(OPENING, game.state.fen)
        assertEquals(1, game.state.game?.stake)
        assertNull(game.state.game?.nextDoubler)
        assertTrue(game.state.canOfferDouble)
    }

    @Test
    fun `games at the cube's limits reopen exactly as saved`() = runTest {
        val opening = positionFromFen(OPENING)
        val limits = listOf(
            GameRecord(opening, null, stake = 64, nextDoubler = Side.Black),
            GameRecord(opening, null, stake = 32, nextDoubler = Side.White, doublePending = true),
            GameRecord(opening, null, stake = 1, nextDoubler = null, doublePending = true),
            GameRecord(
                opening,
                GameResult(Side.White, EndReason.DoubleDeclined),
                stake = 64,
                nextDoubler = Side.White
            ),
            GameRecord(opening, GameResult(null, EndReason.Agreement), stake = null)
        )
        for (record in limits) {
            device.repository().save(record)

            assertEquals(record, device.launch().state.game)
        }
    }

    companion object {
        const val AFTER_E4 = "rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1"
        const val OPENING = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
    }
}
