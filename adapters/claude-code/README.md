# Claude Code adapter

The framework's harness adapter for Claude Code (`framework-changes.md`, Plain core). It does three things and no more: runs the framework's pre-commit install when a session starts, prints each session's Cost line, and says how Claude Code runs an orchestrator (Orchestrating a ticket). Nothing in the framework requires it; without it the Cost line reads `not recorded`, and the session runs `framework/hooks/install` itself.

Built and checked against Claude Code 2.1.302. It needs 2.1.277 or later, the first version that reads `AGENTS.md` natively, and the `python3` that Xcode's Command Line Tools provide, like the hook.

## What's here

| File | Job |
|---|---|
| `session-start` | The SessionStart hook: runs `framework/hooks/install` and exports the session's id and transcript path to the session's shell. |
| `statusline` | The status line command: saves the session's cost figures to a cache on every refresh, then prints your own status line or a default one. |
| `cost` | Prints the Cost line for a handoff entry from that cache and the session's transcript, or an orchestrator's session total. |
| `subagent-cost-env` | The PreToolUse hook that gives a subagent's Cost command its own transcript path. |
| `settings.json` | What the project's `.claude/settings.json` needs, merged in at the first install (Wiring it in). |
| `test` | Self-test. Run it after any change here and show its output on the change request. |

## Wiring it in

Once per consumer app. At the first install, `install --adapter claude-code` does steps 1 to 3 (`framework-changes.md`, First install); a project that adds the adapter later does them in a ticket, such as the one that takes the framework release, with `install --wire <ticket worktree> --adapter claude-code`, and `install --check` reports any it lacks (`framework-changes.md`, Checking the wiring).

