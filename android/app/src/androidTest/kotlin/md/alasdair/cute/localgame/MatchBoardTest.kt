package md.alasdair.cute.localgame

import androidx.activity.ComponentActivity
import androidx.compose.ui.semantics.SemanticsProperties
import androidx.compose.ui.test.SemanticsMatcher
import androidx.compose.ui.test.SemanticsNodeInteraction
import androidx.compose.ui.test.assert
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.assertIsNotEnabled
import androidx.compose.ui.test.assertTextEquals
import androidx.compose.ui.test.junit4.v2.createAndroidComposeRule
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performScrollTo
import androidx.test.ext.junit.runners.AndroidJUnit4
import org.junit.After
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/**
 * A match to 15 points on the running board, one or more checks per criterion C10 to C15, with
 * accessibility checks on every action (BoardHarness.enableAccessibilityChecks). Matches under
 * way are seeded as version-3 files, with totals in half points, and saves from before matches
 * as version-1 and version-2 files.
 */
@RunWith(AndroidJUnit4::class)
class MatchBoardTest {
    @get:Rule val rule = createAndroidComposeRule<ComponentActivity>()

    private val board = BoardHarness(rule)

    @Before
    fun checkAccessibility() = board.enableAccessibilityChecks()

    @After
    fun cleanUp() = board.cleanUp()

    @Test
    fun c10_theScoreAndTargetShowInPlay_duringADoubleResponse_andAfterTheEnd_andReopen() {
        board.launch()
        board.awaitText("White to move")
        score().assertTextEquals("White 0 points · Black 0 points · first to 15 points")

        offer()
        board.awaitText("Black, answer the double")
        score().assertTextEquals("White 0 points · Black 0 points · first to 15 points")

        board.tapText("Decline")
        board.awaitText("White wins · Double declined")
        score().assertTextEquals("White 1 point · Black 0 points · first to 15 points")

        board.relaunch()
        board.awaitText("White wins · Double declined")
        score().assertTextEquals("White 1 point · Black 0 points · first to 15 points")
    }

    @Test
    fun c10_halfPointsShowAsHalf_andAreSpokenAndAHalf() {
        board.launch()
        board.awaitText("White to move")

        board.tapText("Agree draw")
        board.tapText("Confirm")

        board.awaitText("Draw · Agreement")
        score().assertTextEquals("White ½ point · Black ½ point · first to 15 points")
        assertSpoken(score(), "White half a point · Black half a point · first to 15 points")

        board.save("playing", white = 9, black = 3)
        board.relaunch()
        board.awaitText("White to move")
        score().assertTextEquals("White 4½ points · Black 1½ points · first to 15 points")
        assertSpoken(
            score(),
            "White 4 and a half points · Black 1 and a half points · first to 15 points"
        )
    }

    @Test
    fun c11_aFinishedGameBelow15OffersNextGame_whichStartsAtOnceAndKeepsTheScore() {
        board.save("playing", stake = "4", nextDoubler = "Black", white = 6, black = 10)
        board.launch()
        board.awaitText("White to move")

        board.tapText("Resign")
        board.tapText("Confirm")
        board.awaitText("Black wins · Resignation")
        score().assertTextEquals("White 3 points · Black 9 points · first to 15 points")
        listOf("Resign", "Agree draw", "Offer double").forEach {
            rule.onNodeWithText(it).assertDoesNotExist()
        }
        rule.onNodeWithText("New match").assertExists()

        nextGame()

        board.awaitText("White to move")
        rule.onNodeWithText("Replace this match?").assertDoesNotExist()
        assertBottomLeft("a1", topRight = "h8")
        board.assertSquare("e2", "e2, White pawn")
        board.assertSquare("e4", "e4, Empty")
        stake().assertTextEquals("Stake: 1 point", "Either player can offer")
        score().assertTextEquals("White 3 points · Black 9 points · first to 15 points")
        rule.onNodeWithText("Next game").assertDoesNotExist()
        board.relaunch()
        board.awaitText("White to move")
        score().assertTextEquals("White 3 points · Black 9 points · first to 15 points")
    }

