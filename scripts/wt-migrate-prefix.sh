#!/bin/bash
# Migrate worktree branch names to include task ID prefix
# Usage: wt-migrate-prefix.sh [--dry-run] [base-dir]
#
# Changes branches from:   feature/{kebab-name}
# To:                       feature/{TASK_ID}-{kebab-name}
#
# Also moves worktree directories and updates INDEX.md.
#
# Compatible with bash 3.2+ (macOS default) - no associative arrays.
#
# Exit codes:
#   0 - Success (or nothing to migrate)
#   1 - Error during migration

set -eo pipefail

DRY_RUN=false
BASE_DIR=""

# Parse arguments
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    *) BASE_DIR="$arg" ;;
  esac
done

BASE_DIR="${BASE_DIR:-$(git rev-parse --show-toplevel)}"
WT_BASE="${BASE_DIR}-wt"
INDEX_FILE="$BASE_DIR/tasks/INDEX.md"

if [[ ! -f "$INDEX_FILE" ]]; then
  echo "No tasks/INDEX.md found at $BASE_DIR"
  exit 0
fi

echo "Worktree Migration: Add Task ID Prefix to Branch Names"
echo "======================================================="
echo ""
echo "  Repo: $BASE_DIR"
echo "  Mode: $( [[ "$DRY_RUN" == "true" ]] && echo "DRY RUN" || echo "LIVE" )"
echo ""

# Temporary directory for lookups (bash 3.2 compatible - no associative arrays)
MIGRATE_TMP=$(mktemp -d)
mkdir -p "$MIGRATE_TMP/task_branch" "$MIGRATE_TMP/task_dir"
trap 'rm -rf "$MIGRATE_TMP"' EXIT

# Parse INDEX.md to find tasks with active worktrees
echo "Scanning INDEX.md for active worktrees..."
echo ""

FOUND_WORKTREES=0
while IFS= read -r line; do
  # Skip non-table lines
  [[ ! "$line" =~ ^\|.*\|$ ]] && continue
  # Skip header and separator rows
  [[ "$line" =~ ^[[:space:]]*\|[[:space:]]*ID ]] && continue
  [[ "$line" =~ ^[[:space:]]*\|[[:space:]]*[-:]+ ]] && continue

  # Parse table columns
  line="${line#|}"
  line="${line%|}"

  i=0
  id="" worktree=""
  OLD_IFS="$IFS"
  IFS='|'
  for col in $line; do
    col=$(echo "$col" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    case $i in
      0) id="$col" ;;
      4) worktree="$col" ;;
    esac
    i=$((i + 1))
  done
  IFS="$OLD_IFS"

  # Only process rows with valid task IDs and active worktrees
  [[ ! "$id" =~ ^[A-Z]+-[0-9]+$ ]] && continue
  [[ -z "$worktree" || "$worktree" == "-" ]] && continue

  # Store mapping: task ID -> current branch name
  echo "$worktree" > "$MIGRATE_TMP/task_branch/$id"

  # Find matching task directory to get the canonical name
  TASK_DIR=$(ls -d "$BASE_DIR/tasks/${id}-"* 2>/dev/null | head -1)
  if [[ -n "$TASK_DIR" ]]; then
    basename "$TASK_DIR" > "$MIGRATE_TMP/task_dir/$id"
  fi

  FOUND_WORKTREES=$((FOUND_WORKTREES + 1))
done < "$INDEX_FILE"

if [[ $FOUND_WORKTREES -eq 0 ]]; then
  echo "No active worktrees found in INDEX.md."
  exit 0
fi

echo "Found $FOUND_WORKTREES task(s) with active worktrees."
echo ""

# Process each worktree that needs migration
MIGRATED=0
SKIPPED=0
ERRORS=0

