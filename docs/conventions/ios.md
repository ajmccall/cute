# iOS convention reference

The rules an iOS builder follows and an iOS reviewer checks against. Cite a rule by its number, for example "rule 4.3". A review finding names the rule behind it where there is one. A breach of a required rule (Required rules, below) is a **required finding**, which the review sends back; a breach of any other rule, which is advisory, is a **nit**, which the builder may take or leave. A finding with no rule behind it still stands, but this reference doesn't make it required. The nine sections match the Android reference, so "section 4" means navigation on both.

`ios-sources.md` holds each rule's sources, quotations and the observations behind it, under the same rule numbers. Read it when a rule is questioned, unclear or being changed.

## How to read this reference

- **Assumes** the current stable toolchain on 2026-10-02: Xcode 27, with Swift 6.4 and the iOS 27 SDK. Update this line, and any rule it affects, when a new Xcode leaves beta.
- A project never edits this reference. It departs from a required rule, including the section 9 third-party decision, by recording a deviation, which the product owner approves: in `AGENTS.md`'s **Deviations** for the whole app, or in the feature's **Deliberate platform differences** for one feature. Departing from an advisory rule needs no deviation.
- Where a rule names an alternative ("Alternative: …"), a project that uses the alternative isn't departing from the rule, so it records no deviation.
- A rule whose API needs a minimum OS is labelled with it, for example **iOS 17+**. The project decides its minimum OS. If that minimum is lower than a rule's label, the builder raises it as a decision rather than working around it. Rules without a label use APIs available from iOS 13.
- `AGENTS.md` holds the rules both platforms share, such as parity and how sessions isolate their work, and they aren't repeated here. Section 9 holds the default dependencies.

## Required rules

