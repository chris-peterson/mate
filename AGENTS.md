# mate

A Claude Code plugin that carries the playbooks for the work where code actually
changes: `/mate:fix` drives a defect from symptom to shipped fix, and
`/mate:feature` adds a capability to a working codebase. `hooks/react.sh`
listens for what the siblings announce: when tack opens work on an issue, it has
the agent decide which playbook fits and start it; when anchor pushes a commit
or takes a change request out of draft, it names the step after.

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
hooks/hooks.yml         source of record for the hook registration
hooks/react.sh          the reactions to tack's and anchor's announcements
skills/fix/             the defect skill and its reference files
skills/feature/         the capability skill and its reference files
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

- **mate's remit is the seams between plugins, and nothing inside one.** Each
  plugin suggests its own next phase, and only when it is certain which one it
  is; a plugin that needs another's events subscribes to them straight from the
  source. mate exists to connect what otherwise isn't, or shouldn't be,
  connected: tack opening work and the playbook that does it, a playbook
  finishing and anchor's commit. Before adding a line, name the two plugins it
  joins. If it's one plugin, the line belongs in that plugin. The design note
  is in `docs/README.md`.
- **Act only on what the user's command already said.** The command reached for
  first says what mode they're in: `/anchor:backlog` is exploring, `/tack:start`
  is a decision already made, `/mate:fix` on a production issue is urgent. mate
  acts on its own in one place, starting the playbook once tack has opened the
  work; everywhere else a line names the step and leaves it to the user.
- **Listen to what the siblings announce; don't ask for a mate command.** tack
  owns starting work, so mate subscribes to `codes.bridgeai.tack/session.started`
  rather than asking the user to call something of mate's, or matching the name
  of tack's skill.
- **The anchor reactions are a stand-in.** `commit.pushed` and `cr.ready` mostly
  name steps inside anchor's own chain, which by the rule above are anchor's to
  name. They stay until
  [anchor#164](https://github.com/chris-peterson/anchor/issues/164) lands, and
  then only the cross-plugin part survives: a push to the default branch, with
  nothing to release, closing with `/tack:end`.
- **A synthetic payload proves the matcher, never the delivery.** The test suite
  is green on a hook Claude Code never calls. A change to the registration or
  the matching is finished when the line has come back in a live session. A
  headless run that binds a scratch route is the cheap way to get one:

  ```bash
  claude -p 'Run `tack init <scratch-slug>` and nothing else, then quote every "mate:" block that reached you after it.' \
    --permission-prompts none --allowedTools 'Bash(tack init <scratch-slug>)'
  ```

  Then remove the route with `tack rm <scratch-slug> --force`. The line appearing
  in the run's `transcript_path` proves only that the script ran: a PostToolUse
  hook's plain stdout is recorded there as `hook_success` and never reaches the
  agent, which is why the prompt asks the agent to quote what it received.
- **The non-matching path is a pattern test and an `exit 0`.** `react.sh` runs on
  every Bash call in every session where mate is enabled, so what a payload that
  isn't for mate costs is the budget to protect. Bash and `jq` are the whole
  toolkit until a key has matched; past that, the push line resolves the default
  branch with one `git symbolic-ref` on a local ref. No network, no interpreter
  startup, on any path.
- **A line reaches the agent only as `additionalContext`.** PostToolUse puts
  plain stdout in the transcript alone, so the line goes out as
  `{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":…}}`.
  The tests decode that JSON and fail on anything else.
- **anchor and tack are required, and installed by the user.** The hook and
  skills name their commands and read their announcements without a branch for
  their absence. `plugin.yml` keeps its `dependencies:` block commented out,
  with the reason and the condition for restoring it beside the block.

## Glossary

- **The envelope**: what `/tack:start` opens and `/tack:end` closes: the linked
  thread read in full, a slug, a branch, and the route the deliverable is
  recorded against.
- **Sizable work**: work that spans more than one deliverable or more than one
  session. It gets a tack route; a single contained change doesn't.
- **Announcement**: one line a sibling prints on a command's stdout,
  `codes.bridgeai.<plugin>/<key> {json}`.
