# <App name> agent workflow

<Copy this file to the root of the project as `AGENTS.md`, then replace each placeholder. Keep every heading and every row: the framework's roles look each one up. Write "None" where the project has nothing to record.>

<One or two sentences on what the app is.>

## Follow `framework/`

Every role follows the framework in `framework/`. Each session reads this file, its role page's Read line, and the harness adapter's README if Where things live names one, as they are on the ticket branch; each file on its own, not several in one command. The reading lists:

- **Product** (`framework/roles/product.md`): this file, `framework/process.md`, the idea or ticket, the app schema's index and the feature files the work touches, and the product brief.
- **Builder** (`framework/roles/builder.md`): this file, the ticket and its platform part, the feature files the schema change touches on the ticket branch, and its platform's convention reference.
- **Reviewer** (`framework/roles/reviewer.md`): the builder's list, plus the testing reference.

Everything else is lookup, named where it's needed. This file only says which role each skill runs under, who holds each human role, where the project keeps its material, and the app's settings and deviations.

**Prerequisites:** every session runs `framework/hooks/install` when it starts, or its harness adapter does (`framework/hooks/README.md`), and has the skills below.

## Skills and roles

<Keep this table as it is.> The skills are a prerequisite: Matt Pocock's skills (`github.com/mattpocock/skills`), at the commit the harness adapter pins, installed as its README says, or where the project runs without an adapter, at the commit the Claude Code adapter's `marketplace.json` names. A harness without plugin prefixes, such as pi, names a skill `mattpocock-skills:<name>` by its own name for `<name>`. A session starts with one row's first column, on a ticket or an idea: a skill by its qualified name, the Land prompt, or the Orchestrate prompt. It also follows the page beside it: a role page, whose overrides win over the skill, or for the Orchestrate prompt, `framework/orchestrate.md`, which starts the builder and reviewer sessions itself. A session started without the skills stops and tells the human.

| Start a session with | Page |
|---|---|
| `mattpocock-skills:grill-with-docs`, `mattpocock-skills:to-spec`, `mattpocock-skills:to-tickets`, `mattpocock-skills:grilling`, `mattpocock-skills:retro` | `framework/roles/product.md` |
| `Land ticket <n> as the product role` | `framework/roles/product.md` |
| `mattpocock-skills:implement`, `mattpocock-skills:tdd`, `mattpocock-skills:diagnosing-bugs` | `framework/roles/builder.md` |
| `mattpocock-skills:code-review` | `framework/roles/reviewer.md` |
| `Orchestrate ticket <n> for iOS and Android`, `for iOS` or `for Android`; `Orchestrate ticket <n>` with no platform work | `framework/orchestrate.md` |

`framework/` is a git subtree of `git@github.com-personal:ajmccall/dual-native.git`, taken at framework release 6.3.3. Only a take ticket edits it (`framework/framework-changes.md`).

## Human roles

- **Product owner:** <name, and handle on the tracker>
- **Framework steward:** <name, and handle on the tracker>

<If one person holds both roles, say so here.>

## Where things live

| What | Path |
|---|---|
| App schema | <folder holding the schema's `README.md` index and one file per feature (`framework/schema-template.md`)> |
| Product brief | <path of the brief, which holds the app's purpose and open questions> |
| Decision records | <folder, where the skills' ADRs also go> |
| Glossary | <path of the app's domain glossary, which `grill-with-docs` keeps, or "None yet": it's created when the first term is settled> |
| iOS app | <folder> |
| Android app | <folder> |
| iOS convention reference | `framework/conventions/ios.md` |
| Android convention reference | `framework/conventions/android.md` |
| Design source | <path of the design system or designs, or "each platform's standard components"> |
| Testing reference | <path of the project's app interaction checks, which the reviewer role's Run the app section relies on> |
| Tracker | <the tracker that holds the tickets and ideas, and where, for example GitHub Issues on `<organisation>/<repository>`> |
| Tracker binding | <the binding for that tracker, for example `framework/trackers/github.md`, or the project's own binding for another tracker (`framework/tracker.md`)> |
| Harness adapter | `framework/adapters/pi` |

## App settings

<Set by the ticket that sets up the app, and changed only by a ticket. Give the ticket or decision record behind each.>

- **App identifier:** <the iOS bundle ID, and Android's `applicationId` and `namespace`>
- **iOS:** <the minimum iOS version, and the Xcode version and SDK the app builds with>
- **Android:** <`minSdk`, `compileSdk` and `targetSdk`, and the Java toolchain>
- **Android JDK** (Android rule 7.1): <how the Gradle daemon finds Android Studio's JetBrains Runtime, and any machine-specific path, recorded as a limit>
- **Android colour** (Android rule 3.5): <dynamic colour where the device supports it, or the static schemes only. Only needed when the design source is each platform's standard components.>
- **Spoken screen-reader output** (builder override 11, reviewer override 9): <"not checked per ticket", when the product owner decides that nobody checks what VoiceOver and TalkBack say aloud, at review or at acceptance. Without this line, it is a check for acceptance.>
- **Boundary terms:** Cute, Cute Up To Eleven

Other settings:

- <Any other setting that tickets build on, or "None">

## Agent skills

<The block that `setup-matt-pocock-skills` writes: the issue tracker, the triage labels and the domain docs the skills read. Run the setup once, then keep its block here. Where its docs and the tracker binding disagree, the binding wins.>

## Deviations

<Each place where the whole app departs from a convention reference. The reference itself is never edited. Give the rule, what the app does instead, and the decision record behind it. A departure that only one feature makes is recorded in that feature's schema file, under **Deliberate platform differences**, not here.>

- <Platform> rule <number>: <what the app does instead> (<link to its decision record>)
