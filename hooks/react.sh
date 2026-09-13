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
# Only `cr.ready` is read. Of everything anchor publishes it is the one key
# neither of the other two paths reaches: nudge.sh already names the phase after
# the skill that emits the rest, and tack records cr.created, cr.updated,
# cr.merged, issue.created and release.created on the route. cr.ready is also
# the first moment the CR is a thing to hand to somebody — a draft has a URL but
# nobody to send it to.
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

uri=$(printf '%s' "${line#* }" | jq -r '.uri // empty' 2>/dev/null || true)
target=${uri:-the change request}

# Once per session: a CR marked ready twice is still one handoff.
marker_dir="${TMPDIR:-/tmp}/mate-cr-ready"
mkdir -p "$marker_dir"
marker="${marker_dir}/${session_id}"
[ -f "$marker" ] && exit 0
touch "$marker"

cat <<MSG
mate: ${target} is out of draft, so it is ready for eyes that aren't yours.
Before naming the next phase, say in one line what it still needs:

  a reviewer     assign one, or hand the URL to whoever should look
  the pipeline   report where it stands rather than waiting to be asked

After that the next phase is \`/anchor:merge\`. Name it in the wrap-up; don't
run it.
MSG
