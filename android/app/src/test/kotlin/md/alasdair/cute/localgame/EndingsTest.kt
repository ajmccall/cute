package md.alasdair.cute.localgame

import kotlinx.coroutines.test.runTest
import md.alasdair.cute.chess.EndReason
import md.alasdair.cute.chess.GameResult
import md.alasdair.cute.chess.Side
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Rule
import org.junit.Test

class EndingsTest {
    @get:Rule val main = MainDispatcherRule()

    private val device = LocalGameHarness()

    @Test
    fun `fool's mate ends the game for the mover, freezes the board and survives relaunch`() =
        runTest {
            val game = device.launch()

            game.move("f2", "f3")
            game.move("e7", "e5")
            game.move("g2", "g4")
            game.move("d8", "h4")

            assertEquals(GameResult(Side.Black, EndReason.Checkmate), game.state.game?.result)
            assertEquals(FOOLS_MATE, game.state.fen)
            game.onSquareTapped(sq("e1"))
            assertNull(game.state.selection)

            val relaunched = device.launch()
            assertEquals(GameResult(Side.Black, EndReason.Checkmate), relaunched.state.game?.result)
            assertEquals(FOOLS_MATE, relaunched.state.fen)
            relaunched.onSquareTapped(sq("e1"))
            assertNull(relaunched.state.selection)
        }

    @Test
    fun `stalemate is a draw`() = runTest {
        device.seed("7k/8/6K1/8/8/8/8/5Q2 w - - 0 1")
        val game = device.launch()

        game.move("f1", "f7")

        assertEquals(GameResult(null, EndReason.Stalemate), game.state.game?.result)
    }

    @Test
    fun `kings alone is a draw`() = assertAfterKingTakesPawn("4k3/8/8/8/8/8/3p4/4K3", DRAW)

    @Test
    fun `one bishop besides the kings is a draw`() =
        assertAfterKingTakesPawn("4k3/8/8/8/8/8/3p4/4K1B1", DRAW)

    @Test
    fun `one knight besides the kings is a draw`() =
        assertAfterKingTakesPawn("4k3/8/8/8/8/8/3p4/4K1N1", DRAW)

    @Test
    fun `bishops all on squares of one colour are a draw`() =
        assertAfterKingTakesPawn("4kb2/8/8/8/8/8/3p4/4K1B1", DRAW)

    @Test
    fun `bishops on both colours play on`() =
        assertAfterKingTakesPawn("4k1b1/8/8/8/8/8/3p4/4K1B1", null)

    @Test
    fun `two knights against a king play on`() =
        assertAfterKingTakesPawn("4k3/8/8/8/8/8/3p4/4K1NN", null)

    @Test
    fun `a knight against a bishop plays on`() =
        assertAfterKingTakesPawn("4kb2/8/8/8/8/8/3p4/4K1N1", null)

    private fun assertAfterKingTakesPawn(board: String, expected: GameResult?) = runTest {
        device.seed("$board w - - 0 1")
        val game = device.launch()

        game.move("e1", "d2")

        assertEquals(expected, game.state.game?.result)
    }

    companion object {
        const val FOOLS_MATE = "rnb1kbnr/pppp1ppp/8/4p3/6Pq/5P2/PPPPP2P/RNBQKBNR w KQkq - 1 3"
        val DRAW = GameResult(null, EndReason.InsufficientMaterial)
    }
}
