# Development Loop Protocol

**What**: Every code change is immediately verified and reported before the next change begins. The human always controls what happens next.

**Why**: Unverified changes accumulate errors. In multi-service systems, a small change can silently break downstream — batching changes before verification makes root-cause analysis exponentially harder.

## MUST Rules

- MUST verify after every code change — never batch multiple unverified changes. When uncertain whether to split, split.
- MUST report verification results before proceeding to the next change.
- MUST NOT auto-iterate in standalone mode — human chooses the next action.
- MUST read relevant guides/skills from the workspace before coding (if they exist).
- MUST follow the workspace's own agent config throughout all iterations — `.claude/`, `AGENTS.md`, `.cursor/`, `.github/copilot-instructions.md`, or whatever form it takes. It is tier 1; these rules are tier 3.

## Per-Iteration Cycle

1. Make the change (smallest logical unit)
2. Verify — dispatch to type-specific protocol (see below)
3. Run compliance (see below)
4. Report using the iteration report format
5. Human chooses the next action (standalone), or the project's lifecycle engine evaluates (lifecycle mode)

## Verification Dispatch

Dispatch based on `workspace.type` and `workspace.mode` from workbench.yaml:

| Workspace type + mode | Verify protocol |
|---|---|
| `app` + `ui` | `verify/app-ui.md` |
| `app` + `be` | `verify/app-be.md` |
| `test-suite` | `verify/test-suite.md` |
| `tooling` | `verify/tooling.md` |
| `ci` | `verify/ci.md` |
| `docs` | `verify/docs.md` |
| `docs` + `docs_review` config | `verify/docs-review.md` |
| `skill` | `verify/skill.md` |

Try `verify/{type}-{mode}.md` first, then `verify/{type}.md`, then `verify/generic.md`.

**Before that chain**, if `roles.developer.verify` is set in `workbench.yaml`,
run it — a project-wide verify command the human confirmed beats a
type-inferred protocol. When it is `null`, that is a deliberate answer meaning
no such command exists, not a gap: fall straight through to the chain above.

## Compliance

Run after verification, before reporting:

1. **Standard linters** — run detected linters on changed files (ESLint, Prettier, Ruff, mypy, tsc — only if config exists AND tool is installed in workspace). Resolve all paths relative to workspace root.
2. **Agent compliance skills** — if the workspace's own agent config defines compliance-type skills, run them on changed files.
3. **Graceful skip** — no linters and no skills → report "Compliance: skipped — no quality tools detected."

## Iteration Report Format

```
### Iteration {N} — {description}
Mode: {workspace.mode or workspace.type}
Verify: {what was observed — test output, console log, screenshot, network response}
Console/Logs: clean | {N} errors (list critical ones)
Compliance: clean | {N} issues | skipped
Next: 1) Continue  2) Fix {issue}  3) Full compliance pass  4) Done
```

Present the Next menu in standalone mode. In lifecycle mode, the engine decides.

## Session Close

```
### Workbench Session Summary
Workspace(s): {list}
Feature: {what was developed/tested/reviewed}
Files modified:
  - {workspace}/{path} — {what changed}
Verification: {final status per workspace}
Compliance: {final status or "skipped"}
```

If a lifecycle engine is active, suggest the relevant next phase. Otherwise suggest: run tests / open PR / continue developing / commit.

## When This Fails

| Failure | Recovery |
|---|---|
| Verification fails for infrastructure reasons | Do not code-fix. Report infra issue, suggest stack recovery. |
| No verify protocol for workspace type | Use `verify/generic.md`. Suggest creating `verify/{type}.md`. |
| Two passes of code reading produced no confirmable cause | Stop changing code. Escalate to `probe.md` — measure the system instead of guessing at it. |
| A fix makes the symptom go away but you cannot say why | Escalate to `probe.md` and run the control. An unexplained fix is an unverified one. |
