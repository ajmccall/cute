package md.alasdair.cute.localgame

import kotlinx.coroutines.test.runTest
import md.alasdair.cute.chess.EndReason
import md.alasdair.cute.chess.GameResult
import md.alasdair.cute.chess.PieceType
import md.alasdair.cute.chess.PieceType.Knight
import md.alasdair.cute.chess.PieceType.Pawn
import md.alasdair.cute.chess.PieceType.Queen
import md.alasdair.cute.chess.PieceType.Rook
import md.alasdair.cute.chess.Side
import md.alasdair.cute.localgame.data.MaterialAdvantage
import org.junit.After
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Rule
import org.junit.Test

/**
 * Each player's captures and the material advantage (C16, C17), at the game model over its real
 * store: what the board is given to show, and what reopening finds.
 */
class CapturesTest {
    @get:Rule val main = MainDispatcherRule()

    private val device = LocalGameHarness()

    @After
    fun restoreAccess() {
        device.folder.setWritable(true)
    }

    @Test
    fun `a fresh game has no captures and equal material`() = runTest {
        val game = device.launch()

        assertCaptures(game, white = emptyList(), black = emptyList())
        assertNull(game.state.game?.materialAdvantage)
    }

    @Test
    fun `a capture joins the mover's captures, saved with the move`() = runTest {
        val game = device.launch()
        game.move("e2", "e4")
        game.move("d7", "d5")

        game.move("e4", "d5")

        assertCaptures(game, white = listOf(Pawn), black = emptyList())
        assertEquals(MaterialAdvantage(Side.White, 1), game.state.game?.materialAdvantage)
        val reopened = device.launch()
        assertCaptures(reopened, white = listOf(Pawn), black = emptyList())
        assertEquals(MaterialAdvantage(Side.White, 1), reopened.state.game?.materialAdvantage)

        reopened.move("d8", "d5")

        assertCaptures(reopened, white = listOf(Pawn), black = listOf(Pawn))
        assertNull(reopened.state.game?.materialAdvantage)
        assertCaptures(device.launch(), white = listOf(Pawn), black = listOf(Pawn))
    }

    @Test
    fun `captures are kept in the order taken`() = runTest {
        device.seed("4k3/8/8/2p5/3n4/2P1P3/8/4K3 w - - 0 1")
        val game = device.launch()

        game.move("c3", "d4")
        game.move("e8", "e7")
        game.move("d4", "c5")

        assertCaptures(game, white = listOf(Knight, Pawn), black = emptyList())
        assertCaptures(device.launch(), white = listOf(Knight, Pawn), black = emptyList())
    }

    @Test
    fun `a pawn taken en passant joins the captures`() = runTest {
        device.seed("4k3/8/8/3pP3/8/8/8/4K3 w - d6 0 1")
        val game = device.launch()
        assertNull(game.state.game?.materialAdvantage)

        game.move("e5", "d6")

        assertEquals("4k3/8/3P4/8/8/8/8/4K3 b - - 0 1", game.state.fen)
        assertCaptures(game, white = listOf(Pawn), black = emptyList())
        assertEquals(MaterialAdvantage(Side.White, 1), game.state.game?.materialAdvantage)
        assertCaptures(device.launch(), white = listOf(Pawn), black = emptyList())
    }

    @Test
    fun `a promotion changes the material once committed, without a capture`() = runTest {
        device.seed(PROMOTION)
        val game = device.launch()
        assertEquals(MaterialAdvantage(Side.Black, 4), game.state.game?.materialAdvantage)

        game.move("b7", "b8")
        assertEquals(MaterialAdvantage(Side.Black, 4), game.state.game?.materialAdvantage)
        game.onPromotionCancelled()
        assertEquals(MaterialAdvantage(Side.Black, 4), game.state.game?.materialAdvantage)
        game.move("b7", "b8")
        game.onPromotionChosen(Queen)

        assertCaptures(game, white = emptyList(), black = emptyList())
        assertEquals(MaterialAdvantage(Side.White, 4), game.state.game?.materialAdvantage)
        assertEquals(
            MaterialAdvantage(Side.White, 4),
            device.launch().state.game?.materialAdvantage
        )
    }

    @Test
    fun `a captured promoted piece joins the captures as the piece it had become`() = runTest {
        device.seed(PROMOTION)
        val game = device.launch()
        game.move("b7", "b8")
        game.onPromotionChosen(Queen)

        game.move("a8", "b8")

        assertCaptures(game, white = emptyList(), black = listOf(Queen))
        assertEquals(MaterialAdvantage(Side.Black, 5), game.state.game?.materialAdvantage)
        assertCaptures(device.launch(), white = emptyList(), black = listOf(Queen))
    }

