package md.alasdair.cute.localgame

import androidx.activity.ComponentActivity
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.assertIsNotEnabled
import androidx.compose.ui.test.assertTextEquals
import androidx.compose.ui.test.junit4.accessibility.enableAccessibilityChecks
import androidx.compose.ui.test.junit4.v2.createAndroidComposeRule
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.onNodeWithText
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.google.android.apps.common.testing.accessibility.framework.AccessibilityCheckResultUtils.matchesCheck
import com.google.android.apps.common.testing.accessibility.framework.checks.TouchTargetSizeCheck
import com.google.android.apps.common.testing.accessibility.framework.integrations.espresso.AccessibilityValidator
import org.junit.After
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/**
 * The interaction checks in docs/testing.md, one or more per local-game criterion, on the
 * running board. Accessibility checks run on every action. The board's squares are exempt from
 * the touch-target check only: on a phone narrower than 384 dp each square is an eighth of the
 * width, below 48 dp, which the product owner approved for the board (#6, decision 1a).
 */
@RunWith(AndroidJUnit4::class)
class LocalGameBoardTest {
    @get:Rule val rule = createAndroidComposeRule<ComponentActivity>()

    private val board = BoardHarness(rule)

    @Before
    fun checkAccessibility() {
        rule.enableAccessibilityChecks(
            AccessibilityValidator()
                .setRunChecksFromRootView(true)
                .setSuppressingResultMatcher(matchesCheck(TouchTargetSizeCheck::class.java))
        )
    }

    @After
    fun cleanUp() = board.cleanUp()

    @Test
    fun c1_openingShowsWhiteAtTheBottomToMove_andReopeningRestoresTheGame() {
        board.launch()
        board.awaitText("White to move")

        board.assertSquare("e2", "e2, White pawn")
        board.assertSquare("e4", "e4, Empty")
        board.assertSquare("d8", "d8, Black queen")
        assertBottomLeft("a1", topRight = "h8")

        board.tap("g1", "f3")
        board.awaitText("Black to move")
        board.relaunch()
        board.awaitText("Black to move")

        board.assertSquare("f3", "f3, White knight")
        board.assertSquare("g1", "g1, Empty")
        board.tap("b8")
        board.assertSquare("c6", "c6, Empty", "Legal destination")
        board.assertSquare("a6", "a6, Empty", "Legal destination")
        board.tap("c6")
        board.awaitText("White to move")
        board.assertSquare("c6", "c6, Black knight")
    }

    @Test
    fun c2_selectReselectIllegalThenLegalMove() {
        board.launch()
        board.awaitText("White to move")

        board.tap("e2")
        board.assertSquare("e2", "e2, White pawn", "Selected")
        board.assertSquare("e3", "e3, Empty", "Legal destination")
        board.assertSquare("e4", "e4, Empty", "Legal destination")
        board.assertSquare("e5", "e5, Empty")

        board.tap("g1")
        board.assertSquare("e2", "e2, White pawn")
        board.assertSquare("e3", "e3, Empty")
        board.assertSquare("g1", "g1, White knight", "Selected")
        board.assertSquare("f3", "f3, Empty", "Legal destination")
        board.assertSquare("h3", "h3, Empty", "Legal destination")

        board.tap("g3")
        status().assertTextEquals("White to move")
        board.assertSquare("g1", "g1, White knight", "Selected")
        board.assertSquare("g3", "g3, Empty")

        board.tap("f3")
        board.awaitText("Black to move")
        board.assertSquare("f3", "f3, White knight")
    }

    @Test
    fun c2_castlingAndEnPassantAreOfferedAndPlayed() {
        board.seed("r3k2r/8/8/8/3Pp3/8/8/R3K2R b KQkq d3 0 1")
        board.launch()
        board.awaitText("Black to move")

        board.tap("e4")
        board.assertSquare("d3", "d3, Empty", "Legal destination")
        board.tap("d3")
        board.awaitText("White to move")
        board.assertSquare("d4", "d4, Empty")
        board.assertSquare("d3", "d3, Black pawn")

        board.tap("e1")
        board.assertSquare("g1", "g1, Empty", "Legal destination")
        board.assertSquare("c1", "c1, Empty", "Legal destination")
        board.tap("g1")
        board.awaitText("Black to move")
        board.assertSquare("g1", "g1, White king")
        board.assertSquare("f1", "f1, White rook")
    }

    @Test
    fun c2_promotionNeedsAChoiceAndCancelChangesNothing() {
        board.seed("4k3/1P5p/8/8/8/8/8/4K3 w - - 0 1")
        board.launch()
        board.awaitText("White to move")

        board.tap("b7", "b8")
        rule.onNodeWithText("Promote pawn").assertIsDisplayed()
        board.tapText("Cancel")
        status().assertTextEquals("White to move")
        board.assertSquare("b7", "b7, White pawn", "Selected")
        board.assertSquare("b8", "b8, Empty", "Legal destination")

        board.tap("b8")
        listOf("Queen", "Rook", "Bishop").forEach { rule.onNodeWithText(it).assertIsDisplayed() }
        board.tapText("Knight")
        board.awaitText("Black to move")
        board.assertSquare("b8", "b8, White knight")
    }

    @Test
    fun c3_theNextPlayersPiecesComeToTheBottomAndCheckIsNamed() {
        board.seed("4k3/8/8/8/8/8/8/4K2R w K - 0 1")
        board.launch()
        board.awaitText("White to move")
        assertBottomLeft("a1", topRight = "h8")

        board.tap("h1", "h8")
        board.awaitText("Black to move · Check")

        assertBottomLeft("h8", topRight = "a1")
        rule.onNodeWithText("Confirm").assertDoesNotExist()
        board.tap("e8")
        board.assertSquare("e7", "e7, Empty", "Legal destination")
        board.tap("e7")
        board.awaitText("White to move")
    }

