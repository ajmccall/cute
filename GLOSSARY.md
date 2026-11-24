# Dual-native framework

The agent and process system for building one app natively on iOS and Android at the same time.

## Language

**Framework**:
The generic roles, process, templates and convention references that every consumer app follows.
_Avoid_: the system, the agent system, framework/ (that is only the folder a consumer keeps it in)

**App schema**:
The living, platform-neutral description of what a consumer app does as shipped, from which both native apps are built: an index plus one file per feature, changed only through tickets.
_Avoid_: spec, brief (the brief now holds only purpose and open questions), single schema (the hypothesis, not the artefact)

**Feature**:
One capability of a consumer app that the product owner would name, described by one file in the app schema, which owns its data, states, screens, text and acceptance criteria.
_Avoid_: module, screen, epic

**Lifecycle**:
What a feature has when a person can see something in it change state over time in response to events, such as playback, beyond what a screen shows from saved data; such a feature's schema file holds a state machine, and no other feature's does.
_Avoid_: flow, workflow

**Schema change**:
The one change to the app schema that a ticket wraps, committed on the ticket branch and landing with the code; the acceptance criteria it adds or changes are the ticket's.
_Avoid_: schema diff (only its form in version control), delta, spec change (a change after approval)

**Ticket**:
One proposed schema change, wrapped with what this build needs: intent, per-platform notes, codebase facts, validation and decision history. A ticket that changes no app behaviour says so and carries its own criteria.
_Avoid_: story, task

**Adoption ticket**:
The one ticket in which an app that already ships features writes its whole app schema from what the shipped apps do, checked by each platform's reviewer, before any new feature work.
_Avoid_: back-fill, migration ticket

