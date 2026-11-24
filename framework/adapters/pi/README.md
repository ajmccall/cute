# pi adapter

The framework's harness adapter for [pi](https://github.com/earendil-works/pi), the terminal coding agent (`framework-changes.md`, Plain core). It does two things and no more: runs the framework's pre-commit install when a session starts, and prints each session's Cost line. It has no Orchestrating a ticket section, so an orchestrator under pi stops and says so (`orchestrate.md`, Harness). Nothing in the framework requires it.

Built and checked against pi 1.6.0. pi needs Node.js 22.19 or later; the Cost command needs `python3`, like the hook.

## What's here

| File | Job |
|---|---|
| `settings.json` | What the project's `.pi/settings.json` needs, merged in once (Wiring it in): the extension. |
| `dual-native.js` | The extension. At session start it runs `framework/hooks/install`; it tells the person and the model, so a failure stops the session. After each turn it shows the session's dollars in the footer. |
| `cost` | Prints the Cost line for a handoff entry from the session's file. |
| `test` | Self-test. Run it after any change here and show its output on the change request. |

## Wiring it in

Once per consumer app. At the first install, `install --adapter pi` does steps 1 and 2 (`framework-changes.md`, First install); a project that adds the adapter later does them in a ticket, such as the one that takes the framework release, with `install --wire <ticket worktree> --adapter pi`, and `install --check` reports any it lacks (`framework-changes.md`, Checking the wiring).

1. Name the adapter in `AGENTS.md`, in the **Harness adapter** row of Where things live: `framework/adapters/pi`.
2. Merge `framework/adapters/pi/settings.json` into the project's `.pi/settings.json` (shared, committed; create it if there is none): add each `extensions` entry it lacks, and keep everything else. pi resolves a path in project settings from the `.pi` folder, which is why the extension's path starts `../framework/`.
3. Nothing for `AGENTS.md` itself: pi reads `AGENTS.md`, and `CLAUDE.md`, from the working folder and its parents without being told.

Then, once per person:

4. Install Matt Pocock's skills (`AGENTS.md`, Skills and roles) as pi installs skills, if you haven't: the framework doesn't install them. Any place pi reads skills from works, such as `~/.agents/skills`, `<agent directory>/skills`, or `git:github.com/mattpocock/skills` in the `packages` list of `<agent directory>/settings.json`. pi's agent directory is `PI_CODING_AGENT_DIR` when that's set, and `~/.pi/agent` only when it isn't. pi keeps the first skill it finds with a name, so another skill with a role skill's name, found first, runs in its place.
5. Open the project in pi and trust it when asked (or start it with `pi --approve` for one run), once per clone. pi loads a project's settings and extensions only after trust.

## Starting a session

Start pi in the project's main checkout, as with any harness. The extension reports what it found as a notification and as a message in the session: `install: hooks active …`. If it says FAILED, the session stops and tells the human, as `framework/hooks/README.md` (Install) says. It doesn't check the skills: a session that can't find one stops and tells the human (`AGENTS.md`, Skills and roles).

pi names a skill `/skill:<name>`, with no plugin prefix. Where the framework writes a skill's qualified name, `mattpocock-skills:<name>`, type `/skill:<name>`: the handoff entry's **Next session** line `mattpocock-skills:implement on ticket 42 for iOS` is

```
/skill:implement on ticket 42 for iOS
/skill:code-review on ticket 42 for iOS
/skill:retro on ticket 42
Land ticket 42 as the product role
```

pi honours the skills' `disable-model-invocation`: `grill-with-docs`, `to-spec`, `to-tickets`, `implement` and `retro` start only when a person types them, and `grilling`, `tdd`, `diagnosing-bugs` and `code-review` can also be started by the model.

## The Cost line

At the end of a session, before recording the handoff, have the session run, through its bash tool,

```
framework/adapters/pi/cost <iOS|Android|shared> <product|builder|reviewer>
```

and paste the line it prints as the last line of the handoff entry (`measures.md`, Cost per session). pi has no subagents, so the line has no scope field. For example:

```
Cost: iOS · builder · 2,091,213 tokens · $6.80 · not recorded
```

Run it again for each later handoff from the same session: from the second line on, it adds the figures since that session's previous line.

What each figure is, and its limits:

- **Tokens** is every request the session file records: each assistant message, compaction and branch summary, input, output, cache read and cache write, across every branch of the session tree. pi documents the file's format, so it isn't a lower bound.
- **Dollars** is pi's own estimate of the same requests from its model price table, `usage.cost.total`. On a subscription it is still the list-price estimate, not the bill, and only as good as pi's price for the model.
- **Agent time** is `not recorded`: pi records no request durations.
- The command reads the session file from `PI_SESSION_FILE`, which pi sets for its bash tool's commands only. Typed as a `!` command, or in a shell outside pi, it prints `not recorded` and says why on stderr. An ephemeral session, `--no-session`, has no file.

## Limits

- **No orchestration.** pi ships no subagents; packages such as `pi-subagents` add them, but none is wired in or tried here. The Orchestrate prompt stops at its Harness check. Start each builder and reviewer session by hand.
- **Not yet on a live ticket.** Checked by driving pi 1.6.0 in RPC mode in a scratch project: the hook install. The message that carries the report to the model is added to the session's first run (`before_agent_start`); that path hasn't been seen on a model request yet.
