# AI Failure Modes Protocol

**What**: The recurring ways agent-assisted development goes wrong, the tell for each, and the guard that prevents it.

**Why**: These failures are not random. They cluster, they are individually plausible in the moment, and they are expensive because the output *looks* finished — a formal RCA, a green test, a clean diff. Each entry below cost real time on a real ticket.

**When**: Read before a long investigation or a multi-workspace change. Re-read when a session has gone sideways and you cannot say why.

## Outcomes

- Claims carry their source: `observed`, `confirmed` or `inferred` — `grounding.md`
- Defects are attributed to the right layer — product, harness, or environment
- Shared infrastructure gets fixed, not worked around
- The human is told what was *not* covered, not just what was

## MUST Rules

- MUST label every causal claim `observed` (measured), `confirmed` (approved by the human), or `inferred` (read from code, not measured). A claim believed without either reading or measuring is `inferred` too — say so. The labels are defined once, in `grounding.md`; do not grow a second set here.
- MUST reproduce the **reported** configuration before writing an RCA. Reproducing *a* symptom is not reproducing *the* defect.
- MUST read the service log before reporting a product defect. If the log shows the product behaved correctly, the defect is in the harness.
- MUST fix shared infrastructure at the layer that is wrong, never work around it in the caller.
- MUST report what was not covered alongside what was.
- MUST NOT bundle a fix into an investigation step. Probe → verdict → then `dev-loop.md`.

## The Failure Modes

### F1 — Reproducing a symptom the real system never produces

The most expensive one. You pick input values that force the reported symptom, get a match, and write the RCA off it — but production never takes that path.

**Tell**: you *chose* a value specifically to make the symptom appear.

**Guard**: reproduce the reported configuration first, using the real entry point. If you cannot make it fail, that is the finding — say "your described path is correct on this baseline" and keep looking. A non-reproduction is a result, not a dead end.

### F2 — Inference dressed as a finding

A formal RCA with headings and tables reads as measured even when every line came from reading code.

**Tell**: the document exists before the measurement does.

**Guard**: write the hypothesis and its falsifier first (`probe.md`). If a claim is unmeasured, label it a candidate.

### F3 — Blaming the product for a harness bug

**Tell**: the test is red but the service log shows the correct behaviour.

**Guard**: check the service log before touching product code. Two red tests in one session were both the harness — one shared a subject between cases, one depended on journal ordering that is not a contract.

### F4 — Dismissing prior art on partial evidence

Setting aside an existing PR or branch because it does not match your current hypothesis.

**Tell**: "that change is unrelated" justified by one artifact.

**Guard**: explain *why the author wrote it* before setting it aside. A declined PR usually encodes a real observation even when its fix is wrong.

### F5 — Environment drift read as code behaviour

**Tell**: it worked earlier, the code has not changed, and the failure is structural rather than logical.

**Guard**: verify the environment before debugging logic. Seen in practice: a nested bind mount silently detached — HTTP kept serving from the already-loaded process while `docker exec` broke; and a mock accumulating duplicate identities across re-seeds so the first match shadowed the real one, surfacing as an unrelated `KeyError`.

### F6 — Shared mutable subject

**Tell**: passes alone, fails in a suite; or a rerun behaves differently from the first run.

**Guard**: give each case its own account/entity id. Do not tune sleeps to dodge it. Clear caches, queues and journals immediately before the trigger, not after.

### F7 — Working around broken shared infrastructure

**Tell**: "I'll just serialise it myself here."

**Guard**: fix it in the shared component. Seen in practice: a shared serialisation helper treated only `dict` as JSON, so every list response shipped as a language-native repr — valid-looking in the admin UI, unparseable by the caller. Patching the one call site would have left the trap for the next person.

### F8 — Silent success on the wrong shape

**Tell**: the config looks right in a UI, and the consumer still fails.

**Guard**: assert on the wire, not the configuration. Curl the endpoint from inside the consuming container.

### F9 — Reinventing a mechanism that already exists

**Tell**: you are writing a helper that feels like it should be standard.

**Guard**: grep `./framework/protocol/`, the workspace's own agent config, and its guides before building. Probes, capture, stubs and test scaffolding all already have homes.

### F10 — Fixing while investigating

**Tell**: you changed code during a diagnostic step.

**Guard**: a fix mid-probe destroys the baseline you are measuring against. Finish the probe, state the verdict, then fix.

### F11 — Silent scope expansion

Touching files outside the ask because they are nearby and wrong.

**Tell**: the diff spans a workspace nobody mentioned.

**Guard**: fixing a genuine blocker is fine — **name it explicitly in the report** and keep it minimal. Never quietly reshape unrelated code.

### F12 — Accumulating unverified changes

**Tell**: several edits and no run between them.

**Guard**: `dev-loop.md` — verify after each change. When unsure whether to split, split.

### F13 — Green health checks on an unprovisioned stack

**Tell**: every service reports healthy and the app is still empty or unusable.

**Guard**: health checks test liveness — a port answering, an HTTP 200 — not provisioning. A stack that was brought up by hand, or whose setup command died partway, passes them while missing the seed data that makes it work. Assert on domain state, not status output: does the account exist, does the user list contain the login you are about to use, does the entity list return rows. Seen in practice: stepping around a stack's own setup command to dodge an image rebuild skipped bootstrap, patching and mock seeding — so every health check was green against a stack with no users and no data.

**Corollary**: when you deliberately step around an orchestration command, enumerate what it would have done and run each step yourself. The steps you cannot see are the ones that bite.

## Session Hygiene

- State-mutating setup is reversible, and the revert is written **before** the mutation
- Scratch work goes to `probe.probe_dir`, never into a workspace source tree
- Branches created to protect work are reported, not silently left behind
- Before handing back, confirm the stack is in the state the human expects

## When This Fails

| Failure | Recovery |
|---|---|
| Three hypotheses rejected | Stop. Re-read the original report for an assumption nobody has checked — including one of yours. |
| The human repeats a correction | Their model of the system is better than yours. Test their framing directly rather than defending the previous conclusion. |
| "Are you sure?" on a finished answer | Re-derive from evidence, not from the previous answer. Confirmation bias compounds across turns. |
| Session produced heat but no verdict | Write down what *was* eliminated. Narrowing is progress; report it as such. |
