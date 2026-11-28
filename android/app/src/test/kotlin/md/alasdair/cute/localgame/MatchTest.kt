package md.alasdair.cute.localgame

import kotlinx.coroutines.test.runTest
import md.alasdair.cute.chess.Side
import md.alasdair.cute.localgame.data.MatchScore
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test

/** A match of games to 15 points, at the game model over its real store (C10 to C15). */
class MatchTest {
    @get:Rule val main = MainDispatcherRule()

    private val device = LocalGameHarness()

    @Test
    fun `a new match starts at 0 to 0`() = runTest {
        val game = device.launch()

        assertEquals(matchScore(white = 0.0, black = 0.0), game.state.game?.matchScore)
    }

    @Test
    fun `a win adds the stake to the winner's total, saved with the result`() = runTest {
        val game = device.launch()

        game.onResignRequested()
        game.onConfirmed()

        assertEquals(matchScore(white = 0.0, black = 1.0), game.state.game?.matchScore)
        assertEquals(matchScore(white = 0.0, black = 1.0), device.launch().state.game?.matchScore)
    }

    @Test
    fun `a draw at one point gives each player half a point`() = runTest {
        val game = device.launch()

        game.onDrawRequested()
        game.onConfirmed()

        assertEquals(matchScore(white = 0.5, black = 0.5), game.state.game?.matchScore)
        assertEquals(matchScore(white = 0.5, black = 0.5), device.launch().state.game?.matchScore)
    }

    @Test
    fun `a declined double gives the offerer the old stake`() = runTest {
        device.save("playing", stake = "4", nextDoubler = "White", white = 6, black = 2)
        val game = device.launch()

        game.onOfferDoubleRequested()
        game.onDoubleDeclined()

        assertEquals(matchScore(white = 7.0, black = 1.0), game.state.game?.matchScore)
        assertEquals(matchScore(white = 7.0, black = 1.0), device.launch().state.game?.matchScore)
    }

    @Test
    fun `checkmate gives the mover the stake, and a stalemate splits it`() = runTest {
        val game = device.launch()
        game.move("f2", "f3")
        game.move("e7", "e5")
        game.move("g2", "g4")
        game.move("d8", "h4")
        assertEquals(matchScore(white = 0.0, black = 1.0), game.state.game?.matchScore)

        device.save("playing", "7k/8/6K1/8/8/8/8/5Q2 w - - 0 1", "2", "Black", 3, 4)
        val stalemate = device.launch()
        stalemate.move("f1", "f7")
        assertEquals(matchScore(white = 2.5, black = 3.0), stalemate.state.game?.matchScore)
    }

    @Test
    fun `a game in play keeps the match score as it was`() = runTest {
        device.save("playing", white = 5, black = 9)
        val game = device.launch()

        game.move("e2", "e4")
        game.onOfferDoubleRequested()
        game.onDoubleTaken()

        assertEquals(matchScore(white = 2.5, black = 4.5), game.state.game?.matchScore)
        assertEquals(matchScore(white = 2.5, black = 4.5), device.launch().state.game?.matchScore)
    }

    @Test
    fun `a game below 15 offers Next game, which starts at once and keeps the match score`() =
        runTest {
            device.save("playing", stake = "4", nextDoubler = "Black", white = 6, black = 10)
            val game = device.launch()
            game.onResignRequested()
            game.onConfirmed()
            assertTrue(game.state.game!!.canStartNextGame)
            assertFalse(game.state.game!!.matchOver)

            game.onNextGameRequested()

            assertNull(game.state.confirmation)
            assertEquals(OPENING, game.state.fen)
            assertEquals(Side.White, game.state.bottomSide)
            assertNull(game.state.game?.result)
            assertEquals(1, game.state.game?.stake)
            assertNull(game.state.game?.nextDoubler)
            assertTrue(game.state.canOfferDouble)
            assertEquals(matchScore(white = 3.0, black = 9.0), game.state.game?.matchScore)
            val reopened = device.launch()
            assertEquals(OPENING, reopened.state.fen)
            assertEquals(matchScore(white = 3.0, black = 9.0), reopened.state.game?.matchScore)
        }

