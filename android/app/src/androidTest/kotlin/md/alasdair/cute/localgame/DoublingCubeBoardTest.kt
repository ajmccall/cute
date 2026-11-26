package md.alasdair.cute.localgame

import androidx.activity.ComponentActivity
import androidx.compose.ui.semantics.SemanticsProperties
import androidx.compose.ui.test.SemanticsMatcher
import androidx.compose.ui.test.assert
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.assertIsEnabled
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
 * The doubling cube on the running board, one or more checks per criterion C5 to C9, with
 * accessibility checks on every action (BoardHarness.enableAccessibilityChecks). Saved games
 * with a stake are seeded as version-2 files, and games from before the cube as version-1.
 */
@RunWith(AndroidJUnit4::class)
class DoublingCubeBoardTest {
    @get:Rule val rule = createAndroidComposeRule<ComponentActivity>()

    private val board = BoardHarness(rule)

    @Before
    fun checkAccessibility() = board.enableAccessibilityChecks()

    @After
    fun cleanUp() = board.cleanUp()

    @Test
    fun c6_aFreshGameIsForOnePointAndEitherSideCanOffer_includingOnTheOpeningTurn() {
        board.launch()
        board.awaitText("White to move")

        stake().assertTextEquals("Stake: 1 point", "Either player can offer")
        offerDouble().assertIsEnabled()
    }

    @Test
    fun c6_onlyTheHolderOfTheRightCanOffer_andNoOneAt64Points() {
        board.gameFile.writeText("cute-game 2\n$OPENING\nplaying\n4\nBlack\nanswered\n")
        board.launch()
        board.awaitText("White to move")

        stake().assertTextEquals("Stake: 4 points", "Only Black can offer")
        offerDouble().assertIsNotEnabled()

        board.gameFile.writeText("cute-game 2\n$OPENING\nplaying\n64\nWhite\nanswered\n")
        board.relaunch()
        board.awaitText("Stake: 64 points")
        stake().assertTextEquals("Stake: 64 points", "Maximum stake reached")
        offerDouble().assertIsNotEnabled()
    }

    @Test
    fun c6_aSideInCheckCanOffer() {
        board.seed("4k3/8/8/8/8/8/8/4K2R w K - 0 1")
        board.launch()
        board.awaitText("White to move")
        board.tap("h1", "h8")
        board.awaitText("Black to move · Check")

        offerDouble().assertIsEnabled()
    }

    @Test
    fun c6_anOngoingGameSavedBeforeTheCubeGoesOnAtOnePoint() {
        board.gameFile.writeText("cute-game 1\n$AFTER_E4\nplaying\n")
        board.launch()
        board.awaitText("Black to move")

        board.assertSquare("e4", "e4, White pawn")
        stake().assertTextEquals("Stake: 1 point", "Either player can offer")
        offerDouble().assertIsEnabled()
    }

    @Test
    fun c7_tappingOfferDoubleMakesTheOfferAtOnce_withNothingToConfirm() {
        board.launch()
        board.awaitText("White to move")
        board.tap("g1")

        offer()

        board.awaitText("Black, answer the double")
        rule.onNodeWithText("Confirm").assertDoesNotExist()
        rule.onNodeWithText("Cancel").assertDoesNotExist()
        board.assertSquare("g1", "g1, White knight")
        board.assertSquare("f3", "f3, Empty")
    }

    @Test
    fun c7_anOfferFacesTheResponderWithOnlyTakeOrDecline_andSurvivesReopening() {
        board.launch()
        board.awaitText("White to move")
        board.tap("e2", "e4")
        board.awaitText("Black to move")

        offer()

        assertAwaitingWhite()
        board.relaunch()
        assertAwaitingWhite()
    }

    @Test
    fun c7_theResponderSeesTheUnchangedPositionAndThePointsAtStake() {
        board.launch()
        board.awaitText("White to move")

        offer()

        board.awaitText("Black, answer the double")
        assertBottomLeft("h8", topRight = "a1")
        board.assertSquare("e2", "e2, White pawn")
        board.assertSquare("e4", "e4, Empty")
        board.square("e7").assertIsNotEnabled()
        rule.onNodeWithText("Stake: 1 point").assertIsDisplayed()
        rule.onNodeWithText("Take: play for 2 points.").assertIsDisplayed()
        rule.onNodeWithText("Decline: White wins 1 point.").assertIsDisplayed()
        listOf("New match", "Next game", "Resign", "Agree draw", "Offer double").forEach {
            rule.onNodeWithText(it).assertDoesNotExist()
        }
        board.relaunch()
        board.awaitText("Black, answer the double")
        assertBottomLeft("h8", topRight = "a1")
    }

