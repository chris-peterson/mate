# <img src="favicon.svg" alt="mate" width="64" height="64" style="vertical-align: middle"> mate

The two skills that make the change, and one line telling you what's next.

Refine is where the code actually changes, and it has two shapes: a defect whose
cause isn't known yet, and a capability that isn't there yet. mate ships a skill
for each, plus a hook that names the phase after the one you just entered — and
stops there.

## In action

<div class="cw-session" data-cw-session="session"></div>

## Install

```bash
claude plugin marketplace add chris-peterson/claude-marketplace
claude plugin install mate@chris-peterson
```

## The two skills

| | `/mate:fix` | `/mate:feature` |
|---|---|---|
| For | a defect whose cause isn't known yet | a capability an existing codebase doesn't have |
| Triggers on | a stack trace, a CI failure, "works locally but fails in CI" | "add X", a feature request, a spec |
| The spine | root cause → RED → GREEN → verify → sweep the bug class | constraints → first working implementation → refine against real feedback → consolidate |
| Skip it when | the correction is already known and mechanical, or there's no error signal to reason from | the work is a defect, the project is greenfield, or the deliverable is an answer rather than code |

Both carry reference files the skill loads only when it needs them: the symptom
catalog and the diagnostic techniques for `fix`, the verification instruments
and the accumulated patterns catalog for `feature`.

## Nudge, never sequence

A skill that drove these phases end to end was retired in favour of running each
on its own timing. What went with it by accident was the **forward pressure**:
knowing which phase you're in and what comes next. mate brings back that half
and only that half.

| | a sequencer does | mate does |
|---|---|---|
| Phase transitions | runs them back to back with gates | emits one line saying what's next |
| Who runs the next step | the skill | you, by typing it |
| Fix vs feature | you pick | mate classifies from the issue |

The classification is the agent's call rather than a question put to you: `fix`
opens with the rule that decides it — skip this skill when the work is a feature
or a refactor rather than a defect — and the hook applies that sentence to the
linked issue's labels and description.

Everything else is a suggestion:

```text
mate: when this phase is done and the tree is green, the next step is
`/anchor:commit`. Name it in the wrap-up; don't run it.
```

## The chain it names

`/tack:start` → **`/mate:fix`** or **`/mate:feature`** → `/anchor:commit` →
`/code-review` → `/anchor:prepare-review` → `/anchor:merge` →
`/anchor:release` → `/tack:end`

mate supplies the two in bold. [tack](https://github.com/chris-peterson/tack)
and [anchor](https://github.com/chris-peterson/anchor) supply the rest, and both
are optional — a bare `mate` install runs both skills start to finish, and each
step that names a sibling says what to do when it isn't there. The full
contract is in [Composing with the siblings](/guides/composing-with-siblings).

## How the nudge reaches you

A slash command *you* type is expanded into the prompt and fires no `Skill` tool
call; only an agent-invoked skill produces one. mate registers on both events
against the same script, so the line arrives whichever way the phase was
entered.

## Why "mate"

The first mate runs the ship day to day, carries the captain's intent into the
work, and says what's next. The captain still gives the orders.
