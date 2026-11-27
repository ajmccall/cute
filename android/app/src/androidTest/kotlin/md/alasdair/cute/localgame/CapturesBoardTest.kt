package md.alasdair.cute.localgame

import androidx.activity.ComponentActivity
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.test.SemanticsNodeInteraction
import androidx.compose.ui.test.assertContentDescriptionEquals
import androidx.compose.ui.test.assertIsDisplayed
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
 * Each player's captures and the material advantage on the running board (C16, C17), with
 * accessibility checks on every action (BoardHarness.enableAccessibilityChecks). Games with
 * captures are seeded as version-4 files: after the match totals, White's and then Black's
 * captures as piece letters in the order taken, or `none`.
 */
@RunWith(AndroidJUnit4::class)
class CapturesBoardTest {
    @get:Rule val rule = createAndroidComposeRule<ComponentActivity>()

    private val board = BoardHarness(rule)

    @Before
    fun checkAccessibility() = board.enableAccessibilityChecks()

    @After
    fun cleanUp() = board.cleanUp()

    @Test
    fun c16_eachPlayersCapturesSitAtTheirEdge_andTurnWithTheBoard_includingADoubleResponse() {
        board.launch()
        board.awaitText("White to move")
        captures("White").assertContentDescriptionEquals("Captured by White: none")
        captures("Black").assertContentDescriptionEquals("Captured by Black: none")
        assertAtBottom("White")

        board.tap("e2", "e4")
        board.awaitText("Black to move")
        board.tap("d7", "d5")
        board.awaitText("White to move")
        board.tap("e4", "d5")
        board.awaitText("Black to move")

        captures("White").assertContentDescriptionEquals("Captured by White: 1 pawn")
        captures("Black").assertContentDescriptionEquals("Captured by Black: none")
        assertAtBottom("Black")

        rule.onNodeWithText("Offer double").performScrollTo()
        board.tapText("Offer double")
        board.awaitText("White, answer the double")
        captures("White").assertContentDescriptionEquals("Captured by White: 1 pawn")
        assertAtBottom("White")

        board.tapText("Decline")
        board.awaitText("Black wins · Double declined")
        captures("White").assertContentDescriptionEquals("Captured by White: 1 pawn")
        captures("Black").assertContentDescriptionEquals("Captured by Black: none")
        advantage("White").assertTextEquals("+1")

        board.relaunch()
        board.awaitText("Black wins · Double declined")
        captures("White").assertContentDescriptionEquals("Captured by White: 1 pawn")
        advantage("White").assertTextEquals("+1")
    }

    @Test
    fun c16_capturesAreGroupedByKind_andAnnouncedByColourKindAndCount() {
        board.saveWithCaptures(SPARSE, white = "qpnpb", black = "r")
        board.launch()
        board.awaitText("White to move")

        captures("White").assertContentDescriptionEquals(
            "Captured by White: 2 pawns, 1 knight, 1 bishop, 1 queen"
        )
        captures("Black").assertContentDescriptionEquals("Captured by Black: 1 rook")
    }

    @Test
    fun c17_plusNShowsBesideTheLeader_announcedWithoutPoints_andNotWhenEqual() {
        board.launch()
        board.awaitText("White to move")
        assertNoAdvantage()

        board.tap("e2", "e4")
        board.awaitText("Black to move")
        board.tap("d7", "d5")
        board.awaitText("White to move")
        board.tap("e4", "d5")
        board.awaitText("Black to move")

        advantage("White").assertTextEquals("+1")
        advantage("White").assertContentDescriptionEquals("White ahead by 1 in material")
        advantage("Black").assertDoesNotExist()
        assertBeside(advantage("White"), captures("White"))

        board.tap("d8", "d5")
        board.awaitText("White to move")
        captures("Black").assertContentDescriptionEquals("Captured by Black: 1 pawn")
        assertNoAdvantage()
    }

    @Test
    fun c17_aPromotionChangesTheBalanceOnceCommitted_withoutACapture() {
        board.seed(PROMOTION)
        board.launch()
        board.awaitText("White to move")
        advantage("Black").assertTextEquals("+4")
        assertBeside(advantage("Black"), captures("Black"))

        board.tap("b7", "b8")
        rule.onNodeWithText("Promote pawn").assertIsDisplayed()
        advantage("Black").assertTextEquals("+4")
        captures("White").assertContentDescriptionEquals("Captured by White: none")
        captures("Black").assertContentDescriptionEquals("Captured by Black: none")
        board.tapText("Queen")

        board.awaitText("Black to move · Check")
        advantage("White").assertTextEquals("+4")
        advantage("White").assertContentDescriptionEquals("White ahead by 4 in material")
        advantage("Black").assertDoesNotExist()
        captures("White").assertContentDescriptionEquals("Captured by White: none")
        captures("Black").assertContentDescriptionEquals("Captured by Black: none")

        board.tap("a8", "b8")
        board.awaitText("White to move")
        captures("Black").assertContentDescriptionEquals("Captured by Black: 1 queen")
        advantage("Black").assertTextEquals("+5")
    }