    @Test
    fun `Next game isn't taken during play or during a double response`() = runTest {
        val game = device.launch()
        game.move("e2", "e4")

        game.onNextGameRequested()
        assertEquals(AFTER_E4, game.state.fen)

        game.onOfferDoubleRequested()
        game.onNextGameRequested()
        assertTrue(game.state.game!!.doublePending)
        assertEquals(AFTER_E4, game.state.fen)
    }

    @Test
    fun `a win that takes a total to 15 ends the match, and only New match follows, at once`() =
        runTest {
            device.save("playing", stake = "2", nextDoubler = "White", white = 18, black = 26)
            val game = device.launch()

            game.onResignRequested()
            game.onConfirmed()

            assertTrue(game.state.game!!.matchOver)
            assertFalse(game.state.game!!.canStartNextGame)
            assertEquals(matchScore(white = 9.0, black = 15.0), game.state.game?.matchScore)
            assertEquals(Side.Black, game.state.game?.matchScore?.leader)
            game.onNextGameRequested()
            game.onResignRequested()
            game.onDrawRequested()
            game.onOfferDoubleRequested()
            game.onSquareTapped(sq("e2"))
            assertNull(game.state.confirmation)
            assertNull(game.state.selection)
            assertEquals(matchScore(white = 9.0, black = 15.0), game.state.game?.matchScore)
            assertTrue(device.launch().state.game!!.matchOver)

            game.onNewMatchRequested()

            assertNull(game.state.confirmation)
            assertEquals(OPENING, game.state.fen)
            assertNull(game.state.game?.result)
            assertEquals(1, game.state.game?.stake)
            assertEquals(matchScore(white = 0.0, black = 0.0), game.state.game?.matchScore)
            assertEquals(
                matchScore(white = 0.0, black = 0.0),
                device.launch().state.game?.matchScore
            )
        }

    @Test
    fun `the winner wins the match even past 15 in one game`() = runTest {
        device.save("playing", stake = "16", nextDoubler = "White", white = 0, black = 0)
        val game = device.launch()

        game.onOfferDoubleRequested()
        game.onDoubleDeclined()

        assertTrue(game.state.game!!.matchOver)
        assertEquals(matchScore(white = 16.0, black = 0.0), game.state.game?.matchScore)
        assertEquals(Side.White, game.state.game?.matchScore?.leader)
    }

    @Test
    fun `a split draw that takes both past 15 is won by the higher total, or drawn if equal`() =
        runTest {
            device.save("playing", stake = "4", nextDoubler = "White", white = 29, black = 28)
            val higher = device.launch()
            higher.onDrawRequested()
            higher.onConfirmed()
            assertTrue(higher.state.game!!.matchOver)
            assertEquals(matchScore(white = 16.5, black = 16.0), higher.state.game?.matchScore)
            assertEquals(Side.White, higher.state.game?.matchScore?.leader)

            device.save("playing", stake = "2", nextDoubler = "Black", white = 28, black = 28)
            val equal = device.launch()
            equal.onDrawRequested()
            equal.onConfirmed()
            assertTrue(equal.state.game!!.matchOver)
            assertEquals(matchScore(white = 15.0, black = 15.0), equal.state.game?.matchScore)
            assertNull(equal.state.game?.matchScore?.leader)
        }

    @Test
    fun `declining ends the match only when the old stake takes the offerer to 15`() = runTest {
        device.save("playing", stake = "4", nextDoubler = "White", white = 22, black = 0)
        val reaches = device.launch()
        reaches.onOfferDoubleRequested()
        assertTrue(reaches.state.game!!.declineEndsMatch)
        reaches.onDoubleDeclined()
        assertTrue(reaches.state.game!!.matchOver)
        assertEquals(matchScore(white = 15.0, black = 0.0), reaches.state.game?.matchScore)

        device.save("playing", stake = "4", nextDoubler = "White", white = 21, black = 29)
        val short = device.launch()
        short.onOfferDoubleRequested()
        assertFalse(short.state.game!!.declineEndsMatch)
        short.onDoubleDeclined()
        assertTrue(short.state.game!!.canStartNextGame)
        assertEquals(matchScore(white = 14.5, black = 14.5), short.state.game?.matchScore)
    }

