# Setting up the Workbench

Install is one command. This document covers the three things the installer does
not do: **giving the workbench its tools**, **recognising a harness that cannot
run it**, and **confirming the install actually works**.

```bash
npx skills add https://github.com/atishio/workbench.git --skill workbench -a claude-code -y
```

Add `-g` to install at user level instead of per-project. The CLI copies the
skill directory into the harness's skill location and records a hash in
`skills-lock.json`; discovery fires off the frontmatter `description`, so there
is no entrypoint file to wire.

On your first hands-on task the skill finds no `.workbench/` and runs init — a
seven-section interview. **Do not hand-write `.workbench/workbench.yaml`.** Every
value in it is meant to be one a human confirmed.

### One expected warning

```
⚠ Skipped .../framework/protocol/verify/SKILL.md — missing required
  frontmatter field(s): name, description
```

Benign. The verify protocols are named `verify/{type}.md`, and one of the types
is `skill` — so on a case-insensitive filesystem, `verify/skill.md` matches the
CLI's `SKILL.md` glob and gets probed as a skill definition, which it is not.
The file is copied normally; only the probe is skipped. Renaming it would break
the `verify/{type}.md` resolution that `SKILL.md` routes on, which is a worse
trade than a line of install noise.

---

## 1. Tools

The workbench names tools by **capability**, never by vendor. The authoritative
table of what each capability is for, and what the workbench reports when it is
absent, is `framework/ref/ref-tools.md` — read that first. This section only maps
those capabilities onto concrete servers.

Nothing here is required. A harness with file reads and a shell runs the
workbench; each capability you add widens what it can verify rather than
unlocking it.

### Where the config goes

**Project level, in the consuming repository's `.mcp.json`.** Not user level —
a workbench instance is project configuration, and a server only half the team
has produces verification results nobody else can reproduce.

**Secrets are `${ENV_NAME}` placeholders.** Real values live in the harness
environment. A token committed in `.mcp.json` is a token in the git history.

### Issue tracker — Jira

Used for workspace `tracker_project` lookups. Without it the workbench works
without ticket context and **will not invent ticket state**.

```json
{
  "mcpServers": {
    "mcp-atlassian": {
      "command": "uvx",
      "args": ["mcp-atlassian"],
      "env": {
        "JIRA_URL": "https://${ATLASSIAN_SITE}.atlassian.net",
        "JIRA_USERNAME": "${ATLASSIAN_EMAIL}",
        "JIRA_API_TOKEN": "${ATLASSIAN_API_TOKEN}"
      }
    }
  }
}
```

Verify: ask for any issue by key. A tracker that returns a 401 and a tracker that
is not configured look identical from inside a protocol — both produce *unknown*,
so check this once rather than inferring it from a quiet session.

### Wiki — Confluence

Consumed by `framework/protocol/verify/docs-review.md`. Without it, doc review
covers local files only and reports the external source as **unchecked**, not as
passing.

The same server serves both. Add to the `env` block above:

```json
"CONFLUENCE_URL": "https://${ATLASSIAN_SITE}.atlassian.net/wiki",
"CONFLUENCE_USERNAME": "${ATLASSIAN_EMAIL}",
"CONFLUENCE_API_TOKEN": "${ATLASSIAN_API_TOKEN}"
```

Verify: fetch a page you know exists by its page ID.

### Browser driver

Consumed by `verify/app-ui.md` and `stub-and-capture.md`. Without it the UI is
**unverified** — and the protocols say to report that rather than infer from the
backend that the page must be fine.

```json
{
  "mcpServers": {
    "playwright": {
      "command": "npx",
      "args": ["@playwright/mcp@latest", "--browser", "chromium"]
    }
  }
}
```

Verify: navigate to the app URL in `workbench.yaml` `hostnames` and take a
snapshot. See `framework/ref/ref-browser.md` for how protocols drive it.

### HTTP client

Used by `stub-and-capture.md` for mock admin calls — registering a stub, reading
back what was matched. Most harnesses have this built in; otherwise `curl` over
the shell is sufficient. No server needed.

Without it, mocks cannot be registered or read back and capture is unavailable.

### Log reader

Used by `probe.md` and `verify/app-be.md`. Usually the shell is enough —
`docker logs`, `journalctl`, or whatever the `stack` section already calls.

This is the one absence with a sharp consequence: with neither a log MCP nor a
shell, **a defect cannot be attributed to a layer**, and a probe that cannot
attribute is a probe that should not report a cause.

### Out of scope

**Slack, Teams, Google.** Deliberately absent, not overlooked. The workbench is a
hands-on development hub — code, tests, debugging, review. None of those three
has a capability entry in `ref-tools.md` and no protocol reads one, so wiring the
servers would add setup cost and change no behaviour.

Adding them is a real change, not a doc update: widen the capability table, then
give the capability a protocol that consumes it.

---

## 2. Reduced mode

A harness that injects static instruction text but **cannot read arbitrary files
at runtime** installs cleanly and then fails on the first routed task. Name the
degradation rather than discovering it.

**Works** — precedence, the role × signal routing table, grounding. This requires
inlining `SKILL.md` plus every routing target into whatever the harness injects.

**Does not work** — init, repair, migrate, verify profiles, and every on-demand
protocol.

**Consequence** — `.workbench/workbench.yaml` must be authored on a full harness
and copied in. **Say this at install time.** A reduced-mode install that looks
complete is the worst outcome available here.

---

## 3. Verifying the install

| Check | Expected |
|---|---|
| Ask for a trivial code change | The workbench engages before any edit |
| With no `.workbench/` present | Init mode starts and asks about workspaces |
| Ask it to read a protocol, e.g. `probe.md` | It reads the file. Failure here means reduced mode — §2 |
| After init | `.workbench/workbench.yaml` exists, and every value in it is one you confirmed |

The last row is the real test. If the file contains something you were never
shown, the install is wired but the contract is not being honoured — report it
rather than working around it.

### The instance

```
.workbench/          created by init. Project-specific. COMMIT THIS
  workbench.yaml
  domain/            optional, hand-authored reference material
```

`.workbench/` is project configuration reviewed in pull requests, not machine
state. **Do not add it to `.gitignore`.**

### Updating

`npx skills add` again. `.workbench/` is untouched. On the next task the skill
notices `package_version` is behind `SKILL.md`'s `version`, enters migrate mode,
and walks the delta with you.

---

## 4. Appendix — manual install

For a harness the `skills` CLI does not target. Copy `skills/workbench/` wherever
the harness looks for instructions, then wire an entrypoint: something
auto-invoked on hands-on development tasks, carrying this text **verbatim**.

```
For any hands-on development task — changing code, running or writing tests,
debugging, standing services up, capturing behaviour, or reviewing a diff or a
doc set — read `workbench/SKILL.md` first and follow it. It routes the task and
configures itself on first use.
```

Do not paraphrase it. The trigger list is what makes the entrypoint fire on the
tasks it should; shortened to "use the workbench for dev work", it fires on some
and not others, and the gap is invisible until a task is silently handled without
it. Adjust only the path, to wherever you put the package.

Then confirm the harness can read `framework/**` at runtime. If it cannot, §2.
