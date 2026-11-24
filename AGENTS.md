# Cute agent workflow

Cute is a native iOS and Android chess app with a shared backend for two-player games. A backgammon-style doubling cube lets either player offer to double the stakes during a game; initially, the stakes are points only.

## Follow `framework/`

Every role follows the framework in `framework/`. Each session reads this file, its role page's Read line, and the harness adapter's README if Where things live names one, as they are on the ticket branch; each file on its own, not several in one command. The reading lists:

- **Product** (`framework/roles/product.md`): this file, `framework/process.md`, the idea or ticket, the app schema's index and the feature files the work touches, and the product brief.
- **Builder** (`framework/roles/builder.md`): this file, the ticket and its platform part, the feature files the schema change touches on the ticket branch, and its platform's convention reference.
- **Reviewer** (`framework/roles/reviewer.md`): the builder's list, plus the testing reference.

Everything else is lookup, named where it's needed. This file only says which role each skill runs under, who holds each human role, where the project keeps its material, and the app's settings and deviations.

**Prerequisites:** every session runs `framework/hooks/install` when it starts, or its harness adapter does (`framework/hooks/README.md`), and has the skills below.

## Skills and roles

The skills are a prerequisite: Matt Pocock's skills (`github.com/mattpocock/skills`), at the commit the harness adapter pins, installed as its README says, or where the project runs without an adapter, at the commit the Claude Code adapter's `marketplace.json` names. A harness without plugin prefixes, such as pi, names a skill `mattpocock-skills:<name>` by its own name for `<name>`. A session starts with one row's first column, on a ticket or an idea: a skill by its qualified name, the Land prompt, or the Orchestrate prompt. It also follows the page beside it: a role page, whose overrides win over the skill, or for the Orchestrate prompt, `framework/orchestrate.md`, which starts the builder and reviewer sessions itself. A session started without the skills stops and tells the human.

| Start a session with | Page |
|---|---|
| `mattpocock-skills:grill-with-docs`, `mattpocock-skills:to-spec`, `mattpocock-skills:to-tickets`, `mattpocock-skills:grilling`, `mattpocock-skills:retro` | `framework/roles/product.md` |
| `Land ticket <n> as the product role` | `framework/roles/product.md` |
| `mattpocock-skills:implement`, `mattpocock-skills:tdd`, `mattpocock-skills:diagnosing-bugs` | `framework/roles/builder.md` |
| `mattpocock-skills:code-review` | `framework/roles/reviewer.md` |
| `Orchestrate ticket <n> for iOS and Android`, `for iOS` or `for Android`; `Orchestrate ticket <n>` with no platform work | `framework/orchestrate.md` |

`framework/` is a git subtree of `git@github.com-personal:ajmccall/dual-native.git`, taken at framework release 6.3.3. Only a take ticket edits it (`framework/framework-changes.md`).

## Human roles

- **Product owner:** Alasdair McCall (`@ajmccall`)
- **Framework steward:** Alasdair McCall (`@ajmccall`)

Alasdair McCall holds both roles.

## Where things live

| What | Path |
|---|---|
| App schema | `docs/schema/` |
| Product brief | `docs/brief.md` |
| Decision records | <folder, where the skills' ADRs also go> |
| Glossary | `GLOSSARY.md` |
| iOS app | ios/ (created by #5) |
| Android app | android/ (created by #6) |
| iOS convention reference | `framework/conventions/ios.md` |
| Android convention reference | `framework/conventions/android.md` |
| Design source | Each platform's standard components (#2). |
| Testing reference | `docs/testing.md` |
| Tracker | GitHub Issues on `ajmccall/cute` |
| Tracker binding | `framework/trackers/github.md` |
| Harness adapter | `framework/adapters/pi` |

## App settings

Initial playtest settings (#2):

- **App identifier:** `md.alasdair.cute` for the iOS bundle ID and Android `applicationId` and `namespace` (from `alasdair.md`, #2).
- **iOS:** Minimum iOS 26; Xcode 27.0, iOS SDK 27.0.
- **Android:** minSdk 36, compileSdk 37 at minor release 2, targetSdk 36; Java 21. compileSdk 37 takes the latest stable AndroidX releases (product owner, 2b on #6).
- **Android JDK** (Android rule 7.1): Set JAVA_HOME and Studio's Gradle JDK to the bundled JBR; no daemon JVM override. Local macOS path: `/Applications/Android Studio.app/Contents/jbr/Contents/Home`. Limit on the product owner's machine: `~/.gradle/gradle.properties` sets `org.gradle.java.home` to Homebrew JDK 17, so each Gradle command there passes `-Dorg.gradle.java.home="$JAVA_HOME"` (#6).
- **Android colour** (Android rule 3.5): Dynamic colour where supported.
- **Spoken screen-reader output** (builder override 11, reviewer override 9): Check at acceptance.
- **Boundary terms:** Cute, Cute Up To Eleven

Other settings:

- <Any other setting that tickets build on, or "None">

## Agent skills

<The block that `setup-matt-pocock-skills` writes: the issue tracker, the triage labels and the domain docs the skills read. Run the setup once, then keep its block here. Where its docs and the tracker binding disagree, the binding wins.>

## Deviations

<Each place where the whole app departs from a convention reference. The reference itself is never edited. Give the rule, what the app does instead, and the decision record behind it. A departure that only one feature makes is recorded in that feature's schema file, under **Deliberate platform differences**, not here.>

- <Platform> rule <number>: <what the app does instead> (<link to its decision record>)
