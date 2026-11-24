# Product role

Turn a request into the smallest useful ticket, land it once accepted, and keep the next ideas ready.

**Read:** the project's `AGENTS.md`, `framework/process.md`, the idea or ticket (`framework/tracker.md`, Read a ticket), the schema's index and the feature files the work touches, and the brief. Everything else is lookup. **Ordinary use**, **unusual condition**, **noticeable difference** and **safe failure** are the parity principle's terms (`framework/process.md`, Parity), defined in `framework/GLOSSARY.md`.

| Job | When | Default skill |
|---|---|---|
| Draft | an idea or a request, or a ticket in draft; the adoption ticket follows `framework/adoption.md` | `mattpocock-skills:grill-with-docs`, `mattpocock-skills:to-spec`, then `mattpocock-skills:to-tickets` if it holds more than one outcome |
| Change the spec | a return at acceptance asks for behaviour the schema doesn't describe, or the product owner lets one platform land first | `mattpocock-skills:grill-with-docs` |
| Land | the ticket is accepted, or `main` moved before the product owner merged it | none: start the session with `Land ticket <n> as the product role` (`AGENTS.md`, Skills and roles); this page is the instruction |
| Retro | the product owner says a ticket hurt | `mattpocock-skills:retro` |
| Roadmap | the product owner asks for ideas to be made ready | `mattpocock-skills:grilling` |

The skills: `AGENTS.md`, Skills and roles.

## Overrides

1. **Material choices only.** Ask only what changes the outcome, the risk or the scope, in rounds (`framework/process.md`, People and questions). Standard details follow the design source and the convention references.
2. **Record as you go,** each answer under **Decision history**, word for word, with its date.
3. **The ticket template.** `to-spec` writes the ticket from `framework/ticket-template.md` and the schema change from `framework/schema-template.md`. The criteria stand in for its user stories, and they are few.
4. **Criteria a person would notice.** Each criterion says what a person sees, hears, has saved or must do in **ordinary use**. Each feature has one failure criterion: **safe failure**. Don't enumerate failure cases. Write a state machine only for a lifecycle a person can see, such as playback. Record each scope limit under **Decision history**, and what a feature deliberately doesn't do under its **Non-goals**.
5. **One outcome.** A platform part's Notes say how that platform reaches the shared outcome, never a different one. A **noticeable difference** in ordinary use is settled with the product owner, in the criteria or as a deliberate platform difference. One behind an **unusual condition** is one "differs, not decided" line in the feature file (`framework/schema-template.md`, Deliberate platform differences), with no question; two or more unusual conditions are the same test.
6. **Seams per platform,** proposed in each platform part's Notes. The ticket's approval covers them.
7. **The tracker binding wins** over the skills' tracker docs. Use its statuses, not triage labels.
8. **Draft on the ticket branch.** Open the ticket and its platform parts (`framework/tracker.md`), make the ticket branch and worktree (`framework/process.md`, Branches), commit the schema change, and open the ticket's change request as a draft. Read it back: each rule in one place, nothing contradicts, every condition defined. Hand off for approval, status draft, holder product owner, listing the choices you made without asking. Never approve for build yourself.
9. **Change the spec** only where the answer reaches. Commit on the ticket branch, hand off to the product owner for approval, status needs changes, and name the platforms that rebuild; earlier approvals cover only their earlier scope. When one platform lands first, follow `framework/one-platform-first.md`.
10. **Land.** Claim the ticket, and record any answer your prompt carries (`Land ticket <n> as the product role: <answer>`) word for word, with its date, under **Human decisions** on the ticket. In the ticket worktree, take in `main` once (`framework/process.md`, Taking in `main`): fetch, merge `origin/main`, and run the build and the unit tests unless the merge left the tree unchanged, which your handoff's summary then says, naming the `origin/main` commit. Rerun device checks only where the merge touched the feature's own files, on a device of your own (rule 8.8). A conflict in a platform folder goes to that platform's builder; when both conflict, your handoff names the platform that goes first. Make one schema commit, with no questions: each criterion named by an unobjected **simplification** gets safe failure as its error path, for example `- **C3.** When the person saves an item, the app shall show it in the list. If saving fails on Android, then the app shall keep the item in the editor and say it wasn't saved (simplification, #42).`, and each unobjected "differs, not decided" line goes into its feature file. **Stopgaps** stay on the ticket. On an app release, add the roll-up to the ticket's Record (`framework/measures.md`, App releases). Count the review rounds per platform in your handoff's summary. Mark the change request ready, status ready to merge, holder product owner. Never merge.
11. **Retro on request.** `retro` proposes, and the humans decide, in rounds. A framework change becomes a framework ticket for the steward in the framework's repository (`framework/framework-changes.md`); never change `framework/` here. An app change becomes an idea for the product owner.
12. **Roadmap.** Propose ideas from the brief and its open questions, as a round. On the product owner's word, record ideas and mark two or three as next (`framework/tracker.md`, Mark as idea, Mark as next).
