#!/usr/bin/env bash
#
# The package invariants, as one runnable command.
#
# The prose version lives in skills/workbench/framework/protocol/verify/skill.md
# and explains why each check exists. This script is the executable copy, so
# that the checks run in CI instead of relying on a contributor remembering
# them. If the two disagree, the prose is the specification and this is the bug.
#
# Exit codes:  0 = every gate passed   1 = at least one gate failed
#
# A check that could not run reports UNKNOWN and does not pass. That is the
# package's own rule applied to the package, and it is the reason this script
# does not simply `echo FAIL` and exit 0 the way the prose snippets do.

set -uo pipefail

PKG=${PKG:-skills/workbench}
fails=0
unknowns=0

pass()    { printf '  \033[32mPASS\033[0m    %s\n' "$1"; }
fail()    { printf '  \033[31mFAIL\033[0m    %s\n' "$1"; fails=$((fails + 1)); }
unknown() { printf '  \033[33mUNKNOWN\033[0m %s\n' "$1"; unknowns=$((unknowns + 1)); }
review()  { printf '  \033[33mREVIEW\033[0m  %s\n' "$1"; }

echo "workbench package invariants — PKG=$PKG"
echo

# ---------------------------------------------------------------------------
# Anchor. Confirm this before trusting anything below: every check greps a path
# built from PKG, and a grep against a path that does not exist prints nothing
# and exits non-zero, which reads exactly like a pass.
# ---------------------------------------------------------------------------
if [ ! -f "$PKG/SKILL.md" ]; then
  fail "anchor — PKG does not point at the package ($PKG/SKILL.md not found)"
  echo
  echo "Refusing to run the remaining checks. Every one of them would pass vacuously."
  exit 1
fi
pass "anchor — $PKG/SKILL.md exists"

# --- 1. Standing reads are present -----------------------------------------
if grep -q "ai-failure-modes" "$PKG/SKILL.md" && grep -qi "lifecycle tool" "$PKG/SKILL.md"; then
  pass "1 — standing reads present (ai-failure-modes, lifecycle boundary)"
else
  fail "1 — a standing read was removed from SKILL.md"
fi

# --- 2. No intra-package path uses the package-directory prefix -------------
hits=$(grep -rn "workbench/framework\|workbench/domain" "$PKG" --include='*.md' \
        | grep -v "SETUP.md" | grep -v "verify/skill.md" || true)
if [ -z "$hits" ]; then
  pass "2 — no package-prefix paths inside the package"
else
  fail "2 — package-prefix path inside the package:"
  printf '%s\n' "$hits" | sed 's/^/            /'
fi

# --- 3. SKILL.md has not grown ---------------------------------------------
lines=$(wc -l < "$PKG/SKILL.md" | tr -d ' ')
if [ "$lines" -le 150 ]; then
  pass "3 — SKILL.md within budget ($lines/150 lines)"
else
  fail "3 — SKILL.md over budget ($lines/150). Move a block to framework/; do not raise the budget"
fi

# --- 4. Vendor names stay in appendices ------------------------------------
hits=$(grep -rniE 'wiremock|playwright' "$PKG/framework/protocol" "$PKG/framework/ref" \
        | grep -v 'stub-and-capture.md' | grep -v 'ref-browser.md' \
        | grep -v 'verify/skill.md' || true)
if [ -z "$hits" ]; then
  pass "4 — vendor names confined to appendices"
else
  review "4 — vendor name outside an appendix (not a gate; judge it):"
  printf '%s\n' "$hits" | sed 's/^/            /'
fi

# --- 5. Every declared role key has a consumer -----------------------------
missing=""
for k in layout diff_scope verify_profile; do
  n=$(grep -rl "$k" "$PKG/framework/protocol" --include='*.md' | grep -vc 'init.md' || true)
  [ "$n" -gt 0 ] || missing="$missing $k"
done
if [ -z "$missing" ]; then
  pass "5 — every roles key has a consumer"
else
  fail "5 — roles key(s) with no consumer:$missing"
fi

# --- 6. A behaviour change bumps the package version -----------------------
# Locally this reads the index (pre-commit). In CI, set RANGE to the merge base
# so it reads the whole branch. With neither, it cannot run — and says so.
if [ -n "${RANGE:-}" ]; then
  diffcmd=(git diff "$RANGE" -- "$PKG/SKILL.md")
elif git rev-parse --verify -q HEAD >/dev/null && ! git diff --cached --quiet -- "$PKG/SKILL.md" 2>/dev/null; then
  diffcmd=(git diff --cached -- "$PKG/SKILL.md")
else
  diffcmd=()
fi

if [ ${#diffcmd[@]} -eq 0 ]; then
  unknown "6 — no SKILL.md change in scope; version-bump rule not exercised"
else
  body_changed=$("${diffcmd[@]}" --unified=0 \
    | grep -cE '^\+.*(init\.md|dev-loop\.md|probe\.md|review\.md|Mode|repair|migrate)' || true)
  version_bumped=$("${diffcmd[@]}" | grep -c '^+version:' || true)
  if [ "$body_changed" -gt 0 ] && [ "$version_bumped" -eq 0 ]; then
    fail "6 — SKILL.md behaviour changed without a version bump"
  else
    pass "6 — version-bump rule satisfied"
  fi
fi

# --- 7, 8: consumer repositories only --------------------------------------
echo "  SKIP    7, 8 — consumer-repo only (no installed copy, no .workbench/ instance here)"

# --- 9. No consumer's product vocabulary has leaked in ---------------------
# The deny-list is deliberately NOT in this repository: a list of a consumer's
# product names, committed to a public repo, publishes exactly what it exists
# to suppress. Supply it via WORKBENCH_DENYLIST, or a local .workbench-denylist.
LIST=${WORKBENCH_DENYLIST:-.workbench-denylist}
if [ -s "$LIST" ]; then
  terms=$(grep -vE '^[[:space:]]*(#|$)' "$LIST" || true)
  if [ -z "$terms" ]; then
    unknown "9 — deny-list at $LIST has no terms; invariant 9 did not run"
  else
    hits=$(printf '%s\n' "$terms" | grep -rniEf - "$PKG" --include='*.md' --include='*.yaml' || true)
    if [ -z "$hits" ]; then
      pass "9 — none of $(printf '%s\n' "$terms" | wc -l | tr -d ' ') deny-list terms appear"
    else
      fail "9 — consumer vocabulary in the package:"
      printf '%s\n' "$hits" | sed 's/^/            /'
    fi
  fi
else
  unknown "9 — no deny-list at $LIST; invariant 9 did not run"
fi

# ---------------------------------------------------------------------------
echo
if [ "$unknowns" -gt 0 ]; then
  echo "$unknowns check(s) reported UNKNOWN. Unknown is not a pass."
  echo "Invariant 9 cannot be automated away: the list is incomplete by"
  echo "construction. Before any release, read these two by hand --"
  echo "  $PKG/framework/protocol/probe.md"
  echo "  $PKG/framework/protocol/ai-failure-modes.md"
  echo "They are where war stories land, and a war story is where a real"
  echo "identifier arrives."
  echo
fi

if [ "$fails" -gt 0 ]; then
  echo "FAILED — $fails gate(s)."
  exit 1
fi

echo "All gates passed."
exit 0
