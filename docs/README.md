<div class="ph-hero" style="--accent: color-mix(in srgb, var(--color-cyan) 54%, light-dark(black, white))">

<h1 class="ph-lede"><span class="ph-name">mate</span> plugins to combine capabilities.</h1>

<div class="ph-badge"><img class="ph-mark" src="favicon.svg" alt="mate" width="26" height="26">

[](_tags.md ':include')

</div>

</div>

mate is the joint the other bridge.ai plugins fit into: it listens for what each
one announces and names what should run next. Today that is the work where code
actually changes, a defect whose cause is not known yet and a capability that is
not there yet, plus one line of forward pressure when a phase begins. You type
the next command, or you don't.

## In action

<div class="cw-session" data-cw-session="session"></div>

## Install

```bash
claude plugin marketplace add chris-peterson/claude-marketplace
claude plugin install mate@chris-peterson
```

## The skills

| | `/mate:next` | `/mate:fix` | `/mate:feature` |
|---|---|---|---|
| For | choosing what to work on | a defect whose cause isn't known yet | a capability an existing codebase doesn't have |
| Triggers on | "what's next?", "what should I work on?" | a stack trace, a CI failure, "works locally but fails in CI" | "add X", a feature request, a spec |
| The spine | survey → recommend → offer `/tack:start` → wait for your pick | root cause → RED → GREEN → verify → sweep the bug class | constraints → first working implementation → refine against real feedback → consolidate |
| Skip it when | you've already named the work | the correction is already known and mechanical, or there's no error signal to reason from | the work is a defect, the project is greenfield, or the deliverable is an answer rather than code |

`/mate:next` surveys through `/anchor:backlog`. `fix` and `feature` carry
reference files the skill loads only when it needs them: the symptom catalog
and the diagnostic techniques for `fix`, the verification instruments and the
accumulated patterns catalog for `feature`.

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

Getting into the work is the agent's job, from either end. `/mate:fix 42`
already says which work to open, so the skill runs `/tack:start` for it instead
of asking you to type the same reference again. `/tack:start 42` already says
you want the work started, so the nudge has the agent read the issue's labels
and description, say in one line which skill fits, and run it. Either way you
come back to a session that is working, not one waiting on you.

Everything else is a suggestion:

```text
mate: when this phase is done and the tree is green, the next step is
`/anchor:commit`. Name it in the wrap-up; don't run it.
```

## The chain it names

**`/mate:next`** → `/tack:start` → **`/mate:fix`** or **`/mate:feature`** →
`/anchor:commit` → `/anchor:prepare-review` → `/anchor:review` →
`/anchor:merge` → `/anchor:release` → `/tack:end`

mate supplies the three in bold. [tack](https://github.com/chris-peterson/tack)
and [anchor](https://github.com/chris-peterson/anchor) supply the rest, and
installing mate installs both. The full contract is in
[Composing with the siblings](/guides/composing-with-siblings).

## How the nudge reaches you

A slash command *you* type is expanded into the prompt and fires no `Skill` tool
call; only an agent-invoked skill produces one. mate registers on both events
against the same script, so the line arrives whichever way the phase was
entered.

Two lines arrive by a different road. The suite's plugins announce what they
caused on a command's stdout, and mate subscribes to the anchor keys that
carry a fact a command name can never carry.

`commit.pushed` carries the sha and the branch, and lands only once the push
has. That matters because the nudge fires on *entering* a phase: when you type
`/anchor:commit`, nothing about that commit has happened yet. By the time the
announcement arrives, two things are known. The changeset has been read:
`/anchor:commit` opens the pending diff in a review tool and commits only on an
approved verdict, so a push is evidence of a review, and recommending another
one would be asking you to read the same diff twice. And the branch is known,
which decides what the line can even name: a commit heading for a change request
gets `/anchor:prepare-review`, while one landed on the default branch has no
change request to open and gets `/anchor:release` or `/tack:end`.

`cr.ready` is the first moment the change request is something to hand to
somebody, and the announcement carries the URL to hand over. So the line asks
for the two things a CR out of draft still needs: a reviewer and the pipeline's
state. Naming `/anchor:merge` is already the `/anchor:review` nudge's job, so
the reaction leaves it alone.

Everything else anchor announces already lands on a phase the nudge names, and
[tack](https://github.com/chris-peterson/tack) records the CR, issue and release
keys on the route, so mate says nothing about them rather than saying it twice.

## Getting tack told

Plenty of work starts from a plain prompt rather than `/tack:start` or a mate
skill, and that work reaches its commit with tack told nothing, so `/tack:end`
has nothing to close and the sessions view can't say what the session is on. mate
listens for tack's `session.started` announcement, which is the evidence tack
has heard of the session. Until it arrives, two moments draw a line:

| Moment | Why then |
|---|---|
| the first edit to a file inside the repo | the earliest point the session is plainly work rather than a question |
| the first `commit.pushed` | the work now has a durable artifact, whatever was said at the edit |

Each line asks the agent to bind the session to the tack it drives (adding one
when none fits), or to ask you about `/tack:start` when no route resolves. This
is the one place mate asks for something to be done rather than named: binding
is bookkeeping on the record the work already lives in, not a phase of the
chain.

## Why "mate"

To mate two parts is to fit them together so they hold. The bridge.ai plugins
each announce what they caused, and mate is the joint they fit into: it reads
those announcements and names what runs next.

Today that joint is narrow. It reaches two of anchor's keys, the phase names the
nudge resolves from a skill invocation on its own, and the skills where the
code actually changes. Widening it is the direction the plugin is headed.
