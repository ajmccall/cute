# Cute

Cute (Chess Up To Eleven) is a native iOS and Android chess app with a backgammon-style doubling cube. It is two apps built from one **spec**: `docs/schema/` says what a player sees, hears, does and has saved, and both apps match it. `docs/brief.md` says why.

Alasdair McCall (`@ajmccall`) is the product owner: he decides product and UX questions, approves each spec change, accepts each build and merges into `main`.

## Parity

- **Parity is at the spec's level.** Both apps satisfy every acceptance criterion a ticket names. Below that, each platform does what is simplest and most native for it.
- **Each platform is written fresh from the spec**, in its own folder: SwiftUI in `ios/`, Jetpack Compose in `android/`. A builder reads the spec, never the other platform's code.
- **A difference a player would notice in ordinary use** goes to the product owner as a question. Once decided, it is written in that feature's spec file under **Deliberate platform differences**.
- **A difference only an unusual condition reaches**, such as storage failing or the system ending the app partway through, needs no question: record it there in one line, "Differs, not decided". Either way the app fails safely: it keeps the player's saved data and never shows something as done that wasn't.

## A ticket, start to finish

**On trial.** Until the product owner ends the trial, `slim-agents` stands in for `main` everywhere below: cut ticket branches from `origin/slim-agents`, aim the ticket's pull request at it, and start spec and orchestrating sessions in its checkout, `cute-slim-agents`. `main` itself is left alone.

A ticket is a GitHub issue on `ajmccall/cute`, worked with `gh`. Each step ends where its last sentence says; the next step starts in a fresh session or sub-agent.

1. **Spec.** Change the feature's file in `docs/schema/` on a ticket branch, `<issue number>-<short-name>` from `origin/main`, and open a draft pull request into `main`. A new feature file takes the nine sections of `docs/schema/local-game.md`, and each criterion a stable ID, `C<n>`. Done when the product owner approves the spec commit on the issue.
2. **Build, once per platform.** In a worktree beside the repository, on `<ticket branch>-ios` or `<ticket branch>-android`: write each criterion's test first (`tdd`), make it pass, then run the platform's whole test suite and the interaction checks in `docs/testing.md` on a simulator or emulator. Done when a pull request into the ticket branch lists every criterion the ticket names with the test or device check that shows it, and the suite's result.
3. **Review, once per platform.** A fresh context that has seen none of the build runs `code-review` on the platform pull request against the ticket branch, reruns the test suite, and checks each named criterion against the spec and the platform's convention reference. Done when it has posted its findings on the pull request and either squash-merged it into the ticket branch or sent it back to step 2 with the findings that must change.
4. **Accept.** When both platforms are merged, tell the product owner what to try and list anything only a person can check, such as spoken VoiceOver and TalkBack output. He accepts, or returns it naming the platform and the problem, and he squash-merges the ticket's pull request into `main`.

## Working in parallel

Both platforms of a ticket build at once, and several tickets may be in flight on this one machine. Every session and sub-agent therefore **isolates** its work:

- **A worktree of its own**, beside the repository and named after its branch: `../cute-<branch>`, or `../cute-<branch>-review` for a review. The main checkout stays on `main` with a clean tree; it is where orchestrating sessions start and nothing is edited.
- **A device of its own**, created for the session and named after its worktree: an iOS simulator, or an Android emulator on its own port, each addressed by its ID in every command. Check the runtime or system image exists before claiming work, and ask the product owner if it doesn't.
- **Build output inside its worktree**: pass `-derivedDataPath <worktree>/.build/DerivedData` to `xcodebuild`. Gradle already builds per project folder.
- **It removes its worktree and device when its step is done.** A worktree someone else left is reused if `git status` is clean, and otherwise raised with the product owner.

**Orchestrating.** `Orchestrate ticket <n>` runs steps 2 and 3 from the main checkout: a sub-agent per platform build, both at once, then a fresh sub-agent per review, one review at a time since each merges into the ticket branch. The orchestrator edits nothing itself. It reads where a ticket stands from its pull requests, so sending the same prompt again resumes it: no platform pull request means build, an open one means review, a merged one means done. A question for the product owner stops that platform, is asked at once with options and a recommendation, and its answer goes back to the same sub-agent. It stops when both platforms are merged and step 4 is ready.

**Two tickets on one spec file.** Before adding a criterion, check open pull requests for other tickets changing the same feature file, and take criterion IDs none of them uses. The ticket that merges second takes in `main` and resolves the spec before its builds are accepted.

## Where to look

- `docs/conventions/ios.md`, `docs/conventions/android.md`: read your platform's before building or reviewing it. Rule numbers below cite them. They came from a framework this project no longer carries: where one cites `roles/…`, `framework/…`, a platform part or a change request, this file's steps and the pull request are what it means.
- `docs/testing.md`: the interaction checks every build runs on a device.
- `GLOSSARY.md`: use its terms in the spec, the code and the tests. Game and match are different things.

## Skills

Matt Pocock's skills (`github.com/mattpocock/skills`), by whatever name the harness gives them: `grill-with-docs` and `to-spec` for step 1, `tdd` and `diagnosing-bugs` for step 2, `code-review` for step 3. Step 2 is the `implement` skill written out, so a sub-agent can run it. The issue tracker those skills ask for is GitHub Issues on `ajmccall/cute`.

## App settings

- **App identifier:** `md.alasdair.cute` for the iOS bundle ID and Android `applicationId` and `namespace`.
- **iOS:** minimum iOS 26; Xcode 27.0, iOS SDK 27.0.
- **Android:** minSdk 36, compileSdk 37 at minor release 2, targetSdk 36; Java 21.
- **Android JDK** (Android rule 7.1): set `JAVA_HOME` to Android Studio's bundled JBR, `/Applications/Android Studio.app/Contents/jbr/Contents/Home`. On the product owner's machine `~/.gradle/gradle.properties` points Gradle at JDK 17, so pass `-Dorg.gradle.java.home="$JAVA_HOME"` to every Gradle command.
- **Android colour** (Android rule 3.5): dynamic colour where supported.
- **Design:** each platform's standard components.
