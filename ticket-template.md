# Ticket template

A ticket lives in the project's tracker in three kinds of part (`tracker.md`, A ticket's parts), and its changes in change requests (`tracker.md`, Change requests). Copy each part below without its heading:

1. **Ticket body:** the ticket's own record, written when the ticket is opened. The ticket's title is short and outcome-focused.
2. **Platform part body:** one for each platform, on a ticket with platform work.
3. **Handoff entry:** each handoff, added to the ticket or a platform part.
4. **Change request description:** the ticket's change request, and each platform change request with its builder's evidence.

Statuses, for the ticket: draft | approved for build | ready for acceptance | accepted | ready to merge | done (the ticket is closed).
For a platform part: in progress | ready for review | needs changes | approved (the part is closed). A ticket with no platform work takes the platform part's statuses for its build and review.

Holders: product | product owner | builder | reviewer. A platform part's holder is that platform's builder or reviewer.

## Part 1: ticket body

```markdown
## Intent

<What user problem or learning goal this ticket addresses.>

## Schema change

<The one change to the app schema that this ticket wraps (`schema-template.md`). The change itself is committed on the ticket branch; this section summarises it and doesn't copy it.>

- Feature files: <each file the change adds, changes or removes, marked added, changed or removed>
- Acceptance criteria: <each criterion the change adds or changes, as `<feature>#C<n>` with its text, and each it removes, marked removed. These are the ticket's acceptance criteria. For app work, each applies to both iOS and Android.>
- Diff: <link to the ticket's change request, whose changes to the schema folder are the diff>
- Approved at: <the branch commit the product owner approved, filled in at approval. A later change to the schema on the branch is a spec change after approval.>

<For a ticket that changes no app behaviour, write "None: <reason>" in place of the list, then its acceptance criteria:
- for a bug fix, the existing criteria the app must meet again, as `<feature>#C<n>`;
- for other work, such as tooling, a refactor or a change to `framework/`, its own criteria, as observable outcomes.>

## Decision history

<The decisions this ticket depends on, made while drafting. For each, give the options and a recommendation, and record the product owner's answer. Split a ticket when it bundles unrelated decisions. This applies to every decision sent to the product owner: product, UX, process or technical. Write "None" if everything is already decided.>

- <Decision>: <options, recommendation> → <product owner's answer, with its date>

## Notes

<Only on a ticket with no platform work: relevant context, links with sources, and facts about the code it changes. On a ticket with platform work, delete this section; each platform's notes and codebase facts go in its platform part.>

## Validation

- <Check or test that demonstrates the acceptance criteria, on each platform>

## Record

<Only the session that holds the ticket edits this body, or the product owner (`tracker.md`, Who writes what). Each platform's own records go in its platform part.>

- Branch: `<ticket name>`, created from `main` at <commit>. Change request: <link>. <The product role creates the branch and fills in this line when it opens the ticket, and adds the change request's link once it opens it.>
- Human decisions: <Dated decisions the product owner or the framework steward gave to a session after drafting, about the whole ticket, each marked with the role that made it: approval for build, acceptance or a return, letting one platform land first, landing. Copied word for word from the session's prompt or from the session itself. Decisions about one platform go in its platform part. Write "None" if there were none.>
- Review: <On a ticket with no platform work only: the link to the review on the ticket's change request, and its outcome, filled in by the reviewer.>
- Decisions discovered during build: <On a ticket with no platform work only; platform work records these in its platform part. One line per entry, written by the builder: platform · tag · criterion (`<feature>#C<n>`) or feature and flow · what the person gets. The tag is **stopgap** (the schema was silent), **simplification** (an error path collapsed to safe failure, or decided by the platform or reused code, naming the criterion it falls short of) or **differs, not decided** (a difference behind an unusual condition). Write "None" if there were none.>
```

## Part 2: platform part body

Titled `iOS: <ticket title>` or `Android: <ticket title>`.

```markdown
Platform part of #<ticket number> for <iOS or Android>. Only this platform's builder or reviewer edits this body, or the product role while drafting.

## Notes

