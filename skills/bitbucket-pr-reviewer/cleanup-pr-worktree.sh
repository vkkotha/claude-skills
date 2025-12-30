#!/usr/bin/env bash

# Cleanup PR Worktree Script
# Usage: ./cleanup-pr-worktree.sh <PR_NUMBER>
#
# Cross-platform: Works on macOS, Linux, Windows (Git Bash/WSL)

set -e

PR_NUMBER=$1

if [ -z "$PR_NUMBER" ]; then
    echo "Error: PR number is required"
    echo "Usage: $0 <PR_NUMBER>"
    exit 1
fi

# Get project name and set paths
PROJECT_NAME=$(basename "$(pwd)")
WORKTREE_PATH="../${PROJECT_NAME}.worktrees/PR-${PR_NUMBER}"
BRANCH_NAME="pr-${PR_NUMBER}"

echo "Cleaning up worktree for PR #${PR_NUMBER}..."

# Remove the worktree if it exists
if git worktree list | grep -q "PR-${PR_NUMBER}"; then
    echo "Removing worktree at ${WORKTREE_PATH}..."
    git worktree remove "$WORKTREE_PATH"
else
    # If folder exists but not a worktree, just remove the folder
    if [ -d "$WORKTREE_PATH" ]; then
        echo "Removing orphaned folder at ${WORKTREE_PATH}..."
        rm -rf "$WORKTREE_PATH"
    else
        echo "No worktree found for PR #${PR_NUMBER}"
    fi
fi

# Prune stale worktree references
echo "Pruning stale worktree references..."
git worktree prune

# Delete the local PR branch if it exists
if git branch --list "$BRANCH_NAME" | grep -q "$BRANCH_NAME"; then
    echo "Deleting local branch ${BRANCH_NAME}..."
    git branch -D "$BRANCH_NAME"
else
    echo "No local branch ${BRANCH_NAME} found"
fi

echo ""
echo "Cleanup complete for PR #${PR_NUMBER}"
