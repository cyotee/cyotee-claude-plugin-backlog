---
description: List all unarchived tasks with status, dependencies, and worktrees
---

# List Tasks

Display all unarchived tasks with status, dependencies, and worktrees.

**Arguments:** $ARGUMENTS

## Step 1: Read Configuration

```bash
cat design.yaml 2>/dev/null
```

Extract `repo_prefix` for task ID pattern matching.

## Step 2: Read INDEX.md

Read `tasks/INDEX.md` to get all tasks. Parse the markdown table to extract:
- ID (e.g., CRANE-001)
- Title
- Status (Complete, In Progress, In Review, Ready, Blocked)
- Dependencies (task IDs this depends on)
- Worktree (branch name if active)

**If tasks/INDEX.md not found:**
```
No tasks defined.

To create tasks:
1. Run /init to create the tasks/ directory structure
2. Run /design to create your first task
```

## Step 3: Get Active Worktrees

```bash
git worktree list
```

For each worktree (except main), check if `PROMPT.md` exists and extract task ID.

## Step 4: Compute Status

For each task:
- If status is "Complete", "In Progress", or "In Review" - use stored status
- If all dependencies are Complete - status is "Ready"
- If any dependency is not Complete - status is "Blocked"

## Step 5: Output Format

**If `--worktrees-only`:** Skip to worktrees-only section below.

**Standard output:**

```
═══════════════════════════════════════════════════════════════════════════════
  TASK LIST: {PROJECT_NAME}
═══════════════════════════════════════════════════════════════════════════════
┌───────────┬──────────────────────────────────────────┬──────────────────┬──────────────────────────┬────────────────────┐
│ ID        │ Title                                    │ Status           │ Dependencies             │ Worktree           │
├───────────┼──────────────────────────────────────────┼──────────────────┼──────────────────────────┼────────────────────┤
│ PROJ-001  │ Core infrastructure                      │ ✅ Complete      │ -                        │ -                  │
├───────────┼──────────────────────────────────────────┼──────────────────┼──────────────────────────┼────────────────────┤
│ PROJ-002  │ Registry system                          │ 🚀 In Progress   │ PROJ-001                 │ feature/registry   │
├───────────┼──────────────────────────────────────────┼──────────────────┼──────────────────────────┼────────────────────┤
│ PROJ-003  │ Fee collector                            │ ❌ Blocked       │ PROJ-002                 │ -                  │
├───────────┼──────────────────────────────────────────┼──────────────────┼──────────────────────────┼────────────────────┤
│ PROJ-004  │ Vault types                              │ 🆕 Ready         │ PROJ-001                 │ -                  │
└───────────┴──────────────────────────────────────────┴──────────────────┴──────────────────────────┴────────────────────┘

Summary

Total: 4 tasks
┌──────────────────┬───────┬────────────────────────────┐
│ Status           │ Count │ Tasks                      │
├──────────────────┼───────┼────────────────────────────┤
│ ✅ Complete      │ 1     │ PROJ-001                   │
├──────────────────┼───────┼────────────────────────────┤
│ 🚀 In Progress   │ 1     │ PROJ-002                   │
├──────────────────┼───────┼────────────────────────────┤
│ 🆕 Ready         │ 1     │ PROJ-004                   │
├──────────────────┼───────┼────────────────────────────┤
│ ❌ Blocked       │ 1     │ PROJ-003                   │
└──────────────────┴───────┴────────────────────────────┘

Next Actions

Ready to start:
- /launch PROJ-004 - Vault types

Currently blocked:
- PROJ-003: Waiting on PROJ-002
```

## Worktrees-Only View (--worktrees-only)

```
═══════════════════════════════════════════════════════════════════════════════
  ACTIVE WORKTREES
═══════════════════════════════════════════════════════════════════════════════
┌───────────┬────────────────────────┬────────────────────────────────────────┬────────────────┐
│ Task      │ Branch                 │ Path                                   │ Mode           │
├───────────┼────────────────────────┼────────────────────────────────────────┼────────────────┤
│ PROJ-002  │ feature/registry       │ /path/to/worktree                      │ Implementation │
└───────────┴────────────────────────┴────────────────────────────────────────┴────────────────┘

Total: 1 active worktree
```

## Status Icons Reference

| Status | Icon |
|--------|------|
| Complete | ✅ |
| In Progress | 🚀 |
| In Review | 📋 |
| Changes Requested | 🔄 |
| Ready | 🆕 |
| Blocked | ❌ |

## Related Commands

- `/backlog` - Detailed status with dependency graph
- `/read <ID>` - Read full task details
- `/launch <ID>` - Launch agent worktree
- `/complete <ID>` - Complete and cleanup
