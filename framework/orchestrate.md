# Orchestrate a ticket

**Run on one live ticket,** with both platforms ([issue #78](https://github.com/ajmccall/dual-native/issues/78)). Report each gap you find as a framework ticket.

One session, the **orchestrator**, runs a ticket's builds and reviews for the product owner. It starts a builder and a reviewer session per platform, returns required findings to the builder, and stops when the ticket is ready for acceptance, a human is needed, or a role can't go on. It is optional: starting each role by hand works as before.

**Start:** `Orchestrate ticket <n> for iOS and Android`, `for iOS`, `for Android`, or `Orchestrate ticket <n>` for a ticket with no platform work (`AGENTS.md`, Skills and roles). The request lets the orchestrator start role sessions on this ticket. It doesn't change the approved scope, approve the ticket, accept a build, permit a hook bypass or allow a merge into `main`.

**Read:** the project's `AGENTS.md`, `framework/process.md`, the ticket and its platform parts (`framework/tracker.md`, Read a ticket), the builder and reviewer role pages, and the harness adapter's README. Everything else is lookup.

**Harness:** the orchestrator needs a harness that can start role sessions from it and resume one, in which each role can run its skills, including the nested sessions `code-review` starts. A harness adapter supports it only where its README has an **Orchestrating a ticket** section, which says how. Without one, the orchestrator stops and says so: it never claims a role, skill or check ran that didn't.

## Not a role

The orchestrator holds no role. It claims nothing, is never a holder, sets no status, commits nothing and writes nothing to the tracker or a change request. Every claim, status, review, merge and handoff entry is the role session's own, made by its role page. It keeps no progress file: between sessions the tracker holds the state, so starting it again with the same prompt resumes the ticket from where its parts stand. The only thing it holds is a question it is relaying, until the role session that asked records the answer.

## Steps

1. **Pre-flight.** Check what the harness adapter's README lists. If any check fails, stop.
2. **Match the request to the ticket.** A ticket with platform parts needs one or both platforms named, each with its own part. A ticket with no platform work takes no platform. Anything else stops with a question. Never start work for a part the ticket doesn't have.
3. **Check the approval.** Read the ticket's status and its **Approved at** commit, and run `git fetch origin`: the checks below use `origin/<ticket name>`, since reviewers merge on the code host.
   - **Ready for acceptance:** there is nothing to do. Report it and stop.
   - **Platform work, approved for build:** each first-parent commit on `origin/<ticket name>` after the approved commit is the commit that merged one of this ticket's platform change requests, as the code host records it (`framework/tracker.md`, Merge).
   - **No platform work:** approved for build, and `origin/<ticket name>` is the approved commit; or in progress, ready for review or needs changes, and the approved commit is an ancestor of `origin/<ticket name>`.

   Any other status, or any other commit, such as a spec change committed after approval, stops with a question.
4. **Plan from the tracker.** First, any requested part (or the ticket, with no platform work) that a session this orchestrator didn't start has claimed stops the run with a question, whatever its status. Otherwise its status decides the next phase:
   - not yet started (a platform part with no status yet, or a ticket with no platform work still approved for build): a builder.
   - in progress, unclaimed: stop with a question, since a builder left it without a handoff.
   - needs changes: the builder.
   - ready for review: a reviewer.
   - approved: nothing.
5. **Builders.** Start one builder session per platform at once, each on its own part. A ticket with no platform work gets one builder, working on the ticket branch in the ticket worktree. Tell each builder what's under **What each role session is told**.
6. **Reviewers.** When a builder hands off ready for review, queue a fresh reviewer for that platform, even while the other platform's builder is still working. Run **one reviewer session at a time**: the next one starts after the previous one has handed off. One platform's review waits for the other's because each reviewer merges into the ticket branch and checks the ticket's status, then acts on it (`framework/roles/reviewer.md`, override 13): two at once could each miss the other's approval. The queue is a local precaution only. It doesn't coordinate with sessions this orchestrator didn't start, and doesn't prevent their merges from conflicting.
7. **Returns.** On **needs changes**, start that platform's builder on its required findings, then a fresh reviewer for the re-review, which checks only the required findings (`framework/roles/reviewer.md`, override 3). Continue while work can progress. There is no retry limit beyond the existing rules.
8. **A human is needed.** A role session returns to the orchestrator, without handing off, only for a question its role page says to ask or a command its harness refused. A check only a person can make waits for acceptance and never stops a role (`framework/roles/reviewer.md`, override 9). Relay it at once, with the role and the platform. Already-running sessions may carry on to their own handoff, but start no further phase until the human answers. Then resume the same role session with the answer, word for word. If the harness can't resume it, or this session ends first, the claim stays: tell the product owner to finish that role by hand.
9. **A role ends without a handoff.** This covers an error, a context or usage limit, or a permission denial the role didn't return as a refused command: any end that isn't a handoff or a return under step 8. Stop and report the part's tracker status, its holder and the reason. Never restart the part, claim it again, or remove its worktree or device; already-running sessions still reach their own handoff.
10. **Stop** when every requested part is approved (or, with no platform work, the ticket is ready for acceptance), a human is needed, or a role can't go on. A request for one platform on a ticket with two leaves it short of ready for acceptance until the other part is approved too (`framework/roles/reviewer.md`, override 13). Never accept, run Land, or merge into `main`.

**Report** to the product owner at the end: each part's status, holder, change request, and reviews with their outcomes. Then each human stop and its answer, and the ticket's status. When the ticket is ready for acceptance, point to the collected list of entries the reviewer wrote, list beside it each **For acceptance** check with its platform and setup, and end with the Land prompt for the product owner to send with their answer: `Land ticket <n> as the product role: <answer>`. Give the orchestration session's cost only as the harness adapter's README says to, labelled as the whole session's, never as a role's.

## What each role session is told

- **Role:** builder or reviewer, the ticket, and the platform, or none for a ticket with no platform work. It reads its role page's Read line and follows that page's overrides in full, as if a human had started it. That includes its claim, worktree, device, evidence, Cost line and handoff.
- **Skills:** the reviewer runs the `code-review` skill. The builder is given the path of the installed `implement` skill's file, which it reads and follows (The builder's skill, below), and runs the `tdd`, `code-review` and, on a return whose cause isn't obvious, `diagnosing-bugs` skills. If a skill, or the nested sessions it starts, can't run, the role stops and returns to the orchestrator rather than run a substitute or say it ran.
- **Its scratch folder** and anything else the harness adapter's README says a role session needs.
- **Asking the human:** the product owner counts as present in its session, through the orchestrator (`framework/process.md`, People and questions). When its role page says to ask, it returns to the orchestrator with the question instead of handing off, and keeps its claim, worktree and device. On the answer, it records it as People and questions says, under **Human decisions** on its own platform part, or on the ticket with no platform work, and puts the question and the answer in its handoff summary.
- **A refused command:** when its harness refuses a command its role page gives it, such as a reviewer's merge, it returns to the orchestrator with the exact command for the product owner to run, and finishes its handoff once resumed. That isn't a human decision to record.

**The builder's skill.** The builder role's default skill, `implement`, is one only a person can start, so the orchestrator can't start it for a builder session. That limit is on starting the skill, not on reading it. The orchestrator finds the installed `implement` skill's file, as the harness adapter's README says how, and gives the builder session its path. The builder reads that file and follows it as its default skill, as if a person had started it on the ticket, with the builder role's overrides winning (`framework/roles/builder.md`). Where the file says to start another skill, such as `tdd` or `code-review`, the builder starts that skill of Matt Pocock's, by the name its harness gives it. The orchestrator copies nothing from the file and doesn't summarise it, so a builder it starts and one a person starts run the same steps, at whatever version is installed. If it can't find the file, it stops and says so.
