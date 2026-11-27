package md.alasdair.cute.localgame

import android.os.ParcelFileDescriptor
import android.os.SystemClock
import androidx.compose.ui.test.junit4.accessibility.enableAccessibilityChecks
import androidx.compose.ui.test.junit4.v2.createAndroidComposeRule
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import androidx.test.uiautomator.By
import androidx.test.uiautomator.UiDevice
import androidx.test.uiautomator.Until
import com.google.android.apps.common.testing.accessibility.framework.AccessibilityCheckResultUtils.matchesCheck
import com.google.android.apps.common.testing.accessibility.framework.checks.TouchTargetSizeCheck
import com.google.android.apps.common.testing.accessibility.framework.integrations.espresso.AccessibilityValidator
import java.io.File
import md.alasdair.cute.MainActivity
import md.alasdair.cute.localgame.data.FileGameRepository
import org.junit.After
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import org.junit.rules.ExternalResource
import org.junit.rules.RuleChain
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class PortraitPlayTest {
    private val rule = createAndroidComposeRule<MainActivity>()
    private val game = IsolatedGame()

    @get:Rule val chain: RuleChain = RuleChain.outerRule(game).around(rule)

    private var previousRotation = "0"
    private var previousAutoRotate = "1"

    @Before fun setup() {
        previousRotation = shell("settings get system user_rotation").trim()
        previousAutoRotate = shell("settings get system accelerometer_rotation").trim()
        rule.enableAccessibilityChecks(
            AccessibilityValidator().setRunChecksFromRootView(true)
                .setSuppressingResultMatcher(matchesCheck(TouchTargetSizeCheck::class.java))
        )
    }

    @After fun restoreRotation() {
        if (previousAutoRotate == "0" && previousRotation in listOf("0", "1", "2", "3")) {
            shell("cmd window user-rotation lock $previousRotation")
        } else {
            shell("cmd window user-rotation free")
        }
    }

    @Test fun rotatedPhoneStaysPortraitAndBoardStillFacesEachPlayer() {
        rule.waitUntil(10_000) {
            rule.onAllNodes(
                androidx.compose.ui.test.hasText("White to move")
            ).fetchSemanticsNodes().isNotEmpty()
        }
        // Exercise the rotation while the app itself is in front. Android honors the
        // portrait lock by keeping the display in rotation 0, so verify the requested
        // user rotation separately rather than claiming the display became landscape.
        val device = UiDevice.getInstance(InstrumentationRegistry.getInstrumentation())
        assertTrue(
            "App is in front",
            device.wait(Until.hasObject(By.pkg(PACKAGE).depth(0)), 10_000)
        )
        device.setOrientationNatural()
        awaitSetting("user_rotation", "0")
        device.setOrientationLeft()
        awaitSetting("user_rotation", "1")
        awaitSetting("accelerometer_rotation", "0")
        assertTrue(
            "App stayed in front",
            device.wait(Until.hasObject(By.pkg(PACKAGE).depth(0)), 10_000)
        )
        awaitDisplayRotation(0)
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

    private fun awaitSetting(key: String, value: String) {
        val deadline = SystemClock.uptimeMillis() + 10_000
        while (shell("settings get system $key").trim() != value) {
            check(SystemClock.uptimeMillis() < deadline) { "$key did not become $value" }
            SystemClock.sleep(100)
        }
    }

    private fun awaitDisplayRotation(rotation: Int) {
        val deadline = SystemClock.uptimeMillis() + 10_000
        while (!shell("dumpsys display").contains("mCurrentOrientation=$rotation")) {
            check(SystemClock.uptimeMillis() < deadline) {
                "Display did not reach rotation $rotation"
            }
            SystemClock.sleep(100)
        }
    }

    private companion object {
        const val PACKAGE = "md.alasdair.cute"
    }

    private fun shell(command: String) = ParcelFileDescriptor.AutoCloseInputStream(
        InstrumentationRegistry.getInstrumentation().uiAutomation.executeShellCommand(command)
    ).bufferedReader().use { it.readText() }
}

/** Refuse to touch any existing game; seed and remove only this scenario's own file. */
private class IsolatedGame : ExternalResource() {
    private val file = File(
        InstrumentationRegistry.getInstrumentation().targetContext.filesDir,
        FileGameRepository.FILE_NAME
    )
    private var created = false

    override fun before() {
        check(file.createNewFile()) { "Refusing to replace an existing current game" }
        created = true
        try {
            file.writeText(
                "cute-game 4\nrnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1\n" +
                    "playing\n1\nEither\nanswered\n0\n0\nnone\nnone\n"
            )
        } catch (failure: Throwable) {
            file.delete()
            created = false
            throw failure
        }
    }

    override fun after() {
        if (created) check(file.delete()) { "Could not remove the test game" }
    }
}
