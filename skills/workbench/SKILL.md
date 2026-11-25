---
name: workbench
version: "0.5.0"
description: >
  Use for any hands-on development task in this project — changing code,
  running or writing tests, debugging, standing services up, capturing
  behaviour, or reviewing a diff or a doc set. Routes the task to the right
  protocol for the workspace and the role, and sets up its own configuration
  on first use. Invoke before other implementation skills. Skip only for
  purely conversational questions that read no files and run no tools.
---

# Workbench — Development Hub

This repository is a development hub. It knows the workspace landscape — repos,
services, mocks — and supplies default development practices. Workspace repos
are the authority on their own code; hub knowledge fills gaps and never
overrides.

Install, tools and verification: `./SETUP.md`.

## When to invoke

Before any hands-on task: code changes, test runs, verification, debugging,
service startup, network capture, mock setup, or doc review.

Skip only when all three hold: no file reads beyond project instructions, no
tool use, and the answer is purely conversational.

## Step 1 — Deduce the mode

Never ask which mode to run. Two reads, no directory walks:

| Observation | Mode |
|---|---|
| no `.workbench/workbench.yaml` | **init** — `./framework/protocol/init.md`, all seven sections |
| present, does not parse | **repair** — `init.md`, whole file |
| parses, a required section is null or absent | **repair** — `init.md`, that section |
| parses, `package_version` older than this file's `version` | **migrate** — `init.md`, show the delta |
| parses, current | **route** — Step 2 |

Required sections are `workspaces` and `roles`. The rest are skippable, and a
skipped section is `null` on purpose — only these two make the config unusable
by being empty.

Resolve `.workbench/` in this order, which matters:

1. Find the **repository root** — the nearest ancestor holding `.git`.
2. Search for `.workbench/workbench.yaml` from the working directory up to and
   including that root, and no further.
3. **No repository root → search the working directory only.** Do not walk.

Absence is not an error; it is the init trigger. Why the order matters:
`orient.md`.

The split above is by **cost, not by importance**. Checking that a required
section is present is free — the parse already produced it. Resolving every
declared path is not, so it runs at init and at explicit repair, **never as a
pre-flight sweep**. When a path turns out to be missing at the moment it is
used, surface it then: `workspace {name} path missing — repair section 1?`

## Step 2 — Orient and route

1. Identify the workspace from `.workbench/workbench.yaml`
2. Read the workspace's own agent config — skills, rules, guides. **This is the
   authority.**
3. Deduce the role from the task signal
4. Check stack health only if the task needs running services
5. Route — a matching workspace skill wins; otherwise the fallback below

| Task signal | Role | Hub fallback |
|---|---|---|
| implement, add, create, build, fix, refactor | developer | `./framework/protocol/dev-loop.md` |
| cause unconfirmed after two passes, unexplained fix | developer | `./framework/protocol/probe.md` |
| write test, add test, scaffold test | qa | `./framework/protocol/test-scaffold.md` |
| run tests, reproduce, capture, drive UI, mock setup | qa | `./framework/protocol/stub-and-capture.md` → verify |
| review, audit, check the diff | reviewer | `./framework/protocol/review.md` |
| review docs, audit docs | reviewer | `./framework/protocol/verify/docs-review.md` |
| set up, start, stop, health | any | `stack` section, directly |

Several signals match → prefer the more specific. None match → developer plus
`dev-loop.md`. Role is a hint, not a lock; the human can name it. The one
behaviour it fixes is **reviewer writes nothing** — see `review.md`.

**Check the deduced role is declared** in `roles`. If it is not, fall back to
developer and say so once: `no qa role declared — routing as developer`. A role
the project never configured has no runner, no layout and no verify profile, so
routing to it means routing to blanks.

Each role's declared entrypoints are read by the protocol it routes to —
`dev-loop.md` uses `roles.developer.verify`, `test-scaffold.md` uses
`roles.qa.layout`, `review.md` uses `roles.reviewer.diff_scope` and
`verify_profile`.

Full orient protocol: `./framework/protocol/orient.md`.

## Step 3 — Apply precedence

Authority flows strictly top-down:

1. **Workspace authority** — its own agent config (`.claude/`, `.cursor/`,
   `AGENTS.md`, `.github/copilot-instructions.md`, or equivalent)
2. **Workspace conventions** — its coding style, test approach, lint rules
3. **Hub protocols** — `./framework/protocol/`, filling only what the workspace
   does not define
4. **Hub facts** — `.workbench/workbench.yaml`, always available

A hub protocol never overrides a workspace's own approach.

## Standing reads

Before a long investigation or a multi-workspace change, read
`./framework/protocol/ai-failure-modes.md` — the recurring ways AI-assisted
work goes wrong here, and the guard for each. Re-read it when a session has
gone sideways and you cannot say why.

Every claim carries its source: `observed`, `confirmed`, or `inferred`.
`inferred` must be flagged. See `./framework/protocol/grounding.md`.

The workbench does not manage project-level domain knowledge, phases, or
gates — those belong to the project's lifecycle tool. Workbench owns the
hands-on loop and holds no state beyond `workbench.yaml`. It never writes to a
lifecycle tool's directories, and where both could handle a task, the lifecycle
skill wins: it is workspace authority, tier 1.

## Index

| Need | Read |
|---|---|
| Configure or repair the instance | `./framework/protocol/init.md` |
| Orient, route, workspace context | `./framework/protocol/orient.md` |
| Change code and verify it | `./framework/protocol/dev-loop.md` |
| Debugging has stalled | `./framework/protocol/probe.md` |
| Review a diff or a file set | `./framework/protocol/review.md` |
| Guardrails against known failure modes | `./framework/protocol/ai-failure-modes.md` |
| Label a claim's source | `./framework/protocol/grounding.md` |
| Mock setup and network capture | `./framework/protocol/stub-and-capture.md` |
| Turn a capture into tests | `./framework/protocol/test-scaffold.md` |
| Verify by workspace type | `./framework/protocol/verify/{type}.md`, then `{type}-{mode}.md`, then `generic.md` |
| Shared verification checks | `./framework/protocol/verify/common.md` |
| Browser operations | `./framework/ref/ref-browser.md` |
| What tools are expected, and what to report when absent | `./framework/ref/ref-tools.md` |
| Install, MCP wiring, verifying the install | `./SETUP.md` |

Verify types available: `app-be`, `app-ui`, `test-suite`, `tooling`, `docs`,
`docs-review`, `ci`, `skill`, `generic`.
