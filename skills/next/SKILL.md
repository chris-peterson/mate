---
name: next
description: Pick the next piece of work and put it one confirmation away from started. Surveys the issues assigned to you, recommends the top one, and offers the command that opens it. Triggers on "what's next?", "what should I work on?", "pull the next issue".
argument-hint: "[query]"
---

# Next

Find the work to pick up and leave it one confirmation away from started: survey what's filed, recommend the top pick, offer the command that opens it, and start nothing until the user says which.

**Skip this skill when** the user already named the work (`/tack:start 42` and `/mate:fix 42` open it directly), or when the question is about the backlog itself (counts, triage, closing stale issues) rather than choosing what to work on.

## Survey

Where [anchor](https://github.com/chris-peterson/anchor) is installed, invoke `/anchor:backlog` with the user's query passed through. It resolves the scope, ranks by due date and then recent activity, and recommends the top pick. Keep its order: re-ranking it here gives the user two answers to one question.

Where anchor isn't installed, survey with the forge CLI picked from the `origin` remote:

- **Fetch** the open issues assigned to the user: `gh issue list --assignee @me --state open --json number,title,url,updatedAt,milestone,labels`, or `glab issue list --assignee=@me --output json`. Widen the scope only where the query asks for it ("everything open", "unassigned").
- **Rank** soonest due first, then most recently updated. A GitHub issue's due date is its milestone's `dueOn`; a GitLab issue carries its own `due_date`. Undated issues sort after dated ones.
- **Show** number, title, due, updated, and labels, and name the top pick with the reason it's first.

An empty list ends the skill: say so, and offer to widen the scope rather than starting anything.

## Offer, then wait

End the reply by offering to start the pick, with its URL filled in:

- Where [tack](https://github.com/chris-peterson/tack) is installed: `/tack:start <issue-url>`. mate's nudge on it classifies the work and runs `/mate:fix` or `/mate:feature`.
- Where it isn't: `/mate:fix <issue-url>` for a defect whose cause isn't known yet, `/mate:feature <issue-url>` for a capability, chosen from the issue's labels and description.

Ask whether to start that one or another, and run nothing until the user picks. Starting cuts a branch and opens a route, and the survey only answered "what's next?", so the choice stays the user's. When the user names a different issue, offer the same command for that one.

Once the user picks, invoke the command for the chosen issue and carry on with it.
