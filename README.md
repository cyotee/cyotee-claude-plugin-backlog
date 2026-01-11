# backlog - Task Management Plugin

Manage your UNIFIED_PLAN.md task backlog and git worktrees for autonomous agent execution.

## Installation

```bash
/plugin marketplace add cyotee/cyotee-claude-plugins
/plugin install backlog@cyotee
```

## Commands

### `/backlog`

Display a summary table of all tasks in UNIFIED_PLAN.md.

**Aliases:** `/backlog:status`

**What it does:**
1. Reads UNIFIED_PLAN.md from the repository
2. Generates a status table of all tasks
3. Shows summary counts (completed, ready, blocked)
4. Recommends the next task to work on

**Example output:**
```
# Backlog Status

| Task | Title                    | Layer     | Status          | Dependencies |
|------|--------------------------|-----------|-----------------|--------------|
| 1    | V3 Mainnet Fork Tests    | Crane     | Complete        | -            |
| 2    | Slipstream Utils         | Crane     | Complete        | -            |
| 5    | Protocol DETF (CHIR)     | IndexedEx | Ready for Agent | -            |
| 7    | Slipstream Vault         | IndexedEx | Ready for Agent | Task 2       |

Summary:
- Completed: 2
- Ready for agent: 2
- Blocked/pending: 0

Recommended next: Task 5 (Protocol DETF) - no dependencies
```

**When no backlog exists:**
```
No backlog defined.

To create a backlog, use /design to define your first task.
This will create UNIFIED_PLAN.md with your task.
```

---

### `/backlog:read <task-number>`

Display the full content of a specific task from UNIFIED_PLAN.md.

**What it does:**
1. Finds the specified task in UNIFIED_PLAN.md
2. Extracts the complete task section
3. Displays formatted output with all task details

**Example usage:**
```
/backlog:read 5
```

**Example output:**
```markdown
# Task 5: Protocol DETF (CHIR) System

**Layer:** IndexedEx
**Status:** Ready for Agent
**Worktree:** Not started

---

### Description
Implement the Protocol DETF system (CHIR token) with integrated fee distribution...

### User Stories

**US-5.1: Mint CHIR with WETH**
As a user, I want to deposit WETH to receive CHIR tokens...

[Full task content]
```

**Error handling:**
- No task number: Shows usage instructions
- Task not found: Lists available task numbers
- No UNIFIED_PLAN.md: Suggests creating one with /design

---

### `/backlog:launch <task-number>`

Create a git worktree and PROMPT.md for a task, ready for agent execution.

**What it does:**
1. Reads the task from UNIFIED_PLAN.md
2. Determines the correct worktree location based on task layer:
   - Crane tasks → `lib/daosys/lib/crane` submodule
   - daosys tasks → `lib/daosys` submodule
   - Product tasks → repository root
3. Creates the worktree using `git wt <branch-name>`
4. Writes PROMPT.md with the full task and agent instructions
5. Updates the Worktree Status table in UNIFIED_PLAN.md
6. Outputs launch instructions

**Example usage:**
```
/backlog:launch 7
```

**Example output:**
```
# Launch Agent for Task 7: Slipstream Standard Exchange Vault

Worktree created at: /path/to/indexedex-wt/feature/slipstream-vault
Recorded in UNIFIED_PLAN.md

## Start the agent:

cd /path/to/indexedex-wt/feature/slipstream-vault
claude --dangerously-skip-permissions

## Then in Claude, run:

/ralph-loop:ralph-loop "Read PROMPT.md and execute the task." --completion-promise "TASK_COMPLETE" --max-iterations 10
```

**PROMPT.md structure:**
```markdown
# Task N: [Title]

[Full task content from UNIFIED_PLAN.md]

---

## Agent Instructions

1. Read this PROMPT.md and CLAUDE.md
2. Perform inventory checks
3. Implement the user stories
4. Verify completion criteria
5. Output your completion promise

## Completion

When done, output: `<promise>TASK_COMPLETE</promise>`

If blocked, output: `<promise>TASK_BLOCKED: [reason]</promise>`
```

---

### `/backlog:complete [task-number] [--push] [--no-rebase]`

Finalize a completed task by rebasing onto main, fast-forwarding main, and preparing cleanup.

**Must be run from a feature worktree, not main.**

