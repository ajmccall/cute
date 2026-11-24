package md.alasdair.cute.localgame

import android.app.UiAutomation
import android.content.res.Configuration
import android.os.ParcelFileDescriptor
import androidx.activity.ComponentActivity
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.junit4.accessibility.enableAccessibilityChecks
import androidx.compose.ui.test.junit4.v2.createAndroidComposeRule
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performScrollTo
import androidx.test.platform.app.InstrumentationRegistry
import com.google.android.apps.common.testing.accessibility.framework.AccessibilityCheckResultUtils.matchesCheck
import com.google.android.apps.common.testing.accessibility.framework.checks.TouchTargetSizeCheck
import com.google.android.apps.common.testing.accessibility.framework.integrations.espresso.AccessibilityValidator
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import org.junit.rules.ExternalResource
import org.junit.rules.RuleChain
import org.junit.runner.RunWith
import org.junit.runners.Parameterized

/**
 * The board's dialogs at the largest font scale, 200%, in portrait and in landscape, where a
 * dialog has the least height (rule 5.4). The display is set before the activity starts, so
 * the dialogs lay out in the real window, and each test first checks that the activity runs
 * at that scale and orientation. Accessibility checks run on every action; as in
 * LocalGameBoardTest, only the board squares' touch-target size is exempt (#6, decision 1a).
 */
@RunWith(Parameterized::class)
class LargeTextTest(private val orientation: Int) {
    private val rule = createAndroidComposeRule<ComponentActivity>()

    @get:Rule val chain: RuleChain =
        RuleChain.outerRule(DisplayAtFontScale(FONT_SCALE, orientation)).around(rule)

    private val board = BoardHarness(rule)

    @Before
    fun checkDisplayAndAccessibility() {
        rule.activityRule.scenario.onActivity {
            val configuration = it.resources.configuration
            assertEquals(FONT_SCALE, configuration.fontScale)
            assertEquals(orientation, configuration.orientation)
        }
        rule.enableAccessibilityChecks(
            AccessibilityValidator()
                .setRunChecksFromRootView(true)
                .setSuppressingResultMatcher(matchesCheck(TouchTargetSizeCheck::class.java))
        )
    }

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
    fun c4_everyConfirmationShowsConfirmAndCancel() {
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

    companion object {
        const val FONT_SCALE = 2.0f

        @JvmStatic
        @Parameterized.Parameters(name = "orientation={0}")
        fun orientations() =
            listOf(Configuration.ORIENTATION_PORTRAIT, Configuration.ORIENTATION_LANDSCAPE)
    }
}

/**
 * Freezes the display in [orientation] at [fontScale] for one test, then puts back the font
 * scale it found and unfreezes the rotation.
 */
private class DisplayAtFontScale(private val fontScale: Float, private val orientation: Int) :
    ExternalResource() {
    private val automation: UiAutomation get() =
        InstrumentationRegistry.getInstrumentation().uiAutomation
    private var previousFontScale = "1.0"

    override fun before() {
        previousFontScale = shell("settings get system font_scale").trim()
            .takeIf { it.toFloatOrNull() != null } ?: "1.0"
        shell("settings put system font_scale $fontScale")
        automation.setRotation(
            if (orientation == Configuration.ORIENTATION_LANDSCAPE) {
                UiAutomation.ROTATION_FREEZE_90
            } else {
                UiAutomation.ROTATION_FREEZE_0
            }
        )
        InstrumentationRegistry.getInstrumentation().waitForIdleSync()
    }

    override fun after() {
        shell("settings put system font_scale $previousFontScale")
        automation.setRotation(UiAutomation.ROTATION_FREEZE_0)
        automation.setRotation(UiAutomation.ROTATION_UNFREEZE)
    }

    private fun shell(command: String): String = ParcelFileDescriptor.AutoCloseInputStream(
        automation.executeShellCommand(command)
    ).bufferedReader().use { it.readText() }
}
