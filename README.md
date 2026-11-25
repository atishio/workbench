# workbench

A coding agent dropped into a multi-repo workspace has to rediscover the same
things every session: which repos exist, how to reach their services, what mock
infrastructure is available, how this team verifies a change. It usually guesses,
and a guess that reads as confident is worse than no answer.

The workbench is the hub that holds those facts and supplies the missing
practices. It routes any hands-on task — a code change, a test run, a stalled
debugging session, a diff review — to a protocol suited to the workspace and the
role, **without modifying any workspace repo**.

## The idea

Workspace repos are the authority on their own code. A repo that defines how its
UI tests work has already answered the question, and the hub has no business
overriding it. So authority flows strictly top-down:

```
1. Workspace authority     its own agent config — .claude/, AGENTS.md, .cursor/
2. Workspace conventions   its coding style, test approach, lint rules
3. Hub protocols           fallbacks, filling only what the workspace leaves open
4. Hub facts               infrastructure from workbench.yaml, always available
```

The hub fills gaps. It never overrides.

That split has a second consequence, which is what makes this package portable
at all: **the package carries no project facts.** Everything specific to your
work lives in a `.workbench/` instance in the consuming repository, built with
you on first use and committed there.

Project-neutral is a thing the package is kept at, not a thing it is. Invariant
9 greps a deny-list for a consumer's vocabulary, and the list is incomplete by
construction — it cannot catch a term from a project it has never seen. For the
whole life of this repository, `probe.md` carried four class names out of a
private codebase under a heading announcing them as repo-specific, and every
invariant run passed. They are gone, and the rule that replaced the check is
simply: read the two files where war stories land before publishing.

```
Package (this repo)              Instance (your repo)         Workspaces
───────────────────              ────────────────────         ──────────
SKILL.md          router         .workbench/
SETUP.md          wiring           workbench.yaml  facts      agent config
framework/        defaults         domain/         reference  conventions
```

## Install

```bash
npx skills add https://github.com/atishio/workbench.git --skill workbench -a claude-code -y
```

Add `-g` to install at user level instead of per-project. Works with the
[`skills`](https://www.npmjs.com/package/skills) CLI for Claude Code, Codex,
Cursor, OpenCode and others.

Then start any development task. The skill finds no `.workbench/`, and instead
of assuming anything it runs init: a seven-section interview that scans the
project for evidence and has **you** decide every value. Nothing it merely
inferred is written without your say-so — and if the resulting file contains
something you were never shown, that is a bug worth reporting rather than
working around.

`.workbench/` is then committed. It is configuration reviewed in pull requests,
not machine state, so it does not belong in `.gitignore`.

[`SETUP.md`](skills/workbench/SETUP.md) covers the rest: wiring MCP servers for
the tool capabilities, recognising a harness that cannot run the package, and
confirming the install actually works.

## What you get

Three roles, deduced at runtime from what you ask for rather than declared up
front. **Developer** changes code and verifies each change, escalating to a probe
when debugging stalls. **QA** stands the stack up, drives the feature, captures
real traffic and turns it into tests. **Reviewer** reads and reports — and does
not write to workspace source, so findings stay findings until a human decides
which become work.

Behind those sit the fallback protocols, used only where a workspace has no
opinion of its own:

| Protocol | What it does |
|---|---|
| `dev-loop.md` | Change → verify → report, one change at a time |
| `probe.md` | Debugging has stalled — measure the system instead of guessing |
| `review.md` | Read a diff and report findings. Writes nothing |
| `stub-and-capture.md` | Set up mocks, capture network flows |
| `test-scaffold.md` | Turn captured flows into test code |
| `verify/*.md` | Type-specific verification — `app-ui`, `app-be`, `test-suite`, and six more |
| `init.md` | Build or repair the instance config, human-driven, section by section |
| `orient.md` | Identify workspace and role, check stack health, route |
| `ai-failure-modes.md` | The recurring ways this work goes wrong, and the guard for each |
| `grounding.md` | How every claim carries its source |

The last two are the ones worth reading before you need them.

## Grounding

Every output cites its source: `observed` from a running system, `confirmed` by
a human, or `inferred` — which must be flagged as such. A check that could not
run produces **unknown**, never **fine**. That distinction is the point of the
package. An agent that reports a passing UI it never loaded has not saved you
time, it has spent your trust.

## Versioning

`version` in the `SKILL.md` frontmatter is the package version, and an instance
records the version that generated it as `package_version`. When the package
moves ahead, the skill enters migrate mode on the next task and walks the delta
with you.

Which means a behaviour change **must** bump the version, or the propagation
mechanism goes quiet for exactly the changes it exists to propagate. That rule,
and seven others, are enforced by the package invariants in
[`framework/protocol/verify/skill.md`](skills/workbench/framework/protocol/verify/skill.md).

## Working on the package

Read [`AGENTS.md`](AGENTS.md) first — it holds the rules that are easy to break
without anything appearing to fail. Layout:

```
skills/workbench/
  SKILL.md              the router — always loaded, deliberately under 150 lines
  SETUP.md              install-time: tools, reduced mode, verification
  README.md             package overview
  LICENSE               Apache-2.0. Here, not only at the repo root, because
                        this directory is what the CLI copies into a consumer
  SKILL-SCHEMA.yaml     draft, non-normative, nothing reads it
  framework/
    protocol/           fallback protocols
    ref/                tool references, named by capability rather than by vendor
    templates/          annotated example config, capture handoff document
```

Changing what the workbench does **in one workspace** is not a change to this
repo. Add a skill to that workspace — it takes precedence automatically.
