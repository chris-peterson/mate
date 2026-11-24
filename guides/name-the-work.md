# Name the work

`/mate:fix` and `/mate:feature` are often invoked with nothing but an issue
number. Whatever the session prints about that issue outlives the turn: the
user scrolls back to it, copies it into a channel, and beacon's sessions view
shows a label for it beside every other session. A label or a reference that
can't be followed sends the user to look it up again by hand.

## Link the issue, never echo the number

Resolve a bare `<n>` or `#<n>` against the origin remote before saying anything
about it:

| Forge | Lookup |
| --- | --- |
| GitHub | `gh api 'repos/{owner}/{repo}/issues/<n>' --jq .html_url` |
| GitLab | `glab issue view <n> --output json \| jq -r .web_url` |

From then on, write the issue as a markdown link, `[#<n>](<url>)`. The terminal
renders it as an OSC 8 hyperlink: the number stays the text, and a click opens
the issue. A bare `#<n>` names no repo, so anything that picks it up from the
console later is left with text that points nowhere.

## Give the session its headline

Once the issue is read, label the session in beacon with the subject of the
work, a few words taken from the issue's title. Until then the sessions view
falls back to the command that opened the session, and `Mate feature 142` tells
the user nothing about which window holds which work.

- **Only when beacon's rules are loaded.** beacon is optional for mate; its
  rules name the `beacon set task` command to run.
- **Not when a tack route is bound.** tack supplies the label for a session it
  drives.
- **The subject, not the reference.** beacon's task is plain text, so a number
  there would be an unlinked literal. Write `<a few words on what the issue is
  about>`, not `#<n>` or the command.
