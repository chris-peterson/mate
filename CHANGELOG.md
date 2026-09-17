# Changelog

## Unreleased

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
