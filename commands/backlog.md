---
description: Display task status summary (alias for /backlog:status)
---

# Backlog Status

Display a summary of all tasks from the tasks/ directory. This is an alias for `/backlog:status`.

## Instructions

See `/backlog:status` for full documentation.

### Quick Reference

1. **Identify the layer** based on current working directory
2. **Read tasks/INDEX.md** or scan task directories
3. **Display status table** with all tasks
4. **Show summary counts** and recommended next task

## Quick Status Check

```bash
# List all task directories
ls -d tasks/*/

# Check INDEX.md
cat tasks/INDEX.md
```

## Example Output

```
# Backlog Status - IndexedEx

| # | Title | Status | Worktree | Dependencies | Created |
|---|-------|--------|----------|--------------|---------|
| I-1 | Feature One | ✅ complete | - | - | 2026-01-05 |
| I-2 | Feature Two | 🚀 in_progress | `feature/two` | I-1 | 2026-01-08 |
| I-3 | Feature Three | 🆕 pending | - | I-2 | 2026-01-10 |

## Summary

- ✅ Complete: 1
- 🚀 In Progress: 1
- 📋 Review: 0
- 🆕 Pending: 1
- ❌ Blocked: 0

## Recommended Next

Start with: I-3 (after I-2 completes)
```

## Related Commands

- `/backlog:status` - Full status (same as /backlog)
- `/backlog:read <id>` - View specific task details
- `/backlog:launch <id>` - Launch agent for a task
- `/backlog:complete <id>` - Mark task ready for review
- `/backlog:prune` - Archive completed tasks
- `/design:task` - Create a new task
