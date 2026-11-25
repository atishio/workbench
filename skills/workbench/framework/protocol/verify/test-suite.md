# Verify: Test Suite

Inherits: `common.md`

**Outcome**: New/modified tests execute, individual results reported, coverage delta known.

## Additional Rules

- MUST use workspace venv if specified in workbench.yaml — wrong venv silently uses different package versions.
- MUST report individual test results with name and pass/fail, not just aggregate counts.

## Additional Signals

- Each test individually reported with pass/fail
- New tests execute without import or fixture errors
- Coverage delta reported (if tooling available)
