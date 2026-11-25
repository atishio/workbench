# Orient Protocol

**What**: Establish context — which workspace, which role, what tools exist there, and whether to use a workspace skill or a hub fallback.

## Steps

1. **Identify workspace** — read `.workbench/workbench.yaml`, match the task to workspace(s)
2. **Read workspace authority** — scan the workspace's own agent config for skills, rules, guides, agents
3. **Deduce role** — developer, qa or reviewer, from the task signal (below)
4. **Check stack health** — only if the task needs running services (the workspace has `dev_server` or `start_cmd`)
5. **Route** — a matching workspace skill wins; otherwise fall back to a hub protocol

## Task Routing

**The routing table lives in `SKILL.md` and only there.** It is always loaded,
so it has to route without a second read — a copy here would be a second
authority that drifts, and it already had.

What this protocol adds to it:

- A matching **workspace skill always wins** over any hub fallback. Check the
  workspace's own agent config before consulting the table at all.
- The deduced role must be **declared** in `roles`. If it is not, fall back to
  developer and say so once — an undeclared role has no runner, no layout and
  no verify profile.
- Role is a hint, not a lock. The human can name it. The one behaviour it fixes
  is reviewer's no-write rule; see `review.md`.

## Workspace Context

From `workbench.yaml`, use workspace fields to know what is available:

- `skills_dir`, `agents_dir`, `rules_dir`, `guides_dir` — scan for tooling
- `dev_server`, `start_cmd` — how to start and reach the service
- `framework`, `design_system` — tech context
- `tracker_project` — issue tracking context

Read the harness tool manifest to know which tools exist, and use them
proactively for reads. See `../ref/ref-tools.md` for what each capability is
used for, and what to report when one is absent.

## When This Fails

| Failure | Recovery |
|---|---|
| `.workbench/workbench.yaml` not found | Not an error — this is the init trigger. Run init. |
| A config was found, but above the repository root | It is not this project's. Bound the search first (see below), then treat it as not found. |
| Workspace path does not exist | Surface it at the point of use: "workspace {name} path missing — repair section 1?" Do not sweep all paths pre-emptively. |
| Stack health fails | Report which services are down. Suggest the `stack.cli_map` command. Do not code against a down stack. |
| Task matches no workspace | Ask which one. Guessing a workspace routes every later decision wrong. |

## Why config resolution is bounded before it searches

`SKILL.md` resolves `.workbench/` by finding the repository root *first*, then
searching only from the working directory up to that root — and not walking at
all when there is no root.

The obvious implementation does the opposite: walk up, return the first
`.workbench/workbench.yaml` found, stop at `.git` on the way. It is wrong, and
it fails quietly. A directory outside any repository keeps climbing until it
finds some ancestor's config — a sibling project, a scratch directory, a home
directory — and adopts it. The skill then deduces `route`, not `init`, so it
never offers to configure itself, and every task afterwards runs against
another project's workspaces, ports and mock URLs.

Checking `.git` inside the same loop does not save it: the config test runs
first at each level, so an ancestor holding a config is adopted before the
boundary is ever evaluated.

This was found by installing the package into a directory that was not a git
repository. Nothing about it is visible from inside a repo, which is where it
would otherwise have been found by a user rather than by a test.
