# Composing with the siblings

mate is the only plugin in the suite that leans on three others, and every one
of them is optional. A bare `mate` install runs both skills start to finish.
This is the map of who supplies what, and what to do when they aren't there.

## The chain

| Phase | Command | Supplied by |
|---|---|---|
| Open the envelope | `/tack:start [url]` | [tack](https://github.com/chris-peterson/tack) |
| Make the change | `/mate:fix`, `/mate:feature` | mate |
| Commit and push | `/anchor:commit` | [anchor](https://github.com/chris-peterson/anchor) |
| Open the change request | `/anchor:prepare-review` | anchor |
| Self-review it | `/anchor:review` | anchor |
| Merge | `/anchor:merge` | anchor |
| Release | `/anchor:release` | anchor |
| Close the envelope | `/tack:end` | tack |

mate's hooks name the next link in that chain as one line, once. `nudge.sh`
names it on entering a phase. `react.sh` covers the two links a phase's name
alone can't reach: what follows a commit, which depends on the branch it landed
on, and what a change request needs once the draft flag comes off, which is the
one moment the URL to hand over exists. Neither runs anything.

`/anchor:commit` gates on its own review of the pending changeset — only an
approved verdict commits and pushes — so the review of the branch sits inside
the commit phase rather than after it. That is why the chain above steps
straight from the commit to the change request. `/code-review` is yours to run
whenever a broader pass is worth it, and the nudge points it at
`/anchor:prepare-review` when you do.

## What absence costs, and what replaces it

**Without tack.** The envelope is the work the route-opening does: the linked
thread read in full, one slug, a branch, and a record the session's deliverable
lands on. None of that needs a plugin — it needs doing. Read the thread and
every comment on it in one pass, cut a branch named for the work, and at the
close state what landed and what is still owed. The part that genuinely goes
away is the durable record across sessions; say so rather than implying the
close was equivalent.

**Without anchor.** The commit, the change request, the merge and the release
are ordinary forge operations. Write the commit message and the change-request
description leading with *why* — the root cause for a fix, the constraint that
decided the shape for a feature — and open the change request as a draft. What
anchor supplies beyond the mechanics is the drafting discipline and the review
guide; a hand-rolled `gh pr create --body` lands the change request non-draft
with the project template's checklist intact, so at minimum mark it draft.

Two things go with it. The commit's review gate is one: read the pending
changeset yourself, file by file, before committing — `/code-review` over the
branch covers the same ground, and a launched diff viewer is not evidence
anything was read. The line after the commit is the other, since it is keyed to
an announcement only anchor makes; say what the commit's state calls for
yourself, which on a feature branch is the change request and on the default
branch is the release or the close.

## Naming a command the user may not have

The nudge names the command either way. A suggestion for a plugin that isn't
installed reads as a suggestion, which is all it ever was — and it tells the
user the phase exists, which is the half of the sequencer mate is here to keep.
What it must never do is stall on the absence or run something in its place.
