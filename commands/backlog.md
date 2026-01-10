---
description: Display task status summary from UNIFIED_PLAN.md
---

# Backlog Status

Display a summary table of all tasks in UNIFIED_PLAN.md.

## Instructions

1. **Find UNIFIED_PLAN.md** in current working directory or repository root.

2. **If not found or empty:** Report that no backlog is defined:
   ```
   No backlog defined.

   To create a backlog, use /design to define your first task.
   This will create UNIFIED_PLAN.md with your task.
   ```

3. **If found, generate status table:**

| Task | Title | Layer | Status | Dependencies |
|------|-------|-------|--------|--------------|

Include:
- Task number
- Short title (truncate if needed)
- Layer (Crane/daosys/IndexedEx)
- Status (Complete/Ready for Agent/Pending/etc.)
- Key dependencies or blockers

4. **Show summary counts:**
- Completed tasks
- Tasks ready for agent
- Blocked/pending tasks

5. **Recommend next task** to work on (if any are ready).

## Example Output

```
# Backlog Status

| Task | Title                          | Layer    | Status          | Dependencies |
|------|--------------------------------|----------|-----------------|--------------|
| 1    | V3 Mainnet Fork Tests          | Crane    | Complete        | -            |
| 2    | Slipstream Utils               | Crane    | Complete        | -            |
| 3    | Uniswap V4 Utils               | Crane    | Ready for Agent | -            |
| 7    | Slipstream Vault               | IndexedEx| Ready for Agent | Task 2       |

Summary:
- Completed: 2
- Ready for agent: 2
- Blocked/pending: 0

Recommended next: Task 3 (Uniswap V4 Utils) - no dependencies
```

## Related Commands

- `/backlog:status` - Same as /backlog (show status)
- `/backlog:prune` - Archive completed tasks
- `/backlog:launch <N>` - Launch agent worktree for task N
- `/design` - Create a new task
- `/design:review` - Review existing tasks
