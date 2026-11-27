package md.alasdair.cute.localgame

import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.StandardTestDispatcher
import kotlinx.coroutines.test.advanceUntilIdle
import kotlinx.coroutines.test.runTest
import md.alasdair.cute.chess.EndReason
import md.alasdair.cute.chess.GameResult
import md.alasdair.cute.chess.Side
import md.alasdair.cute.localgame.data.GameRecord
import md.alasdair.cute.localgame.data.GameRepository
import org.junit.After
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test

@OptIn(ExperimentalCoroutinesApi::class)
class StorageFailureTest {
    @get:Rule val main = MainDispatcherRule()

    private val device = LocalGameHarness()

    @After
    fun restoreAccess() {
        device.folder.setWritable(true)
        device.folder.setExecutable(true)
        device.gameFile.setReadable(true)
    }

    @Test
    fun `a saved game in a folder that can't be searched is reported, not replaced`() = runTest {
        device.seed(SAVED)
        device.folder.setExecutable(false)

        val game = device.launch()

        assertEquals(Failure.Read, game.state.failure)
        assertNull(game.state.game)
    }

    @Test
    fun `retrying again while a retry is saving starts no second save`() = runTest {
        device.seed(SAVED)
        val slow = StandardTestDispatcher(main.dispatcher.scheduler)
        val saves = CountingRepository(LocalGameHarness(device.folder, slow).repository())
        val game = LocalGameViewModel(saves)
        advanceUntilIdle()
        device.folder.setWritable(false)
        game.move("g1", "f3")
        advanceUntilIdle()
        device.folder.setWritable(true)

        game.onRetry()
        game.onRetry()
        advanceUntilIdle()

        assertEquals(2, saves.saves)
        assertNull(game.state.failure)
        assertEquals(AFTER_NF3, game.state.fen)
    }

    /** Passes everything to [delegate], counting the saves it was asked for. */
    private class CountingRepository(private val delegate: GameRepository) : GameRepository {
        var saves = 0

        override suspend fun load() = delegate.load()

