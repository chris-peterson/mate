# mate spec coverage status

Tracking status of the requirements declared in [`SPEC.md`](SPEC.md).
Maintained by `/sextant:spec-status`.

**Last audit:** 2026-10-22
**Spec version:** unversioned
**Plugin version:** 0.2.1
**Coverage:** 40 Covered, 0 Partial, 1 Missing/Contradicts

## Status by category

| Prefix | Count | Status | Notes |
|--------|------:|--------|-------|
| HOOK-01..06 | 6 | 5 Covered, 1 Contradicts | `hooks/nudge.sh`, `hooks/react.sh` (`announced`), `hooks/underway.sh`. HOOK-03: see Open / Needs Decision |
| NUDGE-01..14 | 12 | All Covered | `hooks/nudge.sh` (`nudge_for`); `scripts/tests/nudge.test.sh`. No NUDGE-03 or NUDGE-04: the `/tack:start` line moved to REACT-08 |
| REACT-01..09 | 9 | All Covered | `hooks/react.sh` (`announced`, `claim`); `scripts/tests/react.test.sh` |
| SKILL-01..07 | 6 | All Covered | `skills/fix/SKILL.md`, `skills/feature/SKILL.md`. No SKILL-02 |
| NEXT-01..03 | 3 | All Covered | `skills/next/SKILL.md` |
| TRACK-01..06 | 5 | All Covered | `hooks/react.sh` (`tack_heard`), `hooks/underway.sh`; `scripts/tests/underway.test.sh`, `scripts/tests/react.test.sh`. No TRACK-05 |

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

## Audit history

### 2026-10-22: Coverage refresh (spec-status)

STATUS.md updated: 30 → 41 IDs (+HOOK-06, SKILL-07, NEXT-01..03, NUDGE-13..14, REACT-08..09, TRACK-01..04, TRACK-06; NUDGE-03..04 and SKILL-02 retired), 2 Partial → retired, version 0.1.0 → 0.2.1.