    @Test
    fun `New match asks first while the match is under way, and cancelling changes nothing`() =
        runTest {
            device.save("playing", white = 8, black = 3)
            val game = device.launch()
            game.move("e2", "e4")

            game.onNewMatchRequested()
            assertEquals(Confirmation.Replace, game.state.confirmation)
            game.onCancelled()

            assertNull(game.state.confirmation)
            assertEquals(AFTER_E4, game.state.fen)
            assertEquals(matchScore(white = 4.0, black = 1.5), game.state.game?.matchScore)

            game.onResignRequested()
            game.onConfirmed()
            assertTrue(game.state.game!!.canStartNextGame)
            game.onNewMatchRequested()
            assertEquals(Confirmation.Replace, game.state.confirmation)
            game.onCancelled()
            assertEquals(matchScore(white = 5.0, black = 1.5), game.state.game?.matchScore)
            assertEquals(
                matchScore(white = 5.0, black = 1.5),
                device.launch().state.game?.matchScore
            )
        }

    @Test
    fun `confirming New match replaces the game and the match score with a fresh game at 0 to 0`() =
        runTest {
            device.save("playing", stake = "2", nextDoubler = "Black", white = 8, black = 3)
            val game = device.launch()
            game.move("e2", "e4")

            game.onNewMatchRequested()
            game.onConfirmed()

            assertEquals(OPENING, game.state.fen)
            assertEquals(1, game.state.game?.stake)
            assertNull(game.state.game?.nextDoubler)
            assertEquals(matchScore(white = 0.0, black = 0.0), game.state.game?.matchScore)
            val reopened = device.launch()
            assertEquals(OPENING, reopened.state.fen)
            assertEquals(matchScore(white = 0.0, black = 0.0), reopened.state.game?.matchScore)
        }

    @Test
    fun `New match isn't available during a double response`() = runTest {
        device.save("playing", white = 8, black = 3)
        val game = device.launch()
        game.onOfferDoubleRequested()

        game.onNewMatchRequested()

        assertNull(game.state.confirmation)
        assertTrue(game.state.game!!.doublePending)
        assertEquals(matchScore(white = 4.0, black = 1.5), game.state.game?.matchScore)
    }

    @Test
    fun `a save opens as the same game after the automatic doubles upgrade`() = runTest {
        device.save("playing", stake = "2", nextDoubler = "White", white = 9, black = 4)
        val game = device.launch()

        game.move("e2", "e4")

        val saved = "cute-game 5\n$AFTER_E4\nplaying\n2\nWhite\nanswered\n9\n4\n" +
            "none\nnone\ntrue\ntrue\nnone\n"
        assertEquals(saved, device.gameFile.readText())
        val reopened = device.launch()
        assertEquals(game.state.game, reopened.state.game)
        assertEquals(matchScore(white = 4.5, black = 2.0), reopened.state.game?.matchScore)
    }

    /**
     * Writes a version-3 save of a match: [result] or `playing` at [fen], with the cube and
     * White's and Black's totals in half points.
     */
    private fun LocalGameHarness.save(
        result: String,
        fen: String = OPENING,
        stake: String = "1",
        nextDoubler: String = "Either",
        white: Int,
        black: Int,
        pending: String = "answered"
    ) = gameFile.writeText(
        "cute-game 3\n$fen\n$result\n$stake\n$nextDoubler\n$pending\n$white\n$black\n"
    )

    companion object {
        const val OPENING = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
        const val AFTER_E4 = "rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1"
    }
}

/** The match score [white] to [black], each in whole or half points. */
fun matchScore(white: Double, black: Double) =
    MatchScore(whiteHalves = (white * 2).toInt(), blackHalves = (black * 2).toInt())

