# Verify: Skill/Agent Definitions

Inherits: `common.md`

**Outcome**: frontmatter is valid, every referenced path resolves, and the workbench package's own invariants still hold.

## Additional Rules

- MUST verify every path in a routing table resolves to an actual file — a broken reference causes silent skill failure, not an error.
- MUST run the package invariants below when the changed files are inside the package directory.

## Additional Signals

- YAML frontmatter parses; `name` and `description` present
- Every file path in the skill body resolves
- No circular references between skills

## Package invariants

These checks exist because each one guards something that can be removed without
anything appearing to break. Run them on any change to the package.

Set `PKG` to the package directory first — `skills/workbench` in the package
repository, or wherever the harness installed it.

```bash
PKG=skills/workbench
[ -f "$PKG/SKILL.md" ] || { echo "FAIL: PKG does not point at the package"; }
```

That second line is not ceremony. Every check below greps a path built from
`PKG`, and a `grep` against a path that does not exist prints nothing and exits
non-zero — which reads exactly like a pass. Confirm the anchor before trusting
any result that follows.

### 1. Standing reads are present

`SKILL.md` must still instruct the reader to consult `ai-failure-modes.md`
before a long investigation, and must still state the boundary against the
project's lifecycle tool.

```bash
grep -q "ai-failure-modes" "$PKG/SKILL.md" || echo "FAIL: standing read removed"
grep -qi "lifecycle tool"  "$PKG/SKILL.md" || echo "FAIL: lifecycle boundary removed"
```

Neither line is routing, so a thinning pass drops them by default. They are the
package's two most load-bearing guardrails, and a guardrail that can be
silently removed is not one.

### 2. No intra-package path uses the package-directory prefix

Inside the package, references are relative — `./framework/...`. A
`workbench/framework/...` prefix works where the package happens to sit at
`workbench/` and breaks the moment it is installed anywhere else.

```bash
grep -rn "workbench/framework\|workbench/domain" "$PKG" --include='*.md' \
  | grep -v "SETUP.md" \
  | grep -v "verify/skill.md" \
  && echo "FAIL: package-prefix path inside package"
```

Quote the `--include` glob. Unquoted, zsh expands it against the current
directory and the command dies with `no matches found` — which exits non-zero
and reads exactly like a pass.

Two exclusions, for different reasons. `SETUP.md` describes paths in the
*target* repository, from the installer's point of view, where the prefix is
correct. This file states the patterns it searches for and so matches itself —
the cost is that a genuine prefix bug introduced here is not caught by this
check, which is worth it to have the check run at all.

### 3. `SKILL.md` has not grown

It is always loaded, so additions must displace, not extend.

```bash
[ "$(wc -l < "$PKG/SKILL.md")" -le 150 ] || echo "FAIL: SKILL.md over budget"
```

### 4. Vendor names stay in appendices

Protocols name capabilities; appendices name implementations. Both files that
legitimately contain vendor names carry an `## Appendix` heading, so exclude
them by filename rather than by pattern — the previous version of this check
tried to exclude by regex, embedded an unescaped backtick, and was a shell
syntax error that never ran once.

```bash
grep -rniE 'wiremock|playwright' \
     "$PKG/framework/protocol" "$PKG/framework/ref" \
  | grep -v 'stub-and-capture.md' \
  | grep -v 'ref-browser.md' \
  | grep -v 'verify/skill.md' \
  && echo "REVIEW: vendor name outside an appendix"
```

This file is excluded because it contains the vendor names inside the check
above and would otherwise match itself forever.

`SETUP.md` is not searched: it is the install-time document and naming concrete
servers is its entire job. `framework/templates/` is excluded by not being
listed — an example config contains example *values*, and one with no concrete
mock type teaches nothing.

### 5. Every declared role key has a consumer

`init.md` asks for role entrypoints. If no protocol reads one back, the
interview is collecting answers into a void — which is exactly the failure
`init.md` warns about, inverted.

```bash
for k in layout diff_scope verify_profile; do
  n=$(grep -rl "$k" "$PKG/framework/protocol" --include='*.md' \
      | grep -v 'init.md' | wc -l)
  [ "$n" -gt 0 ] || echo "FAIL: roles key '$k' has no consumer"
done
```

### 6. A behaviour change bumps the package version

Migrate mode compares `SKILL.md`'s `version` against the instance's
`package_version`. Change the mode table or the routing table without bumping,
and no existing instance is ever told it is behind — the propagation mechanism
goes quiet for exactly the changes it exists to propagate.

```bash
git diff --cached --unified=0 -- "$PKG/SKILL.md" \
  | grep -qE '^\+.*(init.md|dev-loop.md|probe.md|review.md|Mode|repair|migrate)' \
  && ! git diff --cached -- "$PKG/SKILL.md" | grep -q '^+version:' \
  && echo "FAIL: SKILL.md behaviour changed without a version bump"
```

### 7. The installed copy has not drifted

**Consumer repositories only.** There is no installed copy in the package
repository, so this check does not apply there.

Two copies of the same package diverge the first time someone edits one of them.

