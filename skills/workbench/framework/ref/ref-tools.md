# Tool Reference

What the workbench expects from the tools a harness exposes, named by
**capability** rather than by vendor. A harness supplies these however it
likes — built-in tools, MCP servers, shell commands, or not at all.

Read `SETUP.md` for how a harness wires them. Read this for how protocols
use them.

## Capabilities

| Capability | Used by | If absent |
|---|---|---|
| **File read / write** | everything | the package cannot run — see `SETUP.md` reduced mode |
| **Shell** | `dev-loop.md`, `verify/*`, stack commands | verification is limited to reading files; report commands as un-run |
| **Browser driver** | `verify/app-ui.md`, `stub-and-capture.md` | UI unverified — say so, never infer |
| **HTTP client** | `stub-and-capture.md` mock admin calls | mocks cannot be registered or read; capture unavailable |
| **Issue tracker** | workspace `tracker_project` lookups | work without ticket context; do not invent ticket state |
| **Wiki / doc source** | `verify/docs-review.md` | review local docs only; report external source as unchecked |
| **Log reader** | `probe.md`, `verify/app-be.md` | read logs via shell instead; if neither, a defect cannot be attributed to a layer |

## Division of labour

- **The agent drives reads.** Browsing, fetching a ticket, reading a page,
  listing network requests, tailing a log. These need no permission ceremony —
  do them.
- **The human drives writes and auth.** Interactive logins, credentials,
  writes to shared systems, and anything whose blast radius leaves this
  machine. Ask, and say what you intend to write.

That split is not about capability. It is about who is accountable for the
consequence.

## Grounding

A capability that is absent produces *unknown*, never *fine*. Every protocol
that depends on a tool states what it reports when the tool is missing, and
`grounding.md` governs how that is labelled.
