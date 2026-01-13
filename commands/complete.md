---
description: Complete a task - cleanup, rebase onto local main, and merge
argument-hint: <task-id> [--push]
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
---

# Complete Task Worktree

Finalize a completed task by cleaning up worktree-specific files, rebasing onto local main, updating task status, and cascading status updates to dependent tasks.

**Arguments:** $ARGUMENTS

## Instructions

### Phase 1: Verify Context

1. **Verify worktree context:**
   ```bash
   git branch --show-current
   git worktree list
   ```
   - Confirm we're in a feature branch worktree, NOT main
   - If on main: "This command must be run from a feature worktree, not main"

2. **Determine task ID:**
   - If task ID provided in arguments, use it
   - If NOT provided, use AskUserQuestion to select from active tasks

3. **Find task directory:**
   ```bash
   ls -d tasks/${TASK_ID}-* 2>/dev/null
   ```

4. **Check for uncommitted changes:**
   ```bash
   git status --porcelain
   ```
   - If uncommitted changes: "Uncommitted changes detected. Please commit or stash before completing."

### Phase 2: Cleanup Worktree-Specific Files

1. **Delete PROMPT.md** (task-specific agent instructions):
   ```bash
   rm -f PROMPT.md
   ```

2. **Delete state file** (iteration tracking):
   ```bash
   rm -f .claude/backlog-agent.local.md
   ```

3. **Clean up .claude directory** if empty:
   ```bash
   rmdir .claude 2>/dev/null || true
   ```

4. **Commit cleanup:**
   ```bash
   git add -A
   git commit -m "chore: cleanup task files before merge" --allow-empty
   ```

### Phase 3: Merge to Main

1. **Rebase onto LOCAL main:**
   ```bash
   git rebase main
   ```
   - If rebase conflicts: Show resolution steps and abort

2. **Fast-forward main to current HEAD:**
   ```bash
   git branch -f main HEAD
   ```

3. **Push main to origin** (if `--push` specified):
   ```bash
   git push origin main
   ```

### Phase 4: Update Task Status

1. **Update tasks/INDEX.md** status to "Complete":
   - Note: INDEX.md is in the worktree, changes will be on main after fast-forward
   ```bash
   # Edit INDEX.md to change status from "In Progress" to "Complete"
   ```

2. **Commit INDEX.md change:**
   ```bash
   git add tasks/INDEX.md
   git commit -m "chore: mark task ${TASK_ID} as complete"
   git branch -f main HEAD
   ```

3. **Push if requested:**
   ```bash
   if [ "$PUSH" = "true" ]; then
     git push origin main
   fi
   ```

### Phase 5: Cascade Dependency Updates (NEW)

**Update dependents when this task completes:**

```bash
source "${CLAUDE_PLUGIN_ROOT}/scripts/deps.sh"
deps_build_graph

# Get tasks that depend on this one
dependents=$(deps_get_dependents "${TASK_ID}")

if [[ -n "$dependents" ]]; then
  echo "Checking dependent tasks..."

  for dependent in $dependents; do
    # Compute new status (may change from Blocked to Ready)
    old_status="${DEPS_STATUS[$dependent]:-}"
    DEPS_STATUS["${TASK_ID}"]="Complete"  # Mark ourselves complete
    new_status=$(deps_compute_status "$dependent")

    if [[ "$old_status" == "Blocked" && "$new_status" == "Ready" ]]; then
      echo "  $dependent: Blocked -> Ready (unblocked by ${TASK_ID})"

      # Update INDEX.md
      sed -i.bak "s/| $dependent |\([^|]*\)| Blocked |/| $dependent |\1| Ready |/" tasks/INDEX.md
      rm -f tasks/INDEX.md.bak
    fi
  done

  # Commit cascade updates
  if git diff --quiet tasks/INDEX.md; then
    : # No changes
  else
    git add tasks/INDEX.md
    git commit -m "chore: unblock tasks dependent on ${TASK_ID}"
    git branch -f main HEAD

    if [ "$PUSH" = "true" ]; then
      git push origin main
    fi
  fi
fi
```

**Cascade output:**

```
## Dependency Cascade

The following tasks are now unblocked:

| Task | Previous | New | Ready to Launch |
|------|----------|-----|-----------------|
| IDXEX-003 | Blocked | Ready | /backlog:launch IDXEX-003 |
| IDXEX-004 | Blocked | Ready | /backlog:launch IDXEX-004 |

Tasks still blocked (waiting on other deps):
- IDXEX-005: Still waiting on IDXEX-003
```

### Phase 6: Output Summary

