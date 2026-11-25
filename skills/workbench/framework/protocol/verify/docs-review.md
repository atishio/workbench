# Verify: Documentation Review

Inherits: `common.md`

**Outcome**: Statements verified against authoritative sources, gaps and stale content identified.

**Requires**: `docs_review` section in workbench.yaml with `source` and `local_docs`.

## Additional Rules

- MUST cross-reference against both external source AND local architecture docs.
- MUST never fabricate external page content — always fetch live via configured source.

## Verdict per statement

| Status | Meaning |
|---|---|
| Confirmed | Matches both external source and local docs |
| Gap | Not covered in external source or local docs |
| Stale | Contradicted by current architecture or external source |
| Needs SME | Cannot verify from available sources |

## Degradation

- No external source configured → verify local-only, note the limitation
- Neither source available → abort doc review, note in report
