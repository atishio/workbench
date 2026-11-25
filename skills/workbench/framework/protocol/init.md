# Init Protocol

**What**: Build `.workbench/workbench.yaml` by scanning the project for evidence and having a human decide every value.

**Why**: A config the agent guessed is a config nobody can trust, and every protocol downstream reads it as fact. The scan is cheap; being wrong about which service is on which port is not.

**Modes**: this one protocol has three entry points. `SKILL.md` decides which.

| Mode | Trigger | Scope |
|---|---|---|
| **init** | no `.workbench/workbench.yaml` | all seven sections |
| **repair** | file does not parse, a required section (`workspaces`, `roles`) is null or absent, or a path turned out to be missing at the moment it was used | only the affected sections |
| **migrate** | `package_version` older than the package's own | only sections whose *shape* changed, showing the delta — see below |

## MUST Rules

- MUST create seven todos at the start of a full init, one per section. Progress is tracked by the harness, not by recollection.
- MUST tag every scanned value `observed` or `inferred` before presenting it — see `grounding.md`.
- MUST NOT write a value tagged `inferred` without its own explicit confirmation. Confirming a block does not confirm the inferences inside it.
- MUST write unresolved values as `null` with a `# TODO:` naming what is missing. Never omit the key, and never fill it with a plausible guess.
- MUST NOT advance a section without an explicit answer from the human.

That third rule is the one that matters. It is the difference between
human-driven and human-reviewed, and it is only enforceable because the label
is attached at scan time, before anyone has decided anything.

## Shape versus data — what migrate compares

Migrate diffs the instance against the package's expected **shape** and ignores
its **data**. Getting this wrong is not a small error: treat the data as shape
and a healthy instance reports every stub name, port and CLI verb it has as
drift. A human handed sixty lines of false delta either rubber-stamps it or
stops trusting the mode, and both are worse than not running it.

**Shape — fixed keys the package defines. Compare these.**

`schema_version`, `package_version`, `roles.<role>.*`, `mock.type`,
`mock.admin_url`, `mock.base_url`, `env_vars.reference`,
`stack.bootstrap_order`, `stack.health_check`, `probe.*`, `docs_review.*`,
and the fixed per-workspace keys (`type`, `mode`, `path`, …).

**Data — free-form maps whose keys are the project's own. Ignore these.**

`workspaces` (the names), `hostnames`, `ports`, `mock.stubs`, `mock.seeded`,
`stack.cli_map`, `stack.compose_files`, `env_vars.required`,
`env_vars.optional`, `discovery`.

A key under a free-form map is an answer, not a schema element. The package has
no opinion on whether you have eleven ports or two, and a migration that asks
about them is asking the human to re-confirm section 4 for no reason.

When the shape diff is empty, say so plainly and stamp `package_version`. An
empty delta is the common case and a successful one — the package changed
behaviour, not the file.

## The section loop

Every section runs the same four steps:

1. **Scan** — read files, run read-only commands, collect candidates.
2. **Present** — each candidate with its provenance (format below).
3. **Decide** — the human confirms, edits, or parks. The section's todo closes
   only on an explicit answer.
4. **Write** — confirmed values into the section; parked values as `null` +
   `# TODO:`.

## Presentation format

```
Section 1 of 7 — Workspaces                                    [2 found]

  api      type: app / be      observed   pyproject.toml:2
           path: ./services/api
           framework: FastAPI  observed   pyproject.toml:14
           start_cmd: ???      inferred   README.md:31 — "uvicorn app:main --reload"

  web      type: app / ui      observed   package.json:4
           path: ./web
           framework: React    observed   package.json:21
           dev_server: ???     inferred   vite.config.ts:8 — port 5173

  Confirm, edit a field, or park.
```

`observed` cites a file and line, or the command that produced it. `inferred`
cites the reasoning. Confirming `api` above still leaves `start_cmd` open —
inferences need their own answer, one at a time if the human wants them that
way.

## Sections

### 1 — Workspaces *(required)*

**Scan**: the project's own `CLAUDE.md` / `AGENTS.md` for declared repos;
sibling directories for project markers — `package.json`, `pyproject.toml`,
`setup.cfg`, `go.mod`, `Cargo.toml`, `Makefile`, and agent-config directories.

**Capture** per workspace: `name`, `type` (`app` | `test-suite` | `tooling` |
`ci` | `docs` | `infra` | `skill`), `mode` for apps (`ui` | `be` | `infra`),
`path`, `framework`, `dev_server`, `start_cmd`, agent-config dirs,
`tracker_project`.

`type` decides which `verify/{type}.md` runs, so a wrong type is a wrong
verification for the life of the config. Confirm it explicitly even when the
scan is confident.

### 2 — Roles *(required)*

**Scan**: section 1 results, plus test and CI configuration.

**Ask**: which of developer, qa, reviewer this project serves, and each one's
entrypoints.

| Role | Capture |
|---|---|
| developer | start command, verify command |
| qa | test runner, virtualenv, mock admin, and `layout` (below) |
| reviewer | default diff scope, verify profile |

A project that only serves developers answers once and moves on. Declaring qa
without its runner is worse than not declaring it — the role will route to a
guessed command.