1. Name the adapter in `AGENTS.md`, in the **Harness adapter** row of Where things live: `framework/adapters/claude-code`.
2. Merge `framework/adapters/claude-code/settings.json` into the project's `.claude/settings.json` (shared, committed): add each key the project doesn't have, append each hook entry it doesn't already have, and keep every key it has. Where the project already sets one of these keys to a different value, such as its own `statusLine`, decide which to keep; for a status line of your own, see step 6.

   `skillOverrides` switches off Claude Code's own `code-review` skill, which shares its short name with the skill the reviewer role runs on. A plugin's skill is reached only as `/<plugin>:<skill>`, so a bare `/code-review` runs the built-in, a bug hunt on the diff that reports to the session and never posts a review ([Skills](https://code.claude.com/docs/en/skills)). Without the key, one wrong keystroke runs the wrong review.

   The `PreToolUse` hook rewrites only the documented `framework/adapters/claude-code/cost …` Bash command when a subagent runs it. Claude Code supplies its parent transcript path to the hook, plus the subagent's `agent_id`; the hook derives `<session>/subagents/agent-<agent_id>.jsonl`, or `<session>/subagents/<agent_id>.jsonl` where only that file exists, and exports it for that one command. The orchestrating session has no `agent_id`, so its command keeps the whole-session transcript.
3. If the project has a `CLAUDE.md`, put one line in it, `@AGENTS.md`, because Claude Code reads `AGENTS.md` only when there is no `CLAUDE.md`. If it has none, don't add one.

Then, once per person and clone:

4. Open the project in Claude Code and accept the workspace trust dialog. Project settings, their hooks and the status line all wait for it.
5. Install Matt Pocock's skills (`AGENTS.md`, Skills and roles) as Claude Code installs skills, if you haven't: the framework doesn't install them. As a plugin, such as the official marketplace's `mattpocock-skills` (`claude plugin install mattpocock-skills@claude-plugins-official`), each skill is `/mattpocock-skills:<name>`, as the framework writes it. Installed as personal skills instead, each is `/<name>`, and step 2's `skillOverrides` may switch the personal `code-review` off with the built-in one: prefer the plugin.
6. Optional: to keep your own status line, put it at `~/.claude/dual-native-statusline` (or under `CLAUDE_CONFIG_DIR` when you set that) and make it executable. It receives the same JSON Claude Code sends, and `statusline` prints what it prints. Without one, the default line shows the folder, branch, model, context used and the session's dollars so far.

## Starting a session

Start Claude Code in the project's main checkout. A session started in any other folder runs without the project's settings: `session-start` doesn't run and there is no status line, so its Cost line reads `not recorded`. Check it first: if `echo $DUAL_NATIVE_SESSION_ID` prints nothing in the session's shell, stop and ask the human to start the session again in the project.

Type the skill with its plugin prefix, then the ticket and, for platform work, the platform, as the handoff entry's **Next session** line gives them (`ticket-template.md`, part 3). Land takes no skill: type its prompt as the last line shows (`AGENTS.md`, Skills and roles).

```
/mattpocock-skills:implement on ticket 42 for iOS
/mattpocock-skills:code-review on ticket 42 for iOS
/mattpocock-skills:retro on ticket 42
Land ticket 42 as the product role
```

Five of the role skills, `grill-with-docs`, `to-spec`, `to-tickets`, `implement` and `retro`, are user-invoked only: they appear in the `/` list and never in the model's own skill list, so a headless session or a subagent can't start one. `grilling`, `tdd`, `diagnosing-bugs` and `code-review` can also be started by the model.

Claude Code gives a session and its subagents the same scratchpad. Each role invocation keeps its scratch files in its own subfolder, never at the scratchpad's top level: `<ticket>-<platform>-<role>/` for platform work, `<ticket>-shared-<role>/` for a builder or reviewer without platform work, and `<ticket>-product/` for product work. For example: `42-ios-builder/`, `42-shared-reviewer/` and `42-product/`. Don't reuse another invocation's folder. For repeated invocations, including concurrent ones, add distinct suffixes: the caller can assign each invocation a different path before starting it, or each invocation can atomically create a unique folder (for example with `mktemp -d`), rather than checking a name and then creating it.

Read each start file with the Read tool (`agents-template.md`, Follow `framework/`). Search a convention reference with Grep for the rules a step needs, rather than reading it whole: each is longer than the shell shows at once.

Start a long run, such as a full test suite, in the background (the Bash tool's `run_in_background`) and wait for its completion notification. Never poll it with sleep loops or a monitor: each poll is a request that carries the session's whole context again.

Under auto mode, Claude Code's classifier may refuse the reviewer's merge into the ticket branch ("Merge Without Review"), even run on its own (`trackers/github.md`, Merge). The product owner then merges it from the reviewer's session, typing the command with a `!` in front so that it runs in that session: `! gh pr merge <pr> --squash --delete-branch`, or `--merge` for one that takes in `main`. If the classifier also refuses the removal of the reviewer's worktree, the product owner removes it the same way: `! git worktree remove <path>`.

## Orchestrating a ticket

**Run on one live ticket** ([issue #78](https://github.com/ajmccall/dual-native/issues/78)): two builders at once, two reviewers one at a time, a role's question relayed and resumed, and a stop at ready for acceptance. On that run every role subagent's Cost line read `not recorded`; the fix ([issue #84](https://github.com/ajmccall/dual-native/issues/84)) hasn't been on a live run yet. Nor has a builder that reads `implement`'s file: one subagent did it on a scratch ticket, starting `tdd` and `code-review` with its two nested sessions, and committing ([issue #128](https://github.com/ajmccall/dual-native/issues/128)). The procedure is `orchestrate.md`; this section is how Claude Code does it. No other harness is claimed.

Start the orchestrator as any session, in the project's main checkout, by typing its prompt:

```
Orchestrate ticket 42 for iOS and Android
Orchestrate ticket 43
```

**Pre-flight.** Before starting any role, the orchestrator checks each of these, and stops naming the one that failed:

- It runs in the main checkout: `git rev-parse --path-format=absolute --git-dir` and `git rev-parse --path-format=absolute --git-common-dir` print the same folder.
- `echo $DUAL_NATIVE_SESSION_ID` prints a session id.
- Its skill list has `tdd`, `code-review` and `diagnosing-bugs` from Matt Pocock's skills.
- It can read the installed `implement` skill's file (The builder's skill file, below).
- It has the Agent and SendMessage tools, and `CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH` is unset or at least 2: a role session is one level down, and the review sessions `code-review` starts are a second.

**Role sessions are subagents.** The orchestrator starts each builder and reviewer with the Agent tool, as a `general-purpose` subagent run in the background, named after its scratch folder, such as `42-ios-builder` or `42-ios-reviewer-2`. It never passes `isolation: worktree`, which branches from `main`: the role adds its own worktree from the ticket branch, as its role page says. Its prompt is what `orchestrate.md` lists under What each role session is told, plus its scratch folder (Starting a session), which the orchestrator assigns, with a new suffix for each repeated invocation. A subagent can run `tdd`, `code-review` and `diagnosing-bugs` through the Skill tool, but not `implement`, which only a human can start: that's why the builder reads `implement`'s file and follows it (`orchestrate.md`, The builder's skill).

**The builder's skill file.** The file is `implement/SKILL.md`, inside wherever Claude Code installed the skills. For a plugin, `claude plugin list --json` gives the enabled `mattpocock-skills` plugin's `installPath`, and the file is under it: `find <installPath> -path '*/implement/SKILL.md'`. For skills installed without a plugin, it is `.claude/skills/implement/SKILL.md` in the project, or in `~/.claude` (`CLAUDE_CONFIG_DIR` when that's set). Where more than one is installed, take the one whose skills the session lists. The orchestrator reads the file once to check it is there, then gives each builder its absolute path.

**A role's question.** A subagent can't ask the human: Claude Code removes AskUserQuestion from every subagent. It ends its turn with the question instead, and the orchestrator relays it. The orchestrator resumes it with the answer through SendMessage, which keeps the subagent's context, so the question and its answer stay within one session.

**Refused commands.** When auto mode refuses a reviewer's merge or worktree removal (Starting a session), the reviewer returns with the exact command. The product owner runs it as that section says, but in the orchestrator's session rather than the reviewer's, and the orchestrator then resumes the reviewer to finish its handoff.

**Cost.** Each role subagent runs the Cost command before its handoff, as any session does. Its line is a `subagent` line: its own tokens, with dollars and agent time `not recorded` (The Cost line). The orchestrator posts no Cost line, because its session total includes every role subagent and the app release roll-up would count them twice. For its report, it runs `framework/adapters/claude-code/cost --orchestration`, which prints the session's figures labelled "Orchestration session total, includes the role subagents; not a role cost" and leaves the Cost line state alone. The orchestrator's own share of that total isn't measured.

**Stops.** The orchestrator stops where `orchestrate.md`'s Steps say, and at a failed pre-flight check above. In Claude Code, a role subagent that ends its turn without handing off and without a question for the human has ended without a handoff (step 9).

**Limits.**

- Whether `SessionStart` runs inside a subagent isn't documented, and the live run didn't show it. It showed what each part needs: the pre-commit hook was already set for every role's worktree, since `framework/hooks/install` sets it once for the clone, and `DUAL_NATIVE_SESSION_ID` reached every role subagent's shell, holding the orchestrating session's id, so the Cost command found its session.
- Serializing one orchestrator's reviewers doesn't coordinate with other sessions on the same ticket ([issue #77](https://github.com/ajmccall/dual-native/issues/77)).
- Two builders and a reviewer can run at once, each on a simulator or emulator of its own. On a smaller machine, expect slower builds.
- If the orchestrator's session ends while a role waits on a human, that role keeps its claim; the product owner finishes it by hand.

## The Cost line

At the end of a session, before recording the handoff, run

```
framework/adapters/claude-code/cost <iOS|Android|shared> <product|builder|reviewer>
```

and paste the line it prints as the last line of the handoff entry (`measures.md`, Cost per session). For example:

```
Cost: iOS · builder · total · ≥ 2,091,213 tokens · $6.80 · 19m 08s
```

The third field says what the line covers:

- **`total`** is a Cost line from the orchestrating session. Its token lower bound is the session's transcript and every subagent transcript. Its dollars and agent time are Claude Code's whole-session figures.
- **`subagent`** is a Cost line from a subagent. Its token lower bound is that subagent's transcript only. Claude Code provides dollars and agent time only for the whole session, so those fields read `not recorded`; the command never calls the whole-session figures that role's cost.

Run it again for each later handoff from the same transcript, rather than pointing to an earlier line: from the second line on, it adds the figures since that transcript's previous line. A subagent never compares its line with the orchestrating session or another subagent. For example:

```
Cost: shared · product · total · ≥ 5,408,798 tokens · $3.60 · 12m 54s · since the previous Cost line: ≥ 4,279,873 tokens · $2.75 · 10m 44s
```

What each figure is, and its limits:

- **Dollars** is Claude Code's own estimate of the session's cost at list price, from its status line. It resets at `/clear`, so a `total` line that clears mid-ticket under-reports; prefer a fresh session per handoff, as the skills' flow does anyway.
- **Agent time** on a `total` line is the API duration: the model's own time. It leaves out tool runs such as builds and tests, and never counts waiting for a human.
- **Tokens** is a lower bound, marked `≥`. A `total` line sums every request in the orchestrating transcript and its subagents; a `subagent` line sums only its own transcript. The transcript's format isn't documented, and on this machine a total sum reached 85% to 100% of Claude Code's own exit-time total on ordinary sessions, and 68% on one that ran eleven subagents. It counts as recorded.
- Any figure the command can't read prints `not recorded`, with the reason on stderr: usually the SessionStart hook or the status line isn't configured, or the session was started before they were.

## Correcting earlier Cost lines

After taking this version, a consumer adds one correction comment to each ticket whose roles posted Cost lines from one orchestrating Claude Code session before this change. It says that those lines each reported the running whole-session total, not the named role's cost; the ticket uses the latest such line once as its session total and records each role's Cost as `not recorded`. Do not edit the earlier handoffs.
