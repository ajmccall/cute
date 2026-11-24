// The pi adapter's extension (framework/adapters/pi/README.md).
//
// When a session starts, it runs the framework's `hooks/install`, so the
// pre-commit hook is active in this clone (`hooks/README.md`, Install). It
// tells the person with a notification, and tells the model by adding a
// message to the session's first run, so that a refused install stops the
// session, as `hooks/README.md` says. After each turn it shows the session's
// dollars so far in the footer.
//
// It doesn't install or check the skills: they are a prerequisite each person
// installs as pi installs skills (`AGENTS.md`, Skills and roles).
//
// Plain JavaScript, so that it needs no build step and `node --check` can test
// it. pi loads it through `.pi/settings.json`'s `extensions` list.

import { join } from "node:path";

const KEY = "dual-native";

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

export default function (pi) {
  let report = null;

  pi.on("session_start", async (event, ctx) => {
    const top = await root(pi, ctx.cwd);
    if (!top) {
      report = { ok: false, text: "This session isn't in a git checkout, so the framework's hooks aren't installed." };
    } else {
      report = await runInstall(pi, top);
    }
    if (ctx.hasUI) ctx.ui.notify(`dual-native: ${report.text}`, report.ok ? "info" : "error");
  });

  pi.on("before_agent_start", async () => {
    if (!report) return;
    const text = report.ok
      ? `dual-native session start: ${report.text}`
      : `dual-native session start FAILED. Stop and tell the human, as ` +
        `framework/hooks/README.md (Install) says:\n${report.text}`;
    report = null;
    return { message: { customType: KEY, content: text, display: true } };
  });

  pi.on("turn_end", async (_event, ctx) => {
    if (!ctx.hasUI) return;
    ctx.ui.setStatus(KEY, `$${sessionDollars(ctx.sessionManager.getEntries()).toFixed(2)} this session`);
  });
}