**What it does:**
1. Verifies you're in a feature worktree
2. Checks for uncommitted changes (aborts if found)
3. Fetches latest main
4. Rebases onto main (unless `--no-rebase`)
5. Fast-forwards main to include rebased commits
6. Pushes main to origin (if `--push`)
7. Updates task status in UNIFIED_PLAN.md
8. Outputs cleanup instructions

**Arguments:**
| Argument | Description |
|----------|-------------|
| `<task-number>` | Optional - prompts if not provided |
| `--push` | Push main to origin after merge |
| `--no-rebase` | Skip rebase (use if already rebased) |

**Example usage:**
```
/backlog:complete 3 --push
```

**Example output:**
```
# Task 3 Completed Successfully

## Summary

- Task: 3 - Uniswap V4 Utils Library
- Branch: feature/uniswap-v4-utils
- Commits rebased onto main: 3
- Main updated to: abc1234
- Pushed to origin: yes
- UNIFIED_PLAN.md updated: yes

## Cleanup Required

Run from the main worktree:

git wt -d feature/uniswap-v4-utils
```

**Error handling:**
- Not in worktree: "This command must be run from a feature worktree, not main"
- Uncommitted changes: "Please commit or stash before completing"
- Rebase conflicts: Shows resolution steps

---

### `/backlog:prune`

Archive completed tasks from UNIFIED_PLAN.md.

**What it does:**
1. Identifies all completed tasks
2. Removes task sections from the document
3. Adds summary to "Completed Tasks Archive" section
4. Preserves task numbers (never renumbers)
5. Commits the changes

**Example output:**
```
# Pruned Tasks

Archived 2 completed tasks:
- Task 1: V3 Mainnet Fork Tests
- Task 2: Slipstream Utils

Remaining tasks: 5, 6, 7, 8, 9, 10
```

**Archive format:**
```markdown
## Completed Tasks Archive

| Task | Title                  | Completed  |
|------|------------------------|------------|
| 1    | V3 Mainnet Fork Tests  | 2026-01-05 |
| 2    | Slipstream Utils       | 2026-01-07 |
```

---

## Worktree Status Table

The `/backlog:launch` and `/backlog:complete` commands maintain a status table in UNIFIED_PLAN.md:

```markdown
## Worktree Status

| Task | Worktree                        | Status                              |
|------|---------------------------------|-------------------------------------|
| 1    | `feature/v3-mainnet-fork-tests` | ✅ Complete (merged to `crane/main`) |
| 3    | `feature/uniswap-v4-utils`      | 🚀 In Progress                       |
| 7    | `feature/slipstream-vault`      | ⏸️ Paused                            |
```

**Status values:**
- 🚀 In Progress - Agent actively working
- ✅ Complete (merged to `<branch>`) - Done, worktree can be deleted
- ⏸️ Paused - Worktree exists but idle
- ❌ Blocked: `<reason>` - Agent encountered issue

---

## Scripts

The plugin includes submodule-aware worktree management scripts in `scripts/`:

### `wt-create.sh`

Creates a worktree with proper submodule initialization:

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/wt-create.sh" <branch-name> [repo-root]
```

**Features:**
- Creates worktree for new or existing branch
- Attempts `git submodule update --init --recursive`
- Falls back to copying submodules from main repo if git init fails
- Handles nested submodules (repo → daosys → crane)

### `wt-remove.sh`

Removes a worktree safely (handles submodules):

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/wt-remove.sh" <branch-name> [repo-root]
```

**Features:**
- Cleans stale `.lock` files before removal
- Uses `--force` flag (required for submodule worktrees)
- Prunes worktree references
- Deletes the branch

**Why scripts instead of `git wt -d`?**

1. Worktrees with submodules can't be removed without `--force`
2. Submodule pointers can become corrupt (pointing to deleted commits)
3. Lock files cause "Another git process" errors
4. Nested submodules need fallback copying when git init fails

## Requirements

- **git-wt**: Git worktree helper script (optional, scripts provide alternative)
- **UNIFIED_PLAN.md**: Task backlog file

## Workflow Integration

```
1. /design <feature>      # Create task
2. /backlog               # View all tasks
3. /backlog:read 5        # Read task details
4. /backlog:launch 5      # Create worktree
5. (agent works)          # Execute task
6. /backlog:complete 5    # Merge to main
7. /backlog:prune         # Archive completed
```

## License

MIT
