---
description: Complete a task - rebase, merge to main, and prepare for cleanup
argument-hint: [<task-number>] [--push] [--no-rebase]
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
---

# Complete Task Worktree

Finalize a completed task by rebasing onto main, fast-forwarding main, updating UNIFIED_PLAN.md, and providing cleanup instructions.

**Arguments:** $ARGUMENTS

## Instructions

1. **Verify worktree context:**
   ```bash
   git branch --show-current
   git worktree list
   ```
   - Confirm we're in a feature branch worktree, NOT main
   - If on main, abort with error: "This command must be run from a feature worktree, not main"

2. **Determine task number:**
   - If task number provided in arguments, use it
   - If NO task number provided, use AskUserQuestion:
     ```
     Question: "Which task number is being completed?"
     Header: "Task"
     Options: List active tasks from UNIFIED_PLAN.md (status = "In Progress" or "Ready for Agent")
     ```
   - Read UNIFIED_PLAN.md to get task details

3. **Check for uncommitted changes:**
   ```bash
   git status --porcelain
   ```
   - If there are uncommitted changes, abort with error: "Uncommitted changes detected. Please commit or stash before completing."

4. **Fetch latest main:**
   ```bash
   git fetch origin main
   ```

5. **Rebase onto main** (unless `--no-rebase` specified):
   ```bash
   git rebase origin/main
   ```
   - If rebase conflicts occur, abort and show:
     ```
     Rebase conflicts detected. Please resolve manually:
     1. Fix conflicts in the listed files
     2. git add <resolved-files>
     3. git rebase --continue
     4. Re-run /backlog:complete
     ```

6. **Fast-forward main to current HEAD:**
   ```bash
   git branch -f main HEAD
   ```
   - This updates local main to point to the rebased commits

7. **Push main to origin** (if `--push` specified):
   ```bash
   git push origin main
   ```

8. **Update UNIFIED_PLAN.md:**
   - Find the task section and update status to "✅ Complete"
   - Find the "## Worktree Status" table and update the row:
     ```
     | Task N | `<branch-name>` | ✅ Complete (merged to `main`) |
     ```
   - Note: The plan file is in the MAIN worktree, not the feature worktree
     - For IndexedEx tasks: `../../UNIFIED_PLAN.md` or find via git root
     - For Crane tasks: `../../../../UNIFIED_PLAN.md` (in IndexedEx root)

9. **Get cleanup information:**
   ```bash
   BRANCH=$(git branch --show-current)
   WORKTREE_PATH=$(pwd)
   ```

10. **Output completion summary:**

```
# Task N Completed Successfully

## Summary

- Task: N - <title>
- Branch: <branch-name>
- Commits rebased onto main: <count>
- Main updated to: <short-sha>
- Pushed to origin: [yes/no]
- UNIFIED_PLAN.md updated: yes

## Cleanup Required

Run from the main worktree (or any directory outside this worktree):

```bash
git wt -d <branch-name>
```

Or manually:
```bash
cd <parent-directory>
rm -rf <worktree-path>
git worktree prune
git branch -d <branch-name>
```

## Next Steps

1. Exit this Claude session
2. Run the cleanup command above
```

## Arguments Reference

| Argument | Description |
|----------|-------------|
| `<task-number>` | Optional task number being completed (prompts if not provided) |
| `--push` | Push main to origin after fast-forward |
| `--no-rebase` | Skip rebase, just fast-forward main (use if already rebased) |

## AskUserQuestion Format

When no task number is provided, ask:

```
Question: "Which task number is being completed?"
Header: "Task"
Options: (dynamically built from UNIFIED_PLAN.md)
  - "Task 3: Uniswap V4 Utils Library"
  - "Task 7: Slipstream Standard Exchange Vault"
  - "Task 8: Uniswap V3 Standard Exchange Vault"
  - etc.
multiSelect: false
```

## Error Handling

- **Not in worktree:** "This command must be run from a feature worktree, not main"
- **Uncommitted changes:** "Uncommitted changes detected. Please commit or stash before completing."
- **Rebase conflicts:** Show resolution steps and abort
- **Push fails:** Show error and suggest manual push
- **Main has diverged:** Warn and suggest `--no-rebase` if intentional
- **Task not found:** Show available task numbers
- **UNIFIED_PLAN.md not found:** Search parent directories or ask user

## Important Notes

- **Cannot self-delete:** An agent cannot delete its own worktree while running inside it. The cleanup must be performed from outside.
- **Task numbers persist:** Do not renumber tasks in UNIFIED_PLAN.md after completion
- **Branch naming:** The branch name should match the task's "Worktree:" field in UNIFIED_PLAN.md
- **Plan file location:** UNIFIED_PLAN.md lives in the main IndexedEx repo, not in submodule worktrees

## Example Session

```
$ /backlog:complete 3 --push

Verifying worktree context...
  Current branch: feature/uniswap-v4-utils
  Worktree: /path/to/crane-wt/feature/uniswap-v4-utils

Task: 3 - Uniswap V4 Utils Library

Checking for uncommitted changes...
  Working tree clean

Fetching latest main...
  From origin
   * branch main -> FETCH_HEAD

Rebasing onto main...
  Successfully rebased 3 commits

Updating main to current HEAD...
  main -> abc1234

Pushing main to origin...
  main -> origin/main

Updating UNIFIED_PLAN.md...
  Task 3 status: ✅ Complete
  Worktree status table updated

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

## Example Without Task Number

```
$ /backlog:complete --push

Verifying worktree context...
  Current branch: feature/uniswap-v4-utils

[AskUserQuestion: Which task number is being completed?]
  Options:
  - Task 3: Uniswap V4 Utils Library
  - Task 7: Slipstream Standard Exchange Vault
  - Task 8: Uniswap V3 Standard Exchange Vault

User selects: Task 3

Proceeding with Task 3...
[rest of completion flow]
```
