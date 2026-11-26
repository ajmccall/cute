package md.alasdair.cute.localgame

import kotlinx.coroutines.test.runTest
import md.alasdair.cute.chess.EndReason
import md.alasdair.cute.chess.GameResult
import md.alasdair.cute.chess.Side
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Rule
import org.junit.Test

class GameActionsTest {
    @get:Rule val main = MainDispatcherRule()

    private val device = LocalGameHarness()

    @Test
    fun `confirming resignation records a loss for the side to move`() = runTest {
        val game = device.launch()
        game.move("e2", "e4")

        game.onResignRequested()
        assertEquals(Confirmation.Resign, game.state.confirmation)
        game.onConfirmed()

        assertNull(game.state.confirmation)
        assertEquals(GameResult(Side.White, EndReason.Resignation), game.state.game?.result)
        assertEquals(
            GameResult(Side.White, EndReason.Resignation),
            device.launch().state.game?.result
        )
    }

    @Test
    fun `cancelling resignation changes nothing`() = runTest {
        val game = device.launch()

        game.onResignRequested()
        game.onCancelled()

        assertNull(game.state.confirmation)
        assertNull(game.state.game?.result)
        assertEquals(OPENING, game.state.fen)
    }

    @Test
    fun `confirming an agreed draw records a draw by agreement`() = runTest {
        val game = device.launch()

        game.onDrawRequested()
        assertEquals(Confirmation.Draw, game.state.confirmation)
        game.onConfirmed()

        assertEquals(GameResult(null, EndReason.Agreement), game.state.game?.result)
    }

    @Test
    fun `cancelling an agreed draw changes nothing`() = runTest {
        val game = device.launch()

        game.onDrawRequested()
        game.onCancelled()

        assertNull(game.state.game?.result)
    }

    @Test
    fun `a new match during play asks first and cancelling keeps the game`() = runTest {
        val game = device.launch()
        game.move("e2", "e4")

        game.onNewMatchRequested()
        assertEquals(Confirmation.Replace, game.state.confirmation)
        game.onCancelled()

        assertEquals(AFTER_E4, game.state.fen)
    }

    @Test
    fun `confirming a new match during play starts afresh`() = runTest {
        val game = device.launch()
        game.move("e2", "e4")

        game.onNewMatchRequested()
        game.onConfirmed()

        assertEquals(OPENING, game.state.fen)
        assertNull(game.state.game?.result)
        assertEquals(OPENING, device.launch().state.fen)
    }

    @Test
    fun `the next game after the end starts at once`() = runTest {
        val game = device.launch()
        game.onResignRequested()
        game.onConfirmed()

        game.onNextGameRequested()

        assertNull(game.state.confirmation)
        assertEquals(OPENING, game.state.fen)
        assertNull(game.state.game?.result)
    }

    @Test
    fun `resignation and draws aren't offered after the end`() = runTest {
        val game = device.launch()
        game.onDrawRequested()
        game.onConfirmed()

        game.onResignRequested()

        assertNull(game.state.confirmation)
        assertEquals(GameResult(null, EndReason.Agreement), game.state.game?.result)
    }

    companion object {
        const val OPENING = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
        const val AFTER_E4 = "rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1"
    }
}
