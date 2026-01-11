---
description: Launch agent worktree for a specific task
argument-hint: <task-id>
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
---

# Launch Agent for Task

Create a git worktree and launch an agent for a specific task.

**Task to launch:** $ARGUMENTS

## Instructions

### Step 1: Parse Task ID

Extract the task ID from arguments. Expected formats:
- `I-5` (full ID)
- `5` (assumes current layer prefix)
- `C-3` (Crane task)
- `D-2` (daosys task)

Determine the layer and task directory:

| Prefix | Layer | Tasks Directory |
|--------|-------|-----------------|
| I | IndexedEx | `tasks/` |
| D | daosys | `lib/daosys/tasks/` |
| C | Crane | `lib/daosys/lib/crane/tasks/` |

### Step 2: Verify Task Exists

Check that the task directory exists:

```bash
ls tasks/[PREFIX]-[N]/PRD.md
```

If not found, show available tasks and exit.

### Step 3: Read Task PRD

Read `tasks/[PREFIX]-[N]/PRD.md` to get:
- Task title (from frontmatter)
- Worktree name (from frontmatter)
- Status
- Dependencies

### Step 4: Check Dependencies

Read PRD frontmatter for dependencies. For each dependency:
- Read the dependency's PRD.md
- Check its status
- If not complete: warn user, ask to continue anyway

### Step 5: Check Task Status

If task is already `in_progress`:
- Warn user
- Ask if they want to continue (resume existing work)

If task is `complete`:
- Warn user task is already done
- Ask for confirmation to reopen

If task is `blocked`:
- Show block reason
- Ask user to resolve or override

### Step 6: Update Task Status

Update the PRD.md frontmatter to `in_progress`:

```yaml
status: in_progress
```

Update INDEX.md with the status change.

### Step 7: Create Worktree

Get worktree name from PRD frontmatter and create:

```bash
# Use the submodule-aware script if available
./scripts/wt-create.sh [worktree-name]
```

Or if script not available:

```bash
git worktree add ../[repo]-wt/[worktree-name] -b [worktree-name]
cd ../[repo]-wt/[worktree-name]
git submodule update --init --recursive
```

### Step 8: Update PROGRESS.md

Add entry to the task's PROGRESS.md (at the top, reverse chronological):

```markdown
### [Today's Date Time] - Agent Launched

- Worktree created at: [path]
- Agent session starting
- Reading PRD.md for requirements

**Build status:** ⏳ Not checked
**Test status:** ⏳ Not checked
```

### Step 9: Output Launch Instructions

```
# Task [PREFIX]-[N]: [Title]

**Status:** 🚀 in_progress
**Worktree:** [full-path]
**Dependencies:** [list or "None - ready to start"]

## Launch Agent

```bash
cd [worktree-path]
claude --dangerously-skip-permissions
```

## Start Working

In Claude, run:

```
/ralph-loop:ralph-loop "Read tasks/[PREFIX]-[N]/PRD.md and PROGRESS.md. Execute the task, updating PROGRESS.md as you work." --completion-promise "TASK_COMPLETE" --max-iterations 10
```

## Task Files

- PRD: tasks/[PREFIX]-[N]/PRD.md
- Progress: tasks/[PREFIX]-[N]/PROGRESS.md
- Review: tasks/[PREFIX]-[N]/REVIEW.md

## Completion

When done, the agent will output `<promise>TASK_COMPLETE</promise>`

Then run: /backlog:complete [PREFIX]-[N]
```

## Error Handling

- **Task doesn't exist:** Show available tasks from INDEX.md
- **Worktree already exists:** Ask to use existing or recreate
- **Dependency not complete:** Show dependency status, ask to continue
- **Submodule init fails:** Show manual commands

## Notes

- Task IDs are permanent (never renumbered)
- For Crane tasks, worktree in crane submodule directory
- Tasks are tracked in tasks/INDEX.md
- Agent updates PROGRESS.md as it works
