// The pi adapter's extension (framework/adapters/pi/README.md).
//
// When a session starts, it:
//
// 1. Runs the framework's `hooks/install`, so the pre-commit hook is active in
//    this clone (`hooks/README.md`, Install).
// 2. Checks that each role skill pi loaded comes from the pinned package in
//    `settings.json` beside this file. pi keeps the first skill it finds with a
//    name, and a skill in a personal folder, such as `<agent directory>/skills`
//    or `~/.agents/skills`, is found before a project package's, so a personal
//    copy of Matt Pocock's skills silently replaces the pinned one. pi's agent
//    directory is `PI_CODING_AGENT_DIR` when that's set, and `~/.pi/agent`
//    only when it isn't.
//
// It tells the person with a notification, and tells the model by adding a
// message to the session's first run, so that a refused install or an
// unpinned skill stops the session, as `hooks/README.md` and `AGENTS.md`
// (Skills and roles) say. After each turn it shows the session's dollars so
// far in the footer.
//
// Plain JavaScript, so that it needs no build step and `node --check` can test
// it. pi loads it through `.pi/settings.json`'s `extensions` list.

import { readFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";

const KEY = "dual-native";

// The skills the framework's roles start with (`agents-template.md`, Skills
// and roles), and the one-time setup skill.
export const ROLE_SKILLS = [
  "grill-with-docs", "to-spec", "to-tickets", "grilling", "retro",
  "implement", "tdd", "diagnosing-bugs", "code-review",
  "setup-matt-pocock-skills",
];

const SKILLS_REPO = "git:github.com/mattpocock/skills@";

export function pinnedSource(settingsText) {
  const settings = JSON.parse(settingsText);
  const found = (settings.packages || [])
    .map((entry) => (typeof entry === "string" ? entry : entry && entry.source))
    .filter((source) => typeof source === "string" && source.startsWith(SKILLS_REPO));
  if (found.length !== 1) throw new Error(`settings.json names ${found.length} pinned skills packages, not 1`);
  return found[0];
}

// Each role skill that is missing or comes from somewhere other than the
// pinned package, as [name, where it came from].
export function unpinnedSkills(commands, pinned) {
  const bySkill = new Map();
  for (const command of commands) {
    if (command.source !== "skill" || !command.name.startsWith("skill:")) continue;
    bySkill.set(command.name.slice("skill:".length), command.sourceInfo || {});
  }
  const problems = [];
  for (const name of ROLE_SKILLS) {
    const info = bySkill.get(name);
    if (!info) problems.push([name, "not loaded"]);
    else if (info.source !== pinned) problems.push([name, info.path || info.source || "an unknown source"]);
  }
  return problems;
}

// The personal places pi reads skills from, for the advice when one wins over
// the pinned package.
export function personalSkillPlaces(env, home) {
  const agentDir = env.PI_CODING_AGENT_DIR || join(home, ".pi", "agent");
  return [
    join(agentDir, "skills"),
    `any "skills" paths in ${join(agentDir, "settings.json")}`,
    join(home, ".agents", "skills"),
  ];
}

export function sessionDollars(entries) {
  let total = 0;
  for (const entry of entries) {
    const usage = entry.type === "message" ? entry.message && entry.message.role === "assistant" && entry.message.usage
      : (entry.type === "compaction" || entry.type === "branch_summary") ? entry.usage : null;
    const cost = usage && usage.cost && usage.cost.total;
    if (typeof cost === "number") total += cost;
  }
  return total;
}

async function root(pi, cwd) {
  const result = await pi.exec("git", ["rev-parse", "--show-toplevel"], { cwd, timeout: 10000 });
  return result.code === 0 ? result.stdout.trim() : null;
}

async function runInstall(pi, top) {
  const install = join(top, "framework", "hooks", "install");
  const result = await pi.exec(install, [], { cwd: top, timeout: 60000 });
  const text = `${result.stdout}${result.stderr}`.trim();
  if (result.code === 0) return { ok: true, text };
  return { ok: false, text: `The pre-commit hook is NOT active. ${text || `${install} exited ${result.code}.`}` };
}

function checkSkills(pi, top) {
  let pinned;
  try {
    pinned = pinnedSource(readFileSync(join(top, "framework", "adapters", "pi", "settings.json"), "utf8"));
  } catch (error) {
    return { ok: false, text: `Couldn't read the pinned skills from framework/adapters/pi/settings.json: ${error.message}` };
  }
  const problems = unpinnedSkills(pi.getCommands(), pinned);
  if (problems.length === 0) return { ok: true, text: `Role skills load from ${pinned}.` };
  const lines = problems.map(([name, where]) => `- ${name}: ${where}`).join("\n");
  return {
    ok: false,
    text: `These role skills don't come from the pinned package ${pinned}:\n${lines}\n` +
      `Move any personal copy out of ${personalSkillPlaces(process.env, homedir()).join(", and ")} ` +
      "(pi keeps the first skill it finds with a name, and those come first), check that /settings has skill " +
      "commands on, then restart pi (framework/adapters/pi/README.md, Wiring it in).",
  };
}

export default function (pi) {
  let report = null;

  pi.on("session_start", async (event, ctx) => {
    const top = await root(pi, ctx.cwd);
    if (!top) {
      report = { ok: false, text: "This session isn't in a git checkout, so the framework's hooks aren't installed." };
    } else {
      const install = await runInstall(pi, top);
      const skills = checkSkills(pi, top);
      report = { ok: install.ok && skills.ok, text: [install.text, skills.text].filter(Boolean).join("\n") };
    }
    if (ctx.hasUI) ctx.ui.notify(`dual-native: ${report.text}`, report.ok ? "info" : "error");
  });

  pi.on("before_agent_start", async () => {
    if (!report) return;
    const text = report.ok
      ? `dual-native session start: ${report.text}`
      : `dual-native session start FAILED. Stop and tell the human, as AGENTS.md (Skills and roles) and ` +
        `framework/hooks/README.md (Install) say:\n${report.text}`;
    report = null;
    return { message: { customType: KEY, content: text, display: true } };
  });

  pi.on("turn_end", async (_event, ctx) => {
    if (!ctx.hasUI) return;
    ctx.ui.setStatus(KEY, `$${sessionDollars(ctx.sessionManager.getEntries()).toFixed(2)} this session`);
  });
}
