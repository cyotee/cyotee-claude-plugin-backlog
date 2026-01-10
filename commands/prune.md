---
description: Archive completed tasks from UNIFIED_PLAN.md
---

# Prune Completed Tasks

Remove completed tasks from UNIFIED_PLAN.md and archive them.

## Instructions

1. **Read UNIFIED_PLAN.md** from current working directory or repository root.

2. **Identify completed tasks** (status contains "Complete").

3. **For each completed task:**
   - Remove the entire task section (from `## Task N:` to the next `---`)
   - Add a summary line to a "Completed Tasks Archive" section at the end

4. **Important:**
   - DO NOT renumber remaining tasks - task numbers are permanent
   - Update the "Last Updated" date

5. **Show what was pruned:**

```
# Pruned Tasks

Archived 2 completed tasks:
- Task 1: V3 Mainnet Fork Tests
- Task 2: Slipstream Utils

Remaining tasks: 3, 5, 7, 8, 9, 10
```

6. **Commit the changes** with message: `docs: prune completed tasks from UNIFIED_PLAN.md`

## Archive Format

Add to end of UNIFIED_PLAN.md:

```markdown
## Completed Tasks Archive

| Task | Title | Completed |
|------|-------|-----------|
| 1 | V3 Mainnet Fork Tests | 2026-01-05 |
| 2 | Slipstream Utils | 2026-01-07 |
```

## Error Handling

- If no completed tasks: Inform user, no changes made
- If UNIFIED_PLAN.md not found: Ask user to specify location
