# Review Protocol

**What**: Read a change — a diff, a branch, a set of files — and report findings. Write nothing.

**Why**: A reviewer who edits has destroyed the thing being reviewed. The author can no longer see what you objected to, only that it is gone, and the next reviewer inherits a diff nobody wrote deliberately.

**Role**: reviewer. See `orient.md` for how the role is deduced.

## The rule

**Reviewer role does not write to workspace source.** Not a fix, not a typo,
not a formatting nit. Findings go in the report; the human decides which
become work.

Acting on a finding is a separate, developer-role task the human starts
explicitly. That separation is the whole point: it keeps the review auditable
and keeps the author in the loop on their own code.

## Red flags

These thoughts mean stop — you are about to write in a read-only role:

| Thought | Reality |
|---|---|
| "I'll just fix this one typo while I'm here" | Reviewer writes nothing. Output it as a finding. |
| "Applying it is faster than describing it" | Faster for you, invisible to whoever asked for the review. |
| "They'll obviously want this changed" | Then it is a finding they accept in one word. |
| "It's only a test file / only a comment" | Scope is not severity. No writes. |
| "I need to run it to check, and that writes a file" | Build artifacts and logs outside the source tree are fine. Source is not. |
| "I'll stage the fix but not commit" | The working tree is the artifact under review. |

## Steps

1. **Scope** — establish exactly what is under review. Default to
   `roles.reviewer.diff_scope` from `workbench.yaml`; the human can override
   with a branch, range or file set. Record whichever was used. A review whose
   scope was never stated cannot be reported against.
2. **Read workspace authority** — the workspace's own conventions decide what
   counts as a defect here. A hub opinion never overrides them.
3. **Verify where you can** — dispatch to `roles.reviewer.verify_profile`,
   read-only. If it is unset, use `verify/common.md`. An unverified review is
   an opinion; say which it is.
4. **Collect findings** — each with a location, a severity, and its grounding
   label (`observed` / `inferred`) per `grounding.md`.
5. **Report** — the format below.
6. **Exit check** — see below.

## Exit check

Run `git status` in every workspace touched during the review. It must be
unchanged from session start. Report the result as evidence:

```
Workspaces touched: api, web
git status: clean in both — no writes made during review
```

If it is not clean, say so plainly, say what changed, and offer to revert. A
review that silently modified the tree is worse than no review, because the
author will trust the diff.

## Report format

```
### Review — {scope}
Scope: {diff range / branch / file set}  (from roles.reviewer.diff_scope | given by human)
Verified: {profile used} — {tests run, linters run} | not verified — {why}

Findings ({N}):
  {severity}  {file}:{line}  {observed|inferred}
    {one sentence: what is wrong}
    {concrete failure: input → wrong result}

Not covered: {what this review did not look at}
git status: {clean in {workspaces} | CHANGED — {detail}}
```

Severity is the reviewer's judgement, but "it would break" and "I would have
written it differently" are different findings and must not be reported at the
same weight.

## When this fails

| Failure | Recovery |
|---|---|
| The change cannot be understood without running it | Run it read-only. If that is impossible, say the review is static-only and name what that leaves unchecked. |
| A finding needs a fix to demonstrate | Write the proposed diff **in the report**, not into the tree. |
| The scope is ambiguous | Ask. Reviewing the wrong range wastes the author's time twice. |
| Every finding is `inferred` | The review was not verified. Label it that way rather than letting inference read as measurement — `ai-failure-modes.md` F2. |
| You already wrote to the tree before reading this | Report it, revert it, continue. Concealing it is the failure; the write was a mistake. |
