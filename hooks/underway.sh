#!/usr/bin/env bash
# The binding check: once a session starts changing files in a repo, press for
# tack to hear which work it is.
#
# A session that opened with `/tack:start`, `/mate:fix` or `/mate:feature` has
# told tack already. One that started from a plain prompt reaches its first edit
# with tack told nothing, or told only the route its prompt hook guessed from
# the branch or project name — and the tack the session drives is the half tack
# leaves to the agent. The first edit inside the repo is the earliest point the
# session is plainly work rather than a question, so that is where this speaks.
#
# What tack has heard is read off its own announcement, never off its store:
# react.sh marks the session when `codes.bridgeai.tack/session.started` crosses
# a Bash call, and this hook stays quiet on that mark. tack's prompt hook binds
# with announcing switched off, so a route it guessed still draws the line.
#
# Unlike the nudge, this line asks for the binding to be done rather than named.
# Binding is bookkeeping on the record the work already lives in, not a phase of
# the chain, and tack's own route guide asks for it as early as the agent can.
#
# Stdout is injected into the agent's context, so every path that isn't a match
# prints nothing and exits 0.

set -euo pipefail

input=$(cat)

# One jq pass decides whether the edit landed under the session's cwd, which is
# what keeps scratchpad and settings writes from reading as work in this repo.
fields=$(printf '%s' "$input" | jq -r '
  (.tool_input.file_path // .tool_input.notebook_path // "") as $p
  | (.cwd // "") as $c
  | (.session_id // "") as $s
  | select($s != "" and $c != "" and ($p | startswith($c + "/")))
  | [$s, $c] | @tsv' 2>/dev/null || true)
[ -n "$fields" ] || exit 0

session_id=${fields%%$'\t'*}
cwd=${fields#*$'\t'}
marker=${session_id//[^A-Za-z0-9._-]/_}
state="${TMPDIR:-/tmp}"

[ -f "$state/mate-tack-heard/$marker" ] && exit 0
[ -f "$state/mate-tack-underway/$marker" ] && exit 0

toplevel=$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null || true)
[ -n "$toplevel" ] || exit 0

mkdir -p "$state/mate-tack-underway"
find "$state/mate-tack-underway" -type f -mtime +7 -delete 2>/dev/null || true
touch "$state/mate-tack-underway/$marker"

msg=$(cat <<MSG
mate: this session is changing files in ${toplevel##*/} and tack hasn't heard
which work it is. Record it before the next edit:

  a route resolves   the prompt hook named it, or \`tack find --path --json\`
                     finds it. Bind the tack this session drives:
                     tack session <slug> ${session_id} --tack <id>
                     running \`tack add <slug> "<summary>"\` first when no
                     open tack fits
  nothing resolves   ask the user whether to run \`/tack:start\`, which opens a
                     route and cuts a branch for the work

Skip it only for an edit this session won't commit.
MSG
)

# A PostToolUse hook's plain stdout lands in the transcript, not the agent's
# context; only additionalContext reaches the model.
jq -nc --arg m "$msg" \
  '{hookSpecificOutput:{hookEventName:"PostToolUse",additionalContext:$m}}'
