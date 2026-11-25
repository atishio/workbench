# Grounding Protocol

**What**: Every claim the workbench makes carries where it came from.

**Why**: An unlabelled claim reads as measured. That is how an inference
becomes a finding, a finding becomes an RCA, and an afternoon goes to a cause
nobody ever observed — `ai-failure-modes.md` F2.

## The labels

| Source | Meaning | Trust |
|---|---|---|
| `observed` | From the running system — command output, log line, network response, console, screenshot, file content at a cited `file:line` | High |
| `confirmed` | Proposed by the agent, explicitly approved by the human | High |
| `inferred` | Derived by the agent from reading code or docs, not measured and not reviewed | **Low — must be flagged** |

A fourth exists and is worth naming because it hides: `assumed` — believed
without either reading or measuring. Treat it as `inferred` and say so.

## MUST rules

- MUST label every causal claim. Never promote `inferred` to a finding without
  measuring it.
- MUST cite the evidence for `observed` — the command, the file and line, or
  the response. "I checked" is not a citation.
- MUST report what was *not* covered alongside what was.
- MUST NOT report success for a check that could not run. A missing tool, a
  service that is down, or an absent test produces **unknown**, never **fine**.

## Where it applies

| Context | What carries a label |
|---|---|
| `init.md` | every scanned candidate value, before the human confirms it |
| `dev-loop.md` | the verify line of each iteration report |
| `probe.md` | every hypothesis and every verdict |
| `review.md` | every finding |
| `stub-and-capture.md` | the capture context document |
| `verify/*` | the observation, and explicitly its absence |

## The init case

`init.md` is the strictest consumer. A value tagged `inferred` **cannot be
written to `workbench.yaml` by confirming a block** — it needs its own answer
from the human. That single rule is what makes init human-driven rather than
human-reviewed, and it only works because the label is attached at scan time,
before anyone has decided anything.

## When this fails

| Failure | Recovery |
|---|---|
| A claim cannot be traced to a source | It is `inferred`. Label it, or measure it. |
| The evidence is a previous answer of your own | Re-derive from the system. Confirmation bias compounds across turns. |
| Everything is labelled `observed` | Suspect the labelling, not the luck. Inference is normal; unlabelled inference is the problem. |
