# pi adapter

The framework's harness adapter for [pi](https://github.com/earendil-works/pi), the terminal coding agent (`framework-changes.md`, Plain core). It does three things and no more: runs the framework's pre-commit install when a session starts, prints each session's Cost line, and says how pi runs an orchestrator (Orchestrating a ticket). Nothing in the framework requires it.

Built and checked against pi 1.6.0. pi needs Node.js 22.19 or later; the Cost command needs `python3`, like the hook.

## What's here

| File | Job |
|---|---|
| `settings.json` | What the project's `.pi/settings.json` needs, merged in once (Wiring it in): the extension, and the `agents` folder as a place `pi-subagents` looks for agents. |
| `dual-native.js` | The extension. At session start it runs `framework/hooks/install`; it tells the person and the model, so a failure stops the session. After each turn it shows the session's dollars in the footer. |
| `agents/dual-native-role.md` | The agent an orchestrator starts each builder and reviewer as (Orchestrating a ticket). |
| `cost` | Prints the Cost line for a handoff entry from the session's file. |
| `test` | Self-test. Run it after any change here and show its output on the change request. |

## Wiring it in

Once per consumer app. At the first install, `install --adapter pi` does steps 1 and 2 (`framework-changes.md`, First install); a project that adds the adapter later does them in a ticket, such as the one that takes the framework release, with `install --wire <ticket worktree> --adapter pi`, and `install --check` reports any it lacks (`framework-changes.md`, Checking the wiring).

1. Name the adapter in `AGENTS.md`, in the **Harness adapter** row of Where things live: `framework/adapters/pi`.
2. Merge `framework/adapters/pi/settings.json` into the project's `.pi/settings.json` (shared, committed; create it if there is none): add each `extensions` and `subagents.agentScanDirs` entry it lacks, and keep everything else. pi resolves a path in project settings from the `.pi` folder, which is why the extension's path starts `../framework/`. `pi-subagents` resolves a scan folder from the folder pi started in, which is why that one starts `framework/`; without `pi-subagents` the setting does nothing.
3. Nothing for `AGENTS.md` itself: pi reads `AGENTS.md`, and `CLAUDE.md`, from the working folder and its parents without being told.

Then, once per person:

4. Install Matt Pocock's skills (`AGENTS.md`, Skills and roles) as pi installs skills, if you haven't: the framework doesn't install them. Any place pi reads skills from works, such as `~/.agents/skills`, `<agent directory>/skills`, or `git:github.com/mattpocock/skills` in the `packages` list of `<agent directory>/settings.json`. pi's agent directory is `PI_CODING_AGENT_DIR` when that's set, and `~/.pi/agent` only when it isn't. pi keeps the first skill it finds with a name, so another skill with a role skill's name, found first, runs in its place.
5. To orchestrate, install `pi-subagents` as pi installs packages, such as `pi install npm:pi-subagents`. The framework doesn't install it or pin a version; sessions started by hand don't need it.
6. Open the project in pi and trust it when asked (or start it with `pi --approve` for one run), once per clone. pi loads a project's settings and extensions only after trust, and `pi-subagents` reads a project's agents only then.

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

## Orchestrating a ticket

