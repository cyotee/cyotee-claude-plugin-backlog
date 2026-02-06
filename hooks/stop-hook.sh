#!/bin/bash

# Backlog Stop Hook v3.0
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
  # Clean up exit flag if it exists
  rm -f ".claude/backlog-exit" 2>/dev/null || true
  echo '{"decision": "approve"}'
  exit 0
}

# Check for exit flag first (set by management commands like /backlog:launch)
if [[ -f ".claude/backlog-exit" ]]; then
  allow_exit
fi

# Gate: Only activate in backlog-managed sessions
# The state file is created exclusively by /backlog:work and /backlog:launch.
# This prevents trapping sessions from other plugins (e.g., /design:design)
# that may also create PROMPT.md.
STATE_FILE=".claude/backlog-agent.local.md"
if [[ ! -f "$STATE_FILE" ]]; then
  # Not a backlog agent context - allow exit unconditionally
  allow_exit
fi

# Read state from file
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

# Hard safety cap: prevent infinite loops even when max_iterations=0 (unlimited)
HARD_CAP=10
if [[ $MAX_ITERATIONS -eq 0 ]]; then
  EFFECTIVE_MAX=$HARD_CAP
elif [[ $MAX_ITERATIONS -gt $HARD_CAP ]]; then
  EFFECTIVE_MAX=$MAX_ITERATIONS  # User explicitly requested more — honor it
else
  EFFECTIVE_MAX=$MAX_ITERATIONS
fi

# Check if effective max iterations reached
if [[ $ITERATION -ge $EFFECTIVE_MAX ]]; then
  echo "🛑 Safety cap reached ($ITERATION/$EFFECTIVE_MAX iterations)." >&2
  echo "   Agent did not output a <promise> tag within the iteration limit." >&2
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

# Scan the last 5 assistant messages for promise tags (not just the last one).
# This handles the common case where the agent outputs <promise>PHASE_DONE</promise>
# but then adds a closing summary in a subsequent message.
PROMISE_TEXT=""
while IFS= read -r line; do
  MSG_TEXT=$(echo "$line" | jq -r '
    .message.content |
    map(select(.type == "text")) |
    map(.text) |
    join("\n")
  ' 2>/dev/null || echo "")

  if echo "$MSG_TEXT" | grep -q '<promise>'; then
    PROMISE_TEXT=$(echo "$MSG_TEXT" | perl -0777 -pe 's/.*?<promise>(.*?)<\/promise>.*/$1/s; s/^\s+|\s+$//g' 2>/dev/null || echo "")
    break  # Use the most recent promise found (tail gives newest last, but we read in reverse)
  fi
done < <(grep '"role":"assistant"' "$TRANSCRIPT_PATH" | tail -5 | tac)

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
ITER_INFO="Iteration $NEXT_ITERATION of $EFFECTIVE_MAX"

# Output JSON to block the stop and provide continuation prompt
jq -n \
  --arg iter "$ITER_INFO" \
  '{
    "decision": "block",
    "reason": "Read PROMPT.md and continue from where you left off. Check PROGRESS.md for your prior work.",
    "systemMessage": ("🔄 " + $iter + " | Phase incomplete. Re-read PROMPT.md and continue.\n\nWhen done: <promise>PHASE_DONE</promise>\nIf blocked: <promise>BLOCKED: reason</promise>\nIf stuck in loop: run /backlog:stop")
  }'

exit 0
