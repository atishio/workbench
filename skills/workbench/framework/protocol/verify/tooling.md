# Verify: Tooling

Inherits: `common.md`

**Outcome**: Script executes without error, output is correct.

## Additional Rules

- MUST verify using non-destructive inputs (help flags, dry-run modes, test data) — never production data or live endpoints.

## Additional Signals

- Script runs with `--help` or dry-run flag without errors
- Output format matches expectations
- Exit code is 0 for success cases
