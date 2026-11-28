# Android convention reference

The rules an Android builder follows and an Android reviewer checks against. Cite a rule by its number, for example "rule 4.3". A review finding names the rule behind it where there is one. A breach of a required rule (Required rules, below) is a **required finding**, which must be fixed before the feature is accepted; a breach of any other rule, which is advisory, is a **nit**, which the builder may take or leave. A finding with no rule behind it still stands, but this reference doesn't make it required. The nine sections match the iOS reference, so "section 4" means navigation on both.

`android-sources.md` holds each rule's sources, quotations and the observations behind it, under the same rule numbers. Read it when a rule is questioned, unclear or being changed.

## How to read this reference

- **Assumes** the current stable releases on 2026-10-02:
  - Android 17, API level 37, the latest platform in the stable SDK channel.
  - Android Gradle plugin 9.4 and Kotlin 2.4.
  - Compose BOM 2026.09.00, which maps `androidx.compose.material3` to 1.4.0, its latest stable release.
  - Navigation 3 1.2.0 and Lifecycle 2.11.0.
  - Checked on 2026-10-18: Hilt (Dagger) 2.60.1, KSP 2.3.12 and `androidx.hilt` 1.4.0.
  - Checked on 2026-11-08: the ktlint Gradle plugin 14.2.0 and ktlint 1.8.0.

  Update this list, and any rule it affects, when a new stable release lands.
- Where m3.material.io describes a component or variant that the stable `material3` release doesn't have, the stable library wins (rule 3.2). Where both the M3 guidance and an older option are in the stable release, the rule names the one to use.
- A project never edits this reference. It departs from a required rule, including the section 9 third-party decision, by recording a deviation, which the product owner approves: in `AGENTS.md`'s **Deviations** for the whole app, or in the feature's **Deliberate platform differences** for one feature. Departing from an advisory rule needs no deviation.
- Where a rule names an alternative, a project that uses the alternative isn't departing from the rule, so it records no deviation.
- A rule that needs a minimum API level is labelled with it, for example **API 31+**. The project decides its `minSdk`. If that minimum is lower than a rule's label, the builder raises it as a decision rather than working around it. Rules without a label work on every API level that current Compose supports.
- `AGENTS.md` holds the rules both platforms share, such as parity and how sessions isolate their work, and they aren't repeated here. Section 9 holds the default dependencies.

## Required rules

