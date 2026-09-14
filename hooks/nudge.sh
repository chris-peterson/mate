#!/usr/bin/env bash
# The nudge: one line naming the phase after the one just entered.
#
# mate replaces the forward pressure a retired sequencer used to carry, and only
# that half — the line says what comes next and stops there. The user types the
# next command, or doesn't.
#
# A skill invocation arrives in two shapes and this reads both:
#   - the agent invokes it -> PostToolUse, tool_name "Skill", name in
#     .tool_input.skill
#   - the user types /name -> UserPromptSubmit, no tool call at all; the typed
#     command heads .prompt
# Registering only the first is inert for everything a human types, which is
# most of what these phases see.
#
# Stdout is injected into the agent's context, so every path that isn't a match
# prints nothing and exits 0.

set -euo pipefail

input=$(cat)

# One jq pass, with nothing piped downstream of it: a `head -n 1` reading a
# pasted stack trace closes the pipe early, and under `pipefail` the SIGPIPE
# that follows takes the hook down before it reaches the case.
#
# The typed form is anchored at the start of the first line, so a prompt that
# mentions a command mid-sentence doesn't match; the character class is greedy,
# so `/fixture` resolves to `fixture` rather than matching a `fix` prefix.
skill=$(printf '%s' "$input" | jq -r '
  (.tool_input.skill // "") as $s
  | if $s != "" then $s
    else ((.prompt // "")
          | split("\n")[0]
          | [scan("^[[:space:]]*/([A-Za-z0-9:_-]+)")] | .[0][0] // "")
    end' 2>/dev/null || true)

[ -n "$skill" ] || exit 0

# Bare names are taken only where the bare form is the one this suite actually
# uses: `code-review` is invoked bare, and `fix`/`feature` are mate's own, so a
# collision lands on a skill that wants this nudge anyway. `start`, `end`,
# `commit`, `merge` and `release` are generic enough that a stranger's skill
# would draw a nudge about a pipeline it has nothing to do with, and each of
# them is namespaced in every install that has it.
case "$skill" in
  tack:start)
    url=$(printf '%s' "$input" | jq -r '(.prompt // "") | [scan("https://[^ )\n]+")] | .[0] // ""' 2>/dev/null || true)
    target=${url:-the linked issue}
    cat <<MSG
mate: this session is opening work on ${target}. Classify it yourself — read the
labels and the description and decide whether it is a defect (cause not yet
known) or a capability — then say in one line which skill fits:

  /mate:fix      a defect: root-cause it, prove it with a failing test, sweep
                 the bug class
  /mate:feature  a capability: gather the constraints, mirror the repo's
                 patterns, verify each against real feedback

Say which and why in one sentence. Do not invoke either one; the user types it.
MSG
    ;;
  mate:fix|fix|mate:feature|feature)
    cat <<'MSG'
mate: when this phase is done and the tree is green, the next step is
`/anchor:commit`. Name it in the wrap-up; don't run it.
MSG
    ;;
  anchor:commit)
    cat <<'MSG'
mate: with the commit pushed, the next step is `/code-review` over the branch.
Name it in the wrap-up; don't run it.
MSG
    ;;
  code-review)
    cat <<'MSG'
mate: once the review findings are settled, the next step is
`/anchor:prepare-review` to open the change request. Name it in the wrap-up;
don't run it.
MSG
    ;;
  anchor:prepare-review)
    cat <<'MSG'
mate: the change request opens as a draft, so the next step is `/anchor:review`
over your own change — the fixes land in the tree, nothing posts, and it ends by
offering to take the draft flag off. Name it in the wrap-up; don't run it.
MSG
    ;;
  anchor:review)
    cat <<'MSG'
mate: once the change request is out of draft and someone is looking at it, the
next step is `/anchor:merge`. Name it in the wrap-up; don't run it.
MSG
    ;;
  anchor:merge)
    cat <<'MSG'
mate: with the change merged, the next step is `/anchor:release` if this is
shippable on its own. Name it in the wrap-up; don't run it.
MSG
    ;;
  anchor:release)
    cat <<'MSG'
mate: with the release published, the close is `/tack:end`. Name it in the
wrap-up; don't run it.
MSG
    ;;
  *)
    exit 0
    ;;
esac
