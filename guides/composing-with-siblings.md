# Composing with the siblings

mate joins the phases [anchor](https://github.com/chris-peterson/anchor) and
[tack](https://github.com/chris-peterson/tack) supply, and declares both as
dependencies, so Claude Code installs them with it. This is the map of who
supplies what.

## The chain

| Phase | Command | Supplied by |
|---|---|---|
| Pick the work | `/mate:next`, which runs `/anchor:backlog` | mate, with anchor |
| Open the envelope | `/tack:start [url]` | tack |
| Make the change | `/mate:fix`, `/mate:feature` | mate |
| Commit and push | `/anchor:commit` | anchor |
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

The link between the envelope and the skill is the one the agent crosses on its
own, in either direction. `/mate:feature 42` already names the work, so the
skill invokes `/tack:start` for it rather than asking for the same reference a
second time. `/tack:start 42` already asks for the work, so when tack announces
`session.started` for the session it just bound, `react.sh` has the agent
classify the work and invoke `/mate:fix` or `/mate:feature`. Opening the
envelope and starting the work are one request; every link after the skill
stays a line the user acts on or ignores.

Work that never opened the envelope still has to reach tack. `underway.sh`
speaks on the first edit inside the repo, and `react.sh` again on the first
push, each asking the agent to bind the session to a tack until tack announces
`session.started` for it. Binding is a record of work already happening rather
than a phase, so these lines ask for it to be done.

`/anchor:commit` gates on its own review of the pending changeset — only an
approved verdict commits and pushes — so the review of the branch sits inside
the commit phase rather than after it. That is why the chain above steps
straight from the commit to the change request. `/code-review` is yours to run
whenever a broader pass is worth it, and the nudge points it at
`/anchor:prepare-review` when you do.
