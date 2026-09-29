# mate specification

mate names the next phase of a bridge.ai workflow as one line, on entering a
phase or when a sibling plugin announces what it did, and never runs that phase
itself.

Requirements use [EARS syntax](https://alistairmavin.com/ears). Each is one of:
Ubiquitous (`The <system> shall …`), State-Driven (`While …`), Event-Driven
(`When …`), Optional (`Where …`), or Unwanted Behaviour (`If … then …`).

Each requirement is its own heading carrying a stable ID (`XX-NN`), one level
below its category's heading, so every requirement has a linkable anchor
(`SPEC.md#xx-nn`). Lettered decompositions (`XX-NNa`) each count as one.

## Concepts

- **Nudge**: one line naming the next phase, emitted on entering the current
  one. Not a gate, not a prompt, not an invocation.
- **Both shapes**: the two ways a skill invocation reaches a hook. A `Skill`
  tool call when the agent invokes it (`PostToolUse`), and a prompt headed with
  `/name` when the user types it (`UserPromptSubmit`).
- **Announcement**: one line a sibling plugin prints on a command's stdout,
  `codes.bridgeai.<plugin>/<key> {json}`, per the suite's interop contract.
- **The chain**: `/tack:start` → `/mate:fix` or `/mate:feature` →
  `/anchor:commit` → `/anchor:prepare-review` → `/anchor:review` →
  `/anchor:merge` → `/anchor:release` → `/tack:end`.
- **The envelope**: what `/tack:start` opens and `/tack:end` closes: the linked
  thread read in full, a slug, a branch, and the tack route.
- **Soft degrade**: a step that names a sibling's command when the sibling is
  installed and says what to do instead when it is not, in the same sentence.

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

#### `HOOK-04`
The nudge shall compute each line from the current payload alone, keeping no
session state.

#### `HOOK-05`
Every line mate prints shall name the next step and tell the agent not to run
it.

### `NUDGE`
Phase nudges

#### `NUDGE-01`
When the agent invokes a skill, the nudge shall read the skill name from the
`Skill` tool call.

#### `NUDGE-02`
When the user submits a prompt whose first line starts with `/<name>`, the nudge
shall read the name from that token, and a command mentioned later in the
prompt shall not match.

#### `NUDGE-03`
When `/tack:start` is entered, the nudge shall ask the agent to classify the
linked work as a defect or a capability and name `/mate:fix` or
`/mate:feature`, without invoking either.

#### `NUDGE-04`
When `/tack:start` is entered with an `https` URL in the prompt, the nudge shall
name that URL as the work being opened.

#### `NUDGE-05`
When `/mate:fix` or `/mate:feature` is entered, the nudge shall name
`/anchor:commit`.

#### `NUDGE-06`
When `/code-review` is entered, the nudge shall name `/anchor:prepare-review`.

#### `NUDGE-07`
When `/anchor:prepare-review` is entered, the nudge shall name `/anchor:review`
as a self-review of the draft.

#### `NUDGE-08`
When `/anchor:review` is entered, the nudge shall name `/anchor:merge`.

#### `NUDGE-09`
When `/anchor:merge` is entered, the nudge shall name `/anchor:release`.

#### `NUDGE-10`
When `/anchor:release` is entered, the nudge shall name `/tack:end`.

#### `NUDGE-11`
When `/anchor:commit` is entered, the nudge shall print nothing.

#### `NUDGE-12`
The nudge shall match bare skill names only for `code-review`, `fix`, and
`feature`.

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

### `SKILL`
The fix and feature skills

#### `SKILL-01`
Where tack is installed and no route resolves, each skill shall say so and let
the user type `/tack:start`; where tack is absent, the skill shall do the
envelope by hand.

#### `SKILL-02`
Where anchor is absent, the skills shall say what replaces the commit, change
request, merge, and release phases.

#### `SKILL-03`
`/mate:fix` shall prove the defect with a test that fails before the fix and
passes after.

#### `SKILL-04`
`/mate:fix` shall sweep for the same bug class before shipping.

#### `SKILL-05`
`/mate:feature` shall implement one feature at a time.

#### `SKILL-06`
Each skill shall name the next phase in its wrap-up rather than invoke it.