    @Test
    fun c12_aGameTaking15ShowsTheMatchResult_andOnlyNewMatch_whichStartsAtOnce() {
        board.save("playing", AFTER_E4, stake = "2", nextDoubler = "White", white = 26, black = 10)
        board.launch()
        board.awaitText("Black to move")

        board.tapText("Resign")
        board.tapText("Confirm")

        board.awaitText("White wins the match, 15 to 5")
        status().assertTextEquals(
            "White wins · Resignation",
            "White earns 2 points.",
            "White wins the match, 15 to 5"
        )
        score().assertTextEquals("White 15 points · Black 5 points · first to 15 points")
        board.square("e7").assertIsNotEnabled()
        listOf("Next game", "Resign", "Agree draw", "Offer double").forEach {
            rule.onNodeWithText(it).assertDoesNotExist()
        }
        board.relaunch()
        board.awaitText("White wins the match, 15 to 5")

        newMatch()

        board.awaitText("White to move")
        rule.onNodeWithText("Replace this match?").assertDoesNotExist()
        score().assertTextEquals("White 0 points · Black 0 points · first to 15 points")
        stake().assertTextEquals("Stake: 1 point", "Either player can offer")
        board.assertSquare("e4", "e4, Empty")
    }

    @Test
    fun c12_aSplitDrawPast15IsWonByTheHigherTotal_orDrawnWhenEqual() {
        board.save("playing", stake = "2", nextDoubler = "White", white = 28, black = 27)
        board.launch()
        board.awaitText("White to move")
        board.tapText("Agree draw")
        board.tapText("Confirm")
        board.awaitText("White wins the match, 15 to 14½")
        status().assertTextEquals(
            "Draw · Agreement",
            "Each player earns 1 point.",
            "White wins the match, 15 to 14½"
        )
        assertSpoken(
            status(),
            "Draw · Agreement. Each player earns 1 point. White wins the match, 15 to 14 and a half"
        )

        board.save("playing", stake = "2", nextDoubler = "Black", white = 28, black = 28)
        board.relaunch()
        board.awaitText("White to move")
        board.tapText("Agree draw")
        board.tapText("Confirm")
        board.awaitText("Match drawn, 15 to 15")
        rule.onNodeWithText("Next game").assertDoesNotExist()
    }

    @Test
    fun c13_newMatchAsksFirstWhileTheMatchIsUnderWay_andCancelChangesNothing() {
        board.save("playing", white = 8, black = 3)
        board.launch()
        board.awaitText("White to move")
        board.tap("e2", "e4")
        board.awaitText("Black to move")

        newMatch()
        rule.onNodeWithText("Replace this match?").assertIsDisplayed()
        board.tapText("Cancel")
        status().assertTextEquals("Black to move")
        board.assertSquare("e4", "e4, White pawn")
        score().assertTextEquals("White 4 points · Black 1½ points · first to 15 points")

        newMatch()
        board.tapText("Confirm")
        board.awaitText("White to move")
        board.assertSquare("e4", "e4, Empty")
        score().assertTextEquals("White 0 points · Black 0 points · first to 15 points")
        board.relaunch()
        board.awaitText("White to move")
        score().assertTextEquals("White 0 points · Black 0 points · first to 15 points")
    }

    @Test
    fun c13_newMatchAsksFirstAfterAGameBelow15_andIsNotOfferedDuringADoubleResponse() {
        board.save("playing", white = 8, black = 3)
        board.launch()
        board.awaitText("White to move")
        board.tapText("Resign")
        board.tapText("Confirm")
        board.awaitText("Black wins · Resignation")

        newMatch()
        rule.onNodeWithText("Replace this match?").assertIsDisplayed()
        board.tapText("Cancel")
        score().assertTextEquals("White 4 points · Black 2½ points · first to 15 points")

        nextGame()
        board.awaitText("White to move")
        offer()
        board.awaitText("Black, answer the double")
        rule.onNodeWithText("New match").assertDoesNotExist()
        rule.onNodeWithText("Next game").assertDoesNotExist()
    }

    @Test
    fun c14_theDeclineTextNamesTheMatchWhenDecliningWouldTakeTheOffererTo15() {
        board.save("playing", stake = "4", nextDoubler = "White", white = 22, black = 0)
        board.launch()
        board.awaitText("White to move")

        offer()

        board.awaitText("Black, answer the double")
        rule.onNodeWithText("Decline: White wins 4 points and the match.").assertIsDisplayed()
        rule.onNodeWithText("Take: play for 8 points.").assertIsDisplayed()

        board.save("playing", stake = "4", nextDoubler = "White", white = 20, black = 0)
        board.relaunch()
        board.awaitText("White to move")
        offer()
        board.awaitText("Black, answer the double")
        rule.onNodeWithText("Decline: White wins 4 points.").assertIsDisplayed()
    }

