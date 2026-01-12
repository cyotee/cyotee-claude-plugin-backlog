---
description: Launch agent worktree for a specific task
argument-hint: <task-id> [--max-iterations N]
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
---

# Launch Agent Worktree

Create a git worktree and PROMPT.md for a task, ready for agent execution.

**Arguments:** $ARGUMENTS

## Instructions

### Phase 1: Parse Arguments

1. **Extract task ID** from arguments (e.g., "CRANE-003").

2. **Extract optional flags:**
   - `--max-iterations N` - Safety limit for agent iterations (default: 0 = unlimited)

### Phase 2: Validate Task

1. **Find task directory:**
   ```bash
   ls -d tasks/${TASK_ID}-* 2>/dev/null
   ```

2. **If not found:** Show available tasks and abort.

3. **Read task files:**
   - `tasks/{ID}-{name}/TASK.md` - Get task details
   - `tasks/{ID}-{name}/PROGRESS.md` - Check if exists

4. **Check task status:**
   - If "Complete": Warn and ask for confirmation
   - If "In Progress": Warn that worktree may already exist
   - If "Blocked": Show blockers and ask for confirmation

### Phase 3: Prepare Task Files

1. **Initialize PROGRESS.md** if it doesn't exist or is empty:
   ```markdown
   # Progress Log: {PREFIX}-{NNN}

   ## Current Checkpoint

   **Last checkpoint:** Not started
   **Next step:** Read TASK.md and begin implementation
   **Build status:** ⏳ Not checked
   **Test status:** ⏳ Not checked

   ---

   ## Session Log

   ### {TODAY} - Task Launched

   - Task launched via /backlog:launch
   - Agent worktree created
   - Ready to begin implementation
   ```

2. **Commit task files** to ensure worktree will have them:
   ```bash
   git add tasks/${TASK_ID}-*/
   git commit -m "chore: prepare task ${TASK_ID} for agent launch" --allow-empty
   ```

### Phase 4: Create Worktree

1. **Load configuration:**
   ```bash
   cat design.yaml
   ```

2. **Determine worktree location:**
   ```bash
   REPO_ROOT=$(git rev-parse --show-toplevel)
   BRANCH="feature/{kebab-name-from-task}"
   WT_PATH="${REPO_ROOT}-wt/${BRANCH}"
   ```

3. **Create worktree:**
   ```bash
   "${CLAUDE_PLUGIN_ROOT}/scripts/wt-create.sh" "${BRANCH}" "${REPO_ROOT}"
   ```

4. **Initialize submodules:**
   ```bash
   cd "${WT_PATH}"
   git submodule update --init --recursive
   ```

### Phase 5: Setup Agent Environment

1. **Create PROMPT.md** in worktree root that **points to** task files:

```markdown
# Agent Task Assignment

**Task:** {PREFIX}-{NNN} - {Title}
**Repo:** {REPO_NAME}
**Mode:** Implementation
**Task Directory:** tasks/{PREFIX}-{NNN}-{kebab-name}/

## Required Reading

1. `tasks/{PREFIX}-{NNN}-{kebab-name}/TASK.md` - Full requirements
2. `tasks/{PREFIX}-{NNN}-{kebab-name}/PROGRESS.md` - Prior work and current state

## Instructions

1. Read TASK.md to understand requirements
2. Read PROGRESS.md to see what's been done
3. Continue work from where you left off
4. **Update PROGRESS.md** as you work (newest entries first)
5. When complete, output: `<promise>TASK_COMPLETE</promise>`
6. If blocked, output: `<promise>TASK_BLOCKED: [reason]</promise>`

## On Context Compaction

If your context is compacted or you're resuming work:
1. Re-read this PROMPT.md
2. Re-read PROGRESS.md for your prior state
3. Continue from the last recorded progress

## Completion Checklist

Before marking complete, verify:
- [ ] All acceptance criteria in TASK.md are checked
- [ ] PROGRESS.md has final summary
- [ ] All tests pass
- [ ] Build succeeds
```

2. **Create state file** (if max-iterations specified):
   ```bash
   mkdir -p "${WT_PATH}/.claude"
   ```

   Write `.claude/backlog-agent.local.md`:
   ```markdown
   ---
   active: true
   iteration: 1
   max_iterations: {N or 0}
   started_at: "{ISO_TIMESTAMP}"
   task_id: "{TASK_ID}"
   mode: "implementation"
   ---
   ```

3. **Update tasks/INDEX.md** status to "In Progress":
   ```markdown
   | {PREFIX}-{NNN} | {Title} | In Progress | {Deps} | feature/{name} |
   ```

### Phase 6: Output Launch Instructions

Output ready-to-use commands with **absolute paths**:

```
═══════════════════════════════════════════════════════════════════
 AGENT READY: {PREFIX}-{NNN} - {Title}
═══════════════════════════════════════════════════════════════════

Task files committed and worktree created.

## Step 1: Open a new terminal and run:

cd {ABSOLUTE_WORKTREE_PATH}

## Step 2: Start Claude Code:

claude --dangerously-skip-permissions

## Step 3: Give Claude this prompt:

/up:prompt

This will read PROMPT.md which directs the agent to:
- tasks/{PREFIX}-{NNN}-{kebab-name}/TASK.md (requirements)
- tasks/{PREFIX}-{NNN}-{kebab-name}/PROGRESS.md (progress log)

## Stop Hook

The Stop hook will prevent exit until:
- Agent outputs <promise>TASK_COMPLETE</promise>
- Agent outputs <promise>TASK_BLOCKED: [reason]</promise>
- Max iterations reached ({N or "unlimited"})

Agent will use subscription usage, not API credits.

═══════════════════════════════════════════════════════════════════
```

## Arguments Reference

| Argument | Description |
|----------|-------------|
| `<task-id>` | Task ID to launch (e.g., CRANE-003) |
| `--max-iterations N` | Optional safety limit (default: 0 = unlimited) |

## Error Handling

- **Task doesn't exist:** Show available task IDs
- **Task already complete:** Warn and ask for confirmation
- **Worktree already exists:** Show path and ask to continue or abort
- **Worktree creation fails:** Show error and manual steps
- **No tasks/ directory:** "Run /design:init first"
- **Submodule init fails:** Copy from main repo as fallback

## Why Commit Before Worktree?

- Worktree is created from current HEAD
- If task files aren't committed, worktree won't have them
- Agent needs TASK.md and PROGRESS.md to exist in the worktree

## Example Session

```bash
$ /backlog:launch CRANE-003 --max-iterations 20

Finding task CRANE-003...
  Found: tasks/CRANE-003-uniswap-v4-utils/

Preparing task files...
  PROGRESS.md initialized
  Files committed: chore: prepare task CRANE-003 for agent launch

Creating worktree...
  Branch: feature/uniswap-v4-utils
  Path: /Users/you/repos/crane-wt/feature/uniswap-v4-utils

Initializing submodules...
  ✅ Submodules ready

Setting up agent environment...
  PROMPT.md created
  State file created (max 20 iterations)
  INDEX.md updated

═══════════════════════════════════════════════════════════════════
 AGENT READY: CRANE-003 - Uniswap V4 Utils
═══════════════════════════════════════════════════════════════════

...
```
