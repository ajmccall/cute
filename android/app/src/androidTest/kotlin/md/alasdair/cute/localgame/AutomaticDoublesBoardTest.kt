package md.alasdair.cute.localgame

import androidx.activity.ComponentActivity
import androidx.compose.ui.test.assertIsEnabled
import androidx.compose.ui.test.assertIsNotEnabled
import androidx.compose.ui.test.assertIsOff
import androidx.compose.ui.test.assertIsOn
import androidx.compose.ui.test.assertTextEquals
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.isOn
import androidx.compose.ui.test.junit4.v2.createAndroidComposeRule
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performScrollTo
import androidx.test.ext.junit.runners.AndroidJUnit4
import org.junit.After
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class AutomaticDoublesBoardTest {
    @get:Rule val rule = createAndroidComposeRule<ComponentActivity>()
    private val board = BoardHarness(rule)

    @Before fun checkAccessibility() = board.enableAccessibilityChecks()

    @After fun cleanUp() = board.cleanUp()

    @Test fun failedFirstAnswerReopensAtTheFirstPrompt() {
        board.seed("4k3/8/8/8/8/8/4P3/4K2R w K - 0 1")
        board.launch()
        board.awaitText("White to move")
        rule.onNodeWithText("Automatic doubles").performScrollTo().performClick()
        awaitSwitchOn()
        board.tap("e2", "e4")
        board.awaitText("White, continue at 2 points?")
        board.folder.setWritable(false)
        try {
            rule.onNodeWithText("Continue").performScrollTo().performClick()
            board.awaitText("Change not saved.")
            board.relaunch()
            board.awaitText("White, continue at 2 points?")
        } finally {
            board.folder.setWritable(true)
        }
    }

    @Test fun stoppedFirstAnswerSurvivesReopeningWithoutBeingRevealed() {
        board.seed("4k3/8/8/8/8/8/4P3/4K2R w K - 0 1")
        board.launch()
        board.awaitText("White to move")
        rule.onNodeWithText("Automatic doubles").performScrollTo().performClick()
        awaitSwitchOn()
        board.tap("e2", "e4")
        board.awaitText("White, continue at 2 points?")
        rule.onNodeWithText("Automatic doubles").assertDoesNotExist()
        rule.onNodeWithText("Stop").performScrollTo().performClick()
        board.awaitText("Black, continue at 2 points?")
        board.relaunch()
        board.awaitText("Black, continue at 2 points?")
        rule.onNodeWithText("White stopped").assertDoesNotExist()
        rule.onNodeWithText("Continue").performScrollTo().performClick()
        board.awaitText("Black wins · Opponent stopped at automatic double")
        rule.onNodeWithTag("status").assertTextEquals(
            "Black wins · Opponent stopped at automatic double",
            "Black earns 1 point."
        )
        rule.onNodeWithTag("matchScore").assertTextEquals(
            "White 0 points · Black 1 point · first to 15 points"
        )
        board.relaunch()
        board.awaitText("Black wins · Opponent stopped at automatic double")
        rule.onNodeWithText("Automatic doubles").performScrollTo().performClick()
        rule.onNodeWithTag("matchScore").assertTextEquals(
            "White 0 points · Black 1 point · first to 15 points"
        )
        board.relaunch()
        board.awaitText("Black wins · Opponent stopped at automatic double")
        rule.onNodeWithTag("matchScore").assertTextEquals(
            "White 0 points · Black 1 point · first to 15 points"
        )
    }

    @Test fun bothStopAtFourteenAllDrawsTheMatchAndSurvivesReopening() {
        board.gameFile.writeText(
            "cute-game 4\n4k3/8/8/8/8/8/4P3/4K2R w K - 0 1\n" +
                "playing\n2\nWhite\nanswered\n28\n28\nnone\nnone\n"
        )
        board.launch()
        board.awaitText("White to move")
        rule.onNodeWithText("Automatic doubles").performScrollTo().performClick()
        awaitSwitchOn()
        board.tap("e2", "e4")
        board.awaitText("White, continue at 4 points?")
        rule.onNodeWithText("Stop").performScrollTo().performClick()
        board.awaitText("Black, continue at 4 points?")
        rule.onNodeWithText("Stop").performScrollTo().performClick()
        board.awaitText("Match drawn, 15 to 15")
        rule.onNodeWithTag("status").assertTextEquals(
            "Draw · Both stopped at automatic double",
            "Each player earns 1 point.",
            "Match drawn, 15 to 15"
        )
        rule.onNodeWithTag("matchScore").assertTextEquals(
            "White 15 points · Black 15 points · first to 15 points"
        )
        board.relaunch()
        board.awaitText("Match drawn, 15 to 15")
    }

    @Test fun qualifyingMoveAtCapDoesNotPrompt() {
        board.gameFile.writeText(
            "cute-game 4\n4k3/8/8/8/8/8/4P3/4K2R w K - 0 1\n" +
                "playing\n64\nBlack\nanswered\n0\n0\nnone\nnone\n"
        )
        board.launch()
        board.awaitText("White to move")
        rule.onNodeWithText("Automatic doubles").performScrollTo().performClick()
        awaitSwitchOn()
        board.tap("e2", "e4")
        board.awaitText("Black to move")
        board.awaitText("Stake: 64 points")
        rule.onNodeWithText("Continue").assertDoesNotExist()
        board.relaunch()
        board.awaitText("Black to move")
        rule.onNodeWithText("Continue").assertDoesNotExist()
    }

    @Test fun automaticDoubleAtThirtyTwoReachesCapAndPersists() {
        board.gameFile.writeText(
            "cute-game 4\n4k3/8/8/8/8/8/4P3/4K2R w K - 0 1\n" +
                "playing\n32\nBlack\nanswered\n0\n0\nnone\nnone\n"
        )
        board.launch()
        board.awaitText("White to move")
        rule.onNodeWithText("Automatic doubles").performScrollTo().performClick()
        awaitSwitchOn()
        board.tap("e2", "e4")
        board.awaitText("White, continue at 64 points?")
        rule.onNodeWithText("Continue").performScrollTo().performClick()
        board.awaitText("Black, continue at 64 points?")
        rule.onNodeWithText("Continue").performScrollTo().performClick()
        board.awaitText("Black to move")
        board.awaitText("Stake: 64 points")
        board.relaunch()
        board.awaitText("Stake: 64 points")
        board.tap("e8", "d7")
        board.awaitText("White to move")
        rule.onNodeWithText("White, continue at 128 points?").assertDoesNotExist()
    }

    @Test fun failedResolutionReopensAtSecondAnswerWithoutAward() {
        board.seed("4k3/8/8/8/8/8/4P3/4K2R w K - 0 1")
        board.launch()
        board.awaitText("White to move")
        rule.onNodeWithText("Automatic doubles").performScrollTo().performClick()
        awaitSwitchOn()
        board.tap("e2", "e4")
        board.awaitText("White, continue at 2 points?")
        rule.onNodeWithText("Continue").performScrollTo().performClick()
        board.awaitText("Black, continue at 2 points?")
        board.folder.setWritable(false)
        try {
            rule.onNodeWithText("Stop").performScrollTo().performClick()
            board.awaitText("Change not saved.")
            board.relaunch()
            board.awaitText("Black, continue at 2 points?")
            rule.onNodeWithText("White wins · Opponent stopped at automatic double")
                .assertDoesNotExist()
        } finally {
            board.folder.setWritable(true)
        }
        rule.onNodeWithText("Stop").performScrollTo().performClick()
        board.awaitText("White wins · Opponent stopped at automatic double")
        rule.onNodeWithTag("status").assertTextEquals(
            "White wins · Opponent stopped at automatic double",
            "White earns 1 point."
        )
        rule.onNodeWithTag("matchScore").assertTextEquals(
            "White 1 point · Black 0 points · first to 15 points"
        )
        board.relaunch()
        board.awaitText("White wins · Opponent stopped at automatic double")
    }

    @Test fun failedTriggeringMoveReopensTheLastCommittedPosition() {
        board.seed("4k3/8/8/8/8/8/4P3/4K2R w K - 0 1")
        board.launch()
        board.awaitText("White to move")
        rule.onNodeWithText("Automatic doubles").performScrollTo().performClick()
        awaitSwitchOn()
        board.folder.setWritable(false)
        try {
            board.tap("e2", "e4")
            board.awaitText("Change not saved.")
            board.assertSquare("e2", "e2, White pawn")
            board.relaunch()
            board.awaitText("White to move")
            board.assertSquare("e2", "e2, White pawn")
            rule.onNodeWithText("White, continue at 2 points?").assertDoesNotExist()
        } finally {
            board.folder.setWritable(true)
        }
    }

    @Test fun movePromptsBothPlayersAndResumesAtTwiceTheStake() {
        board.seed("4k3/8/8/8/8/8/4P3/4K2R w K - 0 1")
        board.launch()
        board.awaitText("White to move")
        rule.onNodeWithText("Automatic doubles").performScrollTo().performClick()
        awaitSwitchOn()
        board.tap("e2", "e4")
        board.awaitText("White, continue at 2 points?")
        assertAutomaticExplanation()
        assertTrue(
            board.square("a1").fetchSemanticsNode().boundsInRoot.top >
                board.square("h8").fetchSemanticsNode().boundsInRoot.top
        )
        board.square("e4").assertIsNotEnabled()
        listOf("New match", "Offer double", "Resign", "Agree draw", "Automatic doubles")
            .forEach { rule.onNodeWithText(it).assertDoesNotExist() }
        rule.onNodeWithText("Continue").performScrollTo().performClick()
        board.awaitText("Black, continue at 2 points?")
        assertAutomaticExplanation()
        assertTrue(
            board.square("h8").fetchSemanticsNode().boundsInRoot.top >
                board.square("a1").fetchSemanticsNode().boundsInRoot.top
        )
        board.square("e4").assertIsNotEnabled()
        rule.onNodeWithText("Continue").performScrollTo().performClick()
        board.awaitText("Black to move")
        board.assertSquare("e4", "e4, White pawn")
        board.awaitText("Stake: 2 points")
        board.relaunch()
        board.awaitText("Black to move")
        board.tap("e8", "d7")
        board.awaitText("White to move")
        rule.onNodeWithText("Continue").assertDoesNotExist()
    }

    @Test fun switchStartsOffAndSurvivesReopening() {
        board.launch()
        board.awaitText("White to move")
        rule.onNodeWithText("Automatic doubles").performScrollTo().assertIsOff().performClick()
        awaitSwitchOn()
        board.relaunch()
        board.awaitText("White to move")
        rule.onNodeWithText("Automatic doubles").performScrollTo().assertIsOn()
    }

    @Test fun voluntaryTakeWhileOffThenEnableChecksOnlyTheNextMoveAndKeepsRight() {
        board.seed("4k3/8/8/8/8/8/4P3/4K2R w K - 0 1")
        board.launch()
        board.awaitText("White to move")
        rule.onNodeWithText("Offer double").performScrollTo().performClick()
        board.awaitText("Black, answer the double")
        rule.onNodeWithText("Take").performScrollTo().performClick()
        board.awaitText("White to move")
        board.tap("e2", "e4")
        board.awaitText("Black to move")
        rule.onNodeWithText("Continue").assertDoesNotExist()
        rule.onNodeWithText("Automatic doubles").performScrollTo().performClick()
        awaitSwitchOn()
        rule.onNodeWithText("Continue").assertDoesNotExist()
        board.tap("e8", "d7")
        board.awaitText("Black, continue at 4 points?")
        board.relaunch()
        board.awaitText("Black, continue at 4 points?")
        rule.onNodeWithText("Continue").performScrollTo().performClick()
        board.awaitText("White, continue at 4 points?")
        rule.onNodeWithText("Continue").performScrollTo().performClick()
        board.awaitText("White to move")
        rule.onNodeWithTag("stake").assertTextEquals("Stake: 4 points", "Only Black can offer")
        rule.onNodeWithText("Offer double").performScrollTo().assertIsNotEnabled()
        rule.onNodeWithText("Automatic doubles").performScrollTo().performClick()
        rule.onNodeWithTag("stake").assertTextEquals("Stake: 4 points", "Only Black can offer")
        board.tap("e1", "d1")
        board.awaitText("Black to move")
        rule.onNodeWithText("Offer double").performScrollTo().assertIsEnabled()
        board.relaunch()
        board.awaitText("Black to move")
        rule.onNodeWithTag("stake").assertTextEquals("Stake: 4 points", "Only Black can offer")
    }

    @Test fun openingMilestoneTriggersOnceAtSixClearedSquares() {
        board.seed("r1bqkb1r/pppppppp/2n2n2/8/2B5/2N2N2/PPPPPPPP/R2QKB1R w KQkq - 0 1")
        board.launch()
        board.awaitText("White to move")
        rule.onNodeWithText("Automatic doubles").performScrollTo().performClick()
        awaitSwitchOn()
        board.tap("e2", "e4")
        board.awaitText("Black to move")
        rule.onNodeWithText("Continue").assertDoesNotExist()
        board.tap("e7", "e5")
        board.awaitText("White to move")
        board.tap("f1", "e2")
        board.awaitText("White, continue at 2 points?")
        rule.onNodeWithText("Continue").performScrollTo().performClick()
        board.awaitText("Black, continue at 2 points?")
        rule.onNodeWithText("Continue").performScrollTo().performClick()
        board.awaitText("Black to move")
        board.relaunch()
        board.awaitText("Black to move")
        board.tap("g7", "g6")
        board.awaitText("White to move")
        rule.onNodeWithText("Continue").assertDoesNotExist()
    }

    @Test fun promotionIsUncommittedUntilChoiceAndThenTriggers() {
        board.seed("4k3/1P5p/8/8/8/8/8/4K3 w - - 0 1")
        board.launch()
        board.awaitText("White to move")
        rule.onNodeWithText("Automatic doubles").performScrollTo().performClick()
        awaitSwitchOn()
        board.tap("b7", "b8")
        board.tapText("Cancel")
        board.assertSquare("b7", "b7, White pawn", "Selected")
        rule.onNodeWithText("Continue").assertDoesNotExist()
        board.tap("b8")
        board.tapText("Rook")
        board.awaitText("White, continue at 2 points?")
        board.assertSquare("b8", "b8, White rook")
        board.relaunch()
        board.awaitText("White, continue at 2 points?")
        board.assertSquare("b8", "b8, White rook")
    }

    @Test fun promotedPieceCountsUntilCapturedAtEndgameThreshold() {
        board.gameFile.writeText(
            "cute-game 5\nr3k2r/1P6/8/8/8/8/8/R3K2R w KQkq - 0 1\n" +
                "playing\n1\nEither\nanswered\n0\n0\nnone\nnone\nfalse\ntrue\nnone\n"
        )
        board.launch()
        board.awaitText("White to move")
        rule.onNodeWithText("Automatic doubles").performScrollTo().performClick()
        awaitSwitchOn()
        board.tap("b7", "b8")
        board.tapText("Knight")
        board.awaitText("Black to move")
        rule.onNodeWithText("Continue").assertDoesNotExist()
        board.tap("a8", "b8")
        board.awaitText("Black, continue at 2 points?")
        board.assertSquare("b8", "b8, Black rook")
        board.relaunch()
        board.awaitText("Black, continue at 2 points?")
    }

    @Test fun failedResolutionCanBeRetriedWithoutDuplicatingAward() {
        board.seed("4k3/8/8/8/8/8/4P3/4K2R w K - 0 1")
        board.launch()
        board.awaitText("White to move")
        rule.onNodeWithText("Automatic doubles").performScrollTo().performClick()
        awaitSwitchOn()
        board.tap("e2", "e4")
        board.awaitText("White, continue at 2 points?")
        rule.onNodeWithText("Continue").performScrollTo().performClick()
        board.awaitText("Black, continue at 2 points?")
        board.folder.setWritable(false)
        try {
            rule.onNodeWithText("Stop").performScrollTo().performClick()
            board.awaitText("Change not saved.")
            board.awaitText("Black, continue at 2 points?")
            rule.onNodeWithTag("matchScore").assertTextEquals(
                "White 0 points · Black 0 points · first to 15 points"
            )
        } finally {
            board.folder.setWritable(true)
        }
        rule.onNodeWithText("Retry").performScrollTo().performClick()
        board.awaitText("White wins · Opponent stopped at automatic double")
        rule.onNodeWithTag("matchScore").assertTextEquals(
            "White 1 point · Black 0 points · first to 15 points"
        )
        board.relaunch()
        board.awaitText("White wins · Opponent stopped at automatic double")
        rule.onNodeWithTag("matchScore").assertTextEquals(
            "White 1 point · Black 0 points · first to 15 points"
        )
    }

    @Test fun failedTriggeringMoveCanBeRetriedAsOneCommittedDecision() {
        board.seed("4k3/8/8/8/8/8/4P3/4K2R w K - 0 1")
        board.launch()
        board.awaitText("White to move")
        rule.onNodeWithText("Automatic doubles").performScrollTo().performClick()
        awaitSwitchOn()
        board.folder.setWritable(false)
        try {
            board.tap("e2", "e4")
            board.awaitText("Change not saved.")
            board.assertSquare("e2", "e2, White pawn")
            rule.onNodeWithText("Continue").assertDoesNotExist()
        } finally {
            board.folder.setWritable(true)
        }
        rule.onNodeWithText("Retry").performScrollTo().performClick()
        board.awaitText("White, continue at 2 points?")
        board.assertSquare("e4", "e4, White pawn")
        board.relaunch()
        board.awaitText("White, continue at 2 points?")
        board.assertSquare("e4", "e4, White pawn")
    }

    @Test fun failedFirstAnswerCanRetryAndSurviveReopening() {
        board.seed("4k3/8/8/8/8/8/4P3/4K2R w K - 0 1")
        board.launch()
        board.awaitText("White to move")
        rule.onNodeWithText("Automatic doubles").performScrollTo().performClick()
        awaitSwitchOn()
        board.tap("e2", "e4")
        board.awaitText("White, continue at 2 points?")
        board.folder.setWritable(false)
        try {
            rule.onNodeWithText("Stop").performScrollTo().performClick()
            board.awaitText("Change not saved.")
            board.awaitText("White, continue at 2 points?")
        } finally {
            board.folder.setWritable(true)
        }
        rule.onNodeWithText("Retry").performScrollTo().performClick()
        board.awaitText("Black, continue at 2 points?")
        board.relaunch()
        board.awaitText("Black, continue at 2 points?")
        rule.onNodeWithText("White stopped").assertDoesNotExist()
    }

    @Test fun legacyPendingOfferReopensAndTakeDoesNotTriggerUntilMove() {
        board.gameFile.writeText(
            "cute-game 4\n4k3/8/8/8/8/8/4P3/4K2R w K - 0 1\n" +
                "playing\n2\nWhite\npending\n4\n6\nnone\nnone\n"
        )
        board.launch()
        board.awaitText("Black, answer the double")
        board.assertSquare("e2", "e2, White pawn")
        rule.onNodeWithTag("matchScore").assertTextEquals(
            "White 2 points · Black 3 points · first to 15 points"
        )
        rule.onNodeWithText("Take").performScrollTo().performClick()
        board.awaitText("White to move")
        rule.onNodeWithTag("stake").assertTextEquals("Stake: 4 points", "Only Black can offer")
        rule.onNodeWithText("Automatic doubles").performScrollTo().performClick()
        awaitSwitchOn()
        rule.onNodeWithText("Continue").assertDoesNotExist()
        board.tap("e2", "e4")
        board.awaitText("White, continue at 8 points?")
        board.relaunch()
        board.awaitText("White, continue at 8 points?")
    }

    @Test fun voluntaryTakeWithSwitchOnDoesNotItselfTriggerAQualifyingPosition() {
        board.seed("4k3/8/8/8/8/8/4P3/4K2R w K - 0 1")
        board.launch()
        board.awaitText("White to move")
        rule.onNodeWithText("Automatic doubles").performScrollTo().performClick()
        awaitSwitchOn()
        rule.onNodeWithText("Offer double").performScrollTo().performClick()
        board.awaitText("Black, answer the double")
        rule.onNodeWithText("Take").performScrollTo().performClick()
        board.awaitText("White to move")
        rule.onNodeWithText("Continue").assertDoesNotExist()
        board.tap("e2", "e4")
        board.awaitText("White, continue at 4 points?")
        rule.onNodeWithText("Continue").performScrollTo().performClick()
        board.awaitText("Black, continue at 4 points?")
        rule.onNodeWithText("Continue").performScrollTo().performClick()
        board.awaitText("Black to move")
        rule.onNodeWithTag("stake").assertTextEquals("Stake: 4 points", "Only Black can offer")
        rule.onNodeWithText("Offer double").performScrollTo().assertIsEnabled()
    }

    @Test fun finishedLegacySaveKeepsPositionResultStakeAndMatchScore() {
        board.gameFile.writeText(
            "cute-game 4\n4k3/8/8/8/4P3/8/8/4K2R b K e3 0 1\n" +
                "White Resignation\n2\nBlack\nanswered\n8\n6\nnone\nnone\n"
        )
        board.launch()
        board.awaitText("White wins · Resignation")
        board.assertSquare("e4", "e4, White pawn")
        rule.onNodeWithTag("matchScore").assertTextEquals(
            "White 4 points · Black 3 points · first to 15 points"
        )
        board.awaitText("White earns 2 points.")
        board.relaunch()
        board.awaitText("White wins · Resignation")
        rule.onNodeWithTag("matchScore").assertTextEquals(
            "White 4 points · Black 3 points · first to 15 points"
        )
    }

    @Test fun checkmateWinsInsteadOfTriggeringAnAutomaticDecision() {
        board.seed("7k/5K2/6Q1/8/8/8/8/8 w - - 0 1")
        board.launch()
        board.awaitText("White to move")
        rule.onNodeWithText("Automatic doubles").performScrollTo().performClick()
        awaitSwitchOn()
        board.tap("g6", "g7")
        board.awaitText("White wins · Checkmate")
        board.awaitText("White earns 1 point.")
        rule.onNodeWithText("Continue").assertDoesNotExist()
        board.relaunch()
        board.awaitText("White wins · Checkmate")
    }

    private fun assertAutomaticExplanation() {
        board.awaitText("Stake: 1 point")
        board.awaitText(
            "If both continue, play for 2 points. If only one continues, they win 1 point. " +
                "If both stop, it’s a draw and each earns ½ point."
        )
        rule.onNodeWithText("Continue").assertExists()
        rule.onNodeWithText("Stop").assertExists()
        rule.onNodeWithText("Confirm").assertDoesNotExist()
        rule.onNodeWithText("Cancel").assertDoesNotExist()
    }

    private fun awaitSwitchOn() {
        rule.waitUntil(BoardHarness.TIMEOUT) {
            rule.onAllNodes(hasText("Automatic doubles") and isOn())
                .fetchSemanticsNodes().isNotEmpty()
        }
    }
}
