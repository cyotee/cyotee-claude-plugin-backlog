---
description: List all unarchived tasks with status, dependencies, and worktrees
argument-hint: [--worktrees-only] [--json] [--compact]
allowed-tools: Read, Bash, Glob, Grep
---

# List Tasks

**CRITICAL: Execute the shell scripts. Do NOT generate your own tables or summaries.**

## Step 1: Determine the command based on arguments

Arguments received: $ARGUMENTS

**Default (no arguments):**
```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/index-to-json.sh" | "${CLAUDE_PLUGIN_ROOT}/scripts/format-task-list.sh"
```

**With --json:**
```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/index-to-json.sh" --pretty
```

**With --compact:**
```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/index-to-json.sh" | "${CLAUDE_PLUGIN_ROOT}/scripts/format-task-list.sh" --compact
```

**With --worktrees-only:**
```bash
git worktree list --porcelain
```
Then display worktree info with associated tasks from PROMPT.md files.

## Step 2: Execute the command

Run the appropriate bash command above using the Bash tool.

## Step 3: Display the output

Show the complete output from the script. The script produces:
- Task table with columns: ID, Title, Status, Dependencies, Worktree
- Summary section with counts by status
- Active worktrees section (if any exist)
- Next actions (ready tasks and blocked tasks)

## Error Handling

If scripts fail:
- **No tasks/ directory:** Tell user to run `/design:init`
- **No INDEX.md:** Tell user to create tasks with `/design`
- **jq not installed:** Tell user to run `brew install jq`

## Reference: Status Icons

| Status | Icon |
|--------|------|
| Complete | ✅ |
| In Progress | 🚀 |
| In Review | 📋 |
| Changes Requested | 🔄 |
| Ready | 🆕 |
| Blocked | ❌ |