#### Where to scan for role entrypoints

"Test and CI config" is too vague to act on. Look in these, by runner:

| Runner | Look in | Usually yields |
|---|---|---|
| pytest | `pyproject.toml [tool.pytest.ini_options]`, `pytest.ini`, `tox.ini`, `setup.cfg` | `testpaths` → `suites`, `markers` → `selectors` |
| jest / vitest | `package.json` scripts + `jest.config.*` / `vitest.config.*` | `testMatch`/`include` → `suites`, `setupFiles` → `fixtures` |
| go test | `Makefile`, `go.mod` layout | `suites` by convention (`*_test.go` beside source) |
| any | CI workflow files, the project's README "running tests" section | `runner`, and the flags a human actually uses |

A project can be perfectly healthy and have none of these — a repo with
`tests/unit/` and no `conftest.py` has no shared fixtures because it does not
need any. Park the slot; do not manufacture one.

#### `qa.layout` — where test support lives

The slot names are fixed by the workbench; the paths belong to the project.
Ask for each, and omit what does not exist rather than inventing it.

| Slot | Meaning |
|---|---|
| `fixtures` | shared runner fixtures — `conftest.py`, `setup.ts`, equivalent |
| `helpers` | shared test utilities |
| `suites` | roots holding the tests. **A list** — a second root is common |
| `selectors` | where markers, tags or groups are declared |
| `reports` | where run output lands |
| `guides` | the workspace's own test-writing docs |

This is declared rather than discovered on purpose. No two suites lay
themselves out the same way, and a protocol that goes looking for "the
conftest" finds the wrong one without failing — `test-scaffold.md` then writes
a test importing helpers that are not the shared ones, and it passes.

### 3 — Stack *(skippable)*

**Scan**: compose files, process managers, CLI entrypoints, README.

**Capture**: compose/process files, `bootstrap_order`, `health_check`,
`cli_map`.

`bootstrap_order` is the one nobody can infer safely. Ask for it in words:
which plane must be up before which.

### 4 — Network *(skippable)*

**Scan**: compose port maps, `.env*`, README.

**Capture**: `hostnames`, `ports`.

Note any host that must resolve differently inside a container than on the
host — that asymmetry causes the "stub registered but upstream still hit"
failure in `stub-and-capture.md`, and it is invisible later.

### 5 — Mocks *(skippable)*

**Scan**: mock config directories, stub/mapping files.

**Capture**: `mock.type` (required if the section exists), `admin_url`,
`base_url`, stub inventory, seeded fixtures.

A project with no mocks parks this section whole.

### 6 — Env vars *(skippable)*

**Scan**: `.env.example`, compose `environment:` blocks.

**Capture**: `required`, `optional`, `reference`.

Capture names and purposes. **Never capture a value.** A secret in
`workbench.yaml` is a secret in version control.

### 7 — Docs & references *(skippable)*

**Scan**: docs directories, contract directories.

**Capture**: `docs_review.source`, `docs_review.local_docs`,
`discovery.contracts`, `discovery.local_contracts`, domain files,
`probe.probe_dir`.

`contracts` is a **read-only pointer** to whatever the project's lifecycle tool
owns. The workbench reads contracts; it never authors them.

`probe.probe_dir` must be outside every workspace source tree.

## Migrating an existing config

When a config exists at a legacy path — an earlier layout, or another tool's
file — offer it as the scan source for every section rather than starting
blank. Its values arrive as candidates like any other, tagged `observed` with
the legacy file and line.

The human still confirms each one. The saving is retyping, not review.

## Close

Write `.workbench/workbench.yaml`, then validate:

- parses as YAML; `schema_version` and `package_version` present as strings
- every workspace has `type` and `path`; every `path` resolves
- at least one role declared, each with at least one entrypoint
- `stack.bootstrap_order` non-empty if `stack` exists
- `env_vars.reference` exists if declared
- `mock.type` set if `mock` exists

Report every failure. The human acknowledges before init is complete.

### Summary report

```
### Workbench initialised
Workspaces:  {N} — {name (type/mode), ...}
Roles:       {developer, qa, reviewer}
Stack:       {N} commands, bootstrap: {order}
Network:     {N} hostnames, {N} ports
Mocks:       {type} — {N} stubs | parked
Env vars:    {N} required, {N} optional
Unresolved:  {N} — {key: what is missing}
Config:      .workbench/workbench.yaml
```

`Unresolved` is not a failure line. It is the honest count of what nobody could
answer yet, and it is what repair mode will come back to.

## When this fails

| Failure | Recovery |
|---|---|
| The human does not know a value | Park it. `null` + `# TODO:` is a correct answer; a guess is not. |
| The scan finds nothing for a section | Present that honestly — "nothing found, describe it or park it." Do not pad with defaults. |
| A workspace path is outside the repo | Allowed, and worth confirming out loud. Relative paths that escape the repo break for the next person who clones it. |
| The project has one repo and no stack | Sections 1 and 2 only. A four-line config is a valid config. |
| Init is interrupted | Nothing partial is written. Re-run; the todos show what was settled. |
