#!/usr/bin/env bash
# Synthetic-payload tests for hooks/nudge.sh. Every case here is a payload handed
# straight to the script, so a green run proves the matcher and says nothing
# about whether Claude Code delivers that payload on that event. The live check
# — type the command in a session and watch for the line — is what settles
# delivery, and no run of this file substitutes for it.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HOOK="$SCRIPT_DIR/../../hooks/nudge.sh"
PASS=0; FAIL=0; TOTAL=0
RED='\033[0;31m'; GREEN='\033[0;32m'; NC='\033[0m'

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

# The agent invoked it: a Skill tool call. The line has to arrive as
# PostToolUse additionalContext to reach the agent, so a case reads that text,
# and output in any other shape comes back marked rather than passing.
skill_case() {
  local raw
  raw=$(jq -nc --arg s "$3" '{tool_name:"Skill",tool_input:{skill:$s}}' | bash "$HOOK" 2>/dev/null || true)
  if [ -n "$raw" ]; then
    raw=$(printf '%s' "$raw" \
      | jq -er 'select(.hookSpecificOutput.hookEventName == "PostToolUse") | .hookSpecificOutput.additionalContext' 2>/dev/null \
      || echo NOT-CONTEXT)
  fi
  check "$1" "$2" "$raw"
}

# The user typed it: no tool call, the prompt is the whole event.
prompt_case() {
  check "$1" "$2" \
    "$(jq -nc --arg p "$3" '{prompt:$p}' | bash "$HOOK" 2>/dev/null || true)"
}

echo "=== nudge tests ==="

echo ""
echo "Names the next phase when the agent invokes a phase skill:"
skill_case "backlog -> start"             "/tack:start <issue-url>" "anchor:backlog"
skill_case "fix -> commit"                "/anchor:commit"         "mate:fix"
skill_case "feature -> commit"            "/anchor:commit"         "mate:feature"
skill_case "code review -> prepare"       "/anchor:prepare-review" "code-review"
skill_case "prepare -> self-review"       "/anchor:review"         "anchor:prepare-review"
skill_case "review -> merge"              "/anchor:merge"          "anchor:review"
skill_case "merge -> release"             "/anchor:release"        "anchor:merge"
skill_case "release -> close"             "/tack:end"              "anchor:release"

echo ""
echo "Names the next phase when the user types it:"
prompt_case "typed backlog"               "/tack:start <issue-url>" "/anchor:backlog"
prompt_case "typed backlog with a query"  "/tack:start <issue-url>" "/anchor:backlog anything due soon?"
prompt_case "typed mate:fix"              "/anchor:commit"         "/mate:fix"
prompt_case "bare fix"                    "/anchor:commit"         "/fix the flaky test"
prompt_case "bare feature"                "/anchor:commit"         "/feature add retries"
prompt_case "bare code-review"            "/anchor:prepare-review" "/code-review"
prompt_case "leading whitespace"          "/anchor:commit"         "  /mate:fix"
prompt_case "trailing lines"              "/anchor:commit"         "/mate:fix
and then tell me what you found"
# Built in a file rather than through `prompt_case`: Linux caps a single argv
# entry at 128 KB, so a payload this size can't reach jq as `--arg`. The hook
# reads it off stdin, which has no such cap.
trace=$(mktemp)
printf '/mate:fix\n' > "$trace"
yes '  at Foo.Bar(x) in /src/foo.cs:line 42' 2>/dev/null | head -n 5000 >> "$trace"
check "a pasted trace after it" "/anchor:commit" \
  "$(jq -nc --rawfile p "$trace" '{prompt:$p}' | bash "$HOOK" 2>/dev/null || true)"
rm -f "$trace"

echo ""
echo "Never sequences — every nudge says not to run the next step:"
skill_case "fix nudge is hands-off"       "don't run it" "mate:fix"
skill_case "backlog waits for the pick"   "don't run it until the user picks" "anchor:backlog"

echo ""
echo "Leaves opening the envelope to react.sh, which hears tack's session.started:"
skill_case "tack:start, agent-invoked"    silent "tack:start"
prompt_case "tack:start, typed"           silent "/tack:start https://github.com/o/r/issues/42"

echo ""
echo "Leaves the commit phase to react.sh, which sees what the commit did:"
# Entering the commit phase says nothing about how it ends, so the line that
# follows a commit comes from `commit.pushed` in react.test.sh instead.
skill_case "commit, agent-invoked"        silent "anchor:commit"
prompt_case "commit, typed"               silent "/anchor:commit"

echo ""
echo "Silent on everything else:"
skill_case "unrelated skill"              silent "docsify"
skill_case "tack:end ends the chain"      silent "tack:end"
skill_case "no skill field"               silent ""
prompt_case "mid-sentence mention"        silent "remind me to run /mate:fix later"
prompt_case "longer name, same prefix"    silent "/fixtures"
prompt_case "generic bare start"          silent "/start"
prompt_case "generic bare release"        silent "/release"
prompt_case "generic bare backlog"        silent "/backlog"
prompt_case "plain prose"                 silent "why is the build red"
prompt_case "empty prompt"                silent ""

echo "========================================="
printf "Results: ${GREEN}%s passed${NC}, ${RED}%s failed${NC} out of %s\n" "$PASS" "$FAIL" "$TOTAL"
echo "========================================="

[ "$FAIL" -eq 0 ]
