package md.alasdair.cute.localgame

import android.app.UiAutomation
import androidx.activity.ComponentActivity
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performScrollTo
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import org.junit.After
import org.junit.Rule
import org.junit.Test
import org.junit.rules.ExternalResource
import org.junit.rules.RuleChain
import org.junit.runner.RunWith

/**
 * The board's dialogs at the largest font scale, 200%, with the screen in landscape, where a
 * dialog has the least height (rule 5.4). The display is set before the activity starts, so
 * the dialogs lay out in the real landscape window, and restored afterwards.
 */
@RunWith(AndroidJUnit4::class)
class LargeTextLandscapeTest {
    private val rule = createAndroidComposeRule<ComponentActivity>()

    @get:Rule val chain: RuleChain = RuleChain.outerRule(LandscapeAtFontScale(2.0f)).around(rule)

    private val board = BoardHarness(rule)

    @After
    fun cleanUp() = board.cleanUp()

    @Test
    fun c2_everyPromotionChoiceCanBeReachedAndChosen() {
        board.seed("4k3/1P5p/8/8/8/8/8/4K3 w - - 0 1")
        board.launch()
        board.awaitText("White to move")
        board.tap("b7", "b8")

        for (choice in listOf("Queen", "Rook", "Bishop", "Knight")) {
            rule.onNodeWithText(choice).performScrollTo().assertIsDisplayed()
        }
        // Cancel is a dialog button, outside the scrolling choices, and always shown.
        rule.onNodeWithText("Cancel").assertIsDisplayed()
        board.tapText("Knight")

        board.awaitText("Black to move")
        board.assertSquare("b8", "b8, White knight")
    }

    @Test
    fun c4_everyConfirmationCanBeConfirmedOrCancelled() {
        board.launch()
        board.awaitText("White to move")

        for (action in listOf("Resign", "Agree draw", "New game")) {
            rule.onNodeWithText(action).performScrollTo()
            board.tapText(action)
            rule.onNodeWithText("Confirm").assertIsDisplayed()
            rule.onNodeWithText("Cancel").assertIsDisplayed()
            board.tapText("Cancel")
        }
    }
}

/** Freezes the display in landscape at [fontScale] for one test, then restores both. */
class LandscapeAtFontScale(private val fontScale: Float) : ExternalResource() {
    private val automation: UiAutomation get() =
        InstrumentationRegistry.getInstrumentation().uiAutomation

    override fun before() {
        shell("settings put system font_scale $fontScale")
        automation.setRotation(UiAutomation.ROTATION_FREEZE_90)
        InstrumentationRegistry.getInstrumentation().waitForIdleSync()
    }

    override fun after() {
        shell("settings put system font_scale 1.0")
        automation.setRotation(UiAutomation.ROTATION_FREEZE_0)
        automation.setRotation(UiAutomation.ROTATION_UNFREEZE)
    }

    private fun shell(command: String) {
        automation.executeShellCommand(command).close()
    }
}
