# Verify: CI/CD Workflows

Inherits: `common.md`

**Outcome**: Workflow YAML is valid, no security anti-patterns.

## Additional Rules

- MUST check for hardcoded secrets, unpinned action versions, missing permissions — CI runs with elevated privileges.

## Additional Signals

- YAML parses without syntax errors
- No string literals that look like secrets
- Action references use pinned versions (SHA or tag), not `@main`/`@latest`
- Required permissions declared explicitly
