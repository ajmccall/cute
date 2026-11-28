package md.alasdair.cute.localgame

import kotlinx.coroutines.test.runTest
import md.alasdair.cute.chess.EndReason
import md.alasdair.cute.chess.GameResult
import md.alasdair.cute.chess.Side
import md.alasdair.cute.chess.positionFromFen
import md.alasdair.cute.localgame.data.GameRecord
import md.alasdair.cute.localgame.data.MatchScore
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test

class AutomaticDoublesTest {
    @get:Rule val main = MainDispatcherRule()
    private val device = LocalGameHarness()

    @Test
    fun `checkmate takes precedence over a qualifying automatic double`() = runTest {
        device.seed("7k/5K2/6Q1/8/8/8/8/8 w - - 0 1")
        val game = device.launch()
        game.onAutomaticDoublesChanged(true)
        game.move("g6", "g7")
        assertEquals(GameResult(Side.White, EndReason.Checkmate), game.state.game!!.result)
        assertNull(game.state.game!!.automaticPending)
    }

    @Test
    fun `switch off skips a qualifying move until a later move with it on`() = runTest {
        device.seed("4k3/8/8/8/8/8/4P3/4K2R w K - 0 1")
        val game = device.launch()
        game.move("e2", "e4")
        assertNull(game.state.game!!.automaticPending)
        assertTrue(game.state.game!!.endgameAvailable)
        game.onAutomaticDoublesChanged(true)
        assertNull(game.state.game!!.automaticPending)
        game.move("e8", "d7")
        assertTrue(game.state.game!!.automaticPending != null)
        assertFalse(game.state.game!!.endgameAvailable)
    }

    @Test
    fun `turning on and answering a voluntary double do not check the position`() = runTest {
        device.seed("4k3/8/8/8/8/8/4P3/4K2R w K - 0 1")
        val game = device.launch()
        game.onAutomaticDoublesChanged(true)
        assertNull(game.state.game!!.automaticPending)
        game.onOfferDoubleRequested()
        assertTrue(game.state.game!!.doublePending)
        game.onDoubleTaken()
        assertNull(game.state.game!!.automaticPending)
        assertEquals(2, game.state.game!!.stake)
        game.move("e2", "e4")
        assertTrue(game.state.game!!.automaticPending != null)
        game.onAutomaticAnswer(true)
        game.onAutomaticAnswer(true)
        assertEquals(4, game.state.game!!.stake)
        assertEquals(Side.Black, game.state.game!!.nextDoubler)
        assertTrue(game.state.canOfferDouble)
    }

    @Test
    fun `opening milestone waits until six starting squares are cleared`() = runTest {
        device.seed("r1bqkb1r/pppppppp/2n2n2/8/2B5/2N2N2/PPPPPPPP/R2QKB1R w KQkq - 0 1")
        val game = device.launch()
        game.onAutomaticDoublesChanged(true)
        game.move("f1", "e2")
        // e2 is occupied, so no move or decision has been committed.
        assertNull(game.state.game!!.automaticPending)
        game.move("f1", "g2")
        assertNull(game.state.game!!.automaticPending)
        game.move("e2", "e4")
        assertNull(game.state.game!!.automaticPending)
        game.move("e7", "e5")
        assertNull(game.state.game!!.automaticPending)
        game.move("f1", "e2")
        assertTrue(game.state.game!!.automaticPending != null)
        assertFalse(game.state.game!!.openingAvailable)
        assertTrue(game.state.game!!.endgameAvailable)
    }

    @Test
    fun `automatic doubles share the cap and preserve the voluntary offer right`() = runTest {
        for (stake in listOf(32, 64)) {
            val isolated = LocalGameHarness()
            isolated.repository().save(
                GameRecord(
                    positionFromFen("4k3/8/8/8/8/8/4P3/4K2R w K - 0 1"),
                    null,
                    stake = stake,
                    nextDoubler = Side.Black
                )
            )
            val game = isolated.launch()
            game.onAutomaticDoublesChanged(true)
            game.move("e2", "e4")
            if (stake == 32) {
                assertTrue(game.state.game!!.automaticPending != null)
                game.onAutomaticAnswer(true)
                game.onAutomaticAnswer(true)
            } else {
                assertNull(game.state.game!!.automaticPending)
            }
            assertEquals(64, game.state.game!!.stake)
            assertEquals(Side.Black, game.state.game!!.nextDoubler)
            assertFalse(game.state.canOfferDouble)
            assertEquals(game.state.game, isolated.launch().state.game)
        }
    }

    @Test
    fun `failed answers leave the last committed step intact on reopening`() = runTest {
        device.seed("4k3/8/8/8/8/8/4P3/4K2R w K - 0 1")
        val game = device.launch()
        game.onAutomaticDoublesChanged(true)
        game.move("e2", "e4")
        device.folder.setWritable(false)
        try {
            game.onAutomaticAnswer(true)
            assertEquals(Failure.Write, game.state.failure)
            assertNull(device.launch().state.game!!.automaticPending!!.firstAnswer)
        } finally {
            device.folder.setWritable(true)
        }
        game.onRetry()
        assertEquals(true, device.launch().state.game!!.automaticPending!!.firstAnswer)
        device.folder.setWritable(false)
        try {
            game.onAutomaticAnswer(true)
            assertEquals(Failure.Write, game.state.failure)
            assertEquals(true, device.launch().state.game!!.automaticPending!!.firstAnswer)
            assertEquals(1, game.state.game!!.stake)
        } finally {
            device.folder.setWritable(true)
        }
        game.onRetry()
        assertEquals(2, device.launch().state.game!!.stake)
    }

