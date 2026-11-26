# Cute

Cute (Chess Up To Eleven) is a native iOS and Android chess app with a backgammon-style doubling cube. It is two apps built from one **schema**: `docs/schema/` says what a player sees, hears, does and has saved, in numbered acceptance criteria, and both apps match it. `docs/brief.md` says why.

Alasdair McCall (`@ajmccall`) is the product owner: he decides product and UX questions, approves each schema change, accepts each build and merges into `main`.

Work follows Matt Pocock's skills (`github.com/mattpocock/skills`): `grill-with-docs` → `to-spec` → `to-tickets` → `implement` → `code-review`. This file adds only what those skills don't know: the schema, parity, and how sessions share one machine.

## Parity

- **Parity is at the schema's level.** Both apps satisfy every acceptance criterion a feature names. Below that, each platform does what is simplest and most native for it.
- **Each platform is written fresh from the schema**, in its own folder: SwiftUI in `ios/`, Jetpack Compose in `android/`. A builder reads the schema, never the other platform's code.
- **A difference a player would notice in ordinary use** goes to the product owner as a question. Once decided, it is written in the schema file it belongs to, under **Deliberate platform differences**.
- **A difference only an unusual condition reaches**, such as storage failing or the system ending the app partway through, needs no question: record it there in one line, "Differs, not decided". Either way the app fails safely: it keeps the player's saved data and never shows something as done that wasn't.

## A feature, start to finish

**On trial.** Until the product owner ends the trial, `slim-agents` stands in for `main` everywhere below: cut feature branches from `origin/slim-agents`, aim the feature's pull request at it, and start sessions in its checkout, `cute-slim-agents`. `main` itself is left alone.

A **feature** is the issue `to-spec` publishes; its **tickets** are the sub-issues `to-tickets` publishes under it. Issues live on `ajmccall/cute`, worked with `gh`. Each step ends where its last sentence says; the next starts in a fresh session or sub-agent.

1. **Spec**, started by the product owner: `grill-with-docs`, then `to-spec`. Beside the issue `to-spec` publishes, commit the schema change on a feature branch, `<issue number>-<short-name>` from `origin/main`, and open a draft pull request into `main` that the issue links. A new schema file takes the nine sections of `docs/schema/local-game.md`; each criterion takes a stable ID, `C<n>`. The issue cites criteria by ID, such as `local-game#C10`, and leaves their wording to the schema. Done when the product owner approves the schema commit on the issue.
2. **Tickets**, started by the product owner: `to-tickets` on the feature issue. Slice by platform: each ticket is one platform's complete path through a set of criteria, labelled `platform:ios` or `platform:android`, with those criterion IDs as its acceptance checkboxes. Every criterion the feature names appears on one iOS ticket and one Android ticket; a small feature is exactly two tickets. A ticket is blocked only by tickets of its own platform. Done when the product owner approves the breakdown and the sub-issues exist.
3. **Build, once per ticket.** Follow the `implement` skill on the ticket, in a worktree on `<feature branch>-<ticket number>-<platform>`, cut from the feature branch. To what `implement` says, add the interaction checks in `docs/testing.md` on a simulator or emulator. Done when a pull request into the feature branch lists every criterion on the ticket with the test or device check that shows it, and the whole suite's result.
4. **Review, once per ticket.** A fresh context that has seen none of the build runs `code-review` on the pull request with the feature branch as its fixed point, reruns the test suite, and checks each criterion against the schema and the platform's convention reference. Done when it has posted its findings and either squash-merged the pull request and closed the ticket, or sent it back to step 3 with the findings that must change.
5. **Accept.** When every ticket is closed, tell the product owner what to try and list anything only a person can check, such as spoken VoiceOver and TalkBack output. He accepts, or returns it naming the platform and the problem; he squash-merges the feature's pull request into `main`, and the feature issue is closed.

## Working in parallel

Both platforms of a feature build at once, and several features may be in flight on this one machine. Every session and sub-agent therefore **isolates** its work:

- **A worktree of its own**, beside the repository and named after its branch: `../cute-<branch>`, or `../cute-<branch>-review` for a review. The main checkout stays on `main` with a clean tree; it is where orchestrating sessions start and nothing is edited.
- **A device of its own**, created for the session and named after its worktree: an iOS simulator, or an Android emulator on its own port, each addressed by its ID in every command. Check the runtime or system image exists before starting a ticket, and ask the product owner if it doesn't.
- **Build output inside its worktree**: pass `-derivedDataPath <worktree>/.build/DerivedData` to `xcodebuild`. Gradle already builds per project folder.
- **It removes its worktree and device when its step is done.** A worktree someone else left is reused if `git status` is clean, and otherwise raised with the product owner.

**Orchestrating.** `Orchestrate feature <n>` runs steps 3 and 4 from the main checkout, one sub-agent per build and a fresh one per review. It works the **frontier**: every open ticket whose blockers are closed builds at once, so iOS and Android run side by side; reviews run one at a time, since each merges into the feature branch. The orchestrator edits nothing itself. Tickets and pull requests hold the state, so the same prompt resumes it: an open ticket with no pull request means build, with an open one means review, and a closed ticket is done. A question for the product owner stops that ticket, is asked at once with options and a recommendation, and its answer goes back to the same sub-agent. It stops when every ticket is closed and step 5 is ready.

**A sub-agent can't start `implement`**, which only a person can. The orchestrator finds the installed skill's file, `implement/SKILL.md` in the folder beside `tdd`'s, and gives each builder its path to read and follow, with the ticket as its argument. A person building one ticket by hand starts `implement` on it directly.

**Two features on one schema file.** Before adding a criterion, check open pull requests for other features changing the same file, and take criterion IDs none of them uses. The feature that merges second takes in `main` and resolves the schema before its builds are accepted.

## Where to look

- `docs/conventions/ios.md`, `docs/conventions/android.md`: read your platform's before building or reviewing it. Rule numbers below cite them. They came from a framework this project no longer carries: where one cites `roles/…`, `framework/…`, a platform part or a change request, this file's steps and the pull request are what it means.
- `docs/testing.md`: the interaction checks every build runs on a device.
- `GLOSSARY.md`: use its terms in the schema, the code and the tests. Game and match are different things.

## Agent skills

What Matt Pocock's skills ask a project to tell them:

- **Issue tracker:** GitHub Issues on `ajmccall/cute`, through `gh`. A ticket is a sub-issue of its feature, with GitHub's blocked-by links.
- **Triage label:** `ready-for-agent` on a published feature or ticket.
- **Domain docs:** `GLOSSARY.md` at the root; decision records in `docs/adr/`, created when the first one is written.

## App settings

- **App identifier:** `md.alasdair.cute` for the iOS bundle ID and Android `applicationId` and `namespace`.
- **iOS:** minimum iOS 26; Xcode 27.0, iOS SDK 27.0.
- **Android:** minSdk 36, compileSdk 37 at minor release 2, targetSdk 36; Java 21.
- **Android JDK** (Android rule 7.1): set `JAVA_HOME` to Android Studio's bundled JBR, `/Applications/Android Studio.app/Contents/jbr/Contents/Home`. On the product owner's machine `~/.gradle/gradle.properties` points Gradle at JDK 17, so pass `-Dorg.gradle.java.home="$JAVA_HOME"` to every Gradle command.
- **Android colour** (Android rule 3.5): dynamic colour where supported.
- **Design:** each platform's standard components.
