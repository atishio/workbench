# Changelog

The package version lives in the `SKILL.md` frontmatter. An instance records
the version that generated it as `package_version`, and the skill enters
migrate mode when the two differ — so this file is the written form of the
delta that migrate mode walks you through.

## 0.5.0 — 2026-11-25

**First public release.**

Pre-1.0 on purpose. The shape of `workbench.yaml` and the routing table are
still moving, and below `1.0.0` they may move without a migration path. The
version is a statement about stability, not about completeness — the package
is in use, it simply has not earned a number that promises you it will not
change under you.

### What it does

A coding agent dropped into a multi-repo workspace rediscovers the same facts
every session — which repos exist, how to reach their services, how this team
verifies a change — and a guess that reads as confident is worse than no
answer. The workbench holds those facts and supplies the missing practices,
routing any hands-on task to a protocol suited to the workspace and the role,
**without modifying any workspace repo.**

Authority flows strictly top-down: a workspace's own agent config wins, then
its conventions, then hub protocols, then hub facts. The hub fills gaps and
never overrides. Everything project-specific lives in a `.workbench/` instance
in the consuming repository, built with the human on first use.

Every output cites its source — `observed`, `confirmed` or `inferred` — and a
check that could not run reports **unknown**, never **fine**.

### What ships

- **`SKILL.md`** — the router. Deduces mode (init, repair, migrate, route),
  role and workspace, applies precedence, dispatches. Under 150 lines by rule,
  because it is always loaded.
- **`framework/protocol/`** — the fallback protocols: `init`, `orient`,
  `dev-loop`, `probe`, `review`, `stub-and-capture`, `test-scaffold`,
  `ai-failure-modes`, `grounding`, and nine `verify/` profiles.
- **`framework/ref/`** — tool references named by capability, not by vendor.
- **`scripts/invariants.sh`** — the package's own rules as one runnable
  command that exits non-zero, run by CI on every push and pull request. A
  check that cannot run reports `UNKNOWN` and does not pass.
- `SETUP.md`, `CONTRIBUTING.md`, `SECURITY.md`, issue templates, and
  Apache-2.0 both at the repository root and inside `skills/workbench/` — the
  CLI copies that directory alone, so a licence only at the root would not
  travel with the thing that gets installed.

### One thing worth knowing before you contribute

The package is portable because it carries **no project facts**, and the check
that enforces that — invariant 9 — is not the control.

Its deny-list lives outside the repository, in an untracked
`.workbench-denylist`: a list of a consumer's product names, committed to a
public repo, publishes exactly what it exists to suppress. Without a list the
check reports `UNKNOWN`, never pass.

It is also incomplete by construction and cannot catch a term it has never
seen. An earlier revision of this package held that list inline, which meant
the only match it could ever produce was itself — and four class names out of
a private codebase sat in `probe.md` through every invariant run, under a
heading announcing them as repo-specific. They were found by reading the file.

So the control is reading `probe.md` and `ai-failure-modes.md` before a
release, by hand. Those two earn their credibility by being concrete, and that
is the same property that makes them where a real identifier arrives. If you
contribute a war story — they are welcome, they are the best material here —
**invent the nouns.** There is a fictional project in
`framework/templates/workbench.yaml.example` to borrow from.
