# Browser Driver Reference

Reference for driving a browser during verification and capture. Used by
`../protocol/verify/app-ui.md` and `../protocol/stub-and-capture.md`.

This file names **operations**, not a vendor. Any driver that provides them
works. The appendix maps them onto one concrete implementation.

## Required operations

A harness must offer these for `verify/app-ui.md` to run:

| Operation | Purpose |
|---|---|
| navigate | Go to a URL |
| snapshot | Structured accessibility tree of the current page |
| console read | Console output, filterable by level |

## Strongly preferred

Without these, verification still runs but produces weaker evidence:

| Operation | Purpose |
|---|---|
| network list | Every request since page load |
| network detail | Headers and body of one request |
| screenshot | Pixel capture — for visual defects, not assertions |
| find | Search the snapshot for text or a pattern |
| wait for | Block until expected text appears or disappears |

## Interaction

Needed to drive a feature rather than only observe it:

| Operation | Purpose |
|---|---|
| click · type · fill form · select option | Form and control interaction |
| hover · press key · drag | Pointer and keyboard events |
| file upload | Attach files to an input |
| tabs | List, open, close, switch |

## Practice

- **Prefer snapshot over screenshot for assertions.** A snapshot is structured
  and stable; a screenshot asserts pixels, which change for reasons that are
  not defects. Screenshot when the defect *is* visual.
- **Find before interacting.** Locating an element beats reading a whole
  snapshot, and it fails loudly when the element is absent.
- **Classify console output.** `TypeError` and `ReferenceError` are blockers.
  Hot-reload chatter and favicon 404s are noise. Network errors mean check the
  stubs before you touch product code.
- **Wait on content, not on time.** After navigating, wait for expected text.
  A fixed sleep either wastes time or hides a race — usually both, on
  different runs.

## When an operation is missing

| Missing | Consequence |
|---|---|
| snapshot | `verify/app-ui.md` cannot run. Report "UI unverified — no browser driver" rather than inferring success |
| console read | Report console state as unknown. Do not claim "no errors" |
| network list | Capture falls back to the mock journal alone. Note that client-side calls were not observed |
| interaction | Observation-only. A feature that needs driving cannot be verified this way |

Grounding applies here as everywhere: if verification could not be performed,
say so. See `../protocol/grounding.md`.

---

## Appendix — Playwright MCP

One implementation of the operations above. Tool names as exposed by the
Playwright MCP server.

| Operation | Tool |
|---|---|
| navigate | `browser_navigate` |
| snapshot | `browser_snapshot` |
| screenshot | `browser_take_screenshot` |
| find | `browser_find` |
| console read | `browser_console_messages` |
| wait for | `browser_wait_for` |
| network list | `browser_network_requests` |
| network detail | `browser_network_request` |
| click | `browser_click` |
| type | `browser_type` |
| fill form | `browser_fill_form` |
| select option | `browser_select_option` |
| hover | `browser_hover` |
| press key | `browser_press_key` |
| file upload | `browser_file_upload` |
| drag | `browser_drag` |
| tabs | `browser_tabs` |

*Last verified: 2026-09-24.*
