---
description: Migrate worktree branch names to include task ID prefix
argument-hint: [--dry-run]
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
---

# Migrate Worktree Branch Names

Migrate existing worktrees from the old naming convention (`feature/{kebab-name}`) to the new convention (`feature/{TASK_ID}-{kebab-name}`). This ensures every worktree branch includes its task ID for easy matching by humans and agents.

**Arguments:** $ARGUMENTS

## Instructions

### Step 1: Detect Dry-Run Flag

```bash
DRY_RUN=""
if [[ "$ARGUMENTS" == *"--dry-run"* ]]; then
  DRY_RUN="--dry-run"
  echo "Running in DRY RUN mode (no changes will be made)"
  echo ""
fi
```

### Step 2: Verify Prerequisites

1. **Check tasks/INDEX.md exists:**
   ```bash
   if [[ ! -f "tasks/INDEX.md" ]]; then
     echo "No tasks/INDEX.md found. Run /design:init first."
     exit 1
   fi
   ```

2. **Check migration script exists:**
   ```bash
   SCRIPT="${CLAUDE_PLUGIN_ROOT}/scripts/wt-migrate-prefix.sh"
   if [[ ! -f "$SCRIPT" ]]; then
     echo "ERROR: Migration script not found at $SCRIPT"
     exit 1
   fi
   ```

### Step 3: Run Migration Script

```bash
REPO_ROOT=$(git rev-parse --show-toplevel)
"${CLAUDE_PLUGIN_ROOT}/scripts/wt-migrate-prefix.sh" $DRY_RUN "$REPO_ROOT"
```

The script will:
- Scan INDEX.md for tasks with active worktrees
- Skip branches that already have a task ID prefix
- For each branch needing migration:
  - Rename the git branch to include the task ID
  - Move the worktree directory to match the new branch name
  - Update the Worktree column in INDEX.md
- Commit INDEX.md changes (unless `--dry-run`)

### Step 4: Report Results

**If dry-run:**
```
═══════════════════════════════════════════════════════════════════
 DRY RUN COMPLETE
═══════════════════════════════════════════════════════════════════

No changes were made. Re-run without --dry-run to apply:

  /backlog:migrate

═══════════════════════════════════════════════════════════════════
```

**If live run:**
```
═══════════════════════════════════════════════════════════════════
 MIGRATION COMPLETE
═══════════════════════════════════════════════════════════════════

Worktree branches now include task ID prefixes.

## What Changed

- Branches renamed: feature/{name} -> feature/{TASK_ID}-{name}
- Worktree directories moved to match
- INDEX.md updated with new branch names
- Changes committed

## Verify

Run: git worktree list

All branches should show task ID prefixes (e.g., feature/CRANE-003-utils).

## Note for Active Worktree Sessions

If you have Claude sessions running in migrated worktrees, they will
need to be restarted since their working directory path has changed.

═══════════════════════════════════════════════════════════════════
```

## Error Handling

- **No INDEX.md:** "Run /design:init first"
- **No active worktrees:** "No worktrees to migrate" (not an error)
- **Branch already has task ID:** Skipped automatically
- **Branch rename fails:** Reported per-worktree, others continue
- **Worktree move fails:** Falls back to manual move + prune

## Examples

```bash
# Preview what would change
/backlog:migrate --dry-run

# Apply migration
/backlog:migrate
```

## Related Commands

- `/backlog:launch <ID>` - Creates worktrees with new naming convention
- `/backlog:complete <ID>` - Completes and removes worktrees
- `/backlog` - View task status
