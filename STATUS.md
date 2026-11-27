# mate spec coverage status

Tracking status of the requirements declared in [`SPEC.md`](SPEC.md).
Maintained by `/sextant:spec-status`.

**Last audit:** 2026-11-27
**Spec version:** unversioned
**Plugin version:** 0.2.1
**Coverage:** 21 Covered, 0 Partial, 0 Missing/Contradicts

## Status by category

| Prefix | Count | Status | Notes |
|--------|------:|--------|-------|
| HOOK-01..06 | 4 | All Covered | `hooks/react.sh`; `scripts/tests/react.test.sh`. No HOOK-04 or HOOK-05. HOOK-03: `announced` matches in `jq` alone and reads the git config switch only after a key matched |
| SKILL-01..09 | 8 | All Covered | `skills/fix/SKILL.md`, `skills/feature/SKILL.md`. No SKILL-02. SKILL-09: `skills/fix/SKILL.md` Phase 4, step 1 |
| REACT-01..09 | 9 | All Covered | `hooks/react.sh` (`announced`, `claim`); `scripts/tests/react.test.sh`. REACT-01 now cites the suite contract: an object body (`announced`), string fields stripped of control characters (`field`), the switches (`subscribed`) and the line that names each (`say`), with tests for each near-miss, a 300 KB stdout, and the switches |

## How to use this file

When you implement a new requirement, change the row's status and add an
evidence pointer. When an audit reveals drift, update the row to **Partial**
or **Contradicts** with a one-line note.

Evidence pointers are the file plus its enclosing symbol by default. To use a
different granularity, add `**Evidence pointers:** line` (or `anchor`, `file`,
`directory`) to the metadata block above.

## Audit history

### 2026-11-27: Coverage refresh (spec-status)

+SKILL-09: `/mate:fix` diagnoses a failure the base shares, comparing failing
tests rather than pipeline status. 20 → 21 Covered.

### 2026-11-15: Coverage refresh (spec-status)

REACT-01 reworded to cite the bridge.ai suite contract rather than restate one
rule of it. Auditing against that contract found `cr.ready` reacting to a body
that wasn't JSON, announced values reaching the agent with control characters
in them, and no way to turn a reaction off; all three are fixed. Moving the key
match into `jq` resolved HOOK-03, which closes the open question. 19 → 20
Covered.

### 2026-10-22: Coverage refresh (spec-status)

STATUS.md updated: 41 → 20 IDs (+SKILL-08; NUDGE, NEXT and TRACK retired with the hooks and skill that carried them, along with HOOK-04..05).

### 2026-10-22: Coverage refresh (spec-status)

STATUS.md updated: 30 → 41 IDs (+HOOK-06, SKILL-07, NEXT-01..03, NUDGE-13..14, REACT-08..09, TRACK-01..04, TRACK-06; NUDGE-03..04 and SKILL-02 retired), 2 Partial → retired, version 0.1.0 → 0.2.1.