    @Test
    fun c4_foolsMateEndsAndFreezesTheBoard_thenNewGameStartsAtOnce() {
        board.launch()
        board.awaitText("White to move")

        listOf("f2" to "f3", "e7" to "e5", "g2" to "g4").forEachIndexed { i, (from, to) ->
            board.tap(from, to)
            board.awaitText(if (i % 2 == 0) "Black to move" else "White to move")
        }
        board.tap("d8", "h4")
        board.awaitText("Black wins · Checkmate")

        board.square("e1").assertIsNotEnabled()
        board.assertSquare("h4", "h4, Black queen")
        rule.onNodeWithText("Resign").assertDoesNotExist()
        rule.onNodeWithText("Agree draw").assertDoesNotExist()
        board.relaunch()
        board.awaitText("Black wins · Checkmate")

        board.tapText("New game")
        board.awaitText("White to move")
        rule.onNodeWithText("Replace this game?").assertDoesNotExist()
        board.assertSquare("e2", "e2, White pawn")
    }

    @Test
    fun c4_stalemateAndInsufficientMaterialEndTheGame() {
        board.seed("7k/8/6K1/8/8/8/8/5Q2 w - - 0 1")
        board.launch()
        board.awaitText("White to move")

        board.tap("f1", "f7")
        board.awaitText("Draw · Stalemate")

        board.seed("4k3/8/8/8/8/8/3p4/4K1B1 w - - 0 1")
        board.relaunch()
        board.awaitText("White to move · Check")
        board.tap("e1", "d2")
        board.awaitText("Draw · Insufficient material")
    }

    @Test
    fun c4_twoKnightsAgainstAKingPlaysOn() {
        board.seed("4k3/8/8/8/8/8/3p4/4K1NN w - - 0 1")
        board.launch()
        board.awaitText("White to move · Check")

        board.tap("e1", "d2")

        board.awaitText("Black to move")
    }

    @Test
    fun c4_resignationIsConfirmedOrCancelled() {
        board.launch()
        board.awaitText("White to move")

        board.tapText("Resign")
        rule.onNodeWithText("Resign as White?").assertIsDisplayed()
        board.tapText("Cancel")
        status().assertTextEquals("White to move")

        board.tapText("Resign")
        board.tapText("Confirm")
        board.awaitText("Black wins · Resignation")
    }

    @Test
    fun c4_agreedDrawIsConfirmedOrCancelled() {
        board.launch()
        board.awaitText("White to move")

        board.tapText("Agree draw")
        rule.onNodeWithText("Do both players agree to a draw?").assertIsDisplayed()
        board.tapText("Cancel")
        status().assertTextEquals("White to move")

        board.tapText("Agree draw")
        board.tapText("Confirm")
        board.awaitText("Draw · Agreement")
    }

    @Test
    fun c4_replacingAnOngoingGameAsksFirst() {
        board.launch()
        board.awaitText("White to move")
        board.tap("e2", "e4")
        board.awaitText("Black to move")

        board.tapText("New game")
        rule.onNodeWithText("Replace this game?").assertIsDisplayed()
        board.tapText("Cancel")
        status().assertTextEquals("Black to move")
        board.assertSquare("e4", "e4, White pawn")

        board.tapText("New game")
        board.tapText("Confirm")
        board.awaitText("White to move")
        board.assertSquare("e2", "e2, White pawn")
        board.assertSquare("e4", "e4, Empty")
    }

    @Test
    fun c5_anUnreadableGameIsReportedWithoutAFreshBoard_andRetryOpensIt() {
        board.seed("rnbqkbnr/pppp1ppp/8/4p3/4P3/8/PPPP1PPP/RNBQKBNR w KQkq e6 0 2")
        val saved = board.gameFile.readText()
        board.gameFile.writeText("damaged")
        board.launch()

        board.awaitText("Couldn’t open the saved game.")
        rule.onNodeWithTag("board").assertDoesNotExist()
        assertTrue(board.gameFile.readText() == "damaged")

        board.gameFile.writeText(saved)
        board.tapText("Retry")
        board.awaitText("White to move")
        board.assertSquare("e4", "e4, White pawn")
        board.assertSquare("e5", "e5, Black pawn")
    }

    @Test
    fun c5_aMoveThatCantBeSavedIsReportedAndNotShown_andRetrySavesIt() {
        board.launch()
        board.awaitText("White to move")
        board.folder.setWritable(false)

        board.tap("e2", "e4")
        board.awaitText("Change not saved.")
        status().assertTextEquals("White to move")
        board.assertSquare("e2", "e2, White pawn")
        board.assertSquare("e4", "e4, Empty")

        board.folder.setWritable(true)
        board.tapText("Retry")
        board.awaitText("Black to move")
        rule.onNodeWithText("Change not saved.").assertDoesNotExist()
        board.relaunch()
        board.awaitText("Black to move")
        board.assertSquare("e4", "e4, White pawn")
    }

    private fun status() = rule.onNodeWithTag("status")

    private fun assertBottomLeft(bottomLeft: String, topRight: String) {
        val low = board.square(bottomLeft).fetchSemanticsNode().boundsInRoot
        val high = board.square(topRight).fetchSemanticsNode().boundsInRoot
        assertTrue("$bottomLeft is below $topRight", low.top > high.top)
        assertTrue("$bottomLeft is left of $topRight", low.left < high.left)
    }
}