A rule is **required** when a breach harms a person using the app (they can't read, reach or leave something, or they lose saved data), commits the app to something without the product owner, or breaks parallel sessions. Architecture, test method, project setup, look and command-line how-to are advisory. The eight required rules, each labelled **Required** in place:

- 2.7: the SwiftData schema is versioned from the first release, so saved data survives an upgrade.
- 4.3: the system Back button, and the edge swipe back.
- 4.5: a full-screen cover shows its own visible close control.
- 5.1: Dynamic Type, up to the largest accessibility sizes.
- 5.2: hit targets of 44 pt, never under 28 pt.
- 5.3: a VoiceOver label on every control and meaningful image.
- 8.8: a Simulator of its own per session.
- 9.1, the third-party decision only: no third-party package without the product owner's decision. The preference order itself is advisory.

Every other rule is advisory: a builder follows it by default, and departing from it needs no deviation.

## Design versus platform

- The project's design source, named in `AGENTS.md`, owns the look: colour, type, shape, layout and custom components.
- This reference owns the behaviour that people and the OS rely on: navigation and back gestures, accessibility (Dynamic Type, VoiceOver, hit targets) and system integration.
- When the design really clashes with a rule here, the builder doesn't settle it. It sends the clash to the product owner as a decision in the ticket.

## 1. Project structure

1.1. The app is an Xcode project with an app target, a unit-test target and a UI-test target.

1.2. The entry point is one type that conforms to `App`, marked `@main`, whose `body` declares its scenes (`WindowGroup`). **iOS 14+**.

1.3. Colours and images live in the asset catalog. The app icon is a single Icon Composer file, which supports Liquid Glass, and from which Xcode generates icons for earlier OS releases. Alternative: an app icon set in the asset catalog, which keeps an existing icon unchanged on earlier releases. If the design source supplies the icon in one of these forms, use that form.

1.4. User-facing strings live in a String Catalog (`.xcstrings`), even before the app is localised.

1.5. Names follow the Swift API Design Guidelines.

1.6. Keep main-actor default isolation on, as Xcode 26 and later set it for new app projects, and turn on Approachable Concurrency, which Apple recommends for all projects.

1.7. Use the Swift 6 language mode, so data races are compile-time errors. Alternative: Swift 5 mode with complete concurrency checking.

1.8. Group source files by feature, with shared code in its own group.

## 2. Architecture layers and state holders

2.1. Keep three parts. Views only display state and send user actions. Observable model types hold screen and app state and the logic that changes it. Services (data, system frameworks) sit behind protocols (rule 9.4) and know nothing about views. Alternative: views that read model data directly, as in Apple's samples, with no screen-level model.

2.2. State shared between views lives in a class marked `@Observable`. The view that creates it owns it with `@State`; other views receive it through their initialiser or the environment, and use `@Bindable` to bind to its properties. **iOS 17+**.

2.3. Use the `Observable` macro rather than `ObservableObject`, `@Published` and `@StateObject` in new code. Keep the older types only if the project's minimum OS is below iOS 17. **iOS 17+**.

2.4. State that belongs to one view is `@State private`. A child that must change it receives a `@Binding`.

2.5. Async work tied to a view's lifetime starts in `.task`, which SwiftUI cancels when the view goes away. **iOS 15+**.

2.6. State that views observe is main-actor isolated: under rule 1.6 by default, otherwise mark the type `@MainActor`. Slow work runs off the main actor in async service code.

2.7. **Required.** **Data saved with SwiftData.** Version the schema from the first release: the models live in a `VersionedSchema`, listed in a `SchemaMigrationPlan`, and the container is created with that plan. Each later schema change adds its version to the plan, with a migration stage. **iOS 17+**. A store written by a later schema version can open without error under the earlier schema and its plan, and be migrated down, losing what the later version had added. A store whose main file isn't a database throws only `SwiftDataError.loadIssueModelContainer`, with no underlying error. So a ticket that must keep such stores checks an existing store before opening it: Core Data's `metadataForPersistentStore(type:at:options:)` returns the store's metadata, and `isConfiguration(withName:compatibleWithStoreMetadata:)` checks it against each version in the plan. This check reads the store's metadata only, so damaged pages further in pass it, and the open then fails.

## 3. Building UI

3.1. The design source comes first. If the project names none, use stock SwiftUI components and system styles as the HIG describes them. Restyling them is a look decision, which belongs to a design source, not to the builder.

3.2. Let standard bars, sheets, popovers and controls take Liquid Glass automatically. Don't rebuild them with custom chrome. Use `glassEffect` only for custom controls, sparingly, and never in the content layer. **iOS 26+** (`glassEffect`).

3.3. **Colour tokens.** Use system and semantic colours by default. A custom colour is a Color Set in the asset catalog, with light, dark and increased-contrast variants. No hard-coded colour values in views.

3.4. **Type tokens.** Use the system text styles (`.body`, `.headline` and so on). Apply a custom font with `Font.custom(_:size:relativeTo:)`, naming the text style it stands in for, so it scales with Dynamic Type like that style. Don't use `Font.custom(_:fixedSize:)` for text, because it doesn't scale. **iOS 14+**.

3.5. **Size tokens.** Spacing and sizes that should grow with text use `@ScaledMetric`. **iOS 14+**.

3.6. Tokens that aren't asset-catalog colours (for example spacing or corner radii from a design system) are passed down as custom environment values declared with `@Entry`. Alternative: a static constants type.

3.7. **Custom components.** When a custom design changes how a stock control looks but not what it does, write a style (`ButtonStyle`, `ToggleStyle` and so on) for the stock control. A `ButtonStyle` keeps the button's standard interaction behaviour and changes only its appearance. Otherwise compose views, and share repeated styling as a `ViewModifier` behind a `View` extension.

3.8. Every custom component meets section 5 itself: it scales with Dynamic Type, has a VoiceOver label and the right traits, and has a large enough hit target.

3.9. Not used. The number stays, so the rules after it keep theirs.

3.10. A `List` `swipeActions` action that opens a confirmation may close the revealed action before the confirmation appears. Test that lifecycle before treating a retained action as a requirement. Accept stock SwiftUI behaviour unless the design source requires otherwise; a retained action needs a custom control or UIKit alternative and is a decision for the product owner.

## 4. Navigation and back behaviour

4.1. Hierarchical navigation uses `NavigationStack` with value-based `navigationDestination(for:)`. When code needs to push, pop or restore the stack (for example deep links or state restoration), hold the path in state and pass it to `NavigationStack(path:)`. Otherwise the stack manages its own state. Don't use `NavigationView`. **iOS 16+**.

4.2. Top-level sections use a `TabView`, declared with `Tab` values. **iOS 18+** for `Tab`.

4.3. **Required.** Use the system Back button, and keep the edge swipe back. If the design source styles the Back button, the custom button must look like the standard one, behave like it (one tap goes back one level), and leave the edge swipe working. A design that drops the Back button or the edge swipe is a clash for the product owner (see **Design versus platform**).

4.4. A self-contained task is shown in a sheet, with an explicit Cancel button on the leading edge of its toolbar and a Done (or Save) button on the trailing edge. Without unsaved changes, the person can also dismiss the sheet by swiping down. While there are unsaved changes, block the swipe with `interactiveDismissDisabled`, and when the person taps Cancel, confirm with an action sheet (`confirmationDialog`) before discarding. **iOS 15+**. Under this rule, a swipe to dismiss a sheet with unsaved changes simply stops, with no confirmation. This reference doesn't use UIKit's `presentationControllerDidAttemptToDismiss(_:)`, and iOS 27's `dismissalConfirmationDialog(_:shouldPresent:actions:)` isn't part of this rule.

4.5. **Required.** A full-screen presentation (`fullScreenCover`) has no system Back, so it shows its own visible close control, which stays on screen at every text size: keep it outside the scrolling content, for example in a top `safeAreaInset`. VoiceOver's escape gesture also closes it (`accessibilityAction(.escape)`).

## 5. Accessibility

5.1. **Required.** All text supports Dynamic Type, up to the largest accessibility sizes. Use text styles (rule 3.4), and let layouts wrap or reflow rather than truncate.

5.2. **Required.** Controls have a hit target of 44 × 44 pt by default and never less than 28 × 28 pt.

5.3. **Required.** Every control and meaningful image has a VoiceOver label: `accessibilityLabel` for icon-only controls, and values, hints and traits where they help. Group related elements with `accessibilityElement(children:)`. Purely decorative images use `Image(decorative:)`. A time shown as a clock, such as "0:05" or "1:02:30", has a label that says it in words ("5 seconds", "1 hour, 2 minutes, 30 seconds"), because VoiceOver reads the bare digits as a time of day.

5.4. Text contrast is at least 4.5:1 up to 17 pt, and 3:1 at 18 pt or bold. Never use colour alone to convey meaning.

5.5. Respect Reduce Motion: read `accessibilityReduceMotion` and replace large motion with a fade or nothing.

5.6. Once a flow has UI tests, every scenario calls `try app.performAccessibilityAudit()`, never `try?`, which throws its failures away. **iOS 17+**.

## 6. Unit testing

6.1. Unit tests use Swift Testing: `import Testing`, `@Test` functions, `#expect` for checks and `#require` to stop a test early.

6.2. UI tests and performance tests use XCTest (with XCUIAutomation for UI), because Swift Testing doesn't support them.

6.3. Unit tests cover models and logic directly, not views. Most of a project's tests are fast, well-isolated unit tests.

6.4. Cases that differ only in input are one parameterised test, `@Test(arguments:)`.

6.5. Async code is tested with `async` test functions. Events that should happen use `confirmation`.

6.6. Unit tests run inside the app. So the `App` type, and the services it creates (rule 9.3), run during the tests, and whatever the app does at launch, such as opening its saved data, also happens then. The ticket's pull request says how the tests keep away from the app's real data.

6.7. **When a ticket changes saved data.** Rules 6.8 to 6.10 apply to a ticket that adds or changes a write to saved data, or changes what the app does with a damaged store. They run on the real SwiftData store (rule 2.7), each in its own new temporary folder, away from the app's real data (rule 6.6). A stub store, including one that holds a write until the test releases it, and state a view model kept can't show what reached the disk, so neither is evidence for these rules.

6.8. **A write that can be cancelled** (for example when leaving a screen cancels its `.task` while the write runs) is tested cancelled at two points: just before the real store saves, and just after. Wrap the real store in a test store that forwards to it and waits on a gate at either point, and cancel the calling task there. After each, compare what the model types hold, and what the screen shows, with what the store holds, asserting every field the write saves, including a field a ticket adds to an existing write. Then reopen the store and compare again. A task cancelled after the save has still saved, so code that updates its state only when the task wasn't cancelled leaves the screen behind the store. Cover the cases with one parameterised test (rule 6.4).

6.9. **Keeping files when damage is found.** Where a ticket requires the store's files to be kept rather than deleted, moved, reset or replaced, show it on the store the app actually opens, at each point the ticket names, such as at launch and while running. Checkpoint the store's write-ahead log into the main file, damage a page of the main file, run the access, and compare the main file and each companion file (`-wal`, `-shm`) before and after, by bytes and inode. The `-shm` file's reader bookkeeping may change, and an assertion allows for it.

6.10. **Damage fixtures.** Releasing a `ModelContainer` can checkpoint the store after the test has moved on, writing over damage injected in the meantime. So seed in a separate folder, keep the seed's container alive with `withExtendedLifetime` until its files have been copied into the test's own folder, damage the copy, and `#require` the exact damaged bytes before the access under test.

## 7. Command-line build

7.1. Build and run the tests with `xcodebuild`, naming the scheme and a Simulator destination, the session's own device by its UDID (rule 8.8):

```sh
xcodebuild -scheme <App> -destination 'platform=iOS Simulator,id=<UDID>' build
xcodebuild -scheme <App> -destination 'platform=iOS Simulator,id=<UDID>' test
```

7.2. Choose the device type and the OS version from `xcrun simctl list devicetypes` and `xcrun simctl list runtimes`, and create the session's own device from them (rule 8.8). Record in the ticket's pull request the destination, the device type, the OS version and the runtime build, which `xcrun simctl getenv <UDID> SIMULATOR_RUNTIME_BUILD_VERSION` prints, so a reviewer can create a device like it on another Mac, where the UDID names nothing. The runtime build tells apart two runtimes with one identifier (for example a beta and a release of the same OS version), which `OS=` can't.

7.3. Record `xcodebuild -version` in the ticket's pull request, so a reviewer knows which toolchain built it.

7.4. If the project has test plans, run them with `-testPlan`.

7.5. The test run a builder hands off with builds from a new, empty `-derivedDataPath <folder>`, so that an incremental build can't hide a failure that the reviewer's clean build shows.

7.6. Evidence from a test run names how many tests ran, from its result bundle (`-resultBundlePath <path>`): `xcrun xcresulttool get test-results summary --path <path>` prints `totalTestCount`. A run that ran no tests still prints `TEST SUCCEEDED`, and counts as a failure. In `-only-testing`, a Swift Testing test's identifier ends in `()`, as `<target>/<suite>/<test>()`; without them the filter matches nothing. `test-without-building` runs whatever test binary the last build left, so build in the same run, or use `test`.

7.7. A failed test can look like a hang: `xcodebuild` then collects diagnostics, for up to 600 seconds on this toolchain. Pass `-collect-test-diagnostics never -test-timeouts-enabled YES -maximum-test-execution-time-allowance <seconds>`, so a failure reports at once and a stuck test stops. Run the whole suite with `-parallel-testing-enabled NO` as well, not only UI scenarios (rule 8.6): parallel testing runs the tests on clones of the Simulator, and on a loaded machine the clones stall timing tests until they fail.

## 8. Command-line Simulator screenshots

8.1. Boot the session's own Simulator (rule 8.8), then install and launch the build with `xcrun simctl boot`, `xcrun simctl install` and `xcrun simctl launch`. Alternative: `devicectl device install app` and `devicectl device process launch`; try the install on a simulated device before relying on it.

8.2. Take each screenshot with `xcrun simctl io <UDID> screenshot <file>.png`.

8.3. Before taking screenshots, fix the status bar with `xcrun simctl status_bar <UDID> override` (for example `--time 9:41`), and clear it afterwards.

8.4. When a criterion needs dark appearance or a large text size, set them with `xcrun simctl ui <UDID> appearance dark` and `xcrun simctl ui <UDID> content_size <size>`. After changing the text size, relaunch the app with `xcrun simctl launch --terminate-running-process` before the screenshot, because a running app's stock navigation bar can clip its large title until the next launch. When the screenshot needs state that a relaunch would lose (held only in memory), build that state at the default text size with the native UI test (rule 8.6), change the text size while the test waits, and check that the large title isn't clipped in the screenshot. Building the state at the largest accessibility size instead stalled the test: with an alert's keyboard up, each step waited 60 seconds for app animations to finish.

8.5. Name each screenshot after the ID of the acceptance criterion it shows, as `<feature>-C<n>`, save it in `~/Library/Caches/<repository>/evidence/<ticket number>-<platform>/`, and give that folder's path in the ticket's pull request with each file listed under its criterion. `gh` can't attach an image, and a session's own temporary folder doesn't outlive it. Never commit it. One screenshot can show several criteria: name it after all of them, for example `saved-items-C1-C2.png`. For a criterion of a ticket that changes no app behaviour, which has no ID, use a short name for the criterion. Alternative to rules 8.1 and 8.2, once UI tests exist: attach `XCTAttachment` screenshots from the UI test.

8.6. `simctl` manages lifecycle and screenshots but can't scroll, tap or type. Use maintained XCUITest scenarios for stable review interactions. The test launches the production app, drives it with `tap()`, `typeText(_:)` and `swipeUp(velocity:)`, waits for elements with `waitForExistence(timeout:)`, and asserts the action's result. `isHittable` can be true for an element scrolled off screen, as a title was at the largest text size, so scroll it into view before asserting on it, and check the screenshot. Retain useful screenshots with `XCTAttachment(screenshot: XCUIScreen.main.screenshot())` and `.keepAlways`; successful tests otherwise discard attachments. Run selected scenarios on the session's own device, named by its UDID (rules 7.1 and 8.8), with `-parallel-testing-enabled NO`, `-only-testing:<UI test target>/<class>` and `-resultBundlePath <path>`. `-parallel-testing-enabled NO` keeps appearance/text-size/status-bar setup on the named device rather than a test clone. Export screenshots with `xcrun xcresulttool export attachments --path <path> --output-path <folder>` and name them after their criteria (rule 8.5). One-off exploratory tests may remain temporary; return a durable regression and its reproduction sequence to the builder when exploration finds a defect.

8.7. The Simulator has no network of its own. Taking the Simulator offline would take the Mac offline too, cutting off the session that drives it. So a criterion that needs the device offline isn't shown in a screenshot: unit tests with a stub service (rule 9.4) show it, the ticket's pull request says so, and the product owner checks it at acceptance.

8.8. **Required.** Every session that reaches a device, whatever its role, runs on a Simulator of its own, which no other session uses. Sessions on one device install the same bundle ID, so concurrent `xcodebuild test` runs overwrite each other's app and share its data container; build products are separate per worktree, but the device isn't. `booted` doesn't name a device: when several devices are booted, `simctl` chooses one of them. So:

- Every session creates its device when it adds its worktree, named after the worktree: `xcrun simctl create <worktree name> <device type> <runtime>`. It prints the new device's UDID.
- Name the device with `id=<UDID>` in every `xcodebuild` destination (rule 7.1), and with its UDID in place of `booted` in every `simctl` command: boot, install, launch, settings, screenshots and cleanup target that device only. Never boot, erase or install on a device another session or a person started.
- Remove it when the session removes its worktree, with `xcrun simctl shutdown <UDID>` and `xcrun simctl delete <UDID>`.
- Automated tests and opening a human-visible Simulator window are separate capabilities.

## 9. Dependencies

This section is this reference's default. An app may override any of it by recording a deviation (How to read this reference).

9.1. **Required (third-party decision).** **Preference order.** Build on these, in order:

1. **Apple's own frameworks and packages**: the SDK's frameworks and any Swift package Apple publishes officially, such as Swift Collections or Swift Algorithms. These need no decision.
2. **A highly respected third-party package**, widely used, actively maintained and stable, where the first tier doesn't offer what a ticket needs. It needs a one-line decision in the ticket, naming the package and what its documentation says it brings, which the product owner approves with the ticket.
3. **Hand-written code**, where neither does.

Custom design-system components are expected; the order governs what they are built on. Packages are added with Swift Package Manager at their latest stable release, with the Up to Next Major Version rule; never copy a version from a sample, which drifts behind the stable releases.

9.2. **Dependency listing.** The ticket's pull request lists every package the build adds compared with `main`, from the project's `Package.resolved`, including packages that another package brings with it. It marks each one first tier or third-party, so the product owner can confirm any that no decision named, or query a first-tier one.

9.3. Wire dependencies by hand. Create services and app-wide models in the `App` type, pass them into initialisers, and put shared `@Observable` objects in the environment with `.environment(_:)`. No dependency-injection framework. **iOS 17+** (for the `Observable` overload of `.environment(_:)`).

9.4. Each service is used through a protocol, so tests can pass in a stub.