<How this platform can meet the schema change: the platform APIs and guidance that apply, each with its source, so the builder doesn't research them again. Never a different outcome from the other platform. Write "None" if there is nothing to add to the convention reference.>

## Codebase facts

<What this platform's code already has or lacks for the change, found in the repository while drafting, for example "saved data needs a migration" or "the field is already parsed". Write "None" if there are none.>

## Record

<The builder's evidence goes in its platform change request (part 4), not here.>

- Change request: <the link to this platform's change request, and to any later one after a return, filled in by the builder>
- Review: <the link to each review on the change request and its outcome, filled in by the reviewer>
- Human decisions: <Dated decisions about this platform only, such as which review findings to fix or answers on its **Decisions discovered during build**, each marked with the role that made it and copied word for word as on the ticket. Write "None" if there were none.>
- Decisions discovered during build: <One line per entry, written by this platform's builder only: platform · tag · criterion (`<feature>#C<n>`) or feature and flow · what the person gets. The tag is **stopgap** (the schema was silent), **simplification** (an error path collapsed to safe failure, or decided by the platform or reused code, naming the criterion it falls short of) or **differs, not decided** (a difference behind an unusual condition). Write "None" if there were none.>
- Product outcomes: <On an app release only: cold start, download size (on iOS also install size), release build time and days to adopt each yearly OS design change, each with the device, OS and tool versions it was measured with (`framework/measures.md`, App releases). Delete this line on other tickets.>
```

## Part 3: handoff entry

```markdown
- Status: <the status it is set to>
- Next holder: <the holder it is set to>
- Next session: <what the next session starts with, on this ticket and, for platform work, its platform, for example `mattpocock-skills:implement` on ticket 42 for iOS, or `Land ticket 42 as the product role`; when the next holder is a human role, only what they do first, for example "answer the questions in the summary, then start `to-spec` on ticket 42"; "none" when the ticket is done>
- Summary: <what happened in this session: what changed, what was checked, known limits, and any findings. When the human the questions belong to is absent, the numbered round of questions goes here. The Land entry's summary counts the review rounds per platform.>
- Cost: <platform> · <role> · <total|subagent> · <tokens> tokens · $<dollars> · <agent time> <As the harness adapter's cost command prints them. Scope is `total` for an orchestrating session or `subagent` for its own transcript; a harness without that distinction omits it. A lower bound is marked `≥`; any figure it doesn't supply is "not recorded" (`framework/measures.md`, Cost per session).>
```

The entry has these six fields, in this order, and no heading line.

## Part 4: change request description

For the ticket's change request, opened as a draft by the product role at drafting:

```markdown
<Closes #<ticket number>, in the form the binding gives, so the ticket closes when this merges.>

<One sentence: the ticket's intent.>

- Schema change: <the feature files it adds, changes or removes>
- Platform change requests: <a link to each, added by its reviewer when it merges into this branch>
```

On a ticket with no platform work, the builder adds the evidence list below to it.

For a platform change request, titled `iOS: <ticket title>` or `Android: <ticket title>`, opened by its builder into the ticket branch:

```markdown
Platform change request for #<platform part number>, part of #<ticket number>. <Link only: it never closes the ticket.>

- Changes: <files and behaviour in the platform folder>
- Seams tested: <the seams this platform tested at, as agreed in Notes, and any new one, recorded as a discovered decision>
- Build and tests: <the commands run and their results: `xcodebuild` for iOS; `./gradlew` and its JDK for Android>
- UI interaction checks: <named native scenarios, isolated setup and device, asserted outcomes, result paths and blocked or deferred cases; see `framework/roles/reviewer.md`, override 4>
- Network checks: <each criterion that depends on a real network dependency, exercised by hand, and what was seen, or "None">
- Human-only checks: <the checks a person must make, with the affected states, isolated setup and what remains unverified, or "None">
- Screenshots: <one per acceptance criterion, attached to this change request (`framework/tracker.md`, Attach screenshots) and listed here by criterion>
- Conventions: <what was followed, and any deviations, citing this platform's convention reference>
- Platform choices: <decisions for this platform that the other platform should not copy>
- Third-party libraries: <each one the build adds, including those it brings with it, or "None">
```