A rule is **required** when a breach harms a person using the app (they can't read, reach or leave something, or they lose saved data), commits the app to something without the product owner, or breaks parallel sessions. Architecture, test method, project setup, look and command-line how-to are advisory. The eight required rules, each labelled **Required** in place:

- 1.9: edge to edge, with content clear of the system bars.
- 2.12, schema export only: Room schemas are exported and committed, so saved data survives an upgrade.
- 4.3: predictive back works, and is never intercepted for business logic.
- 5.2: touch targets of at least 48 × 48 dp.
- 5.3: a `contentDescription` on every meaningful image and icon-only control.
- 5.4: text in `sp`, usable at the largest font scale.
- 8.8: an emulator of its own per session, with `ANDROID_SERIAL` set.
- 9.1, the third-party decision only: no third-party library without the product owner's decision. The preference order itself is advisory.

Every other rule is advisory: a builder follows it by default, and departing from it needs no deviation.

## Design versus platform

- The project's design source, named in `AGENTS.md`, owns the look: colour, type, shape, layout and custom components.
- This reference owns the behaviour that people and the OS rely on: navigation and the back gesture, accessibility (font scaling, TalkBack, touch targets) and system integration such as edge-to-edge.
- When the design really clashes with a rule here, the builder doesn't settle it. It sends the clash to the product owner as a decision in the ticket.

## 1. Project structure

1.1. Build scripts use the Gradle Kotlin DSL (`.gradle.kts`).

1.2. Every dependency and plugin version lives in the version catalog, `gradle/libs.versions.toml`.

1.3. Compose libraries take their versions from the Compose BOM, not from individual version numbers.

1.4. Use AGP's built-in Kotlin: don't apply `org.jetbrains.kotlin.android`, even where a setup sample shows it. Apply the Compose compiler Gradle plugin, `org.jetbrains.kotlin.plugin.compose`.

1.5. Start with a single `app` module. Split into modules only when a ticket needs it.

1.6. The app has a single activity. Screens are composables, not activities.

1.7. Inside the module, packages are grouped by feature, with data-layer types in a `data` package.

1.8. `compileSdk` and `targetSdk` are the latest stable API level (see **Assumes**). Google Play requires API 36 or higher for new apps and updates from 31 August 2026.

1.9. **Required.** The app draws edge to edge. Call `enableEdgeToEdge()` in the activity's `onCreate`, and keep content clear of the system bars with insets. Material 3 app bars, `NavigationBar`, `ShortNavigationBar` (rule 4.4) and `NavigationRail` apply their own insets. `Scaffold` doesn't apply insets to its content: it passes them as `innerPadding`, and the content must apply them. Enforced when targeting **API 35+**, with no opt-out from API 36.

1.10. Kotlin code, including `.gradle.kts` scripts, follows the Android Kotlin style guide and the Kotlin coding conventions. ktlint checks the style guide's mechanical rules, among them the four-space indent, the column limit of 100 characters, and imports in a single ASCII-sorted list, so neither the builder nor the reviewer checks those by hand. It applies all of its standard rules in that style, such as wrapping, spacing and trailing commas, not only these three, and its formatting is the project's. Apply the ktlint Gradle plugin, `org.jlleitschuh.gradle.ktlint`, to the `app` module, at 14.1.0 or later, the first release to support built-in Kotlin (rule 1.4). Select ktlint's Android code style in an `.editorconfig` at the root of the Android project:

```ini
[*.{kt,kts}]
ktlint_code_style = android_studio
ktlint_function_naming_ignore_when_annotated_with = Composable
```

The second property keeps the style guide's PascalCase names for composables. `./gradlew ktlintCheck` checks every source set and the project's Kotlin script files, and runs wherever the unit tests run: in the builder's evidence, in the reviewer's reruns, and in the pull request's automated check where the project has one. `./gradlew ktlintFormat` fixes most of what it reports; run it on the files `android create` generates, whose template indents by two spaces, before building on them. The plugin activates only in a project that has the Kotlin plugin applied, so the root project's `build.gradle.kts` and `settings.gradle.kts` are outside it: keep them to the same style. ktlint and its Gradle plugin run in the build and don't ship in the app, so they aren't a third-party library under rule 9.1 and need no decision.

1.11. User-facing strings live in `res/values/strings.xml` and are read with `stringResource`.

1.12. Every dependency is added, or updated, at its latest stable release: for an AndroidX library outside the BOM, the version in the **Stable Release** column of its release page; for any other library, the latest release its own releases page marks stable. Never copy a version from a guide's or sample's setup, which drifts behind the stable releases and may pin alpha ones. A pre-release library is the builder's call, listed in the ticket. The other artifacts that rule 9.1 allows also use stable versions. The Kotlin serialization plugin takes the project's Kotlin version. The kotlinx libraries follow their own versioning, independent of Kotlin, so they and JUnit use their latest stable release, not the version in a guide's sample. The standard library needs no version of its own: it takes the version of the Kotlin Gradle plugin.

1.13. Use a Media3 API marked `@UnstableApi` only where no stable Media3 API does the job. Opt in with `androidx.annotation.OptIn`, as `@OptIn(UnstableApi::class)`, not with `kotlin.OptIn`, on the class or function that uses it. The ticket lists each opt-in, with the API that needs it. Opting in this way isn't a deviation.

## 2. Architecture layers and state holders

2.1. The app has a UI layer and a data layer. Add a domain layer only when logic is complex or reused by several ViewModels.

2.2. Data flows one way: state flows down to the UI and events flow up. UI state is immutable.

2.3. Each screen's state holder is a `ViewModel` that exposes its UI state as one `StateFlow<…UiState>` property, `uiState`. It adds more only for unrelated pieces of data, as the source allows.

2.4. Don't send one-off events from the ViewModel to the UI. Model the outcome as state, and have the UI report back when it has handled it.

2.5. The UI collects flows with `collectAsStateWithLifecycle()`.

2.6. Only the screen-level composable gets the ViewModel. It passes state and event lambdas to stateless child composables. Don't pass ViewModels down.

2.7. When a composable has complex UI logic involving the state of its UI elements, that logic lives in a plain state holder class, remembered in composition.

2.8. A ViewModel holds no `Context`, `Resources` or view references.

2.9. Repositories are the data layer's entry points. Each piece of data has one repository as its single source of truth.

2.10. Async work uses coroutines and flows. ViewModels launch in `viewModelScope`, suspend functions are main-safe, and dispatchers are injected rather than hard-coded.

2.11. UI-element state that must survive configuration change and process death uses `rememberSaveable`. Screen state that must survive process death uses `SavedStateHandle`.

2.12. **Required (schema export).** **Data saved in a Room database.** Use Room 3 (`androidx.room3`). Room 3 requires KSP for annotation processing, and a `SQLiteDriver` to build a `RoomDatabase`. The ticket that adds the database names the driver: `AndroidSQLiteDriver` uses the platform's SQLite, and `BundledSQLiteDriver` adds its own build of SQLite to the app. Apply the Room Gradle plugin with `room3 { schemaDirectory("$projectDir/schemas") }`, and commit the schema files it exports. Through `AndroidSQLiteDriver`, a database opens with Android's `DefaultDatabaseErrorHandler`: opening a main file that wasn't a database has deleted it and created a new, empty database in its place. A separate preflight connection using `SQLiteDatabase.openDatabase` with `OPEN_READONLY` and a non-deleting error handler protects only that inspection, not Room's active connections. For a ticket requiring preservation after opening, choose and verify a non-deleting active driver; preflight alone is insufficient. `BundledSQLiteDriver` has returned native error 11 from b-tree corruption without deleting or replacing the main file or its companions; that is evidence for the tested paths, not every fault. The driver choice, preflight depth and recovery behaviour remain the ticket's decisions. Verify the actual selected driver with isolated connection-level tests and companion-file checks, as rules 6.7 to 6.10 require; fakes or retained UI state cannot prove file preservation.

## 3. Building UI

3.1. The design source comes first. If the project names none, the stock component set is Material 3, `androidx.compose.material3`, at its latest stable release through the BOM (rule 1.3).

3.2. Don't use Material 3 Expressive APIs (anything marked `@ExperimentalMaterial3ExpressiveApi`, or available only in a `1.5.0` alpha) until a stable `material3` release includes them.

3.3. The app has one theme composable that wraps `MaterialTheme` with its colour scheme, typography and shapes. Components read colours, type and shapes from `MaterialTheme`, not from hard-coded values.

3.4. Not used. The number stays, so the rules after it keep theirs.

3.5. Dynamic colour is a look decision, so the design source makes it. When the design source is standard components, `AGENTS.md` says whether the theme uses dynamic colour where the device supports it (with the project's colour scheme elsewhere), or the static schemes only, the same colours on every device. If it doesn't say, the builder sends it to the product owner as a decision. **API 31+** for dynamic colour.

3.6. **Custom designs.** When the design source is a design system or designs, Google documents three options: extend `MaterialTheme` with extra values, replace one or more Material subsystems, or build a fully custom design system on Compose Foundation. This reference doesn't choose. The ticket that introduces the design source sends the choice to the product owner.

3.7. **Design tokens.** The design source's tokens (colour, type, shape, spacing) map to theme values in one place, and components read them from the theme. Tokens that the theme doesn't carry are provided through a `CompositionLocal`. Use `CompositionLocal` only for tree-wide values like these, not to pass ordinary data.

3.8. **Custom components.** A reusable composable accepts `modifier: Modifier = Modifier` and applies it to its root. It takes content through slot parameters (composable lambdas) where callers need to vary it, and is stateless: it takes a value and an `on…Change` lambda.

3.9. Every custom component meets section 5 itself: semantics, a 48 dp touch target and font scaling.

3.10. Each screen and reusable component has a `@Preview`.

## 4. Navigation and back behaviour

4.1. Navigate with Navigation 3 (`androidx.navigation3`). The back stack is state the app owns: keys implement `NavKey` and are `@Serializable`, the stack is created with `rememberNavBackStack`, and `NavDisplay` shows it. Alternative: Navigation Compose 2.x (`androidx.navigation`) with type-safe routes.

4.2. The app has a fixed start destination, and the back stack is the navigation state. Up and Back behave the same inside the app, and Up never leaves it.

4.3. **Required.** Keep predictive back working: it is on by default when targeting **API 36+**, so don't opt out. Intercept back only to dismiss UI the person opened (for example, a sheet or an edit in progress), with `BackHandler` or `PredictiveBackHandler`. Never intercept it to run business logic or to log.

4.4. Three to five top-level destinations of equal importance use a navigation bar. Use `ShortNavigationBar` with `ShortNavigationBarItem`, the flexible bar, stable from `material3` 1.4.0. Alternative: `NavigationBar`, the baseline bar. Where the app must adapt to larger windows, use the `NavigationSuiteScaffold` overload that takes `navigationItems`.

4.5. Each screen's `ViewModel` is scoped to its Navigation 3 entry, so it is cleared when the screen leaves the back stack. Add `rememberSaveableStateHolderNavEntryDecorator()` and then `rememberViewModelStoreNavEntryDecorator()`, from `androidx.lifecycle:lifecycle-viewmodel-navigation3`, to the `NavDisplay`'s `entryDecorators`. Without the ViewModel decorator, a `ViewModel` is scoped to the nearest `ViewModelStoreOwner`, typically the activity. Take the artifact's version from the **Stable Release** column of the Lifecycle release page (rule 1.12), not from the Navigation 3 setup sample, which pins an alpha.

## 5. Accessibility

5.1. Follow Google's accessibility basics for every screen. Material and Foundation components supply most semantics by default; custom ones must add them (rule 3.9).

5.2. **Required.** Every touch target is at least 48 × 48 dp.

5.3. **Required.** Every meaningful image and icon-only control has a `contentDescription`; decorative ones pass `null`. Related elements are merged with `semantics(mergeDescendants = true)`, and custom controls set a `Role`.

5.4. **Required.** Text sizes are in `sp`, and every screen stays usable at the largest font scale (200% from **API 34**).

5.5. Text contrast is at least 4.5:1 for text under 18 sp (or bold text under 14 sp), and at least 3:1 for other text.

5.6. Check each new screen with TalkBack and Accessibility Scanner. Once a flow has Compose UI tests, they call `enableAccessibilityChecks()`. On the emulator, turn TalkBack on with `adb shell settings put secure enabled_accessibility_services com.google.android.marvin.talkback/.TalkBackService`, and off again with `adb shell settings delete secure enabled_accessibility_services`. Alternative: Settings > Accessibility > TalkBack. From the command line, a screenshot shows where TalkBack's focus is, but not what it says, so a person listening with TalkBack on is the check of its speech.

## 6. Unit testing

6.1. Unit tests are local tests in `src/test`, run on the JVM with JUnit 4. Logic that local tests cover uses Kotlin and Java APIs, not Android framework classes such as `android.icu` or `android.util.Xml`, whose methods have no code in local tests and throw an exception. Where the JVM's version of an API can behave differently from the device's, the ticket says so.

6.2. Unit tests cover ViewModels (including their flows) and the data layer.

6.3. Tests use fakes, not mocks: hand-written classes that implement the same interface as the real dependency. Local tests construct ViewModels and other injected classes directly with their fakes, without Hilt (rule 9.3).

6.4. Coroutine code is tested with `runTest` from `kotlinx-coroutines-test`, with injected test dispatchers, and `Dispatchers.setMain` for code that uses the main dispatcher.

6.5. Code that needs the Android framework itself, such as a Room database on the platform's SQLite (rule 2.12), is tested with instrumented tests, which run on the emulator. Everything local tests can reach stays in local tests (rule 6.1). Instrumented tests live in `src/androidTest`, run with `testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"` (or, once a test needs Hilt, the runner in rule 6.6), and use `@RunWith(AndroidJUnit4::class)`. Run them with `./gradlew connectedDebugAndroidTest`, with `ANDROID_SERIAL` set to the session's own emulator (rule 8.8), and record the device and its API level in the ticket. The tests run with the app's own `Application` subclass. With rule 6.6's runner, `HiltTestApplication` takes its place. Either way, whatever runs at launch in that `Application`, or in an activity a test starts, such as opening the app's saved data, also happens during the tests. The ticket says how the tests keep away from the app's real data. The task uninstalls the app when it ends, which deletes the app's data, so take screenshots after it, not before. It can report "No compatible devices connected" while `adb devices` lists the emulator; a second run has then passed.

6.6. An instrumented test that needs objects from the Hilt graph, such as a UI test of a screen whose ViewModel uses `hiltViewModel()`, is annotated `@HiltAndroidTest` and adds `HiltAndroidRule(this)` as its first rule (`@get:Rule(order = 0)`). The module's instrumented tests run with a custom runner that subclasses `AndroidJUnitRunner` and returns `HiltTestApplication` from `newApplication`. A test replaces a binding with a fake through a module in `src/androidTest` annotated `@TestInstallIn(components = [...], replaces = [...])`, which applies to every test there; use `@UninstallModules` only for one test's replacement. Add `com.google.dagger:hilt-android-testing` with `kspAndroidTest` for the compiler. A test that constructs its objects itself, such as a store test on a real database, doesn't need Hilt.

6.7. **When a ticket changes saved data.** Rules 6.8 to 6.10 apply to a ticket that adds or changes a write to saved data, or changes what the app does with a damaged store. They are instrumented tests (rule 6.5) on the real Room database, opened through the driver the app uses (rule 2.12), each in its own new folder. A fake store, including one that holds a write until the test releases it, and state the UI kept can't show what reached the disk, so neither is evidence for these rules.

6.8. **A write that can be cancelled** (for example when leaving a screen clears its ViewModel while the write runs) is tested cancelled at two points: after its statements but before the transaction commits, and just after the commit. Wrap the real `SQLiteDriver` in a test driver that runs a hook after a chosen statement, such as the mutation or `END TRANSACTION`, and cancel the caller's job there. After each, compare what the repository holds, and what the screen state shows, with what the database holds, asserting every field the write saves, including a field a ticket adds to an existing write. Then close and reopen the store and compare again. A coroutine cancelled after the commit still gets a `CancellationException` when `withContext` returns. So code that updates a cache only after the write returns must not lose that update.

6.9. **Keeping files when damage is found.** Where a ticket requires the store's files to be kept rather than deleted, reset or replaced, show it on the driver the app actually opens, at each point the ticket names, such as at launch and while running. Damage a page of the real database file, run the access, and compare the main file and each companion file (`-wal`, `-shm`, `-journal`) before and after, by bytes and inode. The `-shm` file's reader bookkeeping may change, and an assertion allows for it. Rule 2.12 says what the platform's default error handler does.

6.10. **Damage fixtures.** A test that injects damage seeds the database through the real store, closes it and lets the close finish, then writes the damage, so no later checkpoint or teardown from the seed overwrites it. It then checks the damaged bytes are on disk before the access under test. A helper that several tests share for writing the damage makes that check itself, so no test that uses it can leave it out.

6.11. **Playback from outside the app.** A criterion about playback that a person can also drive from the system's media controls, such as the notification, the lock screen or a headset, is tested through a second `MediaController` connected to the app's session, as well as through the app's own UI, in each state of playback that the criterion names, such as playing, paused and failed.

## 7. Command-line build

7.1. Gradle runs on Android Studio's bundled JetBrains Runtime (on macOS, `/Applications/Android Studio.app/Contents/jbr/Contents/Home`). For a terminal build, set `JAVA_HOME` to it, and set Android Studio's Gradle JDK to the same JDK. Other settings can choose a different JDK for the daemon: `org.gradle.java.home` in a `gradle.properties` file, and Gradle Daemon JVM criteria, which Android Studio uses by default for new projects. Check which JDK the daemon used with rule 7.5. The project makes sure the daemon uses the JBR, for example by not using Daemon JVM criteria, or by setting criteria that select it. The ticket that sets up the app decides, and the project's `AGENTS.md` records the choice. If criteria select the JBR and the build fails with "Unable to download toolchain matching the requirements", Gradle hasn't found the JBR: list its path in `org.gradle.java.installations.paths` in the project's `gradle.properties`. That path is machine-specific, so `AGENTS.md` records it under App settings.

7.2. Always use the project's Gradle wrapper, `./gradlew`. Build with `./gradlew assembleDebug`.

7.3. Run unit tests with `./gradlew testDebugUnitTest` (or `./gradlew test` for every variant). A reviewer's rerun adds `--rerun-tasks`, so that Gradle's build cache can't stand in for a run, and the review names it.

7.4. Run `./gradlew lint`, and report any new warnings in the ticket.

7.5. Record the output of `./gradlew --version` in the ticket, including its `Daemon JVM` line, which names the JDK that ran the build and the setting it came from.

7.6. The build specifies its Java toolchain version, so the JDK that compiles the code and runs unit tests doesn't depend on the machine. The ticket that sets up the app chooses the version.

7.7. Evidence from a test run names how many tests ran. `connectedDebugAndroidTest` can exit 0 having run none, for example after `INSTALL_FAILED_UPDATE_INCOMPATIBLE`, so read the count from its XML results under `build/outputs/androidTest-results/connected/`, and count a run of zero tests as a failure. A comma-separated list of classes in `-Pandroid.testInstrumentationRunnerArguments.class` has run only its first class, so check the count against the tests the run names.

## 8. Command-line emulator screenshots

8.1. Create the emulator's AVD with the Android CLI, `android emulator create`, and start a session's own instance of it as rule 8.8 says. `android emulator start <device>` can't choose a port or start the AVD read-only, so a session doesn't start a shared AVD with it. `android emulator create` takes only a device profile, and it fails if an AVD folder with the name it chooses already exists ("…avd already exists"), even one whose name differs only in case. Don't remove or change an existing AVD to get round this: reuse it if it runs the API level the ticket needs (`android emulator list`), or else send it to the product owner. Alternative: the deprecated tools `avdmanager`, `sdkmanager` and `emulator`, which still ship with the SDK, although cmdline-tools 12.0's `avdmanager` can't read an API 37 system image. Every `android` command passes `--no-metrics`, so the CLI collects no usage data.

8.2. Build with `./gradlew assembleDebug`, install with `adb install -r <apk>` and launch with `adb shell am start -W -n <package>/<activity>`, with `ANDROID_SERIAL` set (rule 8.8). `./gradlew installDebug` gives no way to choose the device, so a session doesn't use it. Before a screenshot, check that the `Activity:` line that `-W` prints names the app's own activity. Just after an install, a system "Updating..." screen can cover the app; if it does, run `adb shell am force-stop <package>` and launch again.

8.3. Take each screenshot with `adb exec-out screencap -p > <file>.png`. Alternative: `android screen capture`, with `--no-metrics` (rule 8.1).

8.4. When a criterion needs dark theme or a large font scale, set them with `adb shell cmd uimode night yes` and `adb shell settings put system font_scale <scale>`. Alternative: change them in the emulator's Settings.

8.5. Name each screenshot after the ID of the acceptance criterion it shows, as `<feature>-C<n>`, save it in `~/Library/Caches/<repository>/evidence/<ticket number>-<platform>/`, and give that folder's path in the ticket with each file listed under its criterion. `gh` can't attach an image, and a session's own temporary folder doesn't outlive it. Never commit it. One screenshot can show several criteria: name it after all of them, for example `saved-items-C1-C2.png`. For a criterion of a ticket that changes no app behaviour, which has no ID, use a short name for the criterion.

8.6. When a criterion needs a screenshot of something off screen at launch, such as the end of a long list, scroll with `adb shell input swipe <x1> <y1> <x2> <y2> [duration(ms)]`, dragging from low on the screen to high, and repeat until the element is in view before the screenshot. When it needs taps or typing, such as an open dialog or text in a field, tap with `adb shell input tap <x> <y>` and type with `adb shell input text <string>`, taking each element's coordinates from its `bounds` in `adb shell uiautomator dump`, which writes the screen's UI hierarchy to `/sdcard/window_dump.xml`. Before tapping a button that submits typed text, dump again and check that the field holds all of it: a system dialog that opens meanwhile can take some of the input. `uiautomator dump` waits for the screen to go idle, so it fails ("could not get idle state") while something animates without end, such as an indeterminate progress indicator. Then take the coordinates from a screenshot instead, and check the field's text in a screenshot before tapping the button.

8.7. For stable review flows, maintain native AndroidX UI tests; choose UI Automator when the check crosses between the app and system UI. Assert the action's result with bounded element waits. Every session runs on its own emulator (rule 8.8); use `adb -s <serial>` or `ANDROID_SERIAL`, and each Android CLI command's explicit device selector, for installation, input, inspection and cleanup.

8.8. **Required.** Every session that reaches a device, whatever its role, runs on an emulator of its own, which no other session uses, and sets `ANDROID_SERIAL` to its serial, `emulator-<port>`, for every Gradle and `adb` command that reaches a device. A command that reads only the host, such as `adb version` or `./gradlew --version`, doesn't need it. Every session sets it, because one without it reaches every device: `connectedDebugAndroidTest` runs on every connected device and uninstalls the app when it ends (rule 6.5), deleting another session's app and data mid-run.

- **Start.** Every session, a reviewer's included, starts its emulator when it adds its worktree, as a read-only instance of an existing AVD that runs the API level the ticket needs (rule 8.1): `emulator -avd <AVD> -read-only -port <port>`, adding `-no-window` when no one needs to see it. `-read-only` lets several instances run on the same AVD, but they can't save a snapshot. Choose an even port from 5556 to 5584 that is free, with the port after it. A port that `adb devices` lists isn't free; a test that binds both ports on `127.0.0.1` also finds an emulator that `adb` hasn't attached, and meets this rule. Leave `-gpu` at its default or pass `-gpu host`, not `-gpu swiftshader_indirect`.
- **Every instance read-only.** A read-only instance doesn't start while the same AVD runs without the flag. So everyone, sessions and people, starts a shared AVD with `-read-only`, never with `android emulator start` (rule 8.1). Never stop or wipe an instance another session or a person started.
- **Check it's yours.** When `adb -s emulator-<port> shell getprop sys.boot_completed` prints `1`, check that `adb -s emulator-<port> emu avd name` prints the AVD you started, before any other command. If the name differs, stop your own instance by its process and choose another port.
- **Stop.** Stop it with `adb -s emulator-<port> emu kill` when the session removes its worktree. Leave Gradle daemons to expire: `./gradlew --stop` stops every session's daemons of that Gradle version, ending their builds and test runs.

Alternative: an AVD of the session's own in a new `ANDROID_AVD_HOME`, with `ANDROID_USER_HOME` beside it; but `android emulator create` there chooses its own system image, downloading it into the SDK, and can't name the AVD or choose its API level.

## 9. Dependencies

This section is this reference's default. An app may override any of it by recording a deviation (How to read this reference).

9.1. **Required (third-party decision).** **Preference order.** Build on these, in order:

1. **Google's own libraries**: AndroidX/Jetpack and any other library Google publishes officially, such as Hilt (rule 9.3), plus the Kotlin libraries JetBrains publishes (the standard library, coroutines and flows, serialization, and `kotlinx-coroutines-test`) and JUnit 4 for local tests. These need no decision.
2. **A highly respected third-party library**, widely used, actively maintained and stable, where the first tier doesn't offer what a ticket needs. It needs a one-line decision in the ticket, naming the library and what its documentation says it brings, which the product owner approves with the ticket.
3. **Hand-written code**, where neither does.

Custom design-system components are expected; the order governs what they are built on.

9.2. **Dependency listing.** The ticket lists every artifact the build adds, including those a library brings with it, from `./gradlew :app:dependencies --configuration releaseRuntimeClasspath` compared with the same report on `main`. It marks each one first tier or third-party, so the product owner can confirm any that no decision named, or query a first-tier one.

9.3. **Hilt, from the first ViewModel.** Dependencies are injected with Hilt from the app's first ViewModel. Apply the Hilt Gradle plugin, `com.google.dagger.hilt.android`, and KSP, `com.google.devtools.ksp`, which Room already needs (rule 2.12), and add `com.google.dagger:hilt-android` with `ksp("com.google.dagger:hilt-compiler")`. Use KSP, not kapt: the `org.jetbrains.kotlin.kapt` (or `kotlin-kapt`) plugin is incompatible with built-in Kotlin, which rule 1.4 uses. Annotate the `Application` subclass `@HiltAndroidApp` and the activity `@AndroidEntryPoint`. Take Hilt's version from Dagger's releases page, as rule 1.12 says: developer.android.com's setup samples pin 2.57.1, which predates the Hilt Gradle plugin's AGP 9 support in 2.59. Wiring by hand is a deviation.

9.4. **Bindings.** Classes the app writes take their dependencies through an `@Inject constructor`. An interface, such as a repository's or a store's, is bound to its implementation with `@Binds` in an abstract `@Module` with `@InstallIn(SingletonComponent::class)`. Objects the app can't construct itself, such as the Room database and the coroutine dispatchers (rule 2.10), come from `@Provides` functions, with a qualifier annotation for each dispatcher. App-wide objects are `@Singleton`.

9.5. **ViewModels.** Each ViewModel is `@HiltViewModel` with an `@Inject constructor`. The screen-level composable (rule 2.6) gets it with `hiltViewModel()` from `androidx.hilt:hilt-lifecycle-viewmodel-compose`, not `hilt-navigation-compose`. Called inside a `NavEntry`, it is scoped to that entry by rule 4.5's decorator. A ViewModel that needs its navigation key takes it by assisted injection: `@HiltViewModel(assistedFactory = …Factory::class)` on a class with an `@AssistedInject constructor(@Assisted val key: …)` and an `@AssistedFactory` interface, obtained with `hiltViewModel<…ViewModel, …ViewModel.Factory>(creationCallback = { factory -> factory.create(key) })`. Values passed through assisted parameters aren't saved to disk, so state that must survive process death still uses `SavedStateHandle` (rule 2.11).
