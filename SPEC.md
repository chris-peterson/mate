# mate specification

mate carries the playbooks for a defect and a capability, starts the one that
fits when tack opens work on an issue, and names the step after anchor's push
and draft flag. It acts only where the command the user ran already says what
they want.

Requirements use [EARS syntax](https://alistairmavin.com/ears). Each is one of:
Ubiquitous (`The <system> shall …`), State-Driven (`While …`), Event-Driven
(`When …`), Optional (`Where …`), or Unwanted Behaviour (`If … then …`).

Each requirement is its own heading carrying a stable ID (`XX-NN`), one level
below its category's heading, so every requirement has a linkable anchor
(`SPEC.md#xx-nn`). Lettered decompositions (`XX-NNa`) each count as one.

## Concepts

- **Announcement**: one line a sibling plugin prints on a command's stdout,
  `codes.bridgeai.<plugin>/<key> {json}`, per the suite's interop contract.
- **The envelope**: what `/tack:start` opens and `/tack:end` closes: the linked
  thread read in full, a slug, a branch, and the tack route.
- **Sizable work**: work that spans more than one deliverable or more than one
  session, and so needs a record that outlives the session.

## Requirements

### `HOOK`
Shared hook behavior

#### `HOOK-01`
If a hook's payload matches none of its cases, then the hook shall print nothing
and exit 0.

#### `HOOK-02`
If a hook's payload is not valid JSON, then the hook shall print nothing and
exit 0.

#### `HOOK-03`
While deciding whether a payload is for mate, the hooks shall use only bash and
`jq`, with no network call.

#### `HOOK-06`
When a hook prints a line from a `PostToolUse` event, it shall print it as
`hookSpecificOutput.additionalContext` JSON, the only `PostToolUse` output that
reaches the agent.

### `SKILL`
The fix and feature skills

#### `SKILL-01`
Where the work is sizable and no route resolves, each skill shall invoke
`/tack:start` with the work the user named; otherwise it shall start without
opening a route.

#### `SKILL-03`
`/mate:fix` shall prove the fix with a check that fails before it and passes
after: a test it writes, or the failing run that reported the defect.

#### `SKILL-04`
`/mate:fix` shall sweep for the same bug class before shipping.

#### `SKILL-05`
`/mate:feature` shall implement one feature at a time.

#### `SKILL-06`
Each skill shall name the next phase in its wrap-up rather than invoke it.

#### `SKILL-07`
When the check that proves a fix is a run that already existed, `/mate:fix`
shall report it as that run failing and then passing, without the RED and GREEN
labels.

#### `SKILL-08`
`/mate:fix` shall start diagnosing before it opens a branch or a route.

### `REACT`
Reactions to announcements

#### `REACT-01`
The react hook shall match an announcement only at the start of a line and
followed by whitespace.

#### `REACT-02`
When anchor announces `commit.pushed` on a branch other than the default, the
react hook shall name `/anchor:prepare-review`.

#### `REACT-03`
When anchor announces `commit.pushed` on the default branch, the react hook
shall name `/anchor:release`, or `/tack:end` when the change isn't shippable
alone.

#### `REACT-04`
If the default branch doesn't resolve from `origin/HEAD`, or the announcement
lacks a sha or branch, then the react hook shall print nothing.

#### `REACT-05`
The react hook shall react to `commit.pushed` at most once per session and sha.

#### `REACT-06`
When anchor announces `cr.ready`, the react hook shall name what the change
request still needs (a reviewer and the pipeline's state), once per session.

#### `REACT-07`
The react hook shall delete its one-shot markers after 7 days.

#### `REACT-08`
When tack announces `session.started` for the current session, or with no
session field, the react hook shall ask the agent to classify the work as a
defect or a capability and invoke `/mate:fix` or `/mate:feature` for it, naming
the announced route; to start neither when neither fits; and to carry on when
already in one. It shall do so once per session.

#### `REACT-09`
If a `session.started` body is not a JSON object, then the react hook shall
print nothing.
