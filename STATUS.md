# mate spec coverage status

Tracking status of the requirements declared in [`SPEC.md`](SPEC.md).
Maintained by `/sextant:spec-status`.

**Last audit:** 2026-10-22
**Spec version:** unversioned
**Plugin version:** 0.2.1
**Coverage:** 19 Covered, 0 Partial, 1 Missing/Contradicts

## Status by category

| Prefix | Count | Status | Notes |
|--------|------:|--------|-------|
| HOOK-01..06 | 4 | 3 Covered, 1 Contradicts | `hooks/react.sh`; `scripts/tests/react.test.sh`. No HOOK-04 or HOOK-05. HOOK-03: see Open / Needs Decision |
| SKILL-01..08 | 7 | All Covered | `skills/fix/SKILL.md`, `skills/feature/SKILL.md`. No SKILL-02 |
| REACT-01..09 | 9 | All Covered | `hooks/react.sh` (`announced`, `claim`); `scripts/tests/react.test.sh` |

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

STATUS.md updated: 41 → 20 IDs (+SKILL-08; NUDGE, NEXT and TRACK retired with the hooks and skill that carried them, along with HOOK-04..05).

### 2026-10-22: Coverage refresh (spec-status)

STATUS.md updated: 30 → 41 IDs (+HOOK-06, SKILL-07, NEXT-01..03, NUDGE-13..14, REACT-08..09, TRACK-01..04, TRACK-06; NUDGE-03..04 and SKILL-02 retired), 2 Partial → retired, version 0.1.0 → 0.2.1.
