---
description: Display task status summary from tasks/INDEX.md
---

# Backlog Status

Display a summary table of all tasks from tasks/INDEX.md.

## Instructions

1. **Load configuration:**
   ```bash
   cat design.yaml 2>/dev/null
   ```
   Extract `repo_prefix` and `repo_name`.

2. **Find tasks/INDEX.md** in current working directory.

3. **If not found or empty:** Report that no backlog is defined:
   ```
   No backlog defined.

   To create a backlog:
   1. Run /design:init to create the tasks/ directory structure
   2. Run /design to create your first task
   ```

4. **If found, read and display the contents** with formatted output:

```
═══════════════════════════════════════════════════════════════════
 BACKLOG STATUS: {REPO_NAME}
═══════════════════════════════════════════════════════════════════

| ID | Title | Status | Dependencies | Worktree |
|----|-------|--------|--------------|----------|
| {PREFIX}-001 | ... | Complete | - | - |
| {PREFIX}-002 | ... | In Progress | - | feature/... |
| {PREFIX}-003 | ... | Ready | {PREFIX}-001 | - |

## Summary

- Complete: N
- In Progress: N
- In Review: N
- Ready: N
- Blocked: N

## Ready for Agent

Tasks that can be started:
- {PREFIX}-003: {Title}
- {PREFIX}-004: {Title}

## Blocked

Tasks waiting on dependencies:
- {PREFIX}-005: Waiting on {PREFIX}-003

## Next Recommended

{PREFIX}-003: {Title} - no dependencies, ready to start

═══════════════════════════════════════════════════════════════════
```

5. **Show summary counts:**
   - Complete tasks
   - In Progress tasks
   - In Review tasks
   - Ready tasks (no blockers)
   - Blocked tasks

6. **Recommend next task** to work on (prefer tasks with no dependencies).

## Related Commands

- `/backlog:read <ID>` - Read full task details
- `/backlog:launch <ID>` - Launch agent worktree for a task
- `/backlog:review <ID>` - Transition task to review mode
- `/backlog:complete <ID>` - Complete and merge a task
- `/backlog:prune` - Archive completed tasks
- `/backlog:list` - List active worktrees
- `/design` - Create a new task
- `/design:review` - Review task definitions

## Error Handling

- **No tasks/ directory:** "Run /design:init to set up task management"
- **No design.yaml:** "Run /design:init to configure the repository"
- **Empty INDEX.md:** "No tasks defined. Use /design to create your first task"
