---
description: Read and display a specific task from UNIFIED_PLAN.md
argument-hint: <task-number>
allowed-tools: Read, Glob, Grep
---

# Read Task

Display the full content of a specific task from UNIFIED_PLAN.md.

**Task to read:** $ARGUMENTS

## Instructions

1. **Extract task number** from arguments.

2. **Find UNIFIED_PLAN.md** in the current working directory or repository root.

3. **Locate the task section** by searching for `## Task N:` where N is the task number.

4. **Extract the full task content** from the task header until the next task header (or end of file).

5. **Display the task** with formatted output including:
   - Task number and title
   - Layer (Crane/daosys/IndexedEx)
   - Status
   - Worktree (if applicable)
   - Full description
   - User stories
   - Files to create/modify
   - Inventory check items
   - Completion criteria

## Output Format

```markdown
# Task N: [Title]

**Layer:** [Crane/daosys/IndexedEx]
**Status:** [Status]
**Worktree:** [branch-name or "Not started"]

---

[Full task content from UNIFIED_PLAN.md]
```

## Error Handling

- **No task number provided:** Show usage: `/backlog:read <task-number>`
- **Task doesn't exist:** Show "Task N not found in UNIFIED_PLAN.md" and list available task numbers
- **UNIFIED_PLAN.md not found:** Show "UNIFIED_PLAN.md not found. Create one with /design or specify location."

## Examples

```
/backlog:read 5
```

Output:
```markdown
# Task 5: Protocol DETF (CHIR) System

**Layer:** IndexedEx
**Status:** Ready for Agent
**Worktree:** Not started

---

### Description
Implement the Protocol DETF system (CHIR token) with integrated fee distribution...

[Full task content]
```

## Notes

- Task numbers are permanent and never renumbered
- This is a read-only command - it does not modify any files
- Use `/backlog:launch N` to create a worktree and start working on a task
