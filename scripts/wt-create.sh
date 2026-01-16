#!/bin/bash
# Create worktree with optimized submodule handling
# Usage: wt-create.sh <branch-name> [base-dir]
#
# Arguments:
#   branch-name: Name of the branch/worktree to create
#   base-dir: Optional repo root (defaults to git root)
#
# Submodule Strategy:
#   Uses --reference to share git objects with main repo's submodules,
#   dramatically speeding up worktree creation while maintaining separate
#   working directories. Falls back to copying if reference fails.

set -e

BRANCH="${1:?Usage: wt-create.sh <branch-name> [base-dir]}"
BASE_DIR="${2:-$(git rev-parse --show-toplevel)}"
REPO_NAME="$(basename "$BASE_DIR")"
WT_BASE="${BASE_DIR}-wt"
WORKTREE_PATH="$WT_BASE/$BRANCH"

echo "Creating worktree: $BRANCH"
echo "  Base repo: $BASE_DIR"
echo "  Worktree path: $WORKTREE_PATH"

# Check if worktree already exists
if git -C "$BASE_DIR" worktree list | grep -q "$WORKTREE_PATH"; then
    echo "⚠️  Worktree already exists at $WORKTREE_PATH"
    exit 0
fi

# Create worktree
if git -C "$BASE_DIR" show-ref --verify --quiet "refs/heads/$BRANCH"; then
    echo "  Branch exists, creating worktree..."
    git -C "$BASE_DIR" worktree add "$WORKTREE_PATH" "$BRANCH"
else
    echo "  Creating new branch from HEAD..."
    git -C "$BASE_DIR" worktree add -b "$BRANCH" "$WORKTREE_PATH" HEAD
fi

# Initialize submodules with reference to main repo for speed
echo ""
echo "Initializing submodules..."
cd "$WORKTREE_PATH"

# Check if there are submodules to initialize
if [ ! -f ".gitmodules" ]; then
    echo "  No submodules found"
    echo ""
    echo "✅ Worktree ready: $WORKTREE_PATH"
    exit 0
fi

# Try --reference first (shares git objects, much faster)
# This shares the object store but maintains separate working directories
echo "  Using --reference for faster initialization..."
if git submodule update --init --recursive --reference "$BASE_DIR" 2>/dev/null; then
    echo "✅ Submodules initialized with --reference (shared objects)"
else
    echo "⚠️  --reference failed, trying standard init..."

    # Fallback to normal submodule init
    if git submodule update --init --recursive 2>/dev/null; then
        echo "✅ Submodules initialized via git"
    else
        echo "⚠️  Git submodule init failed, copying from main repo..."

        # Find and copy submodules from main repo as last resort
        if [ -f "$BASE_DIR/.gitmodules" ]; then
            # Parse .gitmodules for submodule paths
            grep "path = " "$BASE_DIR/.gitmodules" | sed 's/.*path = //' | while read -r subpath; do
                src="$BASE_DIR/$subpath"
                dst="$WORKTREE_PATH/$subpath"

                if [ -d "$src" ] && [ ! -z "$(ls -A "$src" 2>/dev/null)" ]; then
                    echo "  Copying $subpath..."
                    rm -rf "$dst"
                    mkdir -p "$(dirname "$dst")"
                    cp -R "$src" "$dst"
                fi
            done
            echo "✅ Submodules copied from main repo"
        fi
    fi
fi

echo ""
echo "✅ Worktree ready: $WORKTREE_PATH"
