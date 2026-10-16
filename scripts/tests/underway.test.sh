#!/usr/bin/env bash
# Synthetic-payload tests for hooks/underway.sh. Every case here is a payload
# handed straight to the script, so a green run proves the matcher and says
# nothing about whether Claude Code delivers an Edit's PostToolUse to it. The
# live check, an edit in a session tack hasn't heard of, is what settles
# delivery, and no run of this file substitutes for it.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HOOK="$SCRIPT_DIR/../../hooks/underway.sh"
PASS=0; FAIL=0; TOTAL=0
RED='\033[0;31m'; GREEN='\033[0;32m'; NC='\033[0m'

TMPROOT="$(mktemp -d)"
trap 'rm -rf "$TMPROOT"' EXIT

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

# Whether the tack CLI is on PATH decides whether there is anyone to tell, so
# the hook runs on a PATH built from jq and git alone, with a stub in front for
# the cases where tack is installed.
NOTACK_PATH="$(dirname "$(command -v jq)"):$(dirname "$(command -v git)"):/usr/bin:/bin"
TACK_STUB="$TMPROOT/stub"
mkdir -p "$TACK_STUB"
printf '#!/bin/sh\nexit 0\n' > "$TACK_STUB/tack"
chmod +x "$TACK_STUB/tack"
HOOK_PATH="$TACK_STUB:$NOTACK_PATH"

REPO="$TMPROOT/widget"
PLAIN="$TMPROOT/plain"
mkdir -p "$REPO/src" "$PLAIN"
git -C "$REPO" init -q

# One file-writing tool call. The session id is passed in rather than minted
# here, since this runs in a command substitution and a counter would reset.
edit() {
  local session="$1" cwd="$2" path="$3" tool="${4:-Edit}" key=file_path
  [ "$tool" = NotebookEdit ] && key=notebook_path
  jq -nc --arg s "$session" --arg c "$cwd" --arg p "$path" --arg t "$tool" --arg k "$key" \
    '{session_id:$s,cwd:$c,tool_name:$t,tool_input:{($k):$p}}' \
    | run_hook
}

# The hook answers in PostToolUse's JSON, so a case reads the text the agent
# receives. Output that isn't that JSON comes back marked, so it can't pass as
# silence or as a match.
run_hook() {
  local raw
  raw=$(TMPDIR="$TMPROOT" PATH="$HOOK_PATH" bash "$HOOK" 2>/dev/null || true)
  [ -n "$raw" ] || return 0
  printf '%s' "$raw" \
    | jq -er 'select(.hookSpecificOutput.hookEventName == "PostToolUse") | .hookSpecificOutput.additionalContext' 2>/dev/null \
    || echo NOT-CONTEXT
}

echo "=== underway tests ==="

echo ""
echo "Presses for a binding on the first edit inside the repo:"
check "names the binding"      "tack session <slug> s1 --tack <id>" "$(edit s1 "$REPO" "$REPO/src/a.sh")"
check "names the repo"         "files in widget"                    "$(edit s2 "$REPO" "$REPO/src/a.sh")"
check "offers /tack:start"     "/tack:start"                        "$(edit s3 "$REPO" "$REPO/src/a.sh")"
check "a Write counts"         "tack session"                       "$(edit s4 "$REPO" "$REPO/b.md" Write)"
check "a NotebookEdit counts"  "tack session"                       "$(edit s5 "$REPO" "$REPO/n.ipynb" NotebookEdit)"

echo ""
echo "Once per session:"
edit s6 "$REPO" "$REPO/src/a.sh" >/dev/null
check "second edit is silent"  silent "$(edit s6 "$REPO" "$REPO/src/b.sh")"

echo ""
echo "Silent once tack has heard of the session:"
mkdir -p "$TMPROOT/mate-tack-heard"
touch "$TMPROOT/mate-tack-heard/s7"
check "heard session"          silent "$(edit s7 "$REPO" "$REPO/src/a.sh")"

echo ""
echo "Silent where the edit isn't work in this repo:"
check "outside the cwd"        silent "$(edit s8 "$REPO" "$TMPROOT/scratch.md")"
check "a sibling path prefix"  silent "$(edit s9 "$REPO" "${REPO}-other/a.sh")"
check "cwd isn't a repo"       silent "$(edit s10 "$PLAIN" "$PLAIN/a.sh")"
check "no session id"          silent "$(edit '' "$REPO" "$REPO/src/a.sh")"
check "not JSON"               silent "$(printf 'nope' | run_hook)"

# The skipped paths above must not spend the session's one line.
check "a skipped edit doesn't charge" "tack session" "$(edit s8 "$REPO" "$REPO/src/a.sh")"

echo ""
echo "Silent with no tack CLI to tell:"
HOOK_PATH="$NOTACK_PATH"
check "no tack on PATH"        silent "$(edit s11 "$REPO" "$REPO/src/a.sh")"

echo ""
echo "========================================="
if [ "$FAIL" -eq 0 ]; then
  printf "Results: ${GREEN}%d passed${NC}, %d failed out of %d\n" "$PASS" "$FAIL" "$TOTAL"
else
  printf "Results: %d passed, ${RED}%d failed${NC} out of %d\n" "$PASS" "$FAIL" "$TOTAL"
fi
echo "========================================="
[ "$FAIL" -eq 0 ]