    @Test
    fun `either sole continuer wins the old stake and the result survives reopening`() = runTest {
        for ((first, second, winner) in listOf(
            Triple(true, false, Side.White),
            Triple(false, true, Side.Black)
        )) {
            val isolated = LocalGameHarness()
            isolated.seed("4k3/8/8/8/8/8/4P3/4K2R w K - 0 1")
            val game = isolated.launch()
            game.onAutomaticDoublesChanged(true)
            game.move("e2", "e4")
            game.onAutomaticAnswer(first)
            game.onAutomaticAnswer(second)
            assertEquals(GameResult(winner, EndReason.OpponentStopped), game.state.game!!.result)
            assertEquals(1, game.state.game!!.stake)
            assertEquals(game.state.game, isolated.launch().state.game)
        }
    }

    @Test
    fun `endgame takes precedence and neither milestone re-arms`() = runTest {
        device.seed("4k3/8/8/8/8/8/4P3/4K2R w K - 0 1")
        val game = device.launch()
        game.onAutomaticDoublesChanged(true)
        game.move("e2", "e4")
        assertFalse(game.state.game!!.openingAvailable)
        assertFalse(game.state.game!!.endgameAvailable)
        game.onAutomaticAnswer(true)
        game.onAutomaticAnswer(true)
        game.move("e8", "d7")
        assertNull(game.state.game!!.automaticPending)
        assertFalse(device.launch().state.game!!.openingAvailable)
    }

    @Test
    fun `a pending decision blocks other actions and changing the switch`() = runTest {
        device.seed("4k3/8/8/8/8/8/4P3/4K2R w K - 0 1")
        val game = device.launch()
        game.onAutomaticDoublesChanged(true)
        game.move("e2", "e4")
        val saved = game.state.game
        assertEquals(Side.White, game.state.bottomSide)
        game.onAutomaticDoublesChanged(false)
        game.onNewMatchRequested()
        game.onDrawRequested()
        game.onOfferDoubleRequested()
        game.move("e8", "d7")
        assertEquals(saved, game.state.game)
        assertTrue(game.state.automaticDoubles)
        assertNull(game.state.confirmation)
        game.onAutomaticAnswer(false)
        assertEquals(Side.Black, game.state.bottomSide)
        assertEquals(false, game.state.game!!.automaticPending!!.firstAnswer)
    }

    @Test
    fun `both stop at two points draws a tied match`() = runTest {
        device.repository().save(
            md.alasdair.cute.localgame.data.GameRecord(
                md.alasdair.cute.chess.positionFromFen("4k3/8/8/8/8/8/4P3/4K2R w K - 0 1"),
                null,
                stake = 2,
                nextDoubler = md.alasdair.cute.chess.Side.Black,
                matchScore = md.alasdair.cute.localgame.data.MatchScore(28, 28)
            )
        )
        val game = device.launch()
        game.onAutomaticDoublesChanged(true)
        game.move("e2", "e4")
        game.onAutomaticAnswer(false)
        game.onAutomaticAnswer(false)
        org.junit.Assert.assertEquals(
            md.alasdair.cute.localgame.data.MatchScore(30, 30),
            game.state.game!!.matchScore
        )
        assertTrue(game.state.game!!.matchOver)
        org.junit.Assert.assertEquals(game.state.game, device.launch().state.game)
    }

    @Test
    fun `switch save failure leaves its committed value and permits retry`() = runTest {
        val game = device.launch()
        device.folder.setWritable(false)
        try {
            game.onAutomaticDoublesChanged(true)
            org.junit.Assert.assertEquals(Failure.Write, game.state.failure)
            assertFalse(game.state.automaticDoubles)
        } finally {
            device.folder.setWritable(true)
        }
        game.onRetry()
        assertTrue(game.state.automaticDoubles)
        assertTrue(device.launch().state.automaticDoubles)
    }

    @Test
    fun `both players continue and reopen at each committed step`() = runTest {
        device.seed("4k3/8/8/8/8/8/4P3/4K2R w K - 0 1")
        val game = device.launch()
        game.onAutomaticDoublesChanged(true)
        game.move("e2", "e4")
        game.onAutomaticAnswer(true)
        val reopened = device.launch()
        assertTrue(reopened.state.game!!.automaticPending != null)
        reopened.onAutomaticAnswer(true)
        assertFalse(reopened.state.game!!.automaticPending != null)
        org.junit.Assert.assertEquals(2, device.launch().state.game!!.stake)
    }

    @Test
    fun `a qualifying move pauses for the mover and reopens there`() = runTest {
        device.seed("4k3/8/8/8/8/8/4P3/4K2R w K - 0 1")
        val game = device.launch()
        game.onAutomaticDoublesChanged(true)
        game.move("e2", "e4")
        assertTrue(game.state.game!!.automaticPending != null)
        assertTrue(device.launch().state.game!!.automaticPending != null)
    }

    @Test
    fun `automatic doubles are off on a fresh install and survive reopening`() = runTest {
        val game = device.launch()
        assertFalse(game.state.automaticDoubles)
        game.onAutomaticDoublesChanged(true)
        assertTrue(device.launch().state.automaticDoubles)
    }
}
