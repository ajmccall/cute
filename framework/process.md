# Delivery process

How one app is built natively on iOS and Android at once. This page holds the parity principle, the delivery loop and the branch rules. Each role's own page says what its session does. Everything else is lookup, named where it's needed.

## Parity

- **Parity is at the feature level.** The schema's criteria say what a person sees, hears or has saved, and the steps they take, in **ordinary use**, on both platforms. Below that, each platform does what is simplest for it: the builder's call.
- **Safe failure** is the floor behind any unusual condition and on any error path a builder collapses (`roles/builder.md`), not a rule for every feature: the feature fails without harm, keeps the person's saved data, and never leaves the person believing something they asked for happened when it didn't. An error the app recovers from, or one that changes nothing the person asked for, stays silent.
- **Ordinary use** includes what the phone routinely does around the person: leaving the app, locking, rotating, losing signal, an incoming call. An **unusual condition** is the system ending the app partway through, storage failing or filling up, or two of the person's own actions landing at once.
- A question goes to the product owner only about a **noticeable difference** in ordinary use. A difference that only an unusual condition reaches is one line, "differs, not decided", with no question. The terms are defined in `GLOSSARY.md`.

## People and questions

- The **product owner** decides every product and UX question, approves each ticket for build, accepts each build and merges into `main`. No agent merges into `main`.
- The **framework steward** approves framework changes and cuts framework releases, in the framework's own repository (`framework-changes.md`). The project's `AGENTS.md` names who holds each role; one person may hold both.
- Ask in numbered rounds, each question with its options and a recommendation, worded so that "yes" accepts it, so that several are answered at once. A round holds every question whose prerequisites are settled, and opens with what the session did since its last message to that human. A role session an orchestrator started has its human in the session, through the orchestrator (`orchestrate.md`). When the human isn't in the session, put the round in the handoff entry's Summary, make that human the holder, and stop; the human answers by starting the next session. Record each answer word for word, with its date, under **Human decisions** (under **Decision history** while drafting). If an answer covers more than the question, quote it, say how you read it, and don't ask again what it already answers.

## Delivery loop

| Step | Who | Ends with status · holder |
|---|---|---|
| 1. Draft | product | draft · product owner |
| 2. Approve | product owner | approved for build · builder |
| 3. Build | builder, one per platform, at once | ready for review · reviewer |
| 4. Review | reviewer, one per platform | approved, or needs changes · builder |
| 5. Accept | product owner | accepted · product |
| 6. Land | product, then product owner | ready to merge · product owner, then done |

1. **Draft.** The product role writes the ticket, with a platform part per platform, and commits its schema change on the ticket branch (`roles/product.md`).
2. **Approve.** The product owner approves the ticket for build, naming the ticket branch's commit it approves.
3. **Build.** Each builder opens its platform change request with its evidence. Its stopgaps, simplifications and differs-not-decided entries go in its own platform part, one line each (`roles/builder.md`).
4. **Review.** One review per platform, in one session; a re-review checks only the required findings (`roles/reviewer.md`). A required finding sends that platform back to its builder. An approval merges the platform change request into the ticket branch. A check only a person can make never stops a review: the reviewer lists it under **For acceptance**. When both platforms are approved, the ticket is ready for acceptance, with both platforms' entries and **For acceptance** checks collected into one list.
5. **Accept.** The product owner tries either app or both, built from the ticket branch, reads the list, makes or skips each **For acceptance** check, and accepts or returns the build in one answer. No session asks a question per entry. An acceptance starts Land with the answer in its prompt, `Land ticket <n> as the product role: <answer>`, and Land records it word for word under **Human decisions** before landing. A return names the platform, the entry, the failed check or the problem, and what they want instead, and goes to that platform's builder. If what they want is new behaviour the schema must describe, it goes to the product role first, which changes the schema and gets the product owner's approval for it.
6. **Land.** The product role takes in `main`, makes one schema commit for the entries nobody objected to, and marks the ticket's change request ready (`roles/product.md`, Land). The product owner squash-merges it, which closes the ticket.

**Orchestrate on request.** Instead of starting each builder and reviewer by hand, the product owner may start one orchestrator for steps 3 and 4 (`orchestrate.md`). It starts the role sessions, which follow their role pages as before, and it stops at ready for acceptance, a question for a human, or a role that can't go on.

