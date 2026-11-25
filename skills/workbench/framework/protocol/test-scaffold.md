# Test Scaffold Protocol

**What**: Transform captured network flows into executable test code. Tests are built stubs-first — assertions added by user after manual testing.

**Why**: Generating assertions before manual verification produces false confidence. Stubs-first means infrastructure is ready; the human adds the truth.

## Outcomes

- Test file created with correct imports, fixtures, and stub setup
- Stubs wired from captured flows (not invented)
- Assertion placeholders marked for human completion

## MUST Rules

- MUST use `roles.qa.venv` if specified in `workbench.yaml`.
- MUST resolve every location from `roles.qa.layout` — never by searching the workspace for one.
- MUST build stubs from captured flows, not invented shapes.
- MUST NOT generate assertions — mark as `# TODO: add assertion after manual verification`.

## Inputs

- Capture context document (from stub-and-capture)
- `roles.qa.layout` from `workbench.yaml` — where test support lives
- Workspace test conventions (from its own agent config or test guides)

### Using `roles.qa.layout`

| Slot | How this protocol uses it |
|---|---|
| `helpers` | import shared utilities from here. Do not re-implement what it already exports |
| `fixtures` | the shared fixture module the new test inherits from |
| `suites` | place the new test under one of these roots. Ask which when there is more than one |
| `selectors` | register the new test's marker/tag here, or it will not be selectable by the runner |
| `reports` | where a run's output lands — cite it when reporting, do not write into it |
| `guides` | read before scaffolding; the workspace's own conventions outrank this protocol |

**Do not go looking for these.** Searching a workspace for "the conftest" is
how a scaffolded test ends up importing a shim-adapter's fixtures instead of
the shared ones — and it passes, which is why nobody notices. If a slot is
absent from `layout`, say so and ask; an absent slot is a configuration gap,
not an invitation to guess.

## When a slot is missing

| Missing | Do this |
|---|---|
| `layout` entirely | Stop. Report: "qa.layout not configured — repair section 2?" |
| `helpers` or `fixtures` | Scaffold without shared imports and say so in the report |
| `suites` | Ask where the test goes. Do not pick a directory |
| `selectors` | Scaffold the test, flag that its marker is unregistered and will not run |

## When This Fails

| Failure | Recovery |
|---|---|
| No capture context document | Run stub-and-capture first. |
| `roles.qa.venv` missing | Ask the user to create or fix the venv before scaffolding. |
| No existing test patterns | Use runner defaults (pytest for Python, Jest/Vitest for JS/TS) and say that is what you did. |
