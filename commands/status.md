---
description: Display task status summary from UNIFIED_PLAN.md
---

# Backlog Status

Display a summary table of all tasks in UNIFIED_PLAN.md.

## Instructions

1. **Read UNIFIED_PLAN.md** from current working directory or repository root.

2. **Generate status table:**

| Task | Title | Layer | Status | Dependencies |
|------|-------|-------|--------|--------------|

Include:
- Task number
- Short title (truncate if needed)
- Layer (Crane/daosys/IndexedEx)
- Status (Complete/Ready for Agent/Pending/etc.)
- Key dependencies or blockers

3. **Show summary counts:**
- Completed tasks
- Tasks ready for agent
- Blocked/pending tasks

4. **Recommend next task** to work on (if any are ready).

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

## Error Handling

- If UNIFIED_PLAN.md not found: Ask user to specify location or create one
