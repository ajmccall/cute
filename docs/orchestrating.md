# Orchestrating a feature

How one session, the **orchestrator**, runs steps 3 and 4 of `AGENTS.md` for every ticket of a feature. It is started in the main checkout with `Orchestrate feature <n>`. A person can do the same by hand: start one session per brief below and paste the brief in.

## The loop

The orchestrator starts one sub-agent per build and a fresh one per review, and edits nothing itself.

- **It works the frontier**: every open ticket whose blockers are closed builds at once, so iOS and Android run side by side. Reviews run one at a time, since each merges into the feature branch.
- **Tickets and pull requests hold the state**, so the same prompt resumes it: an open ticket with no pull request means build, with an open one means review, and a closed ticket is done.
- **A review that sends a ticket back** gives its findings to the builder that built it, where that builder can still be reached, and otherwise to a new one. The next review is a fresh reviewer again.
- **A question for the product owner** stops that ticket, is asked at once with options and a recommendation, and its answer goes back to the same builder.
- **It stops** when every ticket is closed and step 5 is ready.

## Briefs

Give each builder and reviewer its brief below with the blanks filled, then add only what is particular to this ticket. A builder or reviewer reads `AGENTS.md` itself, so a brief doesn't repeat it.

A sub-agent can't start a skill that only a person can start, such as `implement`. Find the installed skills' folder, the one that holds `implement/SKILL.md` beside `tdd`'s, and give its path in the brief.

A rule you find yourself adding to every brief belongs here, not in the next brief: change this file as `AGENTS.md` says under "Where to look".

### Builder

```
You are the <iOS or Android> builder for ticket #<ticket>, "<title>", of
feature #<feature> on <owner>/<repository>. The main checkout is <path>; it
stays on main and you edit nothing there.

Read first:
- AGENTS.md, then your platform's convention reference and the testing
  reference it names.
- The ticket: gh issue view <ticket>. Its checkboxes are the criteria you
  build. Their wording is in docs/schema/.
- <skills folder>/implement/SKILL.md. You can't start it as a skill, so read
  it and follow it with the ticket as its argument, and any skill file it
  points to.

Work on the branch <feature branch>-<ticket>-<platform>, cut from
origin/<feature branch>, in the worktree and on the device that "Working in
parallel" in AGENTS.md gives you. Never read the other platform's code.

You are done as step 3 of AGENTS.md says: a pull request into
<feature branch>, never main, that you don't merge and that doesn't close
the feature. If a product or UX question comes up, stop and report it with
options and a recommendation; don't decide it.

Report back:
- the pull request;
- each criterion with the test or device check that shows it;
- the whole suite's result: counts, device and OS version;
- each choice you made that the schema leaves open;
- anything not done, skipped or failing, with the output.
```

### Reviewer

```
You are the reviewer of pull request #<pull request>: the <iOS or Android>
ticket #<ticket> of feature #<feature> on <owner>/<repository>. You have seen
none of the build, so form your own view from the schema, the diff and what
you run. The main checkout is <path>; it stays on main and you edit nothing
there.

Read first:
- AGENTS.md, then your platform's convention reference and the testing
  reference it names.
- The ticket, and each schema criterion on it.
- <skills folder>/code-review/SKILL.md. Read it and follow it with
  origin/<feature branch> as its fixed point. If it tells you to start
  reviewers in parallel and you can't, do both of its axes yourself.

Work in a review worktree at the pull request's head, on a device of your
own, as "Working in parallel" in AGENTS.md says. Rerun the whole suite
yourself and report your own counts, not the builder's.

Finish as step 4 of AGENTS.md says. Post your findings on the pull request,
with what must change apart from the optional nits. If nothing must change,
confirm the base is <feature branch>, squash-merge and close the ticket.
Otherwise merge nothing.

Report back:
- merged or sent back;
- your suite's result: counts, device and OS version;
- the findings that must change;
- the optional nits;
- anything you couldn't check.
```

Leave commit and pull request attribution lines out of a brief: each session follows its own rules for them.
