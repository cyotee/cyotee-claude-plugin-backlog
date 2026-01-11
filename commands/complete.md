---
description: Complete a task - update status, prepare for review, and cleanup worktree
argument-hint: <task-id> [--push] [--no-rebase]
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
---

# Complete Task

Finalize a completed task by updating status, rebasing onto main, and preparing for review.

**Arguments:** $ARGUMENTS

## Instructions

### Step 1: Verify Worktree Context

```bash
git branch --show-current
git worktree list
```

- Confirm we're in a feature branch worktree, NOT main
- If on main, abort: "This command must be run from a feature worktree"

### Step 2: Determine Task ID

- If task ID provided in arguments, use it
- If NO task ID provided, infer from branch name or use AskUserQuestion:
  ```
  Question: "Which task is being completed?"
  Header: "Task"
  Options: List tasks with status=in_progress
  ```

### Step 3: Read Task PRD

Read `tasks/[PREFIX]-[N]/PRD.md` to get:
- Task title
- Current status
- Acceptance criteria

### Step 4: Check for Uncommitted Changes

```bash
git status --porcelain
```

If uncommitted changes exist, abort: "Uncommitted changes detected. Please commit or stash."

### Step 5: Verify Completion Criteria

Prompt agent to verify:
- All acceptance criteria in PRD.md are checked
- Tests pass (`forge test`)
- Build succeeds (`forge build`)

If not all criteria met, warn but allow proceeding.

### Step 6: Update PROGRESS.md

Add completion entry (at top, reverse chronological):

```markdown
### [Date Time] - Task Complete

**Summary:** Implementation complete, ready for review

**Final status:**
- All acceptance criteria: ✅
- Build: ✅ Passing
- Tests: ✅ Passing

**Notes for reviewer:**
[Any implementation notes]
```

### Step 7: Update PRD.md Status

Update frontmatter:

```yaml
status: review
```

Add notes section if not present:

```markdown
## Notes for Reviewer

[Agent's implementation notes, decisions made, caveats]
```

### Step 8: Rebase onto Main (unless --no-rebase)

```bash
git fetch origin main
git rebase origin/main
```

If conflicts, show resolution steps and abort.

### Step 9: Fast-Forward Main

```bash
git branch -f main HEAD
```

### Step 10: Push (if --push)

```bash
git push origin main
```

### Step 11: Update INDEX.md

Update the task's status in `tasks/INDEX.md`:

```markdown
| [PREFIX]-[N] | [Title] | 📋 review | ... |
```

### Step 12: Output Completion Summary

```
# Task [PREFIX]-[N] Complete

**Title:** [Title]
**Status:** 📋 review
**Branch:** [branch-name]
**Commits:** [count] rebased onto main

## Next Steps

1. **Request Review:**
   Another agent should review using:
   ```
   /backlog:read [PREFIX]-[N]
   ```
   Then update `tasks/[PREFIX]-[N]/REVIEW.md`

2. **After Review Passes:**
   ```
   /backlog:prune [PREFIX]-[N]
   ```

## Cleanup Required

Exit this session and run from main worktree:

```bash
./scripts/wt-remove.sh [branch-name]
```

Or:
```bash
git wt -d [branch-name]
```
```

## Arguments Reference

| Argument | Description |
|----------|-------------|
| `<task-id>` | Task ID (e.g., P-5, [PREFIX]-N) |
| `--push` | Push main to origin after completion |
| `--no-rebase` | Skip rebase (use if already rebased) |

## Error Handling

- **Not in worktree:** "Run from feature worktree, not main"
- **Uncommitted changes:** "Commit or stash first"
- **Rebase conflicts:** Show resolution steps
- **Task not found:** Show available tasks
- **Criteria not met:** Warn but allow proceeding

## Notes

- Task moves to `review` status, not `complete`
- Another agent should review before marking complete
- Worktree cleanup must be done from outside the worktree
