---
description: List all unarchived tasks with status, dependencies, and worktrees
argument-hint: [--worktrees-only]
allowed-tools: Read, Bash, Glob, Grep
---

# List Tasks

Show all unarchived tasks with their status, dependencies, and associated worktrees.

**Arguments:** $ARGUMENTS

## Instructions

### Step 1: Load Configuration

```bash
cat design.yaml 2>/dev/null
```

Extract `repo_prefix` and `repo_name` for display.

### Step 2: Check for Tasks

Find tasks/INDEX.md in current working directory.

**If not found or empty:**
```
No tasks defined.

To create tasks:
1. Run /design:init to create the tasks/ directory structure
2. Run /design to create your first task
```

### Step 3: Build Dependency Graph

Use the dependency utilities to build the full dependency graph:

```bash
source "${CLAUDE_PLUGIN_ROOT}/scripts/deps.sh"
deps_build_graph
```

This parses tasks/INDEX.md and any cross-repo dependencies.

### Step 4: Get Worktree Information

```bash
git worktree list
```

Build a map of branch → worktree path for cross-referencing.

For each worktree (except main):
- Check if PROMPT.md exists
- If exists, extract task ID and mode from PROMPT.md
- Build map of task_id → {path, mode, branch}

### Step 5: Display Task List

**If `--worktrees-only` argument:** Skip to Step 6 (worktrees only view).

**Otherwise, show all tasks:**

```
═══════════════════════════════════════════════════════════════════
 TASK LIST: {REPO_NAME}
═══════════════════════════════════════════════════════════════════

| ID | Title | Status | Dependencies | Worktree |
|----|-------|--------|--------------|----------|
| {PREFIX}-001 | Core infrastructure | ✅ Complete | - | - |
| {PREFIX}-002 | Registry system | 🚀 In Progress | - | feature/registry |
| {PREFIX}-003 | Fee collector | ❌ Blocked | {PREFIX}-002 | - |
| {PREFIX}-004 | Vault types | 🆕 Ready | {PREFIX}-001 | - |
| {PREFIX}-005 | Protocol integration | 📋 In Review | {PREFIX}-003, {PREFIX}-004 | feature/protocol |

## Summary

Total: 5 tasks

| Status | Count | Tasks |
|--------|-------|-------|
| ✅ Complete | 1 | {PREFIX}-001 |
| 🚀 In Progress | 1 | {PREFIX}-002 |
| 📋 In Review | 1 | {PREFIX}-005 |
| 🆕 Ready | 1 | {PREFIX}-004 |
| ❌ Blocked | 1 | {PREFIX}-003 |

## Active Worktrees

| Task | Branch | Path | Mode |
|------|--------|------|------|
| {PREFIX}-002 | feature/registry | /path/to/wt/feature/registry | Implementation |
| {PREFIX}-005 | feature/protocol | /path/to/wt/feature/protocol | Review |

## Next Actions

Ready to start:
- /backlog:launch {PREFIX}-004

Currently blocked:
- {PREFIX}-003: Waiting on {PREFIX}-002

═══════════════════════════════════════════════════════════════════
```

### Step 6: Worktrees-Only View (--worktrees-only)

If `--worktrees-only` argument provided, show only worktree information:

```
═══════════════════════════════════════════════════════════════════
 ACTIVE WORKTREES
═══════════════════════════════════════════════════════════════════

| Task | Branch | Path | Mode | Status |
|------|--------|------|------|--------|
| {PREFIX}-002 | feature/registry | /path/to/wt/feature/registry | Implementation | In Progress |
| {PREFIX}-005 | feature/protocol | /path/to/wt/feature/protocol | Review | In Review |

Total: 2 active worktrees

## Main Worktree

Path: /path/to/main/repo
Branch: main

## Orphan Worktrees

(Worktrees without PROMPT.md or unknown task - may be stale)

| Branch | Path |
|--------|------|
| feature/old-branch | /path/to/wt/feature/old-branch |

## Cleanup Commands

Remove orphan worktrees:

"${CLAUDE_PLUGIN_ROOT}/scripts/wt-remove.sh" feature/old-branch

═══════════════════════════════════════════════════════════════════
```

## Status Icons

| Status | Icon | Description |
|--------|------|-------------|
| Complete | ✅ | Task finished and merged |
| In Progress | 🚀 | Agent actively working |
| In Review | 📋 | Work complete, code review |
| Ready | 🆕 | All dependencies met, can start |
| Blocked | ❌ | Waiting on dependencies |

## Dependency Display

For each task, show dependencies:
- `-` if no dependencies
- Comma-separated task IDs if dependencies exist
- Use computed status (blocked if deps incomplete, ready if deps complete)

## Worktree Detection

For each worktree:

1. **Check for PROMPT.md:**
   - If exists: Agent worktree, extract task ID
   - If not: Orphan or manual worktree

2. **Read mode from PROMPT.md:**
   - Look for `**Mode:** Implementation` or `**Mode:** Code Review`

3. **Read task ID from PROMPT.md:**
   - Look for `**Task:** {PREFIX}-{NNN}`

## Arguments Reference

| Argument | Description |
|----------|-------------|
| `--worktrees-only` | Show only active worktrees (legacy behavior) |

## Error Handling

- **No tasks/ directory:** "Run /design:init to set up task management"
- **No design.yaml:** "Run /design:init to configure the repository"
- **Empty INDEX.md:** "No tasks defined. Use /design to create your first task"
- **Git not available:** "Git command failed. Are you in a git repository?"

## Related Commands

- `/backlog` - Detailed status with dependency graph and analysis
- `/backlog:read <ID>` - Read full task details
- `/backlog:launch <ID>` - Launch a new agent worktree
- `/backlog:complete <ID>` - Complete and cleanup worktree
- `/backlog:prune` - Archive completed tasks
