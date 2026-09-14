#!/usr/bin/env bash
# The reaction: one line naming what a change request still needs, keyed off
# what anchor announces rather than off which skill the user ran.
#
# The suite's plugins collaborate by printing one self-contained line on stdout,
# which reaches this hook as `tool_response.stdout`:
#
#   codes.bridgeai.anchor/cr.ready {"uri":"https://github.com/o/r/pull/88"}
#
# The grammar and the publishing rules are the suite's interop contract:
# https://github.com/chris-peterson/claude-marketplace/blob/main/authoring/plugin-contract.md
#
# Only `cr.ready` is read, and only for what a skill-name match cannot supply:
# the CR's URL, and the moment it becomes a thing to hand to somebody. Naming
# the phase after this one is nudge.sh's `anchor:review` case, so this line
# stops at the handoff. tack records cr.created, cr.updated, cr.merged,
# issue.created and release.created on the route.
#
# Matching what anchor says rather than the shape of the command it ran is what
# lets anchor change forge CLIs without silently taking this line out.
#
# Stdout is injected into the agent's context, so every path that isn't a match
# prints nothing and exits 0.

set -euo pipefail

input=$(cat)

session_id=$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null || true)
[ -n "$session_id" ] || exit 0

output=$(printf '%s' "$input" | jq -r '.tool_response.stdout // empty' 2>/dev/null || true)

# Anchored at the start of a line and followed by whitespace, so a command that
# merely mentions the key — an echo, a grep for it, this comment in a diff —
# doesn't fire, and `cr.readyish` never matches `cr.ready`.
line=$(printf '%s' "$output" \
  | grep -E '^codes\.bridgeai\.anchor/cr\.ready[[:space:]]' \
  | head -n 1 || true)
[ -n "$line" ] || exit 0

# The separator is whatever whitespace the publisher used; a tab is as valid as
# a space and drops the URL if the key is stripped on spaces alone.
body=$(printf '%s' "$line" | sed 's|^[^[:space:]]*[[:space:]]*||')
uri=$(printf '%s' "$body" | jq -r '.uri // empty' 2>/dev/null || true)
target=${uri:-the change request}

# Once per session: a CR marked ready twice is still one handoff. These markers
# are the only thing mate leaves outside the agent's context, so they expire.
marker_dir="${TMPDIR:-/tmp}/mate-cr-ready"
mkdir -p "$marker_dir"
find "$marker_dir" -type f -mtime +7 -delete 2>/dev/null || true
marker="${marker_dir}/${session_id//[^A-Za-z0-9._-]/_}"
[ -f "$marker" ] && exit 0
touch "$marker"

cat <<MSG
mate: ${target} is out of draft, so it is ready for eyes that aren't yours. Say
in one line what it still needs:

  a reviewer     assign one, or hand the URL to whoever should look
  the pipeline   report where it stands rather than waiting to be asked

Say it in the wrap-up; don't act on it.
MSG