**Retro on request.** When the product owner says a ticket hurt, the product role runs `retro` on it after it lands. Its framework lessons become framework tickets in the framework's repository, and its app lessons become ideas. Nothing else runs on every ticket after it lands.

**Handoff entry:** status, next holder, next session, summary and Cost, as `ticket-template.md` part 3 gives them. Questions for a human go in the summary. The Land entry's summary counts the review rounds per platform.

**Statuses:** a ticket is draft, approved for build, ready for acceptance, accepted, ready to merge or done. A platform part is in progress, ready for review, needs changes or approved. A ticket with no platform work takes the platform part's statuses for steps 3 and 4. **Holders:** product, product owner, builder, reviewer. The tracker carries the state between sessions (`tracker.md`): each handoff sets the status and the next holder.

## Branches

- **Main checkout.** No session switches its branch or commits in it. Each session works in a worktree of its own beside the repository, except an orchestrator, which commits nothing and runs where its harness adapter says, such as the main checkout. A session's worktree is named after the ticket, and the session removes it, with any device it started, at handoff. A worktree left by an earlier session is reused after a `git status`; one with uncommitted changes is never removed without asking the product owner.
- **Ticket branch.** `<ticket name>` (`tracker.md`), from `origin/main`, in the ticket worktree `../<repository folder>-<ticket name>`: `git fetch origin`, then `git worktree add -b <ticket name> ../<repository folder>-<ticket name> origin/main`. Its change request, into `main`, opens as a draft and closes the ticket when it merges. A later session on the ticket branch adds the worktree again: `git worktree add ../<repository folder>-<ticket name> <ticket name>`.
- **Platform branches.** `<ticket name>-ios` and `<ticket name>-android`, from the ticket branch, each in its own worktree `../<repository folder>-<ticket name>-<platform>` on a device of its own. Each has a platform change request into the ticket branch. A fix for needs changes goes on the same branch and change request. A platform sent back after its change request merged starts a new branch and change request from the ticket branch.
- **Reviews.** A reviewer works in a worktree detached at the change request's head, `../<repository folder>-<ticket name>-review-<platform>`, on a device of its own, and squash-merges the platform change request it approves.
- **No platform work.** Built on the ticket branch in the ticket worktree, reviewed on the ticket's change request in `../<repository folder>-<ticket name>-review`.
- **Merges into `main`** are the product owner's: a squash merge, one commit per ticket whose message names the ticket, or a merge commit for a git subtree pull or add, such as taking a framework release or the first install (`framework-changes.md`). A platform change request that takes in `main` also lands with a merge commit, because a squash drops `main` as a parent and every later take then conflicts again. The ticket branch is then deleted.
- **Taking in `main`.** Run `git fetch origin`, then merge `origin/main` into the ticket branch. When the merge brings in nothing, because `git rev-parse HEAD^{tree}` prints the same before and after it, skip the build and the unit tests, and the handoff's summary says so, naming the `origin/main` commit merged; otherwise run them. Rerun device checks only when the merge touched the feature's own files. A conflict in a platform folder goes to that platform's builder. When both platform folders conflict, the handoff names the platform that goes first: its builder makes the one merge of `main`, keeping the ticket branch's side of the other folder, and the second builder brings in `main`'s side of its own files as an ordinary commit. If `main` moves again before the product owner merges, the product owner starts Land again.
- **Commits.** Ticket drafts, approvals, ideas and the next mark are tracker writes, not commits. The app schema changes only on a ticket branch (`schema-template.md`, Rules), and a brief or design-source edit a ticket needs goes on the ticket branch with it. A decision record, or a brief edit that no ticket needs, is a planning change committed on `main` by the person who makes it.

## Lookup

`tracker.md` and the tracker binding: the operations on tickets and change requests. `ticket-template.md`, `schema-template.md`, `conventions/` and `GLOSSARY.md`. **Local checks:** `hooks/README.md`, what the pre-commit hook checks, its install and when a commit may bypass it. `measures.md`: the Cost line and the review rounds. Only some tickets: `orchestrate.md`, `adoption.md`, `one-platform-first.md`, `app-releases.md`, `separate-repositories.md`, `framework-changes.md` (the framework's boundary, framework tickets and releases, and taking one), `adapters/` (a harness adapter's README, which `AGENTS.md` names).
