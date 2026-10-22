# Changelog

## Unreleased

### Changed

- `/tack:start` now gets right to work: the agent decides whether the issue
  is a defect or a capability and runs `/mate:fix` or `/mate:feature` itself,
  instead of naming it and waiting for you to type it.

### Added

- `/mate:next` picks your next piece of work: it surveys the issues assigned
  to you (through `/anchor:backlog` when anchor is installed), recommends the
  top one, and offers `/tack:start` with its URL filled in. It starts that
  issue, or another one, once you say which. Typing `/anchor:backlog` yourself
  ends with the same offer.
- Work that didn't start from `/tack:start`, `/mate:fix` or `/mate:feature`
  still gets recorded on tack: the first edit inside the repo, and the first
  push, each ask the agent to bind the session to a tack until tack reports it
  has heard of the session. With no tack CLI installed, nothing changes.

### Fixed

- The nudge works under macOS's built-in bash 3.2, where it printed nothing
  for any phase.
- The lines mate prints after a tool call now reach the agent: the step after
  `/anchor:commit`'s push, what a change request needs once it leaves draft,
  and the next phase when the agent (rather than you) invokes a skill. Each
  used to land in the transcript only.

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
