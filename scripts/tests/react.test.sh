#!/usr/bin/env bash
# Synthetic-payload tests for hooks/react.sh. Every case here is a payload handed
# straight to the script, so a green run proves the matcher and says nothing
# about whether Claude Code delivers an announcement on `tool_response.stdout`.
# The live check (run a command that announces and watch for the line) is what
# settles delivery, and no run of this file substitutes for it.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HOOK="$SCRIPT_DIR/../../hooks/react.sh"
PASS=0; FAIL=0; TOTAL=0
RED='\033[0;31m'; GREEN='\033[0;32m'; NC='\033[0m'

# Each case gets its own session id and its own marker root, so the once-per-
# session guard never leaks from one case into the next.
TMPROOT="$(mktemp -d)"
trap 'rm -rf "$TMPROOT"' EXIT
SESSION_SEQ=0

# The hook answers in PostToolUse's JSON, so a case reads the text the agent
# receives. Output that isn't that JSON comes back marked, so it can't pass as
# silence or as a match.
run_hook() {
  local raw
  raw=$(TMPDIR="$TMPROOT" bash "$HOOK" 2>/dev/null || true)
  [ -n "$raw" ] || return 0
  printf '%s' "$raw" \
    | jq -er 'select(.hookSpecificOutput.hookEventName == "PostToolUse") | .hookSpecificOutput.additionalContext' 2>/dev/null \
    || echo NOT-CONTEXT
}

check() {
  local label="$1" expected="$2" result="$3"
  TOTAL=$((TOTAL + 1))
  case "$expected" in
    silent)
      if [ -z "$result" ]; then
        PASS=$((PASS + 1)); printf "  ${GREEN}PASS${NC}: %s\n" "$label"
      else
        FAIL=$((FAIL + 1)); printf "  ${RED}FAIL${NC}: %s (expected silence, got: %s)\n" "$label" "$result"
      fi ;;
    *)
      if printf '%s' "$result" | grep -qF -- "$expected"; then
        PASS=$((PASS + 1)); printf "  ${GREEN}PASS${NC}: %s\n" "$label"
      else
        FAIL=$((FAIL + 1)); printf "  ${RED}FAIL${NC}: %s (expected %s, got: %s)\n" "$label" "$expected" "$result"
      fi ;;
  esac
}

# Which line a commit.pushed draws turns on the repo's default branch, so the
# cases run against real checkouts rather than a stubbed answer: $REPO has an
# `origin/HEAD`, $NOHEAD is the clone that never got one.
REPO="$TMPROOT/repo"
NOHEAD="$TMPROOT/nohead"
mkdir -p "$REPO" "$NOHEAD"
git -C "$REPO" init -q
git -C "$REPO" symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/main
git -C "$NOHEAD" init -q

# A Bash tool call whose stdout carries whatever the case is testing, run as the
# named session in the named checkout ($REPO when none is given).
react_as() {
  jq -nc --arg o "$1" --arg s "$2" --arg c "${3:-$REPO}" \
    '{session_id:$s,cwd:$c,tool_name:"Bash",tool_response:{stdout:$o}}' \
    | run_hook
}

# The same, as a session no other case has used. The id is minted here rather
# than inside `react_as`, which runs in a command substitution, where an
# increment would be discarded with the subshell.
stdout_case() {
  SESSION_SEQ=$((SESSION_SEQ + 1))
  check "$1" "$2" "$(react_as "$3" "sess-$SESSION_SEQ" "${4:-$REPO}")"
}

# Passes when the needle is absent: the grep output is the result, so "silent"
# means the line never said it.
stdout_absent_case() {
  SESSION_SEQ=$((SESSION_SEQ + 1))
  check "$1" silent "$(react_as "$3" "sess-$SESSION_SEQ" "${4:-$REPO}" | grep -F -- "$2" || true)"
}

# One commit.pushed announcement, in the shape anchor's scripts/commit.sh emits.
pushed() {
  jq -rn --arg b "$1" --arg s "${2:-abc1234}" \
    '"codes.bridgeai.anchor/commit.pushed " + ({uri:"https://github.com/o/r/commit/\($s)",sha:$s,branch:$b} | tojson)'
}

STARTED='codes.bridgeai.tack/session.started {"route":"acme-widget"}'
STARTED_TAB=$(printf 'codes.bridgeai.tack/session.started\t{"route":"acme-widget"}')
READY='codes.bridgeai.anchor/cr.ready {"uri":"https://github.com/o/r/pull/88"}'
READY_TAB=$(printf 'codes.bridgeai.anchor/cr.ready\t{"uri":"https://github.com/o/r/pull/88"}')

echo "=== react tests ==="

echo ""
echo "Starts the work tack opened:"
stdout_case "has the agent start it"     "invoke that skill"          "$STARTED"
stdout_case "names the defect skill"     "/mate:fix"                  "$STARTED"
stdout_case "names the capability skill" "/mate:feature"              "$STARTED"
stdout_case "names the route"            "route \`acme-widget\`"      "$STARTED"
stdout_case "no route field"             "bound this session to its route" \
  'codes.bridgeai.tack/session.started {}'
stdout_case "defers to a running skill"  "If you are already"         "$STARTED"
stdout_case "can decline"                "If neither fits"            "$STARTED"
stdout_case "a tab still carries it"     "route \`acme-widget\`"      "$STARTED_TAB"
stdout_case "announcement among output"  "invoke that skill" \
  "$(printf '[ ] t1: Initial implementation\n%s\n' "$STARTED")"

