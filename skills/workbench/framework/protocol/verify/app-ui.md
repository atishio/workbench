# Verify: App (UI Mode)

Inherits: `common.md`

**Outcome**: Component renders without errors, browser console is clean, design system compliance passes (if applicable).

## Additional Rules

- MUST confirm browser console has no errors after every UI change — silent JS errors corrupt state or break downstream flows.
- MUST use hostnames from workbench.yaml, never hardcode localhost.

## Additional Signals

- Component renders in browser (accessibility snapshot or screenshot confirms)
- No critical console errors (`TypeError`, `ReferenceError` are blockers; HMR messages are noise)
- Design system compliance passes (if workspace has `design_system` configured)

## Browser Reference

For the operations this protocol needs, and what to report when one is absent,
see `../../ref/ref-browser.md`. If no browser driver exists, report "UI
unverified — no browser driver" rather than inferring success.