        override suspend fun save(record: GameRecord) {
            saves++
            delegate.save(record)
        }
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
    fun `starting a new match in place of an unreadable game asks first`() = runTest {
        device.gameFile.writeText("damaged")
        val game = device.launch()

        game.onNewMatchRequested()
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

    @Test
    fun `an offer that can't be saved is reported and the game stays in play`() = runTest {
        device.seed(SAVED)
        val saved = device.gameFile.readBytes()
        val game = device.launch()
        device.folder.setWritable(false)

        game.onOfferDoubleRequested()

        assertEquals(Failure.Write, game.state.failure)
        assertFalse(game.state.game!!.doublePending)
        assertEquals(Side.White, game.state.bottomSide)
        assertArrayEquals(saved, device.gameFile.readBytes())

        device.folder.setWritable(true)
        game.onRetry()
        assertNull(game.state.failure)
        assertTrue(game.state.game!!.doublePending)
        assertTrue(device.launch().state.game!!.doublePending)
    }

    @Test
    fun `an answer that can't be saved is reported and the offer still awaits it`() = runTest {
        device.seed(SAVED)
        val game = device.launch()
        game.onOfferDoubleRequested()
        val saved = device.gameFile.readBytes()
        device.folder.setWritable(false)

        game.onDoubleTaken()
        assertEquals(Failure.Write, game.state.failure)
        assertTrue(game.state.game!!.doublePending)
        assertEquals(1, game.state.game?.stake)
        assertEquals(Side.Black, game.state.bottomSide)

        game.onDoubleDeclined()
        assertEquals(Failure.Write, game.state.failure)
        assertTrue(game.state.game!!.doublePending)
        assertNull(game.state.game?.result)
        assertArrayEquals(saved, device.gameFile.readBytes())

        device.folder.setWritable(true)
        game.onRetry()
        assertNull(game.state.failure)
        assertEquals(GameResult(Side.White, EndReason.DoubleDeclined), game.state.game?.result)
        assertEquals(1, device.launch().state.game?.stake)
    }

    @Test
    fun `an ending that can't be saved leaves the game in play and the match score as it was`() =
        runTest {
            device.gameFile.writeText("cute-game 3\n$SAVED\nplaying\n2\nBlack\nanswered\n8\n26\n")
            val saved = device.gameFile.readBytes()
            val game = device.launch()
            device.folder.setWritable(false)

            game.onResignRequested()
            game.onConfirmed()

            assertEquals(Failure.Write, game.state.failure)
            assertNull(game.state.game?.result)
            assertEquals(matchScore(white = 4.0, black = 13.0), game.state.game?.matchScore)
            assertFalse(game.state.game!!.matchOver)
            assertArrayEquals(saved, device.gameFile.readBytes())

            device.folder.setWritable(true)
            game.onRetry()
            assertNull(game.state.failure)
            assertEquals(matchScore(white = 4.0, black = 15.0), game.state.game?.matchScore)
            assertTrue(game.state.game!!.matchOver)
            assertEquals(
                matchScore(white = 4.0, black = 15.0),
                device.launch().state.game?.matchScore
            )
        }

    @Test
    fun `a failed save of a next game or new match keeps the finished game and its match score`() =
        runTest {
            device.gameFile.writeText(
                "cute-game 3\n$SAVED\nWhite Resignation\n1\nEither\nanswered\n6\n4\n"
            )
            val saved = device.gameFile.readBytes()
            val game = device.launch()
            device.folder.setWritable(false)

            game.onNextGameRequested()
            assertEquals(Failure.Write, game.state.failure)
            assertEquals(SAVED, game.state.fen)
            assertEquals(matchScore(white = 3.0, black = 2.0), game.state.game?.matchScore)

            game.onNewMatchRequested()
            game.onConfirmed()
            assertEquals(Failure.Write, game.state.failure)
            assertEquals(SAVED, game.state.fen)
            assertEquals(matchScore(white = 3.0, black = 2.0), game.state.game?.matchScore)
            assertArrayEquals(saved, device.gameFile.readBytes())

            device.folder.setWritable(true)
            game.onRetry()
            assertNull(game.state.failure)
            assertEquals(OPENING, game.state.fen)
            assertEquals(
                matchScore(white = 0.0, black = 0.0),
                device.launch().state.game?.matchScore
            )
        }

    companion object {
        const val OPENING = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
        const val SAVED = "rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq e6 0 2"
        const val AFTER_NF3 = "rnbqkbnr/pppp1ppp/8/4p3/4P3/5N2/PPPP1PPP/RNBQKB1R b KQkq - 1 2"
        private const val FOOLS_MATE =
            "rnb1kbnr/pppp1ppp/8/4p3/6Pq/5P2/PPPPP2P/RNBQKBNR w KQkq - 1 3"
        private const val GOOD_FEN = "4k3/8/8/8/8/8/4P3/4K3 w - - 0 1"

        /** Saved files that aren't a whole, playable game, each of which must be refused. */
        val DAMAGED = listOf(
            "",
            "cute-game 1\n",
            "cute-game 2\n$GOOD_FEN\nplaying\n",
            "cute-game 1\n$GOOD_FEN\nplaying",
            "cute-game 1\n$GOOD_FEN\nplaying\nextra\n",
            "cute-game 1\n4k3/8/8/8/8/8/4P3/4K3 w - -\nplaying\n",
            "cute-game 1\n4k3/8/8/8/8/8/4P3/4KK2 w - - 0 1\nplaying\n",
            "cute-game 1\n4k3/8/8/8/8/8/4P3/8 w - - 0 1\nplaying\n",
            "cute-game 1\n4k3/8/8/8/8/8/4P3/4K2P w - - 0 1\nplaying\n",
            "cute-game 1\n4k3/8/8/8/8/8/4P3/4K3/8 w - - 0 1\nplaying\n",
            "cute-game 1\n4k3/9/8/8/8/8/8/4K3 w - - 0 1\nplaying\n",
            "cute-game 1\n4k3/8/8/8/8/8/4P3/4K3x w - - 0 1\nplaying\n",
            "cute-game 1\n4k3/8/8/8/8/8/4P3/4K3 x - - 0 1\nplaying\n",
            "cute-game 1\n4k3/8/8/8/8/8/4P3/4K3 w K - 0 1\nplaying\n",
            "cute-game 1\n4k3/8/8/8/8/8/4P3/4K3 w KK - 0 1\nplaying\n",
            "cute-game 1\n4k3/8/8/8/8/8/4P3/4K3 w - e3 0 1\nplaying\n",
            "cute-game 1\n4k3/8/8/8/8/8/4P3/4K3 w - z9 0 1\nplaying\n",
            "cute-game 1\n4k3/8/8/8/8/8/4P3/4K3 w - - -1 1\nplaying\n",
            "cute-game 1\n4k3/8/8/8/8/8/4P3/4K3 w - - 0 0\nplaying\n",
            "cute-game 1\n4k3/8/8/8/8/8/4P3/4K2r b - - 0 1\nplaying\n",
            "cute-game 1\n4k2R/8/8/8/8/8/8/4K3 w - - 0 1\nplaying\n",
            "cute-game 1\n$GOOD_FEN\nWhite\n",
            "cute-game 1\n$GOOD_FEN\nWhite Agreement\n",
            "cute-game 1\n$GOOD_FEN\nDraw Checkmate\n",
            "cute-game 1\n$GOOD_FEN\nGreen Checkmate\n",
            "cute-game 1\n$GOOD_FEN\nWhite Timeout\n",
            "\u0000\u0001binary",
            "cute-game 1\n4k3/8/8/8/8/8/8/4K3 w - - 0 1\nplaying\n",
            "cute-game 1\n$FOOLS_MATE\nplaying\n",
            "cute-game 1\n$GOOD_FEN\nWhite DoubleDeclined\n",
            "cute-game 2\n$GOOD_FEN\nplaying\n1\nEither\n",
            "cute-game 2\n$GOOD_FEN\nplaying\n1\nEither\nanswered",
            "cute-game 2\n$GOOD_FEN\nplaying\n1\nEither\nanswered\nextra\n",
            "cute-game 2\n$GOOD_FEN\nplaying\n0\nEither\nanswered\n",
            "cute-game 2\n$GOOD_FEN\nplaying\n3\nWhite\nanswered\n",
            "cute-game 2\n$GOOD_FEN\nplaying\n-2\nWhite\nanswered\n",
            "cute-game 2\n$GOOD_FEN\nplaying\n128\nWhite\nanswered\n",
            "cute-game 2\n$GOOD_FEN\nplaying\n2.0\nWhite\nanswered\n",
            "cute-game 2\n$GOOD_FEN\nplaying\n99999999999\nWhite\nanswered\n",
            "cute-game 2\n$GOOD_FEN\nplaying\n\nEither\nanswered\n",
            "cute-game 2\n$GOOD_FEN\nplaying\nnone\nEither\nanswered\n",
            "cute-game 2\n$GOOD_FEN\nWhite Resignation\nnone\nWhite\nanswered\n",
            "cute-game 2\n$GOOD_FEN\nplaying\n1\nWhite\nanswered\n",
            "cute-game 2\n$GOOD_FEN\nplaying\n2\nEither\nanswered\n",
            "cute-game 2\n$GOOD_FEN\nplaying\n2\nGreen\nanswered\n",
            "cute-game 2\n$GOOD_FEN\nplaying\n1\nEither\nmaybe\n",
            "cute-game 2\n$GOOD_FEN\nWhite Resignation\n1\nEither\npending\n",
            "cute-game 2\n$GOOD_FEN\nplaying\n2\nBlack\npending\n",
            "cute-game 2\n$GOOD_FEN\nplaying\n64\nWhite\npending\n",
            "cute-game 3\n$GOOD_FEN\nplaying\n1\nEither\nanswered\n",
            "cute-game 3\n$GOOD_FEN\nplaying\n1\nEither\nanswered\n0\n",
            "cute-game 3\n$GOOD_FEN\nplaying\n1\nEither\nanswered\n0\n0",
            "cute-game 3\n$GOOD_FEN\nplaying\n1\nEither\nanswered\n0\n0\nextra\n",
            "cute-game 3\n$GOOD_FEN\nplaying\n1\nEither\nanswered\n-1\n0\n",
            "cute-game 3\n$GOOD_FEN\nplaying\n1\nEither\nanswered\n0\n+1\n",
            "cute-game 3\n$GOOD_FEN\nplaying\n1\nEither\nanswered\n01\n0\n",
            "cute-game 3\n$GOOD_FEN\nplaying\n1\nEither\nanswered\n1.5\n0\n",
            "cute-game 3\n$GOOD_FEN\nplaying\n1\nEither\nanswered\n\n0\n",
            "cute-game 3\n$GOOD_FEN\nplaying\n1\nEither\nanswered\n99999999999\n0\n",
            "cute-game 3\n$GOOD_FEN\nplaying\n1\nEither\nanswered\n30\n0\n",
            "cute-game 3\n$GOOD_FEN\nplaying\n1\nEither\nanswered\n0\n31\n",
            "cute-game 3\n$GOOD_FEN\nWhite Resignation\n4\nBlack\nanswered\n7\n0\n",
            "cute-game 3\n$GOOD_FEN\nDraw Agreement\n2\nBlack\nanswered\n2\n1\n",
            "cute-game 3\n$GOOD_FEN\nWhite Resignation\n2\nBlack\nanswered\n34\n0\n",
            "cute-game 3\n$GOOD_FEN\nDraw Agreement\n1\nEither\nanswered\n1\n31\n",
            "cute-game 4\n$GOOD_FEN\nplaying\n1\nEither\nanswered\n0\n0\n",
            "cute-game 4\n$GOOD_FEN\nplaying\n1\nEither\nanswered\n0\n0\nnone\n",
            "cute-game 4\n$GOOD_FEN\nplaying\n1\nEither\nanswered\n0\n0\nnone\nnone",
            "cute-game 4\n$GOOD_FEN\nplaying\n1\nEither\nanswered\n0\n0\nnone\nnone\nextra\n",
            "cute-game 4\n$GOOD_FEN\nplaying\n1\nEither\nanswered\n0\n0\n\nnone\n",
            "cute-game 4\n$GOOD_FEN\nplaying\n1\nEither\nanswered\n0\n0\nk\nnone\n",
            "cute-game 4\n$GOOD_FEN\nplaying\n1\nEither\nanswered\n0\n0\nnone\nP\n",
            "cute-game 4\n$GOOD_FEN\nplaying\n1\nEither\nanswered\n0\n0\np n\nnone\n",
            "cute-game 4\n$GOOD_FEN\nplaying\n1\nEither\nanswered\n0\n0\nnone\nppppppppnnbbrrq\n",
            "cute-game 4\n$GOOD_FEN\nplaying\n1\nEither\nanswered\n30\n0\nnone\nnone\n"
        )
    }
}
