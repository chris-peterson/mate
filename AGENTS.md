# mate

A Claude Code plugin for the Refine phase: the two skills that make the change,
plus a nudge layer that names the phase you are about to enter next without
running it for you.

`/mate:fix` drives a bug from symptom to shipped fix. `/mate:feature` adds
capability to a working codebase. `hooks/nudge.sh` emits one line, on entering
a phase, naming the phase after it.

## Commands

```bash
just test              # the bash test suite under scripts/tests/
just generate          # regenerate plugin.json, hooks.json, docs/ from source
just check             # the same, then diff what the projection job would commit
just docs              # preview the docsify site locally
```

## Layout

```text
plugin.yml              source of record for metadata and marketplace copy
hooks/hooks.yml         source of record for the two hook registrations
hooks/nudge.sh          the nudge — resolves a skill name from both shapes
skills/fix/             the defect skill and its reference files
skills/feature/         the capability skill and its reference files
guides/                 the composition contract with tack, anchor, code-review
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
  or the hook.
- **The hook reads both shapes a skill invocation arrives in.** A slash command
  the user types fires no `Skill` tool call at all; only an agent-invoked skill
  produces one. A `PostToolUse` matcher on `Skill` alone is silently inert for
  everything a human types. `hooks/hooks.yml` registers both events against the
  same script, and `scripts/tests/nudge.test.sh` exercises both.
- **A synthetic payload proves the matcher, never the delivery.** The test suite
  is green on a hook Claude Code never calls. A change to the registrations or
  to the name resolution is finished when the command has been typed in a live
  session and the line came back.
- **`hooks/nudge.sh` is bash and jq, nothing else.** It runs on every prompt in
  every session where mate is enabled, so the non-matching path is a pattern
  test and an `exit 0`. No network, no interpreter startup.
- **Stdout is context, not a log.** Anything the hook prints lands in the
  agent's context whether or not it is useful there. Every non-matching path
  prints nothing.
- **The siblings are optional and the skills say so at each site.** tack,
  anchor, and `/code-review` each supply a phase; `guides/composing-with-siblings.md`
  carries what replaces each one when it is absent. A skill step that assumes a
  sibling is installed is a bug.

## Glossary

- **Nudge** — one line naming the next phase, emitted on entering the current
  one. Not a gate, not a prompt, not an invocation.
- **The envelope** — what `/tack:start` opens and `/tack:end` closes: the linked
  thread read in full, a slug, a branch, and the route the deliverable is
  recorded against.
- **Soft degrade** — a step that names a sibling's command when the sibling is
  present and says what to do instead when it is not, in the same sentence.
- **Both shapes** — the two ways a skill invocation reaches a hook: a `Skill`
  tool call when the agent invokes it, and a prompt heading with `/name` when
  the user types it.