**Not yet run on a live ticket** ([issue #135](https://github.com/ajmccall/dual-native/issues/135)). Run in a scratch project with pi 1.6.0 and `pi-subagents` 0.89.1, headless: two role sessions started in one call; a builder that read `implement`'s file, followed it and committed; `code-review`'s two nested sessions run at once inside it; a role's question, and the same session resumed with the answer; a Cost line from each session. A reviewer's merge, a refused command and a second review round haven't been tried. The procedure is `orchestrate.md`; this section is how pi does it.

Start the orchestrator as any session, in the project's main checkout, by typing its prompt:

```
Orchestrate ticket 42 for iOS and Android
Orchestrate ticket 43
```

**Pre-flight.** Before starting any role, the orchestrator checks each of these, and stops naming the one that failed:

- It runs in the main checkout, and pi started there: `git rev-parse --path-format=absolute --git-dir` and `git rev-parse --path-format=absolute --git-common-dir` print the same folder, and `pwd` prints the folder above it.
- It has the `subagent` tool, which `pi-subagents` adds, and `subagent({ action: "list" })` lists `dual-native-role` and `delegate`. Where `subagent` has to be enabled first, it enables it.
- Sessions can nest two levels: `echo $PI_SUBAGENT_MAX_DEPTH` prints nothing or at least 2. A role session is one level down, and the review sessions `code-review` starts are a second.
- Its skills catalog has `tdd`, `code-review` and `diagnosing-bugs` from Matt Pocock's skills.
- It can read the installed `implement` skill's file (The builder's skill file, below).

**Role sessions are subagents.** The orchestrator starts each builder and reviewer with the `subagent` tool, as the agent `dual-native-role`, in the foreground: `subagent({ agent: "dual-native-role", async: false, task: "…" })`, or for two builders at once, `subagent({ workflow: "parallel", async: false, args: { tasks: [{ agent: "dual-native-role", task: "…" }, { agent: "dual-native-role", task: "…" }] } })`. The call returns when every session in it has ended its turn, and its call trace gives each session's run id. It never passes `worktree`: the role adds its own worktree from the ticket branch, as its role page says. The task is what `orchestrate.md` lists under What each role session is told; a role session under pi needs no scratch folder. The agent's definition gives the session the project's `AGENTS.md`, the skills catalog and the `subagent` tool, and tells it to run each skill itself and to start a skill's nested sessions as `delegate`, an agent that can start none of its own. No built-in agent of `pi-subagents` can be a role: none has both the skills and the `subagent` tool.

**The builder's skill file.** pi lists each skill a model may start in the session's skills catalog, with its path, and leaves `implement` out, since only a person starts it. The file is `implement/SKILL.md` in the folder beside `tdd`'s: where the catalog gives `…/tdd/SKILL.md`, it is `…/implement/SKILL.md`. The orchestrator reads the file once to check it is there, then gives each builder its absolute path. A role session can't type `/skill:<name>`: it reads each skill's file and follows it, `tdd`, `code-review` and `diagnosing-bugs` from its own catalog.

**A role's question.** A role session can't ask the human, and `contact_supervisor` can't reach an orchestrator that is waiting on a foreground call. The session ends its turn with the question instead, and the orchestrator relays it. The orchestrator resumes it with the answer through `subagent({ action: "resume", id: "<the session's run id>", message: "…" })`, which starts the session again from its own session file, so the question and its answer stay within one session. The id is the session's own, from the call trace, never the call's mission id.

**Refused commands.** Where pi refuses or can't run a command a role page gives the role, such as a reviewer's merge, the session ends its turn with the exact command. The product owner runs it as a `!` command in the orchestrator's session, and the orchestrator then resumes the role to finish its handoff.

**Cost.** Each role session runs the Cost command before its handoff, as any session does: its `PI_SESSION_FILE` is its own session file, so its line covers that session's requests and no other's. The nested sessions a skill starts have session files of their own, which no line covers, so a role's line leaves out its `code-review` reviewers. The orchestrator posts no Cost line. For its report, it runs `framework/adapters/pi/cost shared product` and gives the figures labelled "Orchestrator session only, without the role sessions; not a role cost".

**Stops.** The orchestrator stops where `orchestrate.md`'s Steps say, and at a failed pre-flight check above. Under pi, a role session that ends its turn without handing off, and without a question or a command for the human, has ended without a handoff (step 9).

**Limits.**

- A foreground call blocks the orchestrator until every session in it ends its turn. Two builders started in one call both finish before the first review starts, and one builder's question waits for the other builder.
- A role session doesn't load this adapter's extension: a foreground session of `pi-subagents` loads none of its parent's. The pre-commit hook is already set, since `framework/hooks/install` sets it once for the clone when the orchestrator's session starts.
- A status query for a foreground session finds nothing ("Async run not found"). What ran is in the orchestrator's session folder, where each role session and each nested session has a session file.
- `pi-subagents` resolves the agents folder from the folder pi started in. Started anywhere but the project's root, the orchestrator doesn't find `dual-native-role` and stops at pre-flight.
- A project or user agent named `dual-native-role` or `delegate` runs in place of this one or the built-in.
- Serializing one orchestrator's reviewers doesn't coordinate with other sessions on the same ticket ([issue #77](https://github.com/ajmccall/dual-native/issues/77)).
- If the orchestrator's session ends while a role waits on a human, that role keeps its claim; the product owner finishes it by hand.

## The Cost line

At the end of a session, before recording the handoff, have the session run, through its bash tool,

```
framework/adapters/pi/cost <iOS|Android|shared> <product|builder|reviewer>
```

and paste the line it prints as the last line of the handoff entry (`measures.md`, Cost per session). The line has no scope field: every pi session, a role session an orchestrator started included, has a session file of its own, so each line covers one session and no other (Orchestrating a ticket, Cost). For example:

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

- **Orchestration isn't proven on a live ticket** (Orchestrating a ticket). It needs `pi-subagents`, which pi doesn't ship.
- **Not yet on a live ticket.** Checked by driving pi 1.6.0 in RPC mode in a scratch project: the hook install. The message that carries the report to the model is added to the session's first run (`before_agent_start`); that path hasn't been seen on a model request yet.