    @Test
    fun c16_c17_showInMatchOver_andNextGameStartsWithNone() {
        board.saveWithCaptures(
            SPARSE,
            white = "pp",
            black = "none",
            whiteHalves = 4,
            blackHalves = 26
        )
        board.launch()
        board.awaitText("White to move")

        board.tapText("Agree draw")
        board.tapText("Confirm")
        board.awaitText("Draw · Agreement")
        captures("White").assertContentDescriptionEquals("Captured by White: 2 pawns")
        advantage("White").assertTextEquals("+1")

        board.tapText("Next game")
        board.awaitText("White to move")
        captures("White").assertContentDescriptionEquals("Captured by White: none")
        captures("Black").assertContentDescriptionEquals("Captured by Black: none")
        assertNoAdvantage()

        board.saveWithCaptures(SPARSE, white = "pp", black = "n", whiteHalves = 4, blackHalves = 28)
        board.relaunch()
        board.awaitText("White to move")
        board.tapText("Resign")
        board.tapText("Confirm")
        board.awaitText("Black wins the match, 15 to 2")
        captures("White").assertContentDescriptionEquals("Captured by White: 2 pawns")
        captures("Black").assertContentDescriptionEquals("Captured by Black: 1 knight")
        advantage("White").assertTextEquals("+1")
    }

    @Test
    fun interaction_enPassantCaptureSurvivesFailedSaveRetryAndRelaunch() {
        board.seed("4k3/8/8/8/3Pp3/8/8/4K3 b - d3 0 1")
        board.launch()
        board.awaitText("Black to move")
        board.folder.setWritable(false)
        board.tap("e4", "d3")
        board.awaitText("Change not saved.")
        captures("Black").assertContentDescriptionEquals("Captured by Black: none")
        board.assertSquare("d4", "d4, White pawn")
        board.folder.setWritable(true)
        board.tapText("Retry")
        board.awaitText("White to move")
        captures("Black").assertContentDescriptionEquals("Captured by Black: 1 pawn")
        advantage("Black").assertTextEquals("+1")
        board.relaunch()
        board.awaitText("White to move")
        captures("Black").assertContentDescriptionEquals("Captured by Black: 1 pawn")
        board.assertSquare("d4", "d4, Empty")
    }

    private fun captures(side: String) = rule.onNodeWithTag("captures-$side")

    private fun advantage(side: String) = rule.onNodeWithTag("advantage-$side")

    private fun assertNoAdvantage() {
        advantage("White").assertDoesNotExist()
        advantage("Black").assertDoesNotExist()
    }

    /** [side]'s captures are below the board, and the other side's above it. */
    private fun assertAtBottom(side: String) {
        val other = if (side == "White") "Black" else "White"
        val board = bounds(rule.onNodeWithTag("board"))
        assertTrue("$side's captures below the board", bounds(captures(side)).top >= board.bottom)
        assertTrue("$other's captures above the board", bounds(captures(other)).bottom <= board.top)
    }

    /** [advantage] is on the same line as [captures], after it. */
    private fun assertBeside(
        advantage: SemanticsNodeInteraction,
        captures: SemanticsNodeInteraction
    ) {
        val plus = bounds(advantage)
        val row = bounds(captures)
        assertTrue("beside the captures", plus.center.y > row.top && plus.center.y < row.bottom)
        assertTrue("after the captures", plus.left >= row.right)
    }

    private fun bounds(node: SemanticsNodeInteraction): Rect =
        node.fetchSemanticsNode().boundsInRoot

    /** Writes a version-4 save of a game in play at [fen], with each side's captures. */
    companion object {
        /** White's pawn on b7 can promote; Black's rook on a8 is 4 ahead of it. */
        const val PROMOTION = "r3k3/1P6/8/8/8/8/8/4K3 w - - 0 1"

        /** White's king and pawn against Black's king: White is 1 ahead. */
        const val SPARSE = "4k3/8/8/8/8/8/4P3/4K3 w - - 0 1"
    }
}
