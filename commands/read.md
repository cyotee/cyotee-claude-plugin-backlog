---
description: Read and display a specific task from tasks/
argument-hint: <task-id>
allowed-tools: Read, Glob, Grep
---

# Read Task

Display the full content of a specific task from the tasks/ directory.

**Task to read:** $ARGUMENTS

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

### Step 2: Read Task Files

Read all three task files:
- `tasks/[PREFIX]-[N]/PRD.md` - Requirements and acceptance criteria
- `tasks/[PREFIX]-[N]/PROGRESS.md` - Progress log
- `tasks/[PREFIX]-[N]/REVIEW.md` - Review status (if started)

### Step 3: Display Task Summary

```markdown
# Task [PREFIX]-[N]: [Title]

**Layer:** [from frontmatter]
**Status:** [from frontmatter]
**Worktree:** [from frontmatter]
**Created:** [from frontmatter]
**Dependencies:** [from frontmatter]

---

## PRD Summary

[First section of PRD.md - Description]

## Acceptance Criteria

[Checklist from User Stories]

## Current Progress

**Last checkpoint:** [from PROGRESS.md header]
**Next step:** [from PROGRESS.md header]
**Build status:** [from PROGRESS.md]
**Test status:** [from PROGRESS.md]

## Recent Progress Entries

[Last 3 entries from PROGRESS.md]

## Review Status

**Verdict:** [from REVIEW.md frontmatter or "Not reviewed"]
**Reviewer:** [from REVIEW.md frontmatter or "Pending"]

---

## Quick Actions

- View full PRD: `cat tasks/[PREFIX]-[N]/PRD.md`
- View progress: `cat tasks/[PREFIX]-[N]/PROGRESS.md`
- Launch agent: `/backlog:launch [PREFIX]-[N]`
- Complete task: `/backlog:complete [PREFIX]-[N]`
```

## Error Handling

- **No task ID provided:** Show usage: `/backlog:read <task-id>`
- **Task doesn't exist:** Show "Task [ID] not found" and list available tasks
- **Tasks directory missing:** Suggest running `/design:init`

## Examples

```
/backlog:read I-5
```

Output:
```markdown
# Task I-5: Protocol DETF (CHIR) System

**Layer:** IndexedEx
**Status:** 🚀 in_progress
**Worktree:** feature/protocol-detf
**Created:** 2026-01-05
**Dependencies:** I-3, I-4

---

## PRD Summary

Implement the Protocol DETF system (CHIR token) with integrated fee distribution...

## Current Progress

**Last checkpoint:** Interfaces Complete (2026-01-10 15:01)
**Next step:** Implement ProtocolDETFRepo.sol
**Build status:** ✅ Passing
**Test status:** ⏳ No tests yet

...
```

## Notes

- This is a read-only command - it does not modify any files
- Use `/backlog:launch [ID]` to create a worktree and start working
- Use `/backlog:status` to see all tasks
