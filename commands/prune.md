---
description: Archive completed tasks to tasks/archive/
argument-hint: [<task-id>] [--all]
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
---

# Prune/Archive Completed Tasks

Move completed and reviewed tasks to the archive directory.

**Arguments:** $ARGUMENTS

## Instructions

### Step 1: Identify Tasks to Archive

If `--all` specified:
- Scan all task directories in `tasks/`
- Find tasks with `status: complete` in PRD.md frontmatter

If specific task ID provided:
- Verify task exists and has `status: complete`

If no arguments:
- Show list of archivable tasks and ask which to archive

### Step 2: Verify Review Status

For each task to archive, check `tasks/[PREFIX]-[N]/REVIEW.md`:
- Must have `verdict: pass` or `verdict: pass_with_notes`
- If verdict is `needs_work` or `pending`, warn and skip

### Step 3: Move to Archive

```bash
mv tasks/[PREFIX]-[N] tasks/archive/[PREFIX]-[N]
```

### Step 4: Update INDEX.md

Remove the archived task from the active tasks table.

Add to an "Archived" section at the bottom of INDEX.md:

```markdown
## Archived Tasks

| # | Title | Completed | Review Verdict |
|---|-------|-----------|----------------|
| [P]-1 | Feature Name | 2026-01-10 | ✅ Pass |
```

### Step 5: Clean Up Worktree (if exists)

Check if worktree still exists:

```bash
git worktree list | grep [worktree-name]
```

If exists, provide cleanup command:

```bash
./scripts/wt-remove.sh [worktree-name]
```

### Step 6: Output Summary

```
# Tasks Archived

Archived 2 tasks to tasks/archive/:

| Task | Title | Review Verdict |
|------|-------|----------------|
| [P]-1 | Feature Name | ✅ Pass |
| [P]-2 | Another Feature | ✅ Pass with notes |

## Worktree Cleanup Needed

The following worktrees should be removed:

```bash
./scripts/wt-remove.sh feature/name
./scripts/wt-remove.sh feature/other
```

## Remaining Active Tasks

| # | Title | Status |
|---|-------|--------|
| [P]-3 | Pending Feature | 🆕 pending |
| [P]-5 | In Progress Feature | 🚀 in_progress |
```

## Arguments Reference

| Argument | Description |
|----------|-------------|
| `<task-id>` | Specific task to archive (e.g., P-5) |
| `--all` | Archive all tasks with status=complete |

## Error Handling

- **No completed tasks:** "No tasks ready to archive"
- **Task not reviewed:** "Task [ID] needs review before archiving"
- **Task not found:** Show available tasks
- **Archive directory missing:** Create it

## Notes

- Task directories are preserved in archive for historical reference
- Task numbers are never reused
- Review verdicts are preserved in archived REVIEW.md
- Worktree cleanup is separate from task archiving
