<div class="ph-hero" style="--accent: color-mix(in srgb, var(--color-cyan) 54%, light-dark(black, white))">

<h1 class="ph-lede"><span class="ph-name">mate</span> plugins to combine capabilities.</h1>

<div class="ph-badge"><img class="ph-mark" src="favicon.svg" alt="mate" width="26" height="26">

[](_tags.md ':include')

</div>

</div>

mate carries the playbooks for the work where code actually changes: a defect
whose cause is not known yet, and a capability that is not there yet. When
[tack](https://github.com/chris-peterson/tack) opens work on an issue, mate has
the agent decide which playbook fits and start it. And when
[anchor](https://github.com/chris-peterson/anchor) pushes a commit or takes a
change request out of draft, mate names what comes next.

## In action

<div class="cw-session" data-cw-session="session"></div>

## Install

```bash
claude plugin marketplace add chris-peterson/claude-marketplace
claude plugin install mate@chris-peterson
```

Installing mate installs tack and anchor with it.

## The skills

| | `/mate:fix` | `/mate:feature` |
|---|---|---|
| For | a defect whose cause isn't known yet | a capability an existing codebase doesn't have |
| Triggers on | a stack trace, a CI failure, "works locally but fails in CI" | "add X", a feature request, a spec |
| The spine | root cause → RED → GREEN → verify → sweep the bug class | constraints → first working implementation → refine against real feedback → consolidate |
| Skip it when | the correction is already known and mechanical, or there's no error signal to reason from | the work is a defect, the project is greenfield, or the deliverable is an answer rather than code |

Each carries reference files it loads only when it needs them: the symptom
catalog and the diagnostic techniques for `fix`, the verification instruments
and the accumulated patterns catalog for `feature`.

Neither opens a tack route for a single contained change. Work that spans more
than one deliverable or more than one session gets one, and `/mate:fix` makes
that call after it has looked at the failure, not before.

## The kick-off

`/tack:start <issue>` opens the work: it reads the issue, cuts a branch, and
binds the session to a route. When tack announces that binding
(`session.started`), mate tells the agent to read the issue's labels and
description, say in one line whether it's a defect or a capability, and start
`/mate:fix` or `/mate:feature`. You come back to a session that is working.

That is the one thing mate does without being asked. tack owns starting work,
so mate listens for tack saying it happened rather than asking you to call a
mate command.

## After a push, and out of draft

Two of anchor's announcements carry a fact the command name can't, and mate
names the next step from each. It names; you run it or you don't.

- **`commit.pushed`** lands after `/anchor:commit` has pushed, and that skill
  commits only on an approved review, so the diff has already been read. On a
  feature branch the next step is `/anchor:prepare-review`. On the default
  branch there's no change request to open: `/anchor:release` if it ships on its
  own, otherwise `/tack:end`. Once per commit; an amend is a new one.
- **`cr.ready`** is the first moment a change request is something to hand to
  somebody. mate asks for the two things it still needs: a reviewer, and the
  pipeline's state. Once per session.

## Why so little

The command you reach for first says what kind of session this is, and mate
answers that rather than pulling every session into the same chain:

| You reach for | You're saying | mate |
|---|---|---|
| `/anchor:backlog` | "What should I do, if anything?" | stays out of it. Exploring may end with no work at all |
| `/anchor:issue` | "Record this", or "is this tracked?" | stays out of it |
| `/tack:start <issue>` | "I've chosen; set it up" | picks the playbook and starts it |
| `/mate:feature <x>` | "Build this" | gathers the constraints first, and opens a route if the work is sizable |
| `/mate:fix <prod issue>` | "It's broken, now" | diagnoses first; bookkeeping waits |
| a plain question | nothing yet | stays out of it |

anchor, tack and mate each work on their own. A session that only browses the
backlog, or only fixes one bug, uses one of them and that is the whole session.

The rule behind that: each plugin suggests its own next phase, and only when it
is certain which one it is. A plugin that needs another's events listens to them
directly. mate covers only the seams no single plugin owns, such as tack opening
an issue and the playbook that works it, or a playbook finishing and anchor's
commit. The lines after a push and out of draft are mostly anchor's own chain,
so they move into anchor once
[anchor#164](https://github.com/chris-peterson/anchor/issues/164) lands.

## Why "mate"

To mate two parts is to fit them together so they hold. mate fits at the
joints where one plugin's work ends and the next phase begins: an issue tack
has opened becoming the work that changes the code, and a push or a change
request anchor has finished becoming the step after it.
