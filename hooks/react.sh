#!/usr/bin/env bash
# The reaction: one line on what comes next, keyed off what tack and anchor
# announce rather than off which skill the user ran.
#
# The suite's plugins collaborate by printing one self-contained line on stdout,
# which reaches this hook as `tool_response.stdout`:
#
#   codes.bridgeai.tack/session.started {"session":"…","route":"acme-widget"}
#
# The grammar and the publishing rules are the suite's interop contract:
# https://github.com/chris-peterson/claude-marketplace/blob/main/authoring/plugin-contract.md
#
# Three keys are read, each for something a skill-name match cannot supply.
#
# `codes.bridgeai.tack/session.started` is tack saying it has opened work on a
# route. tack owns starting work, so mate listens for it rather than asking the
# user to call a mate command, and has the agent classify the work and start
# /mate:fix or /mate:feature. That is the one line here that invokes rather than
# names, because opening the envelope is asking for the work inside it. A bind
# the agent runs by hand announces it too.
#
# `commit.pushed` carries the sha and the branch, and it is announced only once
# the push has landed, which is downstream of `/anchor:commit`'s own review of
# the pending changeset, where only an `approved` verdict commits and pushes. The
# announcement is therefore the evidence that the changeset was read, so the line
# names the step after review rather than another review of it. The branch decides
# the wording: a commit on the default branch has no change request to open, and
# naming one the session can't open reads as the flow having gone wrong.
#
# `cr.ready` carries the change request's URL and the moment it becomes a thing
# to hand to somebody.
#
# A PostToolUse hook's plain stdout reaches the transcript and never the agent,
# so the lines are collected and handed over once, as additionalContext. Every
# path that isn't a match prints nothing and exits 0.
#
# Each line can be turned off, per publisher or per key, with
# `mate.subscribe.<publisher>` or `mate.subscribe.<publisher>.<entity>-<event>`
# set to false, read in the repository the command ran in, and each line ends
# with the command that does it. The subscriber rules these follow are the
# suite's, cited by ID:
# https://github.com/chris-peterson/claude-marketplace/blob/main/SPEC.md

set -euo pipefail

input=$(cat)

context=""
# say <publisher> <entity.event>: queue the line on stdin, ending it with the
# command that turns this subscription off (bridge.ai SWITCH-04).
say() {
  context="${context:+$context$'\n\n'}$(cat)
To turn this off: git config --global mate.subscribe.$1.${2//./-} false"
}

session_id=$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null || true)
[ -n "$session_id" ] || exit 0

output=$(printf '%s' "$input" | jq -r '.tool_response.stdout // empty' 2>/dev/null || true)
[ -n "$output" ] || exit 0
cwd=$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null || true)

# Whether the user left this subscription on (bridge.ai SWITCH-01..03): off when
# the publisher's switch or the key's reads false in the repository the command
# ran in, which a repository's own value decides over the global one.
subscribed() {
  local name value
  for name in "mate.subscribe.$1" "mate.subscribe.$1.${2//./-}"; do
    value=$(git -C "${cwd:-.}" config --type=bool --get "$name" 2>/dev/null) || continue
    [ "$value" = false ] && return 1
  done
  return 0
}

# One string field of a body, or nothing when it is absent or not a string
# (bridge.ai SUB-04), with C0, DEL and C1 control characters stripped, since
# the value is about to be placed in the agent's context (bridge.ai SUB-09).
field() {
  printf '%s' "$1" \
    | jq -r --arg f "$2" '.[$f] | strings | gsub("[\\x{0}-\\x{1f}\\x{7f}-\\x{9f}]"; "")' 2>/dev/null \
    || true
}

# announced <publisher> <entity.event>: the JSON body of the first announcement
# of that key, or nothing when it wasn't announced, its subscription is off, or
# no line carrying it has a body that parses as an object (bridge.ai SUB-03).
#
# Anchored at the start of a line and followed by whitespace, so a command that
# merely mentions a key (an echo, a grep for it, this comment in a diff)
# doesn't fire, and `cr.readyish` never matches `cr.ready`. The separator is
# whatever whitespace the publisher used; a tab is as valid as a space, and
# drops the body if the key is stripped on spaces alone.
#
# jq reads the whole output from a here-string rather than through a pipe into
# a reader that can stop early, so a long build log ahead of or behind the line
# can't lose it (bridge.ai SUB-08).
#
# The switch is read only once a key has matched, so deciding whether a Bash
# call is for mate stays within bash and jq (HOOK-03).
announced() {
  local body
  body=$(jq -Rcn --arg key "codes.bridgeai.$1/$2" 'first(inputs
    | select(startswith($key))
    | .[($key | length):]
    | select(test("^[[:space:]]"))
    | try fromjson catch null
    | objects)' <<<"$output" 2>/dev/null) || return 0
  [ -n "$body" ] && subscribed "$1" "$2" && printf '%s' "$body"
  return 0
}

