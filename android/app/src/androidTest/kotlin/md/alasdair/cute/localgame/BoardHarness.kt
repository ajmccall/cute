package md.alasdair.cute.localgame

import androidx.activity.ComponentActivity
import androidx.compose.runtime.getValue
import androidx.compose.runtime.key
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.semantics.SemanticsProperties
import androidx.compose.ui.test.SemanticsMatcher
import androidx.compose.ui.test.SemanticsNodeInteraction
import androidx.compose.ui.test.assert
import androidx.compose.ui.test.assertContentDescriptionEquals
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.junit4.AndroidComposeTestRule
import androidx.compose.ui.test.junit4.accessibility.enableAccessibilityChecks
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.test.ext.junit.rules.ActivityScenarioRule
import androidx.test.platform.app.InstrumentationRegistry
import com.google.android.apps.common.testing.accessibility.framework.AccessibilityCheckResultUtils.matchesCheck
import com.google.android.apps.common.testing.accessibility.framework.checks.TouchTargetSizeCheck
import com.google.android.apps.common.testing.accessibility.framework.integrations.espresso.AccessibilityValidator
import java.io.File
import java.util.UUID
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.runBlocking
import md.alasdair.cute.chess.positionFromFen
import md.alasdair.cute.localgame.data.FileGameRepository
import md.alasdair.cute.localgame.data.GameRecord
import md.alasdair.cute.ui.theme.CuteTheme

typealias BoardRule =
    AndroidComposeTestRule<ActivityScenarioRule<ComponentActivity>, ComponentActivity>

/**
 * The running board over its own current game: a file in a new folder under the app's cache,
 * never the app's saved game. [relaunch] opens the same file again as a cold start does.
 */
class BoardHarness(private val rule: BoardRule) {
    val folder: File = File(
        InstrumentationRegistry.getInstrumentation().targetContext.cacheDir,
        "board-test-${UUID.randomUUID()}"
    ).apply { mkdirs() }
    val gameFile = File(folder, FileGameRepository.FILE_NAME)
    private var launches by mutableIntStateOf(0)

    fun seed(fen: String) = runBlocking {
        FileGameRepository(gameFile, Dispatchers.IO).save(GameRecord(positionFromFen(fen), null))
    }

    /**
     * Writes a version-4 save of a game in play at [fen], at one point, with [white]'s and
     * [black]'s captures as piece letters in the order taken, or `none`, and the totals in half
     * points.
     */
    fun saveWithCaptures(
        fen: String,
        white: String,
        black: String,
        whiteHalves: Int = 0,
        blackHalves: Int = 0
    ) = gameFile.writeText(
        "cute-game 4\n$fen\nplaying\n1\nEither\nanswered\n$whiteHalves\n$blackHalves\n" +
            "$white\n$black\n"
    )

    fun launch() {
        rule.setContent {
            CuteTheme {
                key(launches) {
                    BoardRoute(
                        remember {
                            LocalGameViewModel(FileGameRepository(gameFile, Dispatchers.IO))
                        }
                    )
                }
            }
        }
    }

    /**
     * Runs Google's accessibility checks on every action. Only the touch-target size check is
     * suppressed: on a phone narrower than 384 dp each board square is an eighth of the width,
     * below 48 dp, which the product owner approved for the board (#6, decision 1a).
     */
    fun enableAccessibilityChecks() {
        rule.enableAccessibilityChecks(
            AccessibilityValidator()
                .setRunChecksFromRootView(true)
                .setSuppressingResultMatcher(matchesCheck(TouchTargetSizeCheck::class.java))
        )
    }

    fun relaunch() {
        rule.runOnIdle { launches++ }
    }

    fun cleanUp() {
        folder.setWritable(true)
        gameFile.setReadable(true)
        folder.deleteRecursively()
    }

    fun square(name: String): SemanticsNodeInteraction = rule.onNodeWithTag("square-$name")

    fun tap(vararg squares: String) = squares.forEach { square(it).performClick() }

    fun tapText(text: String) = rule.onNodeWithText(text).performClick()

    /** Waits, at most five seconds, for [text] to be on screen: saves run off the main thread. */
    fun awaitText(text: String) {
        rule.waitUntil(TIMEOUT) {
            rule.onAllNodes(hasText(text)).fetchSemanticsNodes().isNotEmpty()
        }
    }

    fun assertSquare(name: String, label: String, state: String? = null) {
        square(name).assertContentDescriptionEquals(label)
        square(name).assert(
            if (state == null) {
                SemanticsMatcher.keyNotDefined(SemanticsProperties.StateDescription)
            } else {
                SemanticsMatcher.expectValue(SemanticsProperties.StateDescription, state)
            }
        )
    }

    companion object {
        const val TIMEOUT = 5_000L
    }
}
