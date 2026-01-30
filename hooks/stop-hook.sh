#!/bin/bash

# Backlog Stop Hook v2.0
#
# DESIGN PRINCIPLE: Exit permission is SEPARATE from state transitions.
#
# This hook ONLY controls whether an agent can exit. It does NOT:
# - Change task status in INDEX.md
# - Call /backlog:complete or any other skill
# - Trigger any state transitions
#
# Exit is allowed when agent outputs:
# - <promise>PHASE_DONE</promise> - Agent finished their assigned phase
# - <promise>BLOCKED: reason</promise> - Agent cannot proceed
#
# State transitions are ALWAYS explicit user commands:
# - /backlog:launch or /backlog:work → sets "In Progress"
# - /backlog:review → sets "In Review"
# - /backlog:complete → sets "Complete" (only after review)

set -euo pipefail

# Read hook input from stdin (provides transcript_path)
HOOK_INPUT=$(cat)

# Helper function to allow exit with proper JSON output
allow_exit() {
  echo '{"decision": "approve"}'
  exit 0
}

# Check if PROMPT.md exists (indicates we're in an agent context)
if [[ ! -f "PROMPT.md" ]]; then
  # Not an agent context - allow exit
  allow_exit
fi

# State file for iteration tracking (optional)
STATE_FILE=".claude/backlog-agent.local.md"

# Default values if no state file
ITERATION=1
MAX_ITERATIONS=0

# Read state file if exists
if [[ -f "$STATE_FILE" ]]; then
  FRONTMATTER=$(sed -n '/^---$/,/^---$/{ /^---$/d; p; }' "$STATE_FILE")
  ITERATION=$(echo "$FRONTMATTER" | grep '^iteration:' | sed 's/iteration: *//' || echo "1")
  MAX_ITERATIONS=$(echo "$FRONTMATTER" | grep '^max_iterations:' | sed 's/max_iterations: *//' || echo "0")

  # Validate numeric fields
  if [[ ! "$ITERATION" =~ ^[0-9]+$ ]]; then
    echo "⚠️  Backlog hook: Invalid iteration value in state file" >&2
    ITERATION=1
  fi
  if [[ ! "$MAX_ITERATIONS" =~ ^[0-9]+$ ]]; then
    MAX_ITERATIONS=0
  fi
fi

# Check if max iterations reached
if [[ $MAX_ITERATIONS -gt 0 ]] && [[ $ITERATION -ge $MAX_ITERATIONS ]]; then
  echo "🛑 Max iterations ($MAX_ITERATIONS) reached." >&2
  echo "   Phase did not complete within iteration limit." >&2
  echo "   Check PROGRESS.md for current state." >&2
  [[ -f "$STATE_FILE" ]] && rm "$STATE_FILE"
  allow_exit
fi

# Get transcript path from hook input
TRANSCRIPT_PATH=$(echo "$HOOK_INPUT" | jq -r '.transcript_path')

if [[ ! -f "$TRANSCRIPT_PATH" ]]; then
  echo "⚠️  Backlog hook: Transcript file not found" >&2
  allow_exit
fi

# Check if there are any assistant messages
if ! grep -q '"role":"assistant"' "$TRANSCRIPT_PATH"; then
  # No assistant messages yet - allow exit (shouldn't normally happen)
  allow_exit
fi

# Extract last assistant message
LAST_LINE=$(grep '"role":"assistant"' "$TRANSCRIPT_PATH" | tail -1)
LAST_OUTPUT=$(echo "$LAST_LINE" | jq -r '
  .message.content |
  map(select(.type == "text")) |
  map(.text) |
  join("\n")
' 2>/dev/null || echo "")

# Check for promise tags using perl for multiline support
if echo "$LAST_OUTPUT" | grep -q '<promise>'; then
  PROMISE_TEXT=$(echo "$LAST_OUTPUT" | perl -0777 -pe 's/.*?<promise>(.*?)<\/promise>.*/$1/s; s/^\s+|\s+$//g' 2>/dev/null || echo "")
else
  PROMISE_TEXT=""
fi

# Check for PHASE_DONE - generic exit signal
if [[ "$PROMISE_TEXT" = "PHASE_DONE" ]]; then
  echo "✅ Phase complete - agent finished assigned work" >&2
  [[ -f "$STATE_FILE" ]] && rm "$STATE_FILE"
  allow_exit
fi

# Check for BLOCKED (with optional reason)
if [[ "$PROMISE_TEXT" = "BLOCKED" ]] || [[ "$PROMISE_TEXT" == BLOCKED:* ]]; then
  echo "⚠️  Agent blocked - cannot proceed" >&2
  if [[ "$PROMISE_TEXT" == BLOCKED:* ]]; then
    REASON="${PROMISE_TEXT#BLOCKED:}"
    REASON="${REASON# }"  # Trim leading space
    echo "   Reason: $REASON" >&2
  fi
  [[ -f "$STATE_FILE" ]] && rm "$STATE_FILE"
  allow_exit
fi

# Legacy support: Accept old promise tags during transition period
# TODO: Remove after all skills are updated
if [[ "$PROMISE_TEXT" = "TASK_COMPLETE" ]] || [[ "$PROMISE_TEXT" = "REVIEW_COMPLETE" ]]; then
  echo "✅ Legacy promise detected ($PROMISE_TEXT) - allowing exit" >&2
  echo "   Note: Please update to use <promise>PHASE_DONE</promise>" >&2
  [[ -f "$STATE_FILE" ]] && rm "$STATE_FILE"
  allow_exit
fi

if [[ "$PROMISE_TEXT" = "TASK_BLOCKED" ]] || [[ "$PROMISE_TEXT" == TASK_BLOCKED:* ]]; then
  echo "⚠️  Legacy TASK_BLOCKED detected - allowing exit" >&2
  echo "   Note: Please update to use <promise>BLOCKED: reason</promise>" >&2
  [[ -f "$STATE_FILE" ]] && rm "$STATE_FILE"
  allow_exit
fi

# Not complete - increment iteration and block exit
NEXT_ITERATION=$((ITERATION + 1))

# Update state file if exists
if [[ -f "$STATE_FILE" ]]; then
  TEMP_FILE="${STATE_FILE}.tmp.$$"
  sed "s/^iteration: .*/iteration: $NEXT_ITERATION/" "$STATE_FILE" > "$TEMP_FILE"
  mv "$TEMP_FILE" "$STATE_FILE"
fi

# Build iteration info for system message
if [[ $MAX_ITERATIONS -gt 0 ]]; then
  ITER_INFO="Iteration $NEXT_ITERATION of $MAX_ITERATIONS"
else
  ITER_INFO="Iteration $NEXT_ITERATION (no limit)"
fi

# Output JSON to block the stop and provide continuation prompt
jq -n \
  --arg iter "$ITER_INFO" \
  '{
    "decision": "block",
    "reason": "Read PROMPT.md and continue from where you left off. Check PROGRESS.md for your prior work.",
    "systemMessage": ("🔄 " + $iter + " | Phase incomplete. Re-read PROMPT.md and continue. When done, output: <promise>PHASE_DONE</promise>  If blocked, output: <promise>BLOCKED: reason</promise>")
  }'

exit 0
