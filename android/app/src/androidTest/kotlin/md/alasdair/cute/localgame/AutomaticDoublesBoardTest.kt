package md.alasdair.cute.localgame

import androidx.activity.ComponentActivity
import androidx.compose.ui.test.assertIsOff
import androidx.compose.ui.test.assertIsOn
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.isOn
import androidx.compose.ui.test.junit4.v2.createAndroidComposeRule
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performScrollTo
import androidx.test.ext.junit.runners.AndroidJUnit4
import org.junit.After
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
        board.relaunch()
        board.awaitText("Black wins · Opponent stopped at automatic double")
    }

    @Test fun movePromptsBothPlayersAndResumesAtTwiceTheStake() {
        board.seed("4k3/8/8/8/8/8/4P3/4K2R w K - 0 1")
        board.launch()
        board.awaitText("White to move")
        rule.onNodeWithText("Automatic doubles").performScrollTo().performClick()
        awaitSwitchOn()
        board.tap("e2", "e4")
        board.awaitText("White, continue at 2 points?")
        rule.onNodeWithText("Continue").performScrollTo().performClick()
        board.awaitText("Black, continue at 2 points?")
        rule.onNodeWithText("Continue").performScrollTo().performClick()
        board.awaitText("Black to move")
        board.awaitText("Stake: 2 points")
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

    private fun awaitSwitchOn() {
        rule.waitUntil(BoardHarness.TIMEOUT) {
            rule.onAllNodes(hasText("Automatic doubles") and isOn())
                .fetchSemanticsNodes().isNotEmpty()
        }
    }
}