    @Test
    fun c14_decliningWhenItWouldReach15EndsTheMatch() {
        board.save("playing", AFTER_E4, stake = "2", nextDoubler = "Black", white = 0, black = 26)
        board.launch()
        board.awaitText("Black to move")
        offer()
        board.awaitText("White, answer the double")
        rule.onNodeWithText("Decline: Black wins 2 points and the match.").assertIsDisplayed()

        board.tapText("Decline")

        board.awaitText("Black wins the match, 15 to 0")
        status().assertTextEquals(
            "Black wins · Double declined",
            "Black earns 2 points.",
            "Black wins the match, 15 to 0"
        )
    }

    @Test
    fun c15_savesFromBeforeMatchesOpenAsTheFirstGameOfAMatch() {
        board.gameFile.writeText("cute-game 2\n$AFTER_E4\nplaying\n2\nWhite\nanswered\n")
        board.launch()
        board.awaitText("Black to move")
        score().assertTextEquals("White 0 points · Black 0 points · first to 15 points")

        board.gameFile.writeText("cute-game 2\n$AFTER_E4\nWhite Checkmate\n4\nBlack\nanswered\n")
        board.relaunch()
        board.awaitText("White wins · Checkmate")
        score().assertTextEquals("White 4 points · Black 0 points · first to 15 points")
        rule.onNodeWithText("Next game").assertExists()

        board.gameFile.writeText("cute-game 1\n$AFTER_E4\nWhite Resignation\n")
        board.relaunch()
        board.awaitText("White wins · Resignation")
        status().assertTextEquals("White wins · Resignation")
        score().assertTextEquals("White 0 points · Black 0 points · first to 15 points")
        rule.onNodeWithText("Next game").assertExists()

        board.gameFile.writeText(
            "cute-game 2\n$AFTER_E4\nBlack DoubleDeclined\n16\nWhite\nanswered\n"
        )
        board.relaunch()
        board.awaitText("Black wins the match, 16 to 0")
        score().assertTextEquals("White 0 points · Black 16 points · first to 15 points")
        rule.onNodeWithText("Next game").assertDoesNotExist()
        rule.onNodeWithText("New match").assertExists()
    }

    @Test
    fun c5_anEndingThatCantBeSavedKeepsTheGameAndScore_andRetrySavesBoth() {
        board.save("playing", stake = "2", nextDoubler = "Black", white = 8, black = 26)
        board.launch()
        board.awaitText("White to move")
        board.folder.setWritable(false)

        board.tapText("Resign")
        board.tapText("Confirm")

        board.awaitText("Change not saved.")
        status().assertTextEquals("White to move")
        score().assertTextEquals("White 4 points · Black 13 points · first to 15 points")
        board.folder.setWritable(true)
        board.tapText("Retry")
        board.awaitText("Black wins the match, 15 to 4")
        score().assertTextEquals("White 4 points · Black 15 points · first to 15 points")
        board.relaunch()
        board.awaitText("Black wins the match, 15 to 4")
    }

    /** Writes a version-3 save of a match, with White's and Black's totals in half points. */
    private fun BoardHarness.save(
        result: String,
        fen: String = OPENING,
        stake: String = "1",
        nextDoubler: String = "Either",
        white: Int,
        black: Int
    ) = gameFile.writeText(
        "cute-game 3\n$fen\n$result\n$stake\n$nextDoubler\nanswered\n$white\n$black\n"
    )

    private fun offer() {
        rule.onNodeWithText("Offer double").performScrollTo()
        board.tapText("Offer double")
    }

    private fun nextGame() {
        rule.onNodeWithText("Next game").performScrollTo()
        board.tapText("Next game")
    }

    private fun newMatch() {
        rule.onNodeWithText("New match").performScrollTo()
        board.tapText("New match")
    }

    private fun assertSpoken(node: SemanticsNodeInteraction, spoken: String) {
        node.assert(
            SemanticsMatcher.expectValue(SemanticsProperties.ContentDescription, listOf(spoken))
        )
    }

    private fun status() = rule.onNodeWithTag("status")

    private fun score() = rule.onNodeWithTag("score")

    private fun stake() = rule.onNodeWithTag("stake")

    private fun assertBottomLeft(bottomLeft: String, topRight: String) {
        val low = board.square(bottomLeft).fetchSemanticsNode().boundsInRoot
        val high = board.square(topRight).fetchSemanticsNode().boundsInRoot
        assertTrue("$bottomLeft is below $topRight", low.top > high.top)
        assertTrue("$bottomLeft is left of $topRight", low.left < high.left)
    }

    companion object {
        const val OPENING = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
        const val AFTER_E4 = "rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1"
    }
}
