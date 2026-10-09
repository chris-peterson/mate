# Changelog

## Unreleased

### Changed

- `/mate:fix` and `/mate:feature` open the envelope themselves. With tack
  installed and no route bound, the skill invokes `/tack:start` for the work you
  named (`/mate:feature 42` resolves `42` against the origin remote) and carries
  on, instead of asking you to type the same reference again.
- `/mate:fix` uses the failing check a defect already comes with. When a CI
  job, build, or deploy is what failed, that run is the proof: the skill fixes
  it, shows the same job passing, and reports it in those terms rather than as
  RED and GREEN. A new test is added where it would catch the defect earlier.
- The `/tack:start` nudge tells the agent to carry on when `/mate:fix` or
  `/mate:feature` opened the route, so a skill-driven start doesn't come back
  asking which skill to run.

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
