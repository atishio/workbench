# AGENTS.md — atishio/workbench

Rules for agents working **on this package**. For using the workbench in a
project, read `skills/workbench/SKILL.md` — that is the skill itself, and these
rules do not apply to it.

The package is a set of instructions an agent reads at runtime. It has no tests
and no build, so nothing here fails loudly. Every rule below exists because
breaking it produces a package that still looks correct.

## Before you finish, run the invariants

`skills/workbench/framework/protocol/verify/skill.md` holds nine checks. Run
them on any change to the package, from the repository root:

```bash
PKG=skills/workbench
[ -f "$PKG/SKILL.md" ] || echo "FAIL: PKG does not point at the package"
```

**Confirm that anchor first.** Every check greps a path built from `PKG`, and a
grep against a path that does not exist prints nothing and exits non-zero —
which reads exactly like a pass. This is not hypothetical: the checks hardcoded
`workbench/` until the package was extracted, and all of them would have passed
vacuously afterwards.

Checks 7 and 8 are consumer-repo-only. There is no installed copy and no
`.workbench/` instance here. Check 9 needs a `.workbench-denylist` that this
repository deliberately does not carry; without one it reports *unknown*, and
*unknown* is the honest result — do not read it as a pass.

## MUST

- **`SKILL.md` stays under 150 lines.** It is always loaded, so anything added to
  it displaces something else. New material goes in `framework/` and gets a row
  in the index. Do not raise the budget — that is the one fix that is never right.
- **A behaviour change bumps `version` in the `SKILL.md` frontmatter.** Instances
  record it as `package_version`, and migrate mode compares the two. Change the
  mode table or the routing table without bumping and no existing instance is
  ever told it is behind, which silences the mechanism for exactly the changes it
  exists to propagate.
- **Intra-package paths are relative — `./framework/...`.** A `workbench/...`
  prefix works wherever the package happens to sit and breaks everywhere else.
- **No consumer's product vocabulary.** No product, service, hostname, company
  name, or identifier from any private codebase that uses this. Those are
  instance facts and belong in the consuming repo's `.workbench/`.

  Invariant 9 greps a deny-list, which lives in an **untracked
  `.workbench-denylist`** — a list of a consumer's product names, committed to a
  public repository, publishes exactly what it exists to suppress. Without the
  list the check reports *unknown*, not *pass*.

  The list is incomplete by construction and cannot catch a term it has never
  seen, so **it is not the control.** The control is reading `probe.md` and
  `ai-failure-modes.md` before any release. Those two earn their credibility by
  being concrete, which is the same property that makes them where a real
  identifier arrives. This is not hypothetical: `probe.md` carried four named
  classes from a private Django codebase under a heading reading
  `## Repo-Specific Gotchas`, through every invariant run, for the whole life of
  the repository.
- **Protocols name capabilities, not vendors.** "Browser driver", not
  "Playwright". Implementations are named in appendices and in `SETUP.md`, which
  is where naming them is the entire job.
- **Keep the grounding vocabulary.** `observed`, `confirmed`, `inferred`, and a
  failed check reporting *unknown* rather than *fine*. This is the package's
  purpose, not a stylistic preference.

## MUST NOT

- **Do not add project-specific behaviour here.** If the workbench should act
  differently in one workspace, add a skill to *that workspace* — tier 1 of the
  precedence order, so it wins automatically. A conditional in a hub protocol is
  the wrong answer to that problem every time.
- **Do not edit an installed copy.** Change the package here, push, then
  `npx skills update workbench` in the consumer. The CLI overwrites local edits
  silently and is supposed to.
- **Do not treat `SKILL-SCHEMA.yaml` as a contract.** It is a draft that nothing
  reads — verified, not assumed. If it and `SKILL.md` disagree, `SKILL.md` is
  right, because `SKILL.md` is the thing that runs.
- **Do not remove the standing reads from `SKILL.md`.** The pointer to
  `ai-failure-modes.md` and the lifecycle-tool boundary are prose, not routing,
  so a thinning pass drops them by default and nothing breaks. They are the two
  most load-bearing guardrails in the package; invariant 1 exists only because
  they are this easy to lose.

## Writing style

The protocols are read by an agent mid-task, under context pressure. So: state
the rule, then the failure it prevents. A rule whose reason is missing gets
optimised away by the next person tidying up — most of the invariants exist
because that already happened.

Prefer tables for routing and lookup, prose for reasoning. Say what a check
reports when it *cannot* run; that case is the one that gets skipped, and it is
the one that matters.

## Releasing

1. Run the invariants. Confirm the anchor first.
2. Bump `version` in the `SKILL.md` frontmatter if behaviour changed.
3. Tag `v<version>` to match. The tag and the frontmatter must agree — an
   instance compares against the frontmatter, so the tag is for humans and a
   mismatch misleads only them, silently.
