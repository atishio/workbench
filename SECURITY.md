# Security

This package is documentation. It ships no executable code, no dependencies and
no network calls — the only script in the repository is `scripts/invariants.sh`,
a maintainer tool that runs `grep` over the package and is not installed into
anything.

So the usual vulnerability classes do not apply. Two things do.

## 1. A leaked identifier

**This is the one that matters, and it is the one to report.**

The package is portable because it carries no project facts. If you find
anything in it that came out of a real codebase — a class, a service, a
hostname, a CLI subcommand, a product or company name, a ticket reference —
that is a defect in the package's central claim, and it may be someone's
confidential information sitting in a public repository.

It has happened. While this package was still private, the debugging protocol
described, by name, how a particular audit middleware reconnected its signal
handlers, under a heading that announced it as repo-specific. Every invariant
run passed, because the check that was supposed to catch it held its own
deny-list inline and could only ever match itself. It was found and removed
before the first public release — by reading the file, not by running the
check.

**Report it privately**, via
[GitHub's private vulnerability reporting](https://github.com/atishio/workbench/security/advisories/new)
on this repository — not in a public issue, which republishes the thing you are
reporting. Say which file and line; you do not need to prove where it came from.

These are fixed by removing the identifier and re-cutting the example against
the fictional project in `framework/templates/workbench.yaml.example`. The
lesson in a war story is worth keeping; the nouns never are.

## 2. A secret in an instance

`.workbench/workbench.yaml` is generated in *your* repository and committed
there. By design it records environment variable **names and purposes, never
values** — `init.md` says so, and so does the annotated example.

If you find the package instructing anyone to capture a value, report it the
same way. A secret in `workbench.yaml` is a secret in version control.

If a secret of yours has already been committed that way, treat it as disclosed:
rotate it first, then clean the history. Rotation is the fix; history rewriting
is cleanup.

## Scope

| | |
|---|---|
| **In scope** | A real identifier from any codebase, in this repository. The package instructing anyone to record a secret value. A protocol that would cause an agent to exfiltrate credentials or write outside the directories it declares |
| **Out of scope** | Vulnerabilities in the agent harness running the package, in the `skills` CLI, or in any MCP server `SETUP.md` mentions. Report those to their own projects |

## Response

This is a one-person project, so there is no response-time commitment worth
making. Expect acknowledgement within a week. A leaked identifier will be
removed and released ahead of anything else in the queue.

## Supported versions

The current minor release only. This project is pre-2.0 and carries no
backports.
