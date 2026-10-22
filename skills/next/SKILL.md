---
name: next
description: Pick the next piece of work and put it one confirmation away from started. Surveys the issues assigned to you, recommends the top one, and offers the command that opens it. Triggers on "what's next?", "what should I work on?", "pull the next issue".
argument-hint: "[query]"
---

# Next

Find the work to pick up and leave it one confirmation away from started: survey what's filed, recommend the top pick, offer the command that opens it, and start nothing until the user says which.

**Skip this skill when** the user already named the work (`/tack:start 42` and `/mate:fix 42` open it directly), or when the question is about the backlog itself (counts, triage, closing stale issues) rather than choosing what to work on.

## Survey

Invoke `/anchor:backlog` with the user's query passed through. It resolves the scope, ranks by due date and then recent activity, and recommends the top pick. Keep its order: re-ranking it here gives the user two answers to one question.

An empty list ends the skill: say so, and offer to widen the scope rather than starting anything.

## Offer, then wait

End the reply by offering `/tack:start <issue-url>` for the pick, with its URL filled in. mate's line on tack's `session.started`, which `/tack:start` draws, classifies the work and runs `/mate:fix` or `/mate:feature`.

Ask whether to start that one or another, and run nothing until the user picks. Starting cuts a branch and opens a route, and the survey only answered "what's next?", so the choice stays the user's. When the user names a different issue, offer the same command for that one.

Once the user picks, invoke the command for the chosen issue and carry on with it.
