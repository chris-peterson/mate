#!/usr/bin/env bash
# Synthetic-payload tests for hooks/react.sh. Every case here is a payload handed
# straight to the script, so a green run proves the matcher and says nothing
# about whether Claude Code delivers an announcement on `tool_response.stdout`.
# The live check — run a phase that marks a CR ready and watch for the line — is
# what settles delivery, and no run of this file substitutes for it.
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

# A Bash tool call whose stdout carries whatever the case is testing. The
# session id is minted by the caller rather than here: this runs inside a command
# substitution, so an increment made here would be discarded with the subshell
# and every case would reuse one id — which the once-per-session guard reads as a
# repeat and silences.
announced() {
  jq -nc --arg o "$1" --arg s "$2" '{session_id:$s,tool_name:"Bash",tool_response:{stdout:$o}}' \
    | TMPDIR="$TMPROOT" bash "$HOOK" 2>/dev/null || true
}

stdout_case() {
  SESSION_SEQ=$((SESSION_SEQ + 1))
  check "$1" "$2" "$(announced "$3" "sess-$SESSION_SEQ")"
}

READY='codes.bridgeai.anchor/cr.ready {"uri":"https://github.com/o/r/pull/88"}'

echo "=== react tests ==="

echo ""
echo "Names what the change request still needs:"
stdout_case "carries the CR url"       "https://github.com/o/r/pull/88" "$READY"
stdout_case "asks for a reviewer"      "a reviewer"                     "$READY"
stdout_case "asks for the pipeline"    "the pipeline"                   "$READY"
stdout_case "names the next phase"     "/anchor:merge"                  "$READY"
stdout_case "empty body still speaks"  "the change request"             'codes.bridgeai.anchor/cr.ready {}'
stdout_case "announcement among output" "https://github.com/o/r/pull/88" \
  "$(printf 'PUSHED=ok\n%s\n' "$READY")"

echo ""
echo "Never sequences — the line says not to run the next step:"
stdout_case "hands-off"                "don't" "$READY"

echo ""
echo "Silent on everything else:"
stdout_case "a key mate doesn't take"  silent 'codes.bridgeai.anchor/cr.created {"uri":"https://github.com/o/r/pull/88"}'
stdout_case "tack's own keys"          silent 'codes.bridgeai.tack/session.started {"route":"mate"}'
stdout_case "longer key, same prefix"  silent 'codes.bridgeai.anchor/cr.readyish {"uri":"https://x/1"}'
stdout_case "mid-line mention"         silent 'about to emit codes.bridgeai.anchor/cr.ready {"uri":"https://x/1"}'
stdout_case "no announcement"          silent 'PUSHED=ok'
stdout_case "empty stdout"             silent ''

# The guard is per session, so this one drives a single id twice by hand rather
# than through `announced`, which mints a fresh id each call.
payload=$(jq -nc --arg o "$READY" '{session_id:"sess-repeat",tool_name:"Bash",tool_response:{stdout:$o}}')
first=$(printf '%s' "$payload" | TMPDIR="$TMPROOT" bash "$HOOK" 2>/dev/null || true)
second=$(printf '%s' "$payload" | TMPDIR="$TMPROOT" bash "$HOOK" 2>/dev/null || true)
check "first ready speaks" "/anchor:merge" "$first"
check "second ready is silent" silent "$second"

# A payload with no session id can't be guarded, so it says nothing rather than
# repeating on every announcement the session makes.
check "no session id" silent \
  "$(jq -nc --arg o "$READY" '{tool_name:"Bash",tool_response:{stdout:$o}}' | TMPDIR="$TMPROOT" bash "$HOOK" 2>/dev/null || true)"

echo ""
echo "========================================="
if [ "$FAIL" -eq 0 ]; then
  printf "Results: ${GREEN}%d passed${NC}, %d failed out of %d\n" "$PASS" "$FAIL" "$TOTAL"
else
  printf "Results: %d passed, ${RED}%d failed${NC} out of %d\n" "$PASS" "$FAIL" "$TOTAL"
fi
echo "========================================="
[ "$FAIL" -eq 0 ]