# Claims a one-shot slot, failing when it was already taken. These markers are
# the only thing mate leaves outside the agent's context, so they expire.
claim() {
  local dir="${TMPDIR:-/tmp}/mate-$1" marker
  mkdir -p "$dir"
  find "$dir" -type f -mtime +7 -delete 2>/dev/null || true
  marker="$dir/${2//[^A-Za-z0-9._-]/_}"
  [ -f "$marker" ] && return 1
  touch "$marker"
}

# The announcement is for the session that ran the command, so a body naming a
# different one is a bind made on someone else's behalf. A body that isn't a
# JSON object isn't tack's announcement. Once per session: binding again, or
# binding a second tack, opens no new work.
body=$(announced tack session.started)
if [ -n "$body" ] \
  && for_session=$(printf '%s' "$body" | jq -er '.session // "" | strings' 2>/dev/null) \
  && { [ -z "$for_session" ] || [ "$for_session" = "$session_id" ]; } \
  && claim session-started "$session_id"; then
  route=$(field "$body" route)
  if [ -n "$route" ]; then where="route \`$route\`"; else where="its route"; fi
  say tack session.started <<MSG
mate: tack has bound this session to ${where}. Once the envelope is open,
classify the work yourself (read the labels and the description: a defect whose
cause isn't known yet, or a capability) and start it:

  /mate:fix      a defect: root-cause it, prove the fix against something that
                 failed before it, sweep the bug class
  /mate:feature  a capability: gather the constraints, mirror the repo's
                 patterns, verify each against real feedback

Say which and why in one sentence, then invoke that skill for the same work and
carry on with it. If neither fits, say so and start neither. If you are already
in /mate:fix or /mate:feature, carry on.
MSG
fi

body=$(announced anchor commit.pushed)
if [ -n "$body" ]; then
  sha=$(field "$body" sha)
  branch=$(field "$body" branch)

  # Which line applies turns on whether this is the default branch, so a repo
  # whose `origin/HEAD` doesn't resolve gets neither: on a commit that landed
  # directly on the default branch, the feature-branch line names a change
  # request nobody can open.
  default=$(git -C "${cwd:-.}" symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null || true)
  default=${default#origin/}

  # Per changeset rather than per session: an amend force-pushes under a new sha
  # and is a new changeset to say something about, while the same sha announced
  # twice is one.
  if [ -n "$sha" ] && [ -n "$branch" ] && [ -n "$default" ] \
    && claim commit-pushed "${session_id}-${sha}"; then
    if [ "$branch" = "$default" ]; then
      say anchor commit.pushed <<MSG
mate: ${sha} landed on ${branch}, so there is no change request to open.
If this is shippable on its own the next step is \`/anchor:release\`; otherwise
the close is \`/tack:end\`. Name it in the wrap-up; don't run it.
MSG
    else
      say anchor commit.pushed <<MSG
mate: ${sha} is pushed to ${branch}.
\`/anchor:commit\` commits only on an approved review, so this changeset has
already been read once. The next step is \`/anchor:prepare-review\` to open the
change request. Name it in the wrap-up; don't run it.
MSG
    fi
  fi
fi

body=$(announced anchor cr.ready)
if [ -n "$body" ]; then
  uri=$(field "$body" uri)
  target=${uri:-the change request}

  # Once per session: a change request marked ready twice is still one handoff.
  if claim cr-ready "$session_id"; then
    say anchor cr.ready <<MSG
mate: ${target} is out of draft, so it is ready for eyes that aren't yours. Say
in one line what it still needs:

  a reviewer     assign one, or hand the URL to whoever should look
  the pipeline   report where it stands rather than waiting to be asked

Say it in the wrap-up; don't act on it.
MSG
  fi
fi

if [ -n "$context" ]; then
  jq -nc --arg m "$context" \
    '{hookSpecificOutput:{hookEventName:"PostToolUse",additionalContext:$m}}'
fi

exit 0
