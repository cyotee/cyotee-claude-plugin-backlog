---
description: Display task status summary from tasks/INDEX.md
---

# Backlog Status

Display a summary table of all tasks from the tasks/ directory structure.

## Instructions

### Step 1: Detect Layers

Dynamically discover all task directories in the repository:

```bash
# Find all tasks/ directories (excluding node_modules, archive, template dirs)
find . -type d -name "tasks" -not -path "*/node_modules/*" -not -path "*/archive/*" 2>/dev/null
```

For each tasks/ directory found:
1. Read `tasks/INDEX.md` to get layer name and prefix
2. If no INDEX.md, auto-detect layer name from parent directory
3. Auto-generate prefix from first letter of layer name

### Step 2: Read INDEX.md

Read the INDEX.md file from the appropriate tasks directory.

If INDEX.md doesn't exist but task directories do, generate status by scanning:
- Read each `tasks/[PREFIX]-N/PRD.md` frontmatter for status
- Build the status table dynamically

### Step 3: Display Status Table

```
# Backlog Status - [LAYER_NAME]

| # | Title | Status | Worktree | Dependencies | Created |
|---|-------|--------|----------|--------------|---------|
| [P]-1 | Feature Name | ✅ complete | `feature/name` | - | 2026-01-05 |
| [P]-2 | Another Feature | 🚀 in_progress | `feature/other` | [P]-1 | 2026-01-08 |
| [P]-3 | Pending Feature | 🆕 pending | `feature/pending` | [P]-2 | 2026-01-10 |

## Summary

- ✅ Complete: 1
- 🚀 In Progress: 1
- 📋 Review: 0
- 🆕 Pending: 1
- ❌ Blocked: 0

## Ready for Work

Tasks with no unmet dependencies:
- [P]-3: Pending Feature (depends on [P]-2, which is in progress)

## Recommended Next

Start with: [P]-3 (after [P]-2 completes)
```

### Step 4: Check All Layers (Optional)

If user requests full ecosystem status, scan all discovered task directories:

```
# Full Ecosystem Status

## [Layer1] (path/to/tasks/)
| # | Title | Status |
...

## [Layer2] (lib/submodule/tasks/)
| # | Title | Status |
...

## [Layer3] (tasks/)
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
