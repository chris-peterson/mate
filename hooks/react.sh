#!/usr/bin/env bash
# The reaction: one line naming what comes next, keyed off what anchor announces
# rather than off which skill the user ran.
#
# The suite's plugins collaborate by printing one self-contained line on stdout,
# which reaches this hook as `tool_response.stdout`:
#
#   codes.bridgeai.anchor/cr.ready {"uri":"https://github.com/o/r/pull/88"}
#
# The grammar and the publishing rules are the suite's interop contract:
# https://github.com/chris-peterson/claude-marketplace/blob/main/authoring/plugin-contract.md
#
# Two keys are read, each for something a skill-name match cannot supply.
#
# `commit.pushed` carries the sha and the branch, and it is announced only once
# the push has landed — which is downstream of `/anchor:commit`'s own review of
# the pending changeset, where only an `approved` verdict commits and pushes. The
# announcement is therefore the evidence that the changeset was read, so the line
# names the step after review rather than another review of it. The branch decides
# the wording: a commit on the default branch has no change request to open, and
# naming one the session can't open reads as the flow having gone wrong.
#
# `cr.ready` carries the change request's URL and the moment it becomes a thing
# to hand to somebody. Naming the phase after that one is nudge.sh's
# `anchor:review` case, so that line stops at the handoff. tack records
# cr.created, cr.updated, cr.merged, issue.created and release.created on the
# route.
#
# Matching what anchor says rather than the shape of the command it ran is what
# lets anchor change forge CLIs without silently taking these lines out.
#
# Stdout is injected into the agent's context, so every path that isn't a match
# prints nothing and exits 0.

set -euo pipefail

input=$(cat)

session_id=$(printf '%s' "$input" | jq -r '.session_id // empty' 2>/dev/null || true)
[ -n "$session_id" ] || exit 0

output=$(printf '%s' "$input" | jq -r '.tool_response.stdout // empty' 2>/dev/null || true)
[ -n "$output" ] || exit 0

# The JSON body of one announcement, or nothing when that key wasn't announced.
#
# Anchored at the start of a line and followed by whitespace, so a command that
# merely mentions a key — an echo, a grep for it, this comment in a diff —
# doesn't fire, and `cr.readyish` never matches `cr.ready`. The separator is
# whatever whitespace the publisher used; a tab is as valid as a space, and
# drops the body if the key is stripped on spaces alone.
announced() {
  local line
  line=$(printf '%s' "$output" \
    | grep -E "^codes\.bridgeai\.anchor/$1[[:space:]]" \
    | head -n 1 || true)
  [ -n "$line" ] || return 0
  printf '%s' "$line" | sed 's|^[^[:space:]]*[[:space:]]*||'
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

body=$(announced 'commit\.pushed')
if [ -n "$body" ]; then
  sha=$(printf '%s' "$body" | jq -r '.sha // empty' 2>/dev/null || true)
  branch=$(printf '%s' "$body" | jq -r '.branch // empty' 2>/dev/null || true)

  # Which line applies turns on whether this is the default branch, so a repo
  # whose `origin/HEAD` doesn't resolve gets neither: on a commit that landed
  # directly on the default branch, the feature-branch line names a change
  # request nobody can open.
  cwd=$(printf '%s' "$input" | jq -r '.cwd // empty' 2>/dev/null || true)
  default=$(git -C "${cwd:-.}" symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null || true)
  default=${default#origin/}

  # Per changeset rather than per session: an amend force-pushes under a new sha
  # and is a new changeset to say something about, while the same sha announced
  # twice is one.
  if [ -n "$sha" ] && [ -n "$branch" ] && [ -n "$default" ] \
    && claim commit-pushed "${session_id}-${sha}"; then
    if [ "$branch" = "$default" ]; then
      cat <<MSG
mate: ${sha} landed on ${branch}, so there is no change request to open.
If this is shippable on its own the next step is \`/anchor:release\`; otherwise
the close is \`/tack:end\`. Name it in the wrap-up; don't run it.
MSG
    else
      cat <<MSG
mate: ${sha} is pushed to ${branch}.
\`/anchor:commit\` commits only on an approved review, so this changeset has
already been read once — the next step is \`/anchor:prepare-review\` to open the
change request. Name it in the wrap-up; don't run it.
MSG
    fi
  fi
fi

body=$(announced 'cr\.ready')
if [ -n "$body" ]; then
  uri=$(printf '%s' "$body" | jq -r '.uri // empty' 2>/dev/null || true)
  target=${uri:-the change request}

  # Once per session: a change request marked ready twice is still one handoff.
  if claim cr-ready "$session_id"; then
    cat <<MSG
mate: ${target} is out of draft, so it is ready for eyes that aren't yours. Say
in one line what it still needs:

  a reviewer     assign one, or hand the URL to whoever should look
  the pipeline   report where it stands rather than waiting to be asked

Say it in the wrap-up; don't act on it.
MSG
  fi
fi

exit 0
