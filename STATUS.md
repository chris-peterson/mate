# mate spec coverage status

Tracking status of the requirements declared in [`SPEC.md`](SPEC.md).
Maintained by `/sextant:spec-status`.

**Last audit:** 2026-09-29
**Spec version:** unversioned
**Plugin version:** 0.1.0
**Coverage:** 27 Covered, 2 Partial, 1 Missing/Contradicts

## Status by category

| Prefix | Count | Status | Notes |
|--------|------:|--------|-------|
| HOOK-01..05 | 5 | 4 Covered, 1 Contradicts | `hooks/nudge.sh`, `hooks/react.sh` (`announced`). HOOK-03: see Open / Needs Decision |
| NUDGE-01..12 | 12 | 11 Covered, 1 Partial | `hooks/nudge.sh` (the `case` on `$skill`); `scripts/tests/nudge.test.sh`. NUDGE-04: the URL is read from `.prompt` only, so an agent-invoked `/tack:start` names "the linked issue" |
| REACT-01..07 | 7 | All Covered | `hooks/react.sh` (`announced`, `claim`); `scripts/tests/react.test.sh` |
| SKILL-01..06 | 6 | 5 Covered, 1 Partial | `skills/fix/SKILL.md`, `skills/feature/SKILL.md`. SKILL-02: only `guides/composing-with-siblings.md` says what replaces anchor, and neither skill names anchor or links the guide |

## Open / Needs Decision

- **HOOK-03.** The spec says the hooks use only bash and `jq` until a payload
  matches. `hooks/react.sh` (`announced`) runs `grep`, `head`, and `sed` over
  every Bash call's stdout before any key has matched. No network call is made.
  Pending a decision: reword HOOK-03 to allow coreutils, or move the key match
  into `jq`.

## How to use this file

When you implement a new requirement, change the row's status and add an
evidence pointer. When an audit reveals drift, update the row to **Partial**
or **Contradicts** with a one-line note.

Evidence pointers are the file plus its enclosing symbol by default. To use a
different granularity, add `**Evidence pointers:** line` (or `anchor`, `file`,
`directory`) to the metadata block above.