```
═══════════════════════════════════════════════════════════════════
 TASK COMPLETED: {PREFIX}-{NNN}
═══════════════════════════════════════════════════════════════════

## Summary

- Task: {PREFIX}-{NNN} - {Title}
- Branch: {branch-name}
- Commits rebased onto main: {count}
- Main updated to: {short-sha}
- Pushed to origin: {yes/no}
- INDEX.md updated: yes

## Dependency Cascade

{If dependents were unblocked}
The following tasks are now unblocked:
- {PREFIX}-{XXX}: {Title} -> Ready
- {PREFIX}-{YYY}: {Title} -> Ready

Next recommended task:
  /backlog:launch {PREFIX}-{XXX}

{If no dependents}
No dependent tasks were unblocked.

## Files Removed

- PROMPT.md (task assignment)
- .claude/backlog-agent.local.md (iteration state)

## Cleanup Required

Run from the main worktree (or any directory outside this worktree):

### Preferred: Use plugin script

"${CLAUDE_PLUGIN_ROOT}/scripts/wt-remove.sh" {branch-name}

### Or using git-wt:

git wt -d {branch-name}

### Or manually:

cd {parent-directory}
rm -rf {worktree-path}
git worktree prune
git branch -D {branch-name}

## Next Steps

1. Exit this Claude session
2. Run the cleanup command above
3. Use /backlog:prune to archive completed tasks
4. Launch next task: /backlog:launch {next-task}

═══════════════════════════════════════════════════════════════════
```

## Arguments Reference

| Argument | Description |
|----------|-------------|
| `<task-id>` | Task ID being completed (e.g., CRANE-003) |
| `--push` | Push main to origin after merge |

## Rebase Conflict Resolution

If rebase conflicts occur:

```
Rebase conflicts detected. Please resolve manually:

1. Fix conflicts in the listed files:
   - {conflicted-file-1}
   - {conflicted-file-2}

2. Stage resolved files:
   git add <resolved-files>

3. Continue rebase:
   git rebase --continue

4. Re-run /backlog:complete
```

## Error Handling

- **Not in worktree:** "This command must be run from a feature worktree, not main"
- **Uncommitted changes:** "Uncommitted changes detected. Please commit or stash before completing."
- **Rebase conflicts:** Show resolution steps and abort
- **Push fails:** Show error and suggest manual push
- **Task not found:** Show available task IDs
- **Task not in progress:** Warn and ask for confirmation

## Important Notes

- **Local main only:** Rebases onto LOCAL main branch, not origin/main
- **Cannot self-delete:** Agent cannot delete its own worktree while running. Cleanup must be done externally.
- **Task IDs persist:** Task numbers are never changed or renumbered
- **PROMPT.md deleted:** Prevents polluting main branch with task-specific files
- **Cascade updates:** Dependent tasks are automatically unblocked when this task completes

## Example Session

```bash
$ /backlog:complete CRANE-003 --push

Verifying worktree context...
  Current branch: feature/uniswap-v4-utils
  Worktree: /path/to/crane-wt/feature/uniswap-v4-utils

Task: CRANE-003 - Uniswap V4 Utils

Checking for uncommitted changes...
  Working tree clean

Cleaning up worktree-specific files...
  Removed: PROMPT.md
  Removed: .claude/backlog-agent.local.md
  Committed: chore: cleanup task files before merge

Rebasing onto local main...
  Successfully rebased 5 commits

Updating main to current HEAD...
  main -> abc1234

Pushing main to origin...
  main -> origin/main

Updating INDEX.md...
  CRANE-003 status: Complete
  Committed: chore: mark task CRANE-003 as complete

Checking dependent tasks...
  CRANE-005: Blocked -> Ready (unblocked by CRANE-003)
  CRANE-006: Blocked -> Ready (unblocked by CRANE-003)
  Committed: chore: unblock tasks dependent on CRANE-003

═══════════════════════════════════════════════════════════════════
 TASK COMPLETED: CRANE-003
═══════════════════════════════════════════════════════════════════

## Summary

- Task: CRANE-003 - Uniswap V4 Utils
- Branch: feature/uniswap-v4-utils
- Commits rebased onto main: 5
- Main updated to: abc1234
- Pushed to origin: yes
- INDEX.md updated: yes

## Dependency Cascade

The following tasks are now unblocked:
- CRANE-005: Slipstream vault -> Ready
- CRANE-006: V4 vault -> Ready

Next recommended task:
  /backlog:launch CRANE-005

## Cleanup Required

Run from the main worktree:

git wt -d feature/uniswap-v4-utils

...
```
