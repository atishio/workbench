# Probe Protocol

**What**: Instrument a running system to find a defect that reading code has failed to locate. Build small, disposable, read-only observers at each boundary; then change exactly one variable and re-observe.

**Why**: When code reading stalls, the next instinct is to guess — pick a plausible mechanism, "fix" it, and declare victory. A probe replaces that with measurement. It also protects against the subtler failure: a hypothesis that reproduces *a* symptom via a mechanism the real system never takes.

**When**: Escalate here from `dev-loop.md` or a verify protocol when any of these is true:

- Two passes of code reading have produced a hypothesis you cannot confirm
- You reproduced the symptom, but the reporter says their path differs
- The data looks correct at every layer and the output is still wrong
- The bug is in a pipeline (write → signal → queue → worker → transport) and you cannot say which stage drops it

The failure modes this protocol defends against are catalogued in
`ai-failure-modes.md` — F1 (reproducing a symptom the system never produces),
F2 (inference dressed as a finding) and F3 (blaming the product for a harness bug)
are the three that make probing necessary in the first place.

## Outcomes

- A named hypothesis, and a measurement that would falsify it
- Probe scripts under `${probe_dir}` that anyone can re-run
- An A/B result: the same probe with one variable toggled
- A verdict that names the failing stage, or an explicit "not reproduced"

## MUST Rules

- MUST state the hypothesis and its falsifying observation **before** running the probe. A probe you interpret after the fact will confirm whatever you already believed.
- MUST make state probes read-only. A probe that mutates the thing it measures is an experiment, and must be named and treated as one.
- MUST change exactly one variable per run. Two changes means no attributable result.
- MUST run the control — the same probe with the change reverted. "It works now" without a failing baseline proves nothing.
- MUST prefer the system's own vocabulary (its gates, its queries, its queues) over reimplementing the logic in the probe. A probe that recomputes the answer tests the probe.
- MUST distinguish *harness wrong* from *product wrong* before reporting a defect. Check the service log for what the product actually did.
- MUST NOT convert a probe into a fix in the same step. Probe → verdict → then `dev-loop.md`.
- MUST keep probes out of the repo — write them to `${probe_dir}` (see below), never into workspace source trees.

## Where Probes Live

Probes are scratch, not deliverables. Write them to `probe.probe_dir` from `workbench.yaml` — the scratch directory this project designated at init, which section 7 requires to be outside every workspace source tree. If it is unset, ask for one rather than picking a directory; a probe written into a source tree is a failure mode, not a helper.

Group them per investigation with a shared `probe_common.py` (or equivalent) holding the identifiers under test, so every probe in the set observes the same subject.

If a probe proves durably useful, promote it — into the workspace's test suite as a regression test, or into a component GUIDE as a documented diagnostic. Otherwise let it die with the investigation.

## The Four Probe Kinds

### 1. State probe — read-only, safe anytime

Dumps the subject as *the failing subsystem sees it*, with a keep/drop verdict and reason per element.

The reason column is the whole point. `order 24 DROPPED: region 'EU-West' not in catalogue` ends an investigation that a raw row dump would not.

Call the system's own gate functions rather than re-deriving them, and print each gate separately — a pipeline usually has a gate that decides *whether* to act and a second that decides *what* to send. They ask different questions, and a mismatch between them is a common bug shape.

### 2. Write-path probe — which code paths actually fire?

For signal/CDC/trigger bugs. Exercise each way the field is written and record whether the observer fired:

```
Subscription.tier via obj.save()             ENQUEUED
Subscription.tier via queryset .update()     BLOCKED by guard
Subscription.updated_at via save()           --- nothing ---   [noise control]
```

Always include **noise controls** — writes that should *not* fire. A probe showing only positives cannot tell you whether the mechanism is selective or simply always on.

Verify the *real* caller uses the path you tested. A watch on `post_save` is worthless if production writes via `QuerySet.update()`.

### 3. Timeline probe — capture across a boundary

For "the data is correct but the output is wrong". Capture in order: pre-state → the request → service logs since a timestamp → intermediate queues → what reached the external boundary → post-state.

Clear the journal and any debounce/cache immediately before triggering, so the run is observed in isolation.

### 4. Semantics probe — does this query mean what it reads like?

For ORM/query defects. Construct the minimal data shape and ask the system's own function for its answer. Print the resolved SQL when the answer surprises you.

This is the probe that catches the bugs code review cannot: a query whose plain-English reading and actual semantics differ.

## Procedure

1. **Write the hypothesis down.** "I think X because Y. If X, then probe P shows Z."
2. **Build the state probe first.** Often it alone names the stage.
3. **Establish a baseline.** Reset to the unmodified branch and probe. If the defect does not reproduce on the baseline, the hypothesis is already wrong — stop and re-read.
4. **Toggle one variable.** Re-probe. Record both results side by side.
5. **Run the control** — revert, re-probe, confirm the defect returns.
6. **Report the matrix**, including configurations that did *not* reproduce.

## Reporting

```
### Probe — {hypothesis}
Subject:    {account/entity/ids under test}
Baseline:   {ref/branch, and confirmation the fixes under test are absent}
Falsifier:  {what would have disproved this}

| Configuration | Observation | Verdict |
|---|---|---|
| {baseline}    | {measured}  | reproduces / does not |
| {one change}  | {measured}  | reproduces / does not |

Conclusion: {failing stage, or "not reproduced — hypothesis rejected"}
Not covered: {configurations not tried}
```

Report non-reproductions as prominently as reproductions. "Your described path is correct on master" is a result, and often the most valuable one.

## When This Fails

| Failure | Recovery |
|---|---|
| Probe cannot reach the subject | Check stack health before doubting the hypothesis. A restarted container may have lost a nested bind mount while still serving traffic — `docker exec` breaks while HTTP keeps working. |
| Probe output contradicts the service log | Trust the log. The product did what the log says; the probe is reading the wrong thing. |
| Probe passes alone, fails in a suite | Shared subject across runs. Give each case its own account/entity id rather than tuning waits. |
| Async result read before it lands | Poll for a condition, never sleep a fixed time. Prefer a monotonic field in the payload over arrival order — journal ordering is not a contract. |
| Everything measures correct, defect persists | The failing stage is outside the probed boundary. Extend the probe outward one stage, do not re-probe the same span harder. |
| Three hypotheses rejected | Stop probing. The premise is likely wrong — re-read the original report for an assumption nobody has checked. |

## Where the workspace's own gotchas go

Every codebase has two or three traps that cost an afternoon each: a shell that
runs snippets under split globals, an audit hook that fires on delete, a signal
that connects lazily on first instantiation. They are worth writing down and
they do not belong here.

Write them into the workspace's own agent config, which outranks this protocol
anyway (tier 1). A trap recorded in the hub is a trap the hub asserts about
every other workspace it serves, and it will be wrong about most of them.
