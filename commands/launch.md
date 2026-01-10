---
description: Launch agent worktree for a specific task
argument-hint: <task-number>
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
---

# Launch Agent Worktree

Create a git worktree and PROMPT.md for a task, ready for agent execution.

**Task to launch:** $ARGUMENTS

## Instructions

1. **Extract task number** from arguments.

2. **Read UNIFIED_PLAN.md** and find the specified task.

3. **Determine worktree location** based on task Layer:
   - **Crane:** worktree in `lib/daosys/lib/crane` submodule
   - **daosys:** worktree in `lib/daosys` submodule
   - **IndexedEx/product:** worktree in repo root

4. **Get branch name** from the task's "Worktree:" field.

5. **Create the worktree:**
   ```bash
   cd <appropriate-location>
   git wt <branch-name>
   ```

6. **Write PROMPT.md** in the worktree root containing:
   - The full task description from UNIFIED_PLAN.md
   - Clear instructions to read and execute the task
   - Completion promise format: `<promise>TASK_COMPLETE</promise>`
   - Blocked format: `<promise>TASK_BLOCKED: [reason]</promise>`

7. **Record worktree in UNIFIED_PLAN.md:**
   - Find the "## Worktree Status" section
   - Add a new row to the table:
     ```
     | Task N | `<branch-name>` | 🚀 In Progress |
     ```
   - If the table doesn't have a "Task" column, update the header:
     ```
     | Task | Worktree | Status |
     |------|----------|--------|
     ```

8. **Output launch instructions:**

```
# Launch Agent for Task N: <title>

Worktree created at: <full-worktree-path>
Recorded in UNIFIED_PLAN.md

## Start the agent:

cd <full-worktree-path>
claude --dangerously-skip-permissions

## Then in Claude, run:

/ralph-loop:ralph-loop "Read PROMPT.md and execute the task described in it." --completion-promise "TASK_COMPLETE" --max-iterations 10
```

## PROMPT.md Template

```markdown
# Task N: [Title]

[Full task content from UNIFIED_PLAN.md]

---

## Agent Instructions

1. Read this PROMPT.md and CLAUDE.md to understand the task
2. Perform inventory checks listed above
3. Implement the user stories
4. Verify completion criteria are met
5. Output your completion promise

## Completion

When done, output: `<promise>TASK_COMPLETE</promise>`

If blocked, output: `<promise>TASK_BLOCKED: [reason]</promise>`
```

## Worktree Status Table Format

The table in UNIFIED_PLAN.md should follow this format:

```markdown
## Worktree Status

| Task | Worktree | Status |
|------|----------|--------|
| 1 | `feature/v3-mainnet-fork-tests` | ✅ Complete (merged to `crane/main`) |
| 2 | `feature/slipstream-utils` | ✅ Complete (merged to `crane/main`) |
| 3 | `feature/uniswap-v4-utils` | 🚀 In Progress |
```

**Status values:**
- `🚀 In Progress` - Worktree active, agent working
- `✅ Complete (merged to <branch>)` - Task done, worktree can be deleted
- `⏸️ Paused` - Worktree exists but agent not running
- `❌ Blocked: <reason>` - Agent encountered blocker

## Error Handling

- **Task doesn't exist:** Show available task numbers
- **Task already complete:** Warn user and ask for confirmation
- **Worktree creation fails:** Show error and manual steps
- **UNIFIED_PLAN.md not found:** Ask user to specify location
- **Worktree already exists:** Show existing worktree path and ask to continue

## Notes

- Task numbers are permanent (never renumbered)
- For Crane tasks, worktree path: `lib/daosys/lib/crane/../crane-wt/feature/<branch>`
- Worktrees are created on-demand via this command
- The worktree status table provides visibility into active agents
