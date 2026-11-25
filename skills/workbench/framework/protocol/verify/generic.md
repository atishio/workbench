# Verify: Generic (Fallback)

Inherits: `common.md`

**Applies when**: Workspace type has no specific verify protocol. This is a safety net, not a destination — a workspace landing here is usually mistyped, and `type` decides verification for the life of the config. Repair section 1 of `workbench.yaml` rather than accepting the fallback.

**Outcome**: Changed files are syntactically valid, no obvious regressions. Uses only the universal signals and failures from `common.md`.
