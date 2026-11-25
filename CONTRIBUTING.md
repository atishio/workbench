# Contributing

The rules that actually govern changes to this package live in
[`AGENTS.md`](AGENTS.md). They are written for an agent working on the package,
and they apply just as well to a human. **Read that first** — this file only
covers the mechanics around it.

## The one-paragraph version

This package is a set of instructions an agent reads at runtime. It has no
runtime of its own, no build, and no unit tests. Nothing here fails loudly.
Every rule in `AGENTS.md` exists because breaking it produces a package that
still looks correct.

## Before you open a pull request

```bash
./scripts/invariants.sh
```

Six gates, a skip, and two checks that may report `UNKNOWN`. CI runs the same
script on every pull request.

**`UNKNOWN` is not a pass.** The script says so and so does the package — a
check that could not run reports *unknown*, never *fine*. If a check you needed
reports unknown, give it what it needs rather than reading past it.

Then:

- **Does your change alter behaviour?** Bump `version` in the `SKILL.md`
  frontmatter. Instances record it as `package_version` and compare the two on
  the next task; change the routing or mode tables without bumping and no
  existing instance is ever told it is behind, which silences the propagation
  mechanism for exactly the changes it exists to propagate.
- **Did `SKILL.md` grow?** It is always loaded, so additions must displace
  rather than extend. New material goes in `framework/` and gets a row in the
  index. Do not raise the 150-line budget — that is the one fix that is never
  right.

## The thing most likely to go wrong

**Do not put anything from a real codebase in here.** No product, service,
hostname, company name, or identifier out of any project that uses this. Those
are instance facts; they belong in the consuming repo's `.workbench/`.

Invariant 9 greps a deny-list for exactly this, and you should know two things
about it before you trust it:

1. The list lives **outside this repository**, in an untracked
   `.workbench-denylist`. A list of a consumer's product names, committed to a
   public repo, publishes precisely what it exists to suppress.
2. It is **not the control.** It cannot catch a term from a project it has
   never seen.

The control is reading [`probe.md`](skills/workbench/framework/protocol/probe.md)
and [`ai-failure-modes.md`](skills/workbench/framework/protocol/ai-failure-modes.md)
before a release. Those two earn their credibility by being concrete, which is
the same property that makes them where a real identifier arrives. Before this
package was first published they carried four class names out of a private
codebase, under a heading announcing them as repo-specific, through every
invariant run. Reading caught it; the check never would have.

If you contribute a war story — and they are welcome, they are the best
material in the package — **invent the nouns.** There is a fictional project in
`framework/templates/workbench.yaml.example` to borrow from.

## Writing style

The protocols are read by an agent mid-task, under context pressure.

- **State the rule, then the failure it prevents.** A rule whose reason is
  missing gets optimised away by the next person tidying up. Most of the
  invariants exist because that already happened.
- **Tables for routing and lookup; prose for reasoning.**
- **Say what a check reports when it _cannot_ run.** That case is the one that
  gets skipped, and it is the one that matters.
- **Name capabilities, not vendors.** "Browser driver", not a product name.
  Implementations are named in appendices and in `SETUP.md`, where naming them
  is the entire job.

## Changing what the workbench does in one project

Don't do it here. Add a skill to *that* workspace — it is tier 1 of the
precedence order and wins automatically. A conditional in a hub protocol is the
wrong answer to that problem every time.

## Reporting something instead

See [`SECURITY.md`](SECURITY.md) if you have found a leaked identifier or a
secret. Everything else: open an issue.

A specific one worth reporting rather than working around — if `init` writes a
value into `.workbench/workbench.yaml` that you were never shown and never
confirmed, that is a bug in the thing this package exists to guarantee.