    @Test
    fun `a promotion that captures joins the captured piece to the captures`() = runTest {
        device.seed(PROMOTION)
        val game = device.launch()

        game.move("b7", "a8")
        game.onPromotionChosen(Knight)

        assertCaptures(game, white = listOf(Rook), black = emptyList())
        assertEquals(MaterialAdvantage(Side.White, 3), game.state.game?.materialAdvantage)
    }

    @Test
    fun `a capture that ends the game is saved with the result`() = runTest {
        device.seed("3rk3/8/8/8/8/8/5PPP/3N2K1 b - - 0 1")
        val game = device.launch()

        game.move("d8", "d1")

        assertEquals(GameResult(Side.Black, EndReason.Checkmate), game.state.game?.result)
        assertCaptures(game, white = emptyList(), black = listOf(Knight))
        assertEquals(MaterialAdvantage(Side.Black, 2), game.state.game?.materialAdvantage)
        val reopened = device.launch()
        assertEquals(GameResult(Side.Black, EndReason.Checkmate), reopened.state.game?.result)
        assertCaptures(reopened, white = emptyList(), black = listOf(Knight))
    }

    @Test
    fun `the next game starts with no captures, keeping the score`() = runTest {
        val game = device.launch()
        game.move("e2", "e4")
        game.move("d7", "d5")
        game.move("e4", "d5")
        game.onResignRequested()
        game.onConfirmed()
        assertCaptures(game, white = listOf(Pawn), black = emptyList())
        assertEquals(MaterialAdvantage(Side.White, 1), game.state.game?.materialAdvantage)

        game.onNextGameRequested()

        assertCaptures(game, white = emptyList(), black = emptyList())
        assertNull(game.state.game?.materialAdvantage)
        assertEquals(score(white = 1.0, black = 0.0), game.state.game?.score)
        assertCaptures(device.launch(), white = emptyList(), black = emptyList())
    }

    @Test
    fun `a new match starts with no captures`() = runTest {
        val game = device.launch()
        game.move("e2", "e4")
        game.move("d7", "d5")
        game.move("e4", "d5")

        game.onNewMatchRequested()
        game.onConfirmed()

        assertCaptures(game, white = emptyList(), black = emptyList())
        assertNull(game.state.game?.materialAdvantage)
        assertCaptures(device.launch(), white = emptyList(), black = emptyList())
    }

    @Test
    fun `a game saved before captures opens with none, and nothing else changed`() = runTest {
        for (
        saved in listOf(
            "cute-game 1\n$UNEVEN\nplaying\n",
            "cute-game 2\n$UNEVEN\nplaying\n2\nWhite\nanswered\n",
            "cute-game 3\n$UNEVEN\nplaying\n2\nWhite\nanswered\n7\n4\n"
        )
        ) {
            device.gameFile.writeText(saved)

            val game = device.launch()

            assertEquals("for <$saved>", UNEVEN, game.state.fen)
            assertEquals("for <$saved>", null, game.state.failure)
            assertCaptures(game, white = emptyList(), black = emptyList())
            assertEquals(MaterialAdvantage(Side.White, 9), game.state.game?.materialAdvantage)
            assertEquals(saved, device.gameFile.readText())
        }
    }

    @Test
    fun `a capture that can't be saved leaves the captures as they were until Retry`() = runTest {
        device.seed(BEFORE_EXD5)
        val saved = device.gameFile.readBytes()
        val game = device.launch()
        device.folder.setWritable(false)

        game.move("e4", "d5")

        assertEquals(Failure.Write, game.state.failure)
        assertCaptures(game, white = emptyList(), black = emptyList())
        assertNull(game.state.game?.materialAdvantage)
        assertArrayEquals(saved, device.gameFile.readBytes())

        device.folder.setWritable(true)
        game.onRetry()

        assertNull(game.state.failure)
        assertCaptures(game, white = listOf(Pawn), black = emptyList())
        assertEquals(MaterialAdvantage(Side.White, 1), game.state.game?.materialAdvantage)
        assertCaptures(device.launch(), white = listOf(Pawn), black = emptyList())
    }

    private fun assertCaptures(
        game: LocalGameViewModel,
        white: List<PieceType>,
        black: List<PieceType>
    ) {
        val captures = game.state.game?.captures
        assertEquals("White's captures", white, captures?.of(Side.White))
        assertEquals("Black's captures", black, captures?.of(Side.Black))
    }

    companion object {
        /** White's pawn on b7 can promote, or take Black's rook on a8 as it does. */
        const val PROMOTION = "r3k3/1P6/8/8/8/8/8/4K3 w - - 0 1"
        const val BEFORE_EXD5 = "rnbqkbnr/ppp1pppp/8/3p4/4P3/8/PPPP1PPP/RNBQKBNR w KQkq d6 0 2"

        /** After 1.e4 with Black's queen missing: White is 9 ahead, with nothing captured. */
        const val UNEVEN = "rnb1kbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1"
    }
}
