# Changelog

## Unreleased

### Added

- Each of mate's reactions can be turned off. `git config --global
  mate.subscribe.anchor false` turns off what it says after anchor's
  announcements, `mate.subscribe.tack false` after tack's, and
  `mate.subscribe.<plugin>.<entity>-<event>` one at a time, such as
  `mate.subscribe.anchor.cr-ready`. Set without `--global` in a repository
  where it doesn't fit. Each line ends with the command that turns it off.
- `/mate:fix` and `/mate:feature` label the session in beacon with the issue's
  subject once they've read it, in place of the command that opened it, such
  as `Mate feature 142`. A session bound to a tack route keeps tack's label.
- `/mate:fix` now also starts when a failure is about to be dismissed as
  "pre-existing", "unrelated", or "already broken on main". It still
  diagnoses a failure the base branch shares, comparing the two by which
  tests fail and how, not by whether both pipelines are red. Two red
  pipelines can fail for different reasons. Whether a failure predates your
  change decides where its fix goes, never whether there is one.

### Fixed

- `/mate:fix` and `/mate:feature` no longer repeat a bare issue number such
  as `#42` back to the console. They look it up on the origin remote first and
  write it as a link, so it stays clickable wherever it lands, beacon's sessions
  view included.
- `/mate:fix` no longer loses your fix when it proves the new tests catch the
  bug. To show this, it briefly swaps the old, buggy code back in and runs the
  tests. It used to undo that swap with a git command that reset the file to
  the last commit, so a fix you hadn't committed yet was erased, and in Claude
  Code's auto mode the command could be blocked, leaving the buggy code in
  place. It now saves a copy of the fixed file first and puts that copy back.
- mate no longer reacts to a `cr.ready` line whose body isn't JSON.
- A control character in an announced URL, branch, sha, or route no longer
  reaches the agent.

## 0.3.1

### Fixed

- mate loads when anchor or tack comes from a marketplace other than
  `chris-peterson`, such as one that proxies it. It used to stay disabled with
  `Dependency "anchor@chris-peterson" is not installed`.

### Changed

- Installing mate no longer installs anchor and tack. Install both yourself,
  from any marketplace that carries them.

## 0.3.0

mate does fewer things: it carries the fix and feature playbooks, starts the
right one when tack opens an issue, and names the step after anchor's push and
draft flag.

### Changed

- `/tack:start` now gets right to work: once tack binds the session to the
  issue's route, the agent decides whether the issue is a defect or a
  capability and runs `/mate:fix` or `/mate:feature` itself, instead of naming
  it and waiting for you to type it. A bind the agent runs by hand starts it
  the same way.
- `/mate:fix` looks at the failure before anything else. It opens a branch and
  a tack route only once the diagnosis shows the work spans more than one
  deliverable or session, and `/mate:feature` opens one only for work of that
  size.
- Installing mate installs anchor and tack with it.
- `/mate:fix` and `/mate:feature` name `/anchor:commit` in their own wrap-up.

### Removed

- The line on entering each phase (`/anchor:prepare-review`, `/anchor:review`,
  `/anchor:merge`, `/anchor:release`, `/code-review`). The lines after a push
  and after a change request leaves draft stay.
- `/mate:next`, and the `/tack:start` offer at the end of `/anchor:backlog`:
  exploring the backlog is left to anchor.

## 0.2.1

### Changed

- `/mate:feature 42` and `/mate:fix 42` start working right away: with tack
  installed, the skill runs `/tack:start` for that issue itself instead of
  asking you to type it.
- `/mate:fix` treats a failed CI job, build, or deploy as its own proof: it
  reports the job failing and then passing, without RED/GREEN labels or a test
  written only to fail.

## 0.2.0

### Added

- `/mate:fix` — drives a defect from symptom to shipped fix: confirm it is real
  and current, find the mechanism, prove it with a failing test, verify in the
  environment that actually failed, then sweep for the same bug class. Carries
  a symptom catalog (`references/bug-types.md`) and a diagnostic technique set
  (`references/techniques.md`).
- `/mate:feature` — adds capability to a working codebase: gather the
  constraints that prevent false starts, implement one feature at a time
  against the patterns already there, verify each against the feedback loop
  that can catch its failures, then consolidate before merge. Carries
  `references/verification.md` and `references/patterns.md`.
- The nudge hook — on entering a phase, one line naming the phase after it,
  through `/anchor:commit`, `/anchor:prepare-review`, `/anchor:review`,
  `/anchor:merge`, `/anchor:release`, and `/tack:end`. On `/tack:start` it
  instead classifies the linked issue as a defect or a capability and names the
  skill that fits. It registers on both shapes a skill invocation arrives in, so
  a command the user types reaches it as well as one the agent invokes.
- The react hook — subscribes to two suite announcements for the facts a skill
  name can't carry. `codes.bridgeai.anchor/commit.pushed` fires once the push
  lands, which is downstream of the commit's own review gate, so the line names
  `/anchor:prepare-review` rather than a second review of a diff that was just
  read — and its `branch` field is what tells a commit heading for a change
  request apart from one landed on the default branch, which gets
  `/anchor:release` or `/tack:end` instead.
  `codes.bridgeai.anchor/cr.ready` fires when a change request leaves draft, and
  names what it still needs: a reviewer to assign or hand the URL to, and the
  pipeline's state.
- `guides/composing-with-siblings.md` — which sibling supplies which phase, and
  what replaces each one when it isn't installed.
- The docs site's Workflow page — every line mate prints, as
  if-this-then-that, with the flowchart of the chain and how strong the signal
  behind each step is. The Requirements and
  Coverage pages list each rule by ID and what the code covers.
