# Verify: Documentation

Inherits: `common.md`

**Outcome**: Documentation builds successfully, renders correctly, internal links resolve.

## Additional Rules

- MUST execute the workspace's build command (from workbench.yaml `start_cmd`) before declaring docs verified — link resolution and macro expansion only validate at build time.

## Additional Signals

- Build exits 0 with no errors
- No broken internal links reported
- Changed pages render correctly (spot-check structure)
