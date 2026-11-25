# Verify: Common Patterns

Shared verification patterns inherited by all type-specific verify protocols.

## Universal Signals

- Changed files parse/compile without syntax errors
- If tests exist for the changed area, they still pass
- No obviously broken imports or references introduced

## Universal Failures

| Failure | Recovery |
|---|---|
| Workspace path doesn't exist | Re-run orient. Path may have moved since last configure. |
| Service not running | Report which service. Suggest `start_cmd` from workbench.yaml. Do not code against a down stack. |
| No tests cover the changed area | Note: "No tests — change is unverified." Suggest test-scaffold. |
| Cannot determine file language | Skip syntax check for that file. |

## Grounding Rule

Verification reports must cite what was actually observed (test output, console log, screenshot, network response) — not what the AI expects to see. If verification cannot be performed (no browser, no tests, service down), say so explicitly rather than inferring success.