/** Saves from before matches open as the first game of a match (C15), at the model. */
class SavesBeforeMatchesTest {
    @get:Rule val main = MainDispatcherRule()

    private val device = LocalGameHarness()

    @Test
    fun `an ongoing game opens at 0 to 0, and once finished offers Next game`() = runTest {
        device.gameFile.writeText("cute-game 2\n$AFTER_E4\nplaying\n2\nWhite\nanswered\n")
        val game = device.launch()

        assertEquals(AFTER_E4, game.state.fen)
        assertEquals(2, game.state.game?.stake)
        assertEquals(matchScore(white = 0.0, black = 0.0), game.state.game?.matchScore)

        game.onResignRequested()
        game.onConfirmed()
        assertEquals(matchScore(white = 2.0, black = 0.0), game.state.game?.matchScore)
        assertTrue(game.state.game!!.canStartNextGame)
        game.onNextGameRequested()
        assertEquals(OPENING, game.state.fen)
        assertEquals(matchScore(white = 2.0, black = 0.0), device.launch().state.game?.matchScore)
    }

    @Test
    fun `an ongoing game from before the cube opens at 0 to 0`() = runTest {
        device.gameFile.writeText("cute-game 1\n$AFTER_E4\nplaying\n")

        val game = device.launch()

        assertEquals(matchScore(white = 0.0, black = 0.0), game.state.game?.matchScore)
        assertEquals(1, game.state.game?.stake)
    }

    @Test
    fun `a finished game with a stake opens with its award as the match score`() = runTest {
        device.gameFile.writeText("cute-game 2\n$AFTER_E4\nDraw Agreement\n1\nEither\nanswered\n")

        val game = device.launch()

        assertEquals(matchScore(white = 0.5, black = 0.5), game.state.game?.matchScore)
        assertTrue(game.state.game!!.canStartNextGame)
        game.onNextGameRequested()
        assertEquals(OPENING, game.state.fen)
        assertEquals(matchScore(white = 0.5, black = 0.5), game.state.game?.matchScore)
    }

    @Test
    fun `a finished game whose award reaches 15 opens with the match over`() = runTest {
        device.gameFile.writeText(
            "cute-game 2\n$AFTER_E4\nBlack DoubleDeclined\n16\nWhite\nanswered\n"
        )

        val game = device.launch()

        assertEquals(matchScore(white = 0.0, black = 16.0), game.state.game?.matchScore)
        assertTrue(game.state.game!!.matchOver)
        assertEquals(Side.Black, game.state.game?.matchScore?.leader)
        game.onNextGameRequested()
        assertEquals(AFTER_E4, game.state.fen)
        game.onNewMatchRequested()
        assertNull(game.state.confirmation)
        assertEquals(OPENING, game.state.fen)
        assertEquals(matchScore(white = 0.0, black = 0.0), game.state.game?.matchScore)
    }

    @Test
    fun `a finished game from before the cube opens at 0 to 0 and offers Next game`() = runTest {
        device.gameFile.writeText("cute-game 1\n$AFTER_E4\nWhite Resignation\n")

        val game = device.launch()

        assertNull(game.state.game?.stake)
        assertEquals(matchScore(white = 0.0, black = 0.0), game.state.game?.matchScore)
        assertTrue(game.state.game!!.canStartNextGame)
        game.onNextGameRequested()
        assertEquals(OPENING, game.state.fen)
        assertEquals(matchScore(white = 0.0, black = 0.0), game.state.game?.matchScore)
    }

    @Test
    fun `reopening a save from before matches leaves the file as it was until a change`() =
        runTest {
            val saved = "cute-game 2\n$AFTER_E4\nWhite Resignation\n4\nBlack\nanswered\n"
            device.gameFile.writeText(saved)

            device.launch()

            assertEquals(saved, device.gameFile.readText())
        }

    companion object {
        const val OPENING = MatchTest.OPENING
        const val AFTER_E4 = MatchTest.AFTER_E4
    }
}
