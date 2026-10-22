# mate

A Claude Code plugin that joins the other bridge.ai plugins: it reads what they
announce and names what should run next. Today that is a nudge layer over the
skills where the code actually changes, naming the phase you are about to
enter next without running it for you.

`/mate:next` picks the work and offers to start it. `/mate:fix` drives a bug
from symptom to shipped fix. `/mate:feature` adds capability to a working
codebase. `hooks/nudge.sh` emits one line, on entering
a phase, naming the phase after it. `hooks/underway.sh` and `hooks/react.sh`
press for the session to be bound to a tack once work is underway, until tack
announces it has heard of the session.

## Commands

```bash
just test              # the bash test suite under scripts/tests/
just generate          # regenerate plugin.json, hooks.json, docs/ from source
just check-generated   # the same, then list what the projection job would commit
just docs              # preview the docsify site locally
```

## Layout

```text
plugin.yml              source of record for metadata and marketplace copy
hooks/hooks.yml         source of record for the hook registrations
hooks/nudge.sh          the nudge — resolves a skill name from both shapes
hooks/react.sh          the reaction — reads the subscribed keys off a sibling's stdout
hooks/underway.sh       presses for a tack binding on the first edit in the repo
skills/next/            the skill that picks the work and offers to start it
skills/fix/             the defect skill and its reference files
skills/feature/         the capability skill and its reference files
guides/                 the composition contract with tack and anchor
scripts/tests/          bash test suite
docs/                   docsify site (README, _sidebar, favicon are source)
```

`.claude-plugin/plugin.json`, `hooks/hooks.json`, `plugin.yml`'s
`suite.describe` block, and most of `docs/` are **generated** by
[shipyard](https://github.com/chris-peterson/shipyard) from the sources above.
Never hand-edit a generated file; edit its source and let the projection follow.
A key shipyard does not model vanishes silently, so read the generated file
after adding any key that was not already in it.

The projection job in `.github/workflows/project.yml` is that writer: it runs
`shipyard generate` on every push and commits the result to the branch, so a
committed artifact matches its source at all times and the diff a reviewer
approves is what lands.

Releases are dispatched, not tagged by hand: run the **Release** workflow with a
bump level, and shipyard derives the version from `plugin.yml`, retitles
`CHANGELOG.md`'s `## Unreleased` section, commits, tags that commit, and
publishes. Write the notes into `## Unreleased` first — reading what landed is
what picks the level.

## Conventions

- **Nudge, never sequence.** Every line mate emits is a line the user acts on
  or ignores. A step that invokes the next phase on its own has rebuilt the
  sequencer this plugin exists to replace half of. The design note is in
  `docs/README.md`; it is the one constraint to hold when editing either skill
  or the hook. Two exceptions. The line on tack's `session.started` has the agent invoke
  `/mate:fix` or `/mate:feature`, because opening the envelope and starting
  the work are one request. The tack binding: `underway.sh` and `react.sh` ask
  for it to be done, because binding records work already underway and runs no
  phase.
- **The hook reads both shapes a skill invocation arrives in.** A slash command
  the user types fires no `Skill` tool call at all; only an agent-invoked skill
  produces one. A `PostToolUse` matcher on `Skill` alone is silently inert for
  everything a human types. `hooks/hooks.yml` registers both events against the
  same script, and `scripts/tests/nudge.test.sh` exercises both.
- **A synthetic payload proves the matcher, never the delivery.** The test suite
  is green on a hook Claude Code never calls. A change to the registrations or
  to the name resolution is finished when the line has come back in a live
  session. A headless run is the cheap way to get one:

  ```bash
  claude -p --plugin-dir . --settings <capture.json> --permission-prompts none \
    '/tack:start https://github.com/o/r/issues/1'
  ```

  Point `capture.json` at a hook of your own that appends its stdin to a file,
  and the captured payload is the real one — which is how the shape a hook reads
  gets settled rather than assumed. The line appearing in the run's
  `transcript_path` proves only that the script ran: a PostToolUse hook's plain
  stdout is recorded there as `hook_success` and never reaches the agent. Have
  the prompt ask the agent to quote every `mate:` line it received, and read
  its answer.
- **The non-matching path is a pattern test and an `exit 0`.** The hooks run on
  every prompt, every Bash call and every edit in every session where mate is
  enabled, so what a payload that isn't for mate costs is the budget to protect.
  Bash and `jq` are the whole toolkit until a key has matched; past that,
  `react.sh` resolves the default branch with one `git symbolic-ref` on a local
  ref, and `underway.sh` finds the repo with one `git rev-parse`. No network, no
  interpreter startup, on any path.
- **A key another plugin already answers is a key mate leaves alone.** What
  `react.sh` subscribes to is settled by what nobody else says, and tack already
  records the CR, issue and release keys on the route. The test against the
  nudge is narrower than it looks: the nudge fires on *entering* a phase, so it
  knows which phase was entered and nothing about how it ends. A key carrying
  what the phase actually did — `commit.pushed`'s branch and sha — is mate's to
  take; one that merely marks a phase the nudge already names is not. Before
  adding a key, read `plugin.yml`'s `events` block for why the others are
  absent.
- **A line reaches the agent only through the channel its event reads.**
  UserPromptSubmit adds plain stdout to the agent's context. PostToolUse puts
  plain stdout in the transcript alone, so every PostToolUse line goes out as
  `{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":…}}`.
  The tests decode that JSON and fail on anything else. Either way, what lands
  is context whether or not it is useful there, so every non-matching path
  prints nothing.
- **anchor and tack are dependencies.** `plugin.yml` declares both, so Claude
  Code installs them with mate, and a skill or hook can name their commands
  and read their announcements without a branch for their absence.

## Glossary

- **Nudge** — one line naming the next phase, emitted on entering the current
  one. Not a gate, not a prompt, not an invocation.
- **The envelope** — what `/tack:start` opens and `/tack:end` closes: the linked
  thread read in full, a slug, a branch, and the route the deliverable is
  recorded against.
- **Both shapes** — the two ways a skill invocation reaches a hook: a `Skill`
  tool call when the agent invokes it, and a prompt heading with `/name` when
  the user types it.
