package md.alasdair.cute.localgame

import android.app.UiAutomation
import android.content.res.Configuration
import android.content.res.Resources
import android.os.ParcelFileDescriptor
import android.os.SystemClock
import androidx.activity.ComponentActivity
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.junit4.v2.createAndroidComposeRule
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performScrollTo
import androidx.test.platform.app.InstrumentationRegistry
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
 * dialog has the least height (rule 5.4). The font scale is set before the activity starts;
 * the rotation is locked once the activity is in front, and each test waits, at most 30
 * seconds, until the activity runs at that scale and orientation. Accessibility checks run on
 * every action (BoardHarness.enableAccessibilityChecks).
 */
@RunWith(Parameterized::class)
class LargeTextTest(private val orientation: Int) {
    private val rule = createAndroidComposeRule<ComponentActivity>()
    private val display = DisplaySettings(FONT_SCALE)

    @get:Rule val chain: RuleChain = RuleChain.outerRule(display).around(rule)

    private val board = BoardHarness(rule)

    @Before
    fun checkDisplayAndAccessibility() {
        // A phone's home screen holds portrait, and the rotation lock was lost while the test
        // activity started (API 36 emulator), so lock it now, again until the activity turns.
        val deadline = SystemClock.uptimeMillis() + DISPLAY_TIMEOUT_MS
        var configuration = activityConfiguration()
        while (configuration.fontScale != FONT_SCALE || configuration.orientation != orientation) {
            check(SystemClock.uptimeMillis() < deadline) {
                "Activity not at font scale $FONT_SCALE and orientation $orientation after " +
                    "$DISPLAY_TIMEOUT_MS ms: it has ${configuration.fontScale} and " +
                    "${configuration.orientation}"
            }
            display.lockRotation(orientation)
            SystemClock.sleep(POLL_MS)
            configuration = activityConfiguration()
        }
        assertEquals(FONT_SCALE, configuration.fontScale)
        assertEquals(orientation, configuration.orientation)
        board.enableAccessibilityChecks()
    }

    @After
    fun cleanUp() = board.cleanUp()

    private fun activityConfiguration(): Configuration {
        var configuration = Configuration()
        rule.activityRule.scenario.onActivity {
            configuration = Configuration(it.resources.configuration)
        }
        return configuration
    }

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

    @Test
    fun c7_theOfferCanBeConfirmed_andTheResponseReadAndAnswered() {
        board.launch()
        board.awaitText("White to move")

        rule.onNodeWithText("Offer double").performScrollTo()
        board.tapText("Offer double")
        rule.onNodeWithText("Confirm").assertIsDisplayed()
        rule.onNodeWithText("Cancel").assertIsDisplayed()
        board.tapText("Confirm")
        board.awaitText("Black, answer the double")

        for (text in listOf(
            "Stake: 1 point",
            "Take: play for 2 points.",
            "Decline: White wins 1 point.",
            "Decline",
            "Take"
        )) {
            rule.onNodeWithText(text).performScrollTo().assertIsDisplayed()
        }
        board.tapText("Take")
        board.awaitText("White to move")
        rule.onNodeWithText("Stake: 2 points").performScrollTo().assertIsDisplayed()
    }

    companion object {
        const val FONT_SCALE = 2.0f
        const val DISPLAY_TIMEOUT_MS = 30_000L
        const val POLL_MS = 250L

        @JvmStatic
        @Parameterized.Parameters(name = "orientation={0}")
        fun orientations() =
            listOf(Configuration.ORIENTATION_PORTRAIT, Configuration.ORIENTATION_LANDSCAPE)
    }
}

/**
 * The display settings for one test: sets the font scale, waiting until it is in effect, and
 * locks the rotation when asked. Afterwards it puts back the font scale it found (or none, if
 * none was set) and frees the rotation, even when a step fails.
 */
private class DisplaySettings(private val fontScale: Float) : ExternalResource() {
    private val automation: UiAutomation get() =
        InstrumentationRegistry.getInstrumentation().uiAutomation
    private var previousFontScale: String? = null

    override fun before() {
        previousFontScale = shell("settings get system font_scale").trim()
            .takeIf { it.toFloatOrNull() != null }
        try {
            shell("settings put system font_scale $fontScale")
            awaitFontScale()
        } catch (e: Throwable) {
            restore()
            throw e
        }
    }

    override fun after() = restore()

    /**
     * Locks the display in [orientation]. `cmd window user-rotation` turns the display on the
     * API 36 emulator, where UiAutomation.setRotation didn't.
     */
    fun lockRotation(orientation: Int) {
        val rotation = if (orientation == Configuration.ORIENTATION_LANDSCAPE) 1 else 0
        shell("cmd window user-rotation lock $rotation")
    }

    /** Waits, at most [TIMEOUT_MS], until this process has the font scale. */
    private fun awaitFontScale() {
        val deadline = SystemClock.uptimeMillis() + TIMEOUT_MS
        while (Resources.getSystem().configuration.fontScale != fontScale) {
            check(SystemClock.uptimeMillis() < deadline) {
                "Font scale not $fontScale after $TIMEOUT_MS ms"
            }
            SystemClock.sleep(POLL_MS)
        }
        InstrumentationRegistry.getInstrumentation().waitForIdleSync()
    }

    private fun restore() {
        try {
            val previous = previousFontScale
            shell(
                if (previous == null) {
                    "settings delete system font_scale"
                } else {
                    "settings put system font_scale $previous"
                }
            )
        } finally {
            try {
                shell("cmd window user-rotation lock 0")
            } finally {
                shell("cmd window user-rotation free")
            }
        }
    }

    private fun shell(command: String): String = ParcelFileDescriptor.AutoCloseInputStream(
        automation.executeShellCommand(command)
    ).bufferedReader().use { it.readText() }

    private companion object {
        const val TIMEOUT_MS = 30_000L
        const val POLL_MS = 100L
    }
}
