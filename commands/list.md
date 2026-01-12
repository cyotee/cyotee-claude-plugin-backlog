---
description: List active worktrees and their tasks
allowed-tools: Read, Bash, Glob, Grep
---

# List Active Worktrees

Show all active worktrees with their associated tasks.

## Instructions

1. **Get list of worktrees:**
   ```bash
   git worktree list
   ```

2. **For each worktree (except main):**
   - Check if PROMPT.md exists (indicates agent worktree)
   - If PROMPT.md exists, read task ID and mode
   - Get branch name and path

3. **Cross-reference with INDEX.md:**
   - Match worktrees to tasks
   - Show task status

4. **Display formatted output:**

```
═══════════════════════════════════════════════════════════════════
 ACTIVE WORKTREES
═══════════════════════════════════════════════════════════════════

| Task | Branch | Path | Mode | Status |
|------|--------|------|------|--------|
| CRANE-003 | feature/uniswap-v4-utils | /path/to/wt/feature/uniswap-v4-utils | Implementation | In Progress |
| CRANE-004 | feature/slipstream | /path/to/wt/feature/slipstream | Review | In Review |

Total: 2 active worktrees

## Main Worktree

Path: /path/to/main/repo
Branch: main

## Orphan Worktrees

(Worktrees without PROMPT.md - may be stale)

| Branch | Path |
|--------|------|
| feature/old-branch | /path/to/wt/feature/old-branch |

═══════════════════════════════════════════════════════════════════
```

## Worktree Status Detection

For each worktree:

1. **Check for PROMPT.md:**
   - If exists: Agent worktree
   - If not: Orphan or manual worktree

2. **Read mode from PROMPT.md:**
   - Look for `**Mode:** Implementation` or `**Mode:** Code Review`

3. **Read task ID from PROMPT.md:**
   - Look for `**Task:** {PREFIX}-{NNN}`

4. **Check state file:**
   - Read `.claude/backlog-agent.local.md` if exists
   - Get iteration count and max iterations

## Detailed View

If user wants more details about a specific worktree:

```
/backlog:list --verbose
```

Adds:
- Current iteration (from state file)
- Max iterations (from state file)
- Last modified date of PROGRESS.md
- Uncommitted changes count

## Cleanup Suggestions

If orphan worktrees found:

```
## Cleanup Commands

Remove orphan worktrees:

git worktree remove /path/to/wt/feature/old-branch
# or
git wt -d feature/old-branch
```

## Error Handling

- **No worktrees found:** "No active worktrees. Use /backlog:launch to start a task."
- **Git not available:** "Git command failed. Are you in a git repository?"

## Related Commands

- `/backlog:launch <ID>` - Launch a new agent worktree
- `/backlog:complete <ID>` - Complete and cleanup worktree
- `/backlog` - See all task statuses
