---
description: Launch agent worktree for a specific task
argument-hint: <task-id>
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
---

# Launch Agent for Task

Create a git worktree, generate PROMPT.md with memory protocol, and provide launch instructions.

**Task to launch:** $ARGUMENTS

## Instructions

### Step 1: Parse Task ID

Extract the task ID from arguments. Expected formats:
- `[PREFIX]-N` (full ID with prefix, e.g., `I-5`)
- `N` (number only - assumes current layer prefix from INDEX.md)

### Step 2: Detect Layer and Verify Task

Read `tasks/INDEX.md` to get:
- Layer name and prefix
- Verify task exists in index

If task not found, show available tasks and exit.

### Step 3: Read Task PRD

Read `tasks/[PREFIX]-[N]/PRD.md` to get:
- Task title (from first heading or frontmatter)
- Worktree name (from frontmatter, e.g., `feature/protocol-detf`)
- Status
- Dependencies
- Brief description (first paragraph after title)

### Step 4: Check Dependencies

Read PRD frontmatter for dependencies. For each dependency:
- Read the dependency's PRD.md
- Check its status
- If not complete: warn user, ask to continue anyway

### Step 5: Determine Worktree State

Get the repository name and construct worktree path:
```bash
REPO_NAME=$(basename $(git rev-parse --show-toplevel))
WORKTREE_BASE="../${REPO_NAME}-wt"
WORKTREE_PATH="${WORKTREE_BASE}/[worktree-name]"
```

Check worktree state and handle accordingly:

**State A: Worktree does not exist**
- Will create new worktree
- Will create fresh PROMPT.md
- Will create fresh PROGRESS.md (or preserve existing in tasks/ if present)

**State B: Worktree exists and is clean**
- Use AskUserQuestion to ask about PROMPT.md:
  1. "Review existing for errors, then keep"
  2. "Regenerate with latest template"
  3. "Keep existing without review"
- Preserve existing PROGRESS.md

**State C: Worktree exists with uncommitted changes**
- Warn user about dirty state
- Show `git status` summary from worktree
- Use AskUserQuestion: "Commit changes first", "Continue anyway", or "Abort"

**State D: Worktree exists but is behind local main**
Check if behind:
```bash
git -C [worktree-path] rev-list HEAD..main --count
```
- If behind, warn user and suggest: `git merge main` (use local main, NOT origin/main)

### Step 6: Create or Verify Worktree

If worktree doesn't exist:

```bash
# Use the submodule-aware script if available
./scripts/wt-create.sh [worktree-name]

# Or fallback:
git worktree add ../[repo]-wt/[worktree-name] -b [worktree-name]
cd ../[repo]-wt/[worktree-name]
git submodule update --init --recursive
```

### Step 7: Generate PROMPT.md

Create `PROMPT.md` in the **worktree root** with this template.

**IMPORTANT:** Replace all placeholders with actual values from the PRD:
- `[PREFIX]-[N]` with actual task ID (e.g., `I-5`)
- `[Title]` with actual task title
- `[task-summary]` with 2-3 sentences from PRD description
- `[key-requirements]` with bullet list of main acceptance criteria

```markdown
# Task [PREFIX]-[N]: [Title]

## Memory Protocol

**On every iteration, you MUST:**

1. Read `CLAUDE.md` for project conventions
2. Read `tasks/[PREFIX]-[N]/PRD.md` for full requirements
3. Read `tasks/[PREFIX]-[N]/PROGRESS.md` for prior work and context
4. Update PROGRESS.md after each significant action

**Progress update format:**

### [YYYY-MM-DD HH:MM] - [Action Description]
- Completed: [what you accomplished]
- Files modified: [list of files]
- Next: [immediate next step]
- Blockers: [any issues, or "None"]

**Context management:**

If you notice context is getting long (many tool calls, large file reads):
1. Update PROGRESS.md with detailed current state including:
   - Exact file and line you're working on
   - What remains to be done
   - Any decisions made
2. Run `/compact`
3. After compaction, re-read: this file (PROMPT.md), CLAUDE.md, PRD.md, and PROGRESS.md
4. Continue working from where you left off

## Task Summary

[task-summary]

## Key Requirements

[key-requirements]

## Completion Criteria

When ALL acceptance criteria in `tasks/[PREFIX]-[N]/PRD.md` are satisfied:
1. Update PROGRESS.md with final status (mark as ready for review)
2. Ensure all tests pass: `forge test`
3. Ensure code compiles: `forge build`
4. Output: `<promise>TASK_COMPLETE</promise>`

## Files to Read

Start by reading these files in order:
1. `CLAUDE.md` - Project conventions and patterns
2. `tasks/[PREFIX]-[N]/PRD.md` - Full requirements
3. `tasks/[PREFIX]-[N]/PROGRESS.md` - Work log and resumable state
```

### Step 8: Create or Preserve PROGRESS.md

**If PROGRESS.md does not exist** in `tasks/[PREFIX]-[N]/`, create it:

```markdown
# Progress: [PREFIX]-[N] - [Title]

**Started:** [YYYY-MM-DD HH:MM]
**Status:** in_progress

## Checkpoints

Use this section for resumable state after `/compact`:

**Current phase:** Not started
**Files modified:** None yet
**Tests passing:** Not checked
**Next action:** Read PRD.md and begin implementation

---

## Work Log

### [YYYY-MM-DD HH:MM] - Agent Session Started

- Worktree: `[worktree-name]`
- PROMPT.md generated
- Ready to begin work

---
```

**If PROGRESS.md already exists**, append a new session entry at the TOP of the Work Log section (after the `## Work Log` heading, before existing entries):

```markdown
### [YYYY-MM-DD HH:MM] - Agent Session Resumed

- Worktree: `[worktree-name]`
- Resuming from previous session
- Reading PRD.md and prior progress

---
```

### Step 9: Update Task Status

Update the PRD.md frontmatter to `in_progress` if not already:

```yaml
status: in_progress
```

Update INDEX.md status column to match.

### Step 10: Output Launch Instructions

Display to the user:

```
================================================================================
# Task [PREFIX]-[N]: [Title]
================================================================================

**Status:** in_progress
**Worktree:** [full-worktree-path]
**Dependencies:** [list or "None"]

## Launch Commands

Run these commands to start the agent:

    cd [full-worktree-path]
    claude --dangerously-skip-permissions

## Start the Agent

Once Claude Code is running, enter this command:

    /ralph-loop:ralph-loop "Read PROMPT.md and follow its instructions. This file tells you which other files to read and how to track your progress." --completion-promise "TASK_COMPLETE" --max-iterations 15

## Files Created/Updated

- PROMPT.md (worktree root) - Agent instructions with memory protocol
- tasks/[PREFIX]-[N]/PROGRESS.md - Work log and resumable state

## When Complete

The agent will output `<promise>TASK_COMPLETE</promise>` when done.

Then return to this session and run:

    /backlog:complete [PREFIX]-[N]

================================================================================
```

## Error Handling

- **Task doesn't exist:** Show available tasks from INDEX.md
- **Worktree creation fails:** Show manual git worktree commands
- **Submodule init fails:** Suggest copying from main repo
- **Worktree dirty:** Show status and ask user how to proceed
- **Behind local main:** Suggest `git merge main` in worktree (not origin/main)

## Notes

- One task per worktree, one agent per worktree
- PROMPT.md lives in worktree root for easy access
- PROGRESS.md lives in tasks/[ID]/ and is committed with the work
- Agent uses PROGRESS.md to survive context compaction
- Task IDs are permanent (never renumbered)
