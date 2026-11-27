package md.alasdair.cute.localgame

import android.os.ParcelFileDescriptor
import androidx.compose.ui.test.junit4.v2.createAndroidComposeRule
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.test.platform.app.InstrumentationRegistry
import md.alasdair.cute.MainActivity
import org.junit.After
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test

class PortraitPlayTest {
    @get:Rule val rule = createAndroidComposeRule<MainActivity>()

    @After fun restoreRotation() {
        shell("cmd window user-rotation free")
    }

    @Test fun rotatedPhoneStaysPortraitAndBoardStillFacesEachPlayer() {
        rule.waitUntil(10_000) {
            rule.onAllNodes(
                androidx.compose.ui.test.hasText("White to move")
            ).fetchSemanticsNodes().isNotEmpty()
        }
        shell("cmd window user-rotation lock 1")
        // Give the system time to apply the requested device rotation.
        android.os.SystemClock.sleep(2_000)
        rule.waitForIdle()
        val root = rule.onNodeWithTag("board").fetchSemanticsNode().boundsInRoot
        val activity = rule.activity.window.decorView
        assertTrue("App remains portrait", activity.height > activity.width)
        assertTrue("Board visible", root.width > 0)
        fun y(square: String) =
            rule.onNodeWithTag("square-$square").fetchSemanticsNode().boundsInRoot.center.y
        assertTrue("White at bottom", y("e1") > y("e8"))
        rule.onNodeWithTag("square-e2").performClick()
        rule.onNodeWithTag("square-e4").performClick()
        rule.waitUntil(10_000) {
            rule.onAllNodes(
                androidx.compose.ui.test.hasText("Black to move")
            ).fetchSemanticsNodes().isNotEmpty()
        }
        assertTrue("Black at bottom", y("e8") > y("e1"))
        rule.onNodeWithText("Offer double").performClick()
        rule.waitUntil(10_000) {
            rule.onAllNodes(
                androidx.compose.ui.test.hasText("White, answer the double")
            ).fetchSemanticsNodes().isNotEmpty()
        }
        assertTrue("Responder at bottom", y("e1") > y("e8"))
        rule.onNodeWithText("Take").performClick()
        rule.waitUntil(10_000) {
            rule.onAllNodes(
                androidx.compose.ui.test.hasText("Black to move")
            ).fetchSemanticsNodes().isNotEmpty()
        }
        assertTrue("Offerer at bottom", y("e8") > y("e1"))
    }

    private fun shell(command: String) = ParcelFileDescriptor.AutoCloseInputStream(
        InstrumentationRegistry.getInstrumentation().uiAutomation.executeShellCommand(command)
    ).bufferedReader().use { it.readText() }
}
