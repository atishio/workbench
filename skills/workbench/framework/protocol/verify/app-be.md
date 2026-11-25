# Verify: App (Backend Mode)

Inherits: `common.md`

**Outcome**: Changed code passes relevant tests, API contracts hold, endpoint responds correctly.

## Additional Rules

- MUST run tests scoped to the changed area, not the full suite (unless user requests).

## Additional Signals

- Tests for the changed area pass
- API endpoint responds with expected status and shape (if applicable)
- No contract violations against documented API specs
