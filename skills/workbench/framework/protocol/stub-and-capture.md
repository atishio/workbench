# Stub & Capture Protocol

**What**: Configure mock infrastructure and capture network flows for test evidence. Bridges "feature works in the browser" to "we have test data proving it."

**Why**: Without captured flows, test authors write assertions against imagined request/response shapes. Capture-first testing eliminates shape mismatches.

**Requires**: a `mock` section in `workbench.yaml`, with `mock.type` set.

## Outcomes

- Stubs registered and verified in mock infrastructure
- Network flows captured — mock journal, and the browser network log where a driver exists
- Capture context document produced for handoff to test scaffold

## MUST Rules

- MUST clear the mock journal before each capture session — stale entries contaminate the capture.
- MUST verify stubs are registered before navigating to the feature.
- MUST use URLs from `workbench.yaml` `mock` section, never hardcode.
- MUST NOT guess the mock implementation. If `mock.type` is unset, stop and report: "Mock type not configured — run repair on the mocks section." Guessing an admin API produces 404s that read as "the stub did not register."

## Operations

Every adapter provides the same four operations against `mock.admin_url`:

| Operation | Why it matters |
|---|---|
| **Clear journal** | A capture is only evidence if it starts empty |
| **Register stub** | Put the upstream under your control |
| **List stubs** | Confirm registration before navigating — not after failing |
| **Read journal** | The capture itself |

If `mock.base_url` names a higher-level toolkit, prefer it for registration —
it usually encodes project conventions the raw admin API does not.

## Capture Workflows

- **API-only**: Navigate directly to the API. Best for pure API flows.
- **UI-driven**: Navigate via the app UI. Best for user-facing flows where the UI drives API calls.
- **Mixed**: UI navigation plus inspection of the resulting API calls. Best when both rendering and wire shape matter.

## Capture-Complete Checklist

- [ ] Journal contains the expected request/response pairs
- [ ] No unexpected upstream calls leaked through
- [ ] Browser network log, where captured, shows matching client-side calls
- [ ] Capture context document produced using `../templates/capture-context.md`

## When This Fails

| Failure | Recovery |
|---|---|
| `mock.type` unset | Stop. Repair the mocks section of `workbench.yaml`. Do not probe admin APIs to find out which one it is. |
| Mock admin URL unreachable | Check stack health. Start the plane that hosts the mock, per `stack.cli_map`. |
| Stubs register but the feature still hits the real upstream | Name resolution. The consuming process must resolve the upstream hostname to the mock — check from *inside* that process, not from the host. |
| Journal empty after navigation | The app may be caching, or calling a different endpoint than assumed. Check the browser network log for the URLs actually requested. |
| Journal has entries from a previous run | The clear step did not run or did not apply. Re-clear and re-capture; do not filter a dirty journal by eye. |

---

## Appendix — Adapters

Concrete mappings for `mock.type`. All paths are relative to `mock.admin_url`.

### `wiremock`

| Operation | Method | Path |
|---|---|---|
| Clear journal | `DELETE` | `/requests` |
| Register stub | `POST` | `/mappings` |
| List stubs | `GET` | `/mappings` |
| Read journal | `GET` | `/requests` |

### `mockserver`

| Operation | Method | Path |
|---|---|---|
| Clear journal | `PUT` | `/mockserver/clear` |
| Register stub | `PUT` | `/mockserver/expectation` |
| Read journal | `PUT` | `/mockserver/retrieve?type=REQUESTS` |
| List stubs | `PUT` | `/mockserver/retrieve?type=ACTIVE_EXPECTATIONS` |

### `prism`

Prism serves from an OpenAPI document rather than registered stubs. Registration
is editing the document and restarting; journal is the process log. Where the
contract is the source of truth this is a feature, not a limitation — but
capture yields less than with a journal-backed mock.

### Other

Add an adapter here and set `mock.type` to its name. Four operations is the
whole contract.

*Last verified: 2026-09-24.*