**App release**:
A tagged build of both apps, made by a ticket with no schema change, at which each platform's product outcomes are measured and the tickets landed since the previous app release are summarised. For an app that isn't in a store, the tag is the release.
_Avoid_: version, ship, framework release (the framework's own)

**Platform part**:
The child record of a ticket that holds one platform's notes, status, holder and running records, so the two platforms' work never edits the same record.
_Avoid_: sub-ticket, platform ticket, handoff subsection

**Change request**:
A request in the code host to merge one branch into another, which carries that change's evidence and its review: the ticket's into `main`, or a platform's into the ticket branch.
_Avoid_: pull request or merge request (one code host's name for it), branch merge

**Main checkout**:
The repository's first working tree, the one a person cloned and works in. No role's session switches its branch or commits in it: each works in a worktree of its own, named after the ticket.
_Avoid_: the repo, the clone (a clone holds every worktree), main (the branch)

**Ticket worktree**:
The worktree, named after the ticket, in which a session works on the ticket branch itself: the product role while drafting, clarifying the spec or landing, and the builder of a ticket with no platform work.
_Avoid_: product worktree, scratch checkout

**Acceptance**:
The product owner's one answer, after trying either app or both, that accepts a ticket's build or returns it, naming the platform and what's wrong.
_Avoid_: parity check, sign-off, UAT

**Orchestrator**:
A session started with the Orchestrate prompt that starts the builder and reviewer sessions for one ticket and reports to the product owner. It holds no role, claims nothing and is never a holder (`orchestrate.md`).
_Avoid_: coordinator, dispatcher, lead agent

**Claim**:
A session's hold on a ticket or a platform part: the work has an assignee while an agent role holds it. Work an agent role holds with no assignee is free to take; while a human role holds it, the assignee marks the human's turn, not a claim.
_Avoid_: claim entry, lock, taking a ticket

**Human decision**:
A decision a human role gives to a session, in its prompt or during it, that the session records word for word with its date. A comment on the tracker is never a human decision.
_Avoid_: unsigned entry, sign-off

**Idea**:
A record in the tracker of something that may become a ticket; drafting turns the idea itself into the ticket.
_Avoid_: backlog item, plan item

**Consumer app**:
An app repository that takes the framework at a tagged framework release and fills in the consumer contract.
_Avoid_: host app, client app, project

**Consumer contract**:
What a consumer app must provide for the framework to work: an agent guide, made from the framework's template, that names who holds each human role, where each thing the framework names lives, the tracker the app uses, the app's settings and its deviations.
_Avoid_: setup, config

**Product owner**:
The human who makes a consumer app's product and UX decisions, approves its tickets, accepts each build and merges each ticket into `main`.
_Avoid_: owner (on its own), client, stakeholder

**Framework steward**:
The human who approves changes to the framework and cuts framework releases. One person may also be the product owner.
_Avoid_: owner (on its own), maintainer

**Framework choice**:
A convention-reference rule that settles something the platform vendor leaves open, or departs from the vendor's guidance, so the framework decides it. The framework steward can change it; a consumer app can depart from it only by recording a deviation if it is a required rule, and freely if it is advisory.
_Avoid_: owner choice

**Required rule**:
A convention-reference rule whose breach harms a person using the app (they can't read, reach or leave something, or they lose saved data), commits the app to something without the product owner, or breaks parallel sessions. A breach is a required finding.
_Avoid_: mandatory rule, hard rule, core rule

**Advisory rule**:
Any convention-reference rule that isn't a required rule. A builder follows it by default; a breach is an optional finding, and departing from it needs no deviation.
_Avoid_: guideline, soft rule, recommendation

**Deviation**:
A place where a consumer app departs from a required rule or a default, approved by the product owner and recorded in the app's own docs while the reference stays unedited.
_Avoid_: exception, override, fork

**Default skill**:
The published agent skill that a role's job runs as its practice, such as grilling a ticket or test-driving a build; the role adds only what building two native apps needs.
_Avoid_: role skill, practice skill

**Skill override**:
A framework rule that a role lists against its default skill, and that wins where the two conflict.
_Avoid_: override (on its own, which reads as a deviation), skill fork

**Required finding**:
A review finding that goes back to the builder without a human's word: a failing acceptance criterion, or a breach of a required rule. Every other finding, including a breach of an advisory rule, is an optional finding.
_Avoid_: high-priority finding, blocker

**Self-check**:
The builder's own run of its default skill's code review before handoff; it makes fixes, not findings, and it is never a review.
_Avoid_: review, pre-review, builder review

**Stopgap**:
Behaviour the app schema says nothing about that a builder chose during build; it stands as built unless it fails a criterion or the product owner objects at acceptance, and it never changes the schema.
_Avoid_: workaround, temporary fix, discovered decision (the list, not one entry)

**Simplification**:
A criterion's error path that a builder built as safe failure instead, on its own word, because the path costs more to build than it protects, or that the platform or reused code decides; it names the criterion it falls short of.
_Avoid_: shortcut, descoping, partial implementation

**Differs, not decided**:
A difference between the platforms reachable only behind an unusual condition, recorded in one line in the app schema with no question and no decision, provided both platforms meet safe failure.
_Avoid_: accepted difference, known difference, deliberate platform difference (a decided one)

**Optional finding**:
A review finding of an advisory rule's breach, given to the builder only, which fixes it or not on its own word; it never blocks approval, never asks for a re-review and never goes to the product owner. On approval, the reviewer records one worth keeping as an idea.
_Avoid_: nit, suggestion, minor finding

**Tracker binding**:
The one file that maps the framework's generic ticket operations (open a ticket, open a platform part, read a ticket, list tickets, claim, record a handoff, set status, block, close, mark as idea, mark as next, move a platform part) and change-request operations (open, attach screenshots, post a review, mark ready, merge) to a specific issue tracker and code host.
_Avoid_: tracker integration, tracker adapter

**Harness adapter**:
An optional folder per agent harness, named in the consumer contract, that runs the framework's local checks setup when a session starts, and reports each session's cost line as that harness measures it, and may say how its harness runs an orchestrator; the framework never requires one.
_Avoid_: plugin, integration

**Framework release**:
A tagged, semantically versioned state of the framework that a consumer app pins to. A major release means the consumer must change its own files.
_Avoid_: framework version bump, drop

**First install**:
The one command, `install`, run from a clone of the framework's repository, that adopts the framework in a project: it adds a framework release as a git subtree in `framework/` on a branch of its own, turns on the hooks, wires in `AGENTS.md` and, if asked, a harness adapter, and prints what's left for people and agents to decide. It isn't a ticket, and it lands with a merge commit.
_Avoid_: bootstrap, setup script, onboarding

**Wiring**:
What joins a project to its framework release outside `framework/`: `core.hooksPath`, the lines of `AGENTS.md` the first install fills in, and a harness adapter's settings. `install --check` reports what a release expects and a checkout lacks, and `install --wire` adds what a command can.
_Avoid_: setup, configuration

**Take ticket**:
The ticket in which a consumer app takes a framework release: it has no platform work, and its acceptance criteria are the changelog's lines for that release. It runs under the release the consumer had when it started, and no other ticket is open while it runs.
_Avoid_: upgrade ticket, migration ticket

**Boundary search**:
The check that the framework names no consumer app's product and none of its paths: a case-insensitive search of the framework's files for the terms and paths the consumer contract lists, run by the pre-commit hook in a consumer and by hand on a framework change request.
_Avoid_: leak check, grep for the app name

**Hook bypass**:
A commit made with the pre-commit hook skipped, which only a human may allow; it carries a `Hook-bypassed:` trailer naming the reason and counts as a correction.
_Avoid_: no-verify commit, skipping the hook

**Ordinary use**:
What a person does with a feature on purpose, together with what their phone routinely does around them and the outside input the feature's criteria already expect; a condition the feature exists to handle is ordinary use of that feature.
_Avoid_: happy path, typical user, a person doing ordinary things (prose only)

**Unusual condition**:
Something outside ordinary use that the person neither causes on purpose nor meets in routine use of a phone: the system ending the app partway through something, the device's storage failing or filling, or two of the person's own actions landing at the same moment.
_Avoid_: edge case, corner case

**Noticeable difference**:
A difference between the platforms, in ordinary use, in what a person sees, hears or has saved, or in a step they must take; one that follows each platform's own idiom is not one.
_Avoid_: visible difference, platform difference (any difference, noticeable or not)

**Safe failure**:
The floor both platforms meet behind any unusual condition and on any collapsed error path: the feature fails without harm, keeps the person's saved data, and never leaves the person believing something they asked for happened when it didn't. An error the app recovers from, or one that changes nothing the person asked for, stays silent.
_Avoid_: graceful degradation