for branch_file in "$MIGRATE_TMP/task_branch/"*; do
  [[ ! -f "$branch_file" ]] && continue

  TASK_ID=$(basename "$branch_file")
  OLD_BRANCH=$(cat "$branch_file")

  # Get task directory name for the canonical new branch name
  if [[ ! -f "$MIGRATE_TMP/task_dir/$TASK_ID" ]]; then
    echo "  SKIP $TASK_ID: No task directory found"
    SKIPPED=$((SKIPPED + 1))
    continue
  fi

  TASK_DIR_NAME=$(cat "$MIGRATE_TMP/task_dir/$TASK_ID")

  # Determine branch type prefix (e.g., "feature/")
  BRANCH_PREFIX="${OLD_BRANCH%%/*}"
  BRANCH_SUFFIX="${OLD_BRANCH#*/}"

  # Check if already has task ID prefix
  if [[ "$BRANCH_SUFFIX" =~ ^[A-Z]+-[0-9]+ ]]; then
    echo "  SKIP $TASK_ID: Branch '$OLD_BRANCH' already has task ID prefix"
    SKIPPED=$((SKIPPED + 1))
    continue
  fi

  # Construct new branch name
  NEW_BRANCH="${BRANCH_PREFIX}/${TASK_DIR_NAME}"

  # Compute worktree paths
  OLD_WT_PATH="$WT_BASE/$OLD_BRANCH"
  NEW_WT_PATH="$WT_BASE/$NEW_BRANCH"

  echo "  MIGRATE $TASK_ID:"
  echo "    Branch: $OLD_BRANCH -> $NEW_BRANCH"
  echo "    Path:   $OLD_WT_PATH -> $NEW_WT_PATH"

  if [[ "$DRY_RUN" == "true" ]]; then
    echo "    [DRY RUN] Would rename branch and move worktree"
    MIGRATED=$((MIGRATED + 1))
    continue
  fi

  # Verify old branch exists
  if ! git -C "$BASE_DIR" show-ref --verify --quiet "refs/heads/$OLD_BRANCH"; then
    echo "    ERROR: Branch '$OLD_BRANCH' does not exist"
    ERRORS=$((ERRORS + 1))
    continue
  fi

  # Check new branch doesn't already exist
  if git -C "$BASE_DIR" show-ref --verify --quiet "refs/heads/$NEW_BRANCH"; then
    echo "    ERROR: Branch '$NEW_BRANCH' already exists"
    ERRORS=$((ERRORS + 1))
    continue
  fi

  # Step 1: Rename branch
  if ! git -C "$BASE_DIR" branch -m "$OLD_BRANCH" "$NEW_BRANCH"; then
    echo "    ERROR: Failed to rename branch"
    ERRORS=$((ERRORS + 1))
    continue
  fi
  echo "    Renamed branch"

  # Step 2: Move worktree directory (if it exists at the expected path)
  if [[ -d "$OLD_WT_PATH" ]]; then
    # Ensure parent directory for new path exists
    mkdir -p "$(dirname "$NEW_WT_PATH")"

    if git -C "$BASE_DIR" worktree move "$OLD_WT_PATH" "$NEW_WT_PATH" 2>/dev/null; then
      echo "    Moved worktree directory"
    else
      # Fallback: manual move + prune
      echo "    git worktree move failed, trying manual move..."
      mv "$OLD_WT_PATH" "$NEW_WT_PATH" 2>/dev/null || true
      git -C "$BASE_DIR" worktree prune
      echo "    Moved worktree directory (manual)"
    fi
  else
    echo "    NOTE: Worktree directory not found at $OLD_WT_PATH (branch renamed only)"
  fi

  # Step 3: Update INDEX.md
  # Use pipe delimiter in sed to avoid conflicts with branch name slashes
  sed -i.bak "s|${OLD_BRANCH}|${NEW_BRANCH}|g" "$INDEX_FILE"
  rm -f "${INDEX_FILE}.bak"
  echo "    Updated INDEX.md"

  MIGRATED=$((MIGRATED + 1))
done

echo ""
echo "======================================================="
echo "Migration Summary"
echo "======================================================="
echo "  Migrated: $MIGRATED"
echo "  Skipped:  $SKIPPED"
echo "  Errors:   $ERRORS"
echo ""

# Commit changes if not dry-run and something was migrated
if [[ "$DRY_RUN" == "false" && $MIGRATED -gt 0 ]]; then
  cd "$BASE_DIR"
  git add tasks/INDEX.md
  if ! git diff --cached --quiet; then
    git commit -m "chore: migrate $MIGRATED worktree(s) to include task ID prefix in branch names"
    echo "Committed INDEX.md changes."
  fi
fi

if [[ "$DRY_RUN" == "true" && $MIGRATED -gt 0 ]]; then
  echo "Re-run without --dry-run to apply changes."
fi

echo ""
echo "Current worktrees:"
git -C "$BASE_DIR" worktree list
