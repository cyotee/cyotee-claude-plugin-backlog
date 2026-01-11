# backlog - Task Management Plugin

Manage your tasks/ directory backlog and git worktrees for autonomous agent execution.

## Installation

```bash
/plugin marketplace add cyotee/cyotee-claude-plugins
/plugin install backlog@cyotee
```

## Commands

### `/backlog`

Display a summary table of all tasks from the tasks/ directory.

**Aliases:** `/backlog:status`

**What it does:**
1. Scans for tasks/ directories in the repository
2. Reads tasks/INDEX.md or scans task directories
3. Generates a status table of all tasks
4. Shows summary counts (completed, ready, blocked)
5. Recommends the next task to work on

**Example output:**
```
# Backlog Status - [Layer Name]

| # | Title | Status | Worktree | Dependencies | Created |
|---|-------|--------|----------|--------------|---------|
| [P]-1 | Feature One | ✅ complete | - | - | 2026-01-05 |
| [P]-2 | Feature Two | 🚀 in_progress | `feature/two` | [P]-1 | 2026-01-08 |
| [P]-3 | Feature Three | 🆕 pending | - | [P]-2 | 2026-01-10 |

Summary:
- ✅ Complete: 1
- 🚀 In Progress: 1
- 🆕 Pending: 1

Recommended next: [P]-3 (after [P]-2 completes)
```

---

### `/backlog:read <task-id>`

Display the full content of a specific task.

**What it does:**
1. Parses task ID (e.g., `P-5` or just `5`)
2. Detects layer from prefix or current directory
3. Reads PRD.md, PROGRESS.md, and REVIEW.md
4. Displays formatted task summary

**Example usage:**
```
/backlog:read P-5
```

---

### `/backlog:launch <task-id>`

Create a git worktree and launch an agent for a task.

**What it does:**
1. Reads the task from tasks/[ID]/PRD.md
2. Creates worktree using `./scripts/wt-create.sh`
3. Updates task status to `in_progress`
4. Writes PROMPT.md with task instructions
5. Updates tasks/INDEX.md
6. Outputs launch instructions

**Example usage:**
```
/backlog:launch P-7
```

**Example output:**
```
# Task P-7: Feature Name

**Status:** 🚀 in_progress
**Worktree:** /path/to/repo-wt/feature/name

## Launch Agent

cd /path/to/repo-wt/feature/name
claude --dangerously-skip-permissions

## Start Working

/ralph-loop:ralph-loop "Read PROMPT.md and execute the task." --completion-promise "TASK_COMPLETE"
```

---

### `/backlog:complete [task-id] [--push] [--no-rebase]`

Finalize a completed task by rebasing onto main and preparing for review.

**Must be run from a feature worktree, not main.**

**What it does:**
1. Verifies you're in a feature worktree
2. Checks for uncommitted changes
3. Fetches and rebases onto main
4. Fast-forwards main
5. Updates task status to `review`
6. Outputs cleanup instructions

**Arguments:**
| Argument | Description |
|----------|-------------|
| `<task-id>` | Task ID (e.g., P-5) - optional, prompts if not provided |
| `--push` | Push main to origin after merge |
| `--no-rebase` | Skip rebase (use if already rebased) |

---

### `/backlog:prune [task-id] [--all]`

Archive completed and reviewed tasks.

**What it does:**
1. Identifies tasks with `status: complete` and passing review
2. Moves task directories to `tasks/archive/`
3. Updates tasks/INDEX.md
4. Outputs cleanup instructions for worktrees

**Arguments:**
| Argument | Description |
|----------|-------------|
| `<task-id>` | Specific task to archive (e.g., P-5) |
| `--all` | Archive all completed tasks |

---

## Layer Detection

Layers are detected dynamically:

```bash
# Find all tasks/ directories
find . -type d -name "tasks" -not -path "*/node_modules/*" 2>/dev/null
```

For each discovered tasks/ directory:
1. Read `tasks/INDEX.md` for layer name and prefix
2. If not found, auto-detect from directory/repo name
3. Prefix is first letter of layer name (uppercase)

## Task States

| State | Icon | Description |
|-------|------|-------------|
| pending | 🆕 | Ready to start, dependencies met |
| in_progress | 🚀 | Agent actively working |
| review | 📋 | Work complete, awaiting review |
| complete | ✅ | Reviewed and approved |
| blocked | ❌ | Waiting on dependencies |

---

## Scripts

The plugin includes submodule-aware worktree management scripts in `scripts/`:

### `wt-create.sh`

Creates a worktree with proper submodule initialization:

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/wt-create.sh" <branch-name> [repo-root]
```

### `wt-remove.sh`

Removes a worktree safely (handles submodules):

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/wt-remove.sh" <branch-name> [repo-root]
```

**Why scripts instead of `git wt -d`?**
1. Worktrees with submodules can't be removed without `--force`
2. Submodule pointers can become corrupt
3. Lock files cause "Another git process" errors
4. Nested submodules need fallback copying when git init fails

## Requirements

- **git-wt** or **wt-create.sh**: Git worktree helper
- **tasks/**: Task directory (created by `/design:init`)

## Workflow Integration

```
1. /design <feature>      # Create task
2. /backlog               # View all tasks
3. /backlog:read P-5      # Read task details
4. /backlog:launch P-5    # Create worktree
5. (agent works)          # Execute task
6. /backlog:complete P-5  # Prepare for review
7. /backlog:prune P-5     # Archive after review
```

## License

MIT