    @Test
    fun c8_takingReturnsTheBoardToTheOffererAtTwiceTheStake_andGivesTheTakerTheRight() {
        board.launch()
        board.awaitText("White to move")
        offer()
        board.awaitText("Black, answer the double")

        board.tapText("Take")

        board.awaitText("White to move")
        assertBottomLeft("a1", topRight = "h8")
        stake().assertTextEquals("Stake: 2 points", "Only Black can offer")
        offerDouble().assertIsNotEnabled()
        board.tap("e2", "e4")
        board.awaitText("Black to move")
        offerDouble().assertIsEnabled()
        board.relaunch()
        board.awaitText("Black to move")
        stake().assertTextEquals("Stake: 2 points", "Only Black can offer")
    }

    @Test
    fun c9_decliningEndsTheGameForTheOffererAtTheOldStake() {
        board.launch()
        board.awaitText("White to move")
        offer()
        board.awaitText("Black, answer the double")

        board.tapText("Decline")

        board.awaitText("White wins · Double declined")
        status().assertTextEquals("White wins · Double declined", "White earns 1 point.")
        board.assertSquare("e2", "e2, White pawn")
        board.square("e2").assertIsNotEnabled()
        rule.onNodeWithText("Offer double").assertDoesNotExist()
        board.relaunch()
        board.awaitText("White earns 1 point.")
    }

    @Test
    fun c9_aWinAfterATakeIsAwardedTheDoubledStake() {
        board.gameFile.writeText("cute-game 2\n$OPENING\nplaying\n2\nWhite\nanswered\n")
        board.launch()
        board.awaitText("White to move")

        board.tapText("Resign")
        board.tapText("Confirm")

        board.awaitText("Black wins · Resignation")
        status().assertTextEquals("Black wins · Resignation", "Black earns 2 points.")
    }

    @Test
    fun c9_aDrawSplitsTheStake_includingHalfAPointEachAtOnePoint() {
        board.launch()
        board.awaitText("White to move")

        board.tapText("Agree draw")
        board.tapText("Confirm")

        board.awaitText("Draw · Agreement")
        status().assertTextEquals("Draw · Agreement", "Each player earns ½ point.")
        status().assert(
            SemanticsMatcher.expectValue(
                SemanticsProperties.ContentDescription,
                listOf("Draw · Agreement. Each player earns half a point.")
            )
        )

        board.gameFile.writeText("cute-game 2\n$OPENING\nplaying\n4\nWhite\nanswered\n")
        board.relaunch()
        board.awaitText("White to move")
        board.tapText("Agree draw")
        board.tapText("Confirm")
        board.awaitText("Each player earns 2 points.")
    }

    @Test
    fun c9_aFinishedGameSavedBeforeTheCubeShowsItsResultWithoutAnAward() {
        board.gameFile.writeText("cute-game 1\n$AFTER_E4\nBlack Resignation\n")
        board.launch()

        board.awaitText("Black wins · Resignation")
        status().assertTextEquals("Black wins · Resignation")
        rule.onNodeWithTag("stake").assertDoesNotExist()
    }

    @Test
    fun c5_anOfferOrAnAnswerThatCantBeSavedIsReported_andRetrySavesIt() {
        board.launch()
        board.awaitText("White to move")
        board.folder.setWritable(false)

        offer()
        board.awaitText("Change not saved.")
        status().assertTextEquals("White to move")
        offerDouble().assertIsEnabled()

        board.folder.setWritable(true)
        board.tapText("Retry")
        board.awaitText("Black, answer the double")
        board.folder.setWritable(false)

        board.tapText("Take")
        board.awaitText("Change not saved.")
        status().assertTextEquals("Black, answer the double")
        rule.onNodeWithText("Take: play for 2 points.").assertIsDisplayed()

        board.folder.setWritable(true)
        board.tapText("Retry")
        board.awaitText("White to move")
        board.relaunch()
        board.awaitText("Stake: 2 points")
    }

    private fun offer() {
        offerDouble().performScrollTo()
        board.tapText("Offer double")
    }

    /** Black, to move after 1.e4, has offered: White answers, with White's pieces at the bottom. */
    private fun assertAwaitingWhite() {
        board.awaitText("White, answer the double")
        assertBottomLeft("a1", topRight = "h8")
        board.assertSquare("e4", "e4, White pawn")
        board.square("e7").assertIsNotEnabled()
        rule.onNodeWithText("Take: play for 2 points.").assertIsDisplayed()
        rule.onNodeWithText("Decline: Black wins 1 point.").assertIsDisplayed()
        rule.onNodeWithText("Take").assertIsEnabled()
        rule.onNodeWithText("Decline").assertIsEnabled()
    }

    private fun status() = rule.onNodeWithTag("status")

    private fun stake() = rule.onNodeWithTag("stake")

    private fun offerDouble() = rule.onNodeWithText("Offer double")

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
