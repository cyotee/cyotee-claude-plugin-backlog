---
description: Display task status summary from tasks/INDEX.md
---

# Backlog Status

Display a summary table of all tasks from the tasks/ directory structure.

## Instructions

### Step 1: Identify Layer

Determine which layer's tasks to show based on current working directory:

| Location | Layer | Tasks Directory |
|----------|-------|-----------------|
| Repository root | IndexedEx | `tasks/` |
| `lib/daosys/` | daosys | `lib/daosys/tasks/` |
| `lib/daosys/lib/crane/` | Crane | `lib/daosys/lib/crane/tasks/` |

### Step 2: Read INDEX.md

Read the INDEX.md file from the appropriate tasks directory.

If INDEX.md doesn't exist but task directories do, generate status by scanning:
- Read each `tasks/[PREFIX]-N/PRD.md` frontmatter for status
- Build the status table dynamically

### Step 3: Display Status Table

```
# Backlog Status - [Layer]

| # | Title | Status | Worktree | Dependencies | Created |
|---|-------|--------|----------|--------------|---------|
| I-1 | Feature Name | ✅ complete | `feature/name` | - | 2026-01-05 |
| I-2 | Another Feature | 🚀 in_progress | `feature/other` | I-1 | 2026-01-08 |
| I-3 | Pending Feature | 🆕 pending | `feature/pending` | I-2 | 2026-01-10 |

## Summary

- ✅ Complete: 1
- 🚀 In Progress: 1
- 📋 Review: 0
- 🆕 Pending: 1
- ❌ Blocked: 0

## Ready for Work

Tasks with no unmet dependencies:
- I-3: Pending Feature (depends on I-2, which is in progress)

## Recommended Next

Start with: I-3 (after I-2 completes)
```

### Step 4: Check All Layers (Optional)

If user requests full ecosystem status, scan all three task directories:

```
# Full Ecosystem Status

## Crane Layer (lib/daosys/lib/crane/tasks/)
| # | Title | Status |
...

## daosys Layer (lib/daosys/tasks/)
| # | Title | Status |
...

## IndexedEx Layer (tasks/)
| # | Title | Status |
...
```

## Status Icons

- 🆕 **pending** - Task defined, not started
- 🚀 **in_progress** - Agent actively working
- 📋 **review** - Implementation complete, awaiting review
- ✅ **complete** - Reviewed and merged
- ❌ **blocked** - Cannot proceed

## Error Handling

- **No tasks/ directory:** Suggest running `/design:init`
- **Empty tasks/:** Show "No tasks defined. Run /design:task to create one."
- **INDEX.md missing but tasks exist:** Generate status from PRD.md files