echo ""
echo "Only for the session that ran the bind, once:"
check "its own session speaks" "invoke that skill" \
  "$(react_as 'codes.bridgeai.tack/session.started {"session":"sess-own","route":"r"}' sess-own)"
check "another session's bind is silent" silent \
  "$(react_as 'codes.bridgeai.tack/session.started {"session":"sess-other","route":"r"}' sess-mine)"
check "and doesn't spend the slot" "invoke that skill" \
  "$(react_as 'codes.bridgeai.tack/session.started {"session":"sess-mine","route":"r"}' sess-mine)"
check "second bind is silent" silent \
  "$(react_as 'codes.bridgeai.tack/session.started {"session":"sess-mine","route":"r"}' sess-mine)"
stdout_case "body that won't parse"      silent 'codes.bridgeai.tack/session.started {"route":'
stdout_case "body that isn't an object"  silent 'codes.bridgeai.tack/session.started 42'
stdout_case "longer key, same prefix"    silent 'codes.bridgeai.tack/session.startedish {"route":"acme-widget"}'

echo ""
echo "Names the step after the commit, which is the step after a review:"
stdout_case "feature branch -> prepare" "/anchor:prepare-review"  "$(pushed feature-x)"
stdout_case "carries the sha"          "abc1234"                 "$(pushed feature-x)"
stdout_case "carries the branch"       "feature-x"               "$(pushed feature-x)"
stdout_case "says the diff was read"   "already been read"       "$(pushed feature-x)"
stdout_case "hands-off"                "don't run it"            "$(pushed feature-x)"

echo ""
echo "Never names a second review of a changeset commit already gated on:"
stdout_absent_case "no /code-review"   "/code-review"            "$(pushed feature-x)"
stdout_absent_case "no /anchor:review" "/anchor:review"          "$(pushed feature-x)"

echo ""
echo "A commit on the default branch has no branch to review and no CR to open:"
stdout_case "names the close"          "/tack:end"               "$(pushed main)"
stdout_case "offers the release"       "/anchor:release"         "$(pushed main)"
stdout_absent_case "no CR to open"     "/anchor:prepare-review"  "$(pushed main)"
stdout_case "says why there is none"   "no change request to open" "$(pushed main)"

echo ""
echo "Names no next step where the branch can't be placed against a default:"
stdout_case "no origin/HEAD"           silent "$(pushed feature-x)" "$NOHEAD"
stdout_case "no branch field"          silent 'codes.bridgeai.anchor/commit.pushed {"sha":"abc1234"}'
stdout_case "no sha field"             silent 'codes.bridgeai.anchor/commit.pushed {"branch":"feature-x"}'

# The guard is per changeset, so an amend's new sha is a new line while the same
# sha announced twice is one.
check "first push speaks"  "abc1234" "$(react_as "$(pushed feature-x abc1234)" sess-pushed)"
check "same sha is silent" silent    "$(react_as "$(pushed feature-x abc1234)" sess-pushed)"
check "an amend speaks"    "def5678" "$(react_as "$(pushed feature-x def5678)" sess-pushed)"

echo ""
echo "Names what the change request still needs:"
stdout_case "carries the CR url"       "https://github.com/o/r/pull/88" "$READY"
stdout_case "asks for a reviewer"      "a reviewer"                     "$READY"
stdout_case "asks for the pipeline"    "the pipeline"                   "$READY"
stdout_case "a tab still carries it"   "https://github.com/o/r/pull/88" "$READY_TAB"
stdout_case "empty body still speaks"  "the change request"             'codes.bridgeai.anchor/cr.ready {}'
stdout_case "hands-off"                "don't"                          "$READY"
stdout_absent_case "no merge line"     "/anchor:merge"                  "$READY"
check "first ready speaks"     "ready for eyes that aren't yours" "$(react_as "$READY" sess-repeat)"
check "second ready is silent" silent                             "$(react_as "$READY" sess-repeat)"

echo ""
echo "Hands every line over at once:"
check "kick-off and push together" "/anchor:prepare-review" \
  "$(react_as "$(printf '%s\n%s\n' "$STARTED" "$(pushed feature-x)")" sess-both)"

echo ""
echo "Silent on everything else:"
stdout_case "a key mate doesn't take"  silent 'codes.bridgeai.anchor/cr.created {"uri":"https://github.com/o/r/pull/88"}'
stdout_case "longer key, same prefix"  silent 'codes.bridgeai.anchor/cr.readyish {"uri":"https://x/1"}'
stdout_case "mid-line mention"         silent "about to emit $READY"
stdout_case "no announcement"          silent 'PUSHED=ok'
stdout_case "empty stdout"             silent ''
check "no session id" silent \
  "$(jq -nc --arg o "$READY" '{tool_name:"Bash",tool_response:{stdout:$o}}' | run_hook)"
check "not JSON" silent "$(printf 'not json' | run_hook)"

echo ""
echo "========================================="
if [ "$FAIL" -eq 0 ]; then
  printf "Results: ${GREEN}%d passed${NC}, %d failed out of %d\n" "$PASS" "$FAIL" "$TOTAL"
else
  printf "Results: %d passed, ${RED}%d failed${NC} out of %d\n" "$PASS" "$FAIL" "$TOTAL"
fi
echo "========================================="
[ "$FAIL" -eq 0 ]