```bash
npx skills list 2>/dev/null | grep -A1 '^workbench ' | grep -q 'Source: ' \
  || echo "FAIL: installed workbench is untracked — a local fork, not an install"
```

**Do not exempt symlinks.** The obvious-looking guard
`[ -L .claude/skills/workbench ] || ...` is wrong: current CLI versions install
the body into `.agents/skills/<name>/` and symlink each agent's skill directory
at it, so a correct install *is* a symlink and the exemption swallows every
check. Ask the lockfile, which answers for both layouts.

That layout has a second consequence worth checking once per repository: ignore
**`.agents/`** as well as the agent-specific path. Ignoring only
`.claude/skills/<name>` leaves the actual files tracked, and the next
`git add -A` commits the whole package back into the consumer — which is the
exact state installing it was meant to end.

What this catches is an installed copy with **no source in
`skills-lock.json`** — someone hand-placed or hand-edited the directory, and it
is now a fork nothing will ever update.

What it does **not** catch is content drift in a tracked skill. The CLI records
a `computedHash` per skill but exposes no verify command — `list` reports source
and absence, not divergence. So the guard is the rule, not the check: **never
edit the installed copy.** Change the package upstream and run
`npx skills update workbench`, which overwrites local edits silently and is
supposed to.

### 8. The example config and a migrated instance agree on shape

**Consumer repositories only** — it compares against `.workbench/workbench.yaml`,
which exists only where the workbench has been initialised.

The example is the package's expected shape. If an instance at the current
`package_version` disagrees with it on a fixed key, either the example was
updated without a migration path or an instance drifted — and migrate mode
will not catch it, because it only runs when the version is behind.

Compare fixed keys only. `init.md` lists which are shape and which are data;
comparing the free-form maps reports every port and stub name as drift.

```bash
PKG=${PKG:-.claude/skills/workbench} python3 - <<'PY'
import os, yaml
PKG=os.environ['PKG']
FREEFORM={'workspaces','hostnames','ports','mock.stubs','mock.seeded',
          'stack.cli_map','stack.compose_files','env_vars.required',
          'env_vars.optional','discovery'}
def paths(o,p=''):
    out=set()
    if isinstance(o,dict):
        for k,v in o.items():
            q=f'{p}.{k}'.lstrip('.'); out.add(q)
            if q not in FREEFORM and p not in FREEFORM: out|=paths(v,q)
    return out
e=paths(yaml.safe_load(open(f'{PKG}/framework/templates/workbench.yaml.example')))
i=paths(yaml.safe_load(open('.workbench/workbench.yaml')))
d=(e-i)|(i-e)
print("FAIL: shape drift "+str(sorted(d)) if d else "OK: shape matches")
PY
```

### 9. No consumer's product vocabulary has leaked in

The package is portable because it carries no project facts — those live in the
consuming repository's `.workbench/` instance. The leak is never deliberate. It
arrives as an example made concrete, a protocol written while staring at one
codebase, a hostname that seemed generic.

The deny-list lives **outside this repository**, in an untracked
`.workbench-denylist` — one term per line, `#` for comments — held by whoever
maintains the package. It is not committed, and that is the point: a list of a
consumer's product names, checked into a public repository, publishes exactly
what it exists to suppress. The check is the tracked part; the terms are not.

```bash
LIST=${WORKBENCH_DENYLIST:-.workbench-denylist}
if [ -s "$LIST" ]; then
  grep -rniEf <(grep -v '^[[:space:]]*\(#\|$\)' "$LIST") "$PKG" \
       --include='*.md' --include='*.yaml' \
    && echo "FAIL: consumer vocabulary in the package"
else
  echo "UNKNOWN: no deny-list at $LIST — invariant 9 did not run"
fi
```

**The `else` branch is the whole design.** A missing list must report *unknown*,
never *pass* — the earlier version of this check carried its terms inline, which
meant the only match it ever produced was itself, while four pages of a
consumer's internals sat elsewhere in the package untouched. A check that can
only find itself is not a check.

The list is a deny-list, so it is **incomplete by construction** — it cannot
catch a term from a consumer it has never seen. Extend it on each new adoption.
A clean result means "none of these appeared", not "this package is neutral".

What catches the terms no list knows is review, not grep: before publishing,
read `probe.md` and `ai-failure-modes.md` specifically. They are where war
stories land, a war story is where a real identifier arrives, and both files
earn their credibility by being concrete.

`framework/templates/` is searched too, deliberately. The example config
describes a fictional project precisely so that no real one is named, and that
is the file most likely to acquire a real hostname during a debugging session.

## When this fails

| Failure | Recovery |
|---|---|
| A path stopped resolving after a move | Fix the reference, then check invariant 2 — a move usually introduces the prefix bug too. |
| `SKILL.md` is over budget | Do not raise the budget. Move a block to `framework/` and add a row to the index. |
| A standing read was removed | Restore it verbatim. If it genuinely no longer applies, that is a spec change, not a cleanup. |
| A check printed nothing and you read it as a pass | Confirm `PKG` points at a real package first. A grep against a missing path is silent. |
