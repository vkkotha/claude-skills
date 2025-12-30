#!/usr/bin/env bash

# Setup PR Worktree Script
# Usage: ./setup-pr-worktree.sh <PR_NUMBER> [EDITOR_MODE] [EDITOR_CMD]
#
# Arguments:
#   PR_NUMBER   - Required. The pull request number to checkout
#   EDITOR_MODE - Optional. How to open the editor:
#                 "new"     - Open in new window (default)
#                 "reuse"   - Open in current window (reuses existing window)
#                 "skip"    - Don't open any editor
#   EDITOR_CMD  - Optional. Editor command to use:
#                 "code"    - VSCode (default)
#                 "cursor"  - Cursor
#                 "windsurf" - Windsurf
#                 "auto"    - Auto-detect available editor
#                 Or any custom command (e.g., "idea", "pycharm")
#
# Cross-platform: Works on macOS, Linux, Windows (Git Bash/WSL)

set -e

PR_NUMBER=$1
EDITOR_MODE=${2:-new}      # Default to "new" if not specified
EDITOR_CMD=${3:-auto}      # Default to "auto" if not specified

if [ -z "$PR_NUMBER" ]; then
    echo "Error: PR number is required"
    echo "Usage: $0 <PR_NUMBER> [EDITOR_MODE] [EDITOR_CMD]"
    echo ""
    echo "EDITOR_MODE options:"
    echo "  new   - Open in new editor window (default)"
    echo "  reuse - Open in current editor window"
    echo "  skip  - Don't open any editor"
    echo ""
    echo "EDITOR_CMD options:"
    echo "  auto     - Auto-detect available editor (default)"
    echo "  code     - VSCode"
    echo "  cursor   - Cursor"
    echo "  windsurf - Windsurf"
    echo "  <cmd>    - Any custom editor command"
    exit 1
fi

# Auto-detect editor if set to "auto"
detect_editor() {
    # Check for common editors in order of preference
    for editor in code cursor windsurf; do
        if command -v "$editor" &> /dev/null; then
            echo "$editor"
            return
        fi
    done
    echo ""  # No editor found
}

if [ "$EDITOR_CMD" = "auto" ]; then
    EDITOR_CMD=$(detect_editor)
fi

# Get project name and set paths
PROJECT_NAME=$(basename "$(pwd)")
WORKTREE_BASE="../${PROJECT_NAME}.worktrees"
WORKTREE_PATH="${WORKTREE_BASE}/PR-${PR_NUMBER}"
BRANCH_NAME="pr-${PR_NUMBER}"

# Determine the correct remote for fetching PRs
# - For fork setup: upstream points to main repo (where PRs live)
# - For direct clone: origin points to main repo
if git remote | grep -q "^upstream$"; then
    PR_REMOTE="upstream"
else
    PR_REMOTE="origin"
fi

echo "Setting up worktree for PR #${PR_NUMBER}..."
echo "Using remote: ${PR_REMOTE}"
echo "Worktree path: ${WORKTREE_PATH}"

# Fetch the PR branch from Bitbucket (from the correct remote)
echo "Fetching PR branch..."
git fetch "$PR_REMOTE" "refs/pull-requests/${PR_NUMBER}/from:${BRANCH_NAME}"

# Also fetch latest main to ensure accurate diffs later
echo "Fetching latest main branch..."
git fetch "$PR_REMOTE" main 2>/dev/null || git fetch "$PR_REMOTE" master 2>/dev/null || echo "Warning: Could not fetch main/master branch"

# Check if worktree already exists
if git worktree list | grep -q "PR-${PR_NUMBER}"; then
    echo "Worktree already exists. Updating..."
    git -C "$WORKTREE_PATH" fetch "$PR_REMOTE" "refs/pull-requests/${PR_NUMBER}/from:${BRANCH_NAME}"
    git -C "$WORKTREE_PATH" reset --hard "$BRANCH_NAME"
else
    # Check if folder exists but is not a worktree (orphaned folder)
    if [ -d "$WORKTREE_PATH" ]; then
        echo "Folder exists but is not a valid worktree. Cleaning up..."
        rm -rf "$WORKTREE_PATH"
        git worktree prune
    fi

    # Create the worktrees directory if needed
    mkdir -p "$WORKTREE_BASE"

    # Create the worktree
    echo "Creating new worktree..."
    git worktree add "$WORKTREE_PATH" "$BRANCH_NAME"
fi

echo ""
echo "Worktree ready at: ${WORKTREE_PATH}"

# Handle editor opening based on mode
case "$EDITOR_MODE" in
    skip)
        echo ""
        echo "To open in an editor later, run:"
        echo "  code \"${WORKTREE_PATH}\"       # VSCode (new window)"
        echo "  code -r \"${WORKTREE_PATH}\"    # VSCode (reuse window)"
        echo "  cursor \"${WORKTREE_PATH}\"     # Cursor"
        echo "  windsurf \"${WORKTREE_PATH}\"   # Windsurf"
        echo "  cd \"${WORKTREE_PATH}\"         # Terminal only"
        ;;
    new|reuse)
        if [ -n "$EDITOR_CMD" ] && command -v "$EDITOR_CMD" &> /dev/null; then
            if [ "$EDITOR_MODE" = "reuse" ]; then
                echo "Opening in current ${EDITOR_CMD} window..."
                "$EDITOR_CMD" -r "$WORKTREE_PATH"
            else
                echo "Opening in new ${EDITOR_CMD} window..."
                "$EDITOR_CMD" "$WORKTREE_PATH"
            fi
        else
            echo ""
            if [ -n "$EDITOR_CMD" ]; then
                echo "Note: '${EDITOR_CMD}' command not found in PATH."
            else
                echo "Note: No supported editor found in PATH (checked: code, cursor, windsurf)."
            fi
            echo ""
            echo "To open manually:"
            echo "  code \"${WORKTREE_PATH}\"       # VSCode"
            echo "  cursor \"${WORKTREE_PATH}\"     # Cursor"
            echo "  windsurf \"${WORKTREE_PATH}\"   # Windsurf"
            echo "  cd \"${WORKTREE_PATH}\"         # Terminal only"
        fi
        ;;
    *)
        echo "Warning: Unknown EDITOR_MODE '${EDITOR_MODE}'. Use 'new', 'reuse', or 'skip'."
        echo "To open manually: code \"${WORKTREE_PATH}\""
        ;;
esac
