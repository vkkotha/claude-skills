#!/usr/bin/env bash

# Cleanup Git Worktree Script
# Usage: ./cleanup-worktree.sh --pr <NUMBER> | --branch <NAME> | --tag <NAME> | --commit <SHA> [OPTIONS]
#
# Ref Types (one required):
#   --pr <NUMBER>      - Pull request number
#   --branch <NAME>    - Branch name
#   --tag <NAME>       - Tag name
#   --commit <SHA>     - Commit SHA (full or abbreviated)
#
# Options:
#   --yes, -y          - Skip confirmation prompts
#
# Cross-platform: Works on macOS, Linux, Windows (Git Bash/WSL)

set -e

# Default values
REF_TYPE=""
REF_VALUE=""
SKIP_CONFIRM=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --pr)
            REF_TYPE="pr"
            REF_VALUE="$2"
            shift 2
            ;;
        --branch)
            REF_TYPE="branch"
            REF_VALUE="$2"
            shift 2
            ;;
        --tag)
            REF_TYPE="tag"
            REF_VALUE="$2"
            shift 2
            ;;
        --commit)
            REF_TYPE="commit"
            REF_VALUE="$2"
            shift 2
            ;;
        --yes|-y)
            SKIP_CONFIRM=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 --pr <NUMBER> | --branch <NAME> | --tag <NAME> | --commit <SHA> [OPTIONS]"
            echo ""
            echo "Ref Types (one required):"
            echo "  --pr <NUMBER>      Pull request number"
            echo "  --branch <NAME>    Branch name"
            echo "  --tag <NAME>       Tag name"
            echo "  --commit <SHA>     Commit SHA"
            echo ""
            echo "Options:"
            echo "  --yes, -y          Skip confirmation prompts"
            echo ""
            echo "Examples:"
            echo "  $0 --pr 558"
            echo "  $0 --branch feature/login"
            echo "  $0 --tag v1.2.3"
            echo "  $0 --commit abc123def"
            echo "  $0 --pr 558 --yes"
            exit 0
            ;;
        *)
            echo "Error: Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Validate required arguments
if [ -z "$REF_TYPE" ] || [ -z "$REF_VALUE" ]; then
    echo "Error: A ref type is required"
    echo "Usage: $0 --pr <NUMBER> | --branch <NAME> | --tag <NAME> | --commit <SHA> [OPTIONS]"
    echo "Use --help for more information"
    exit 1
fi

# Get project name and set base path
PROJECT_NAME=$(basename "$(pwd)")
WORKTREE_BASE="../${PROJECT_NAME}.worktrees"

# Generate folder name and potential branch names based on ref type
# We need to check for both old-style and new worktree-prefixed branches
generate_names() {
    case $REF_TYPE in
        pr)
            FOLDER_NAME="PR-${REF_VALUE}"
            # New style: worktree-pr-<number>
            WORKTREE_BRANCH_NAME="worktree-pr-${REF_VALUE}"
            # Old style: pr-<number> (for backwards compatibility)
            OLD_BRANCH_NAME="pr-${REF_VALUE}"
            ;;
        branch)
            SANITIZED=$(echo "$REF_VALUE" | tr '/' '-')
            FOLDER_NAME="branch-${SANITIZED}"
            # New style: worktree-branch-<name>
            WORKTREE_BRANCH_NAME="worktree-branch-${SANITIZED}"
            # The original branch name (should NOT be deleted)
            ORIGINAL_BRANCH_NAME="$REF_VALUE"
            ;;
        tag)
            FOLDER_NAME="tag-${REF_VALUE}"
            WORKTREE_BRANCH_NAME="worktree-tag-${REF_VALUE}"
            ;;
        commit)
            SHORT_SHA="${REF_VALUE:0:8}"
            FOLDER_NAME="commit-${SHORT_SHA}"
            WORKTREE_BRANCH_NAME="worktree-commit-${SHORT_SHA}"
            ;;
    esac
    WORKTREE_PATH="${WORKTREE_BASE}/${FOLDER_NAME}"
}

# Ask for confirmation
confirm() {
    local message=$1
    if $SKIP_CONFIRM; then
        return 0
    fi
    echo -n "$message [y/N]: "
    read -r response
    case "$response" in
        [yY][eE][sS]|[yY])
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

generate_names

echo "Cleaning up worktree for ${REF_TYPE}: ${REF_VALUE}..."

# Check if we're currently inside the worktree we're trying to remove
CURRENT_DIR=$(pwd)
WORKTREE_ABSOLUTE_PATH=$(cd "$WORKTREE_PATH" 2>/dev/null && pwd || echo "")

if [ -n "$WORKTREE_ABSOLUTE_PATH" ] && [[ "$CURRENT_DIR" == "$WORKTREE_ABSOLUTE_PATH"* ]]; then
    echo ""
    echo "Error: Cannot remove worktree while inside it."
    echo "You are currently in: $CURRENT_DIR"
    echo "Worktree to remove:   $WORKTREE_ABSOLUTE_PATH"
    echo ""
    echo "Please change to a different directory first:"
    echo "  cd <main-repo-path>"
    echo ""
    echo "Or use the open-main-worktree.sh script to switch to the main repository."
    exit 1
fi

# Remove the worktree if it exists
if git worktree list | grep -q "${FOLDER_NAME}"; then
    echo "Removing worktree at ${WORKTREE_PATH}..."
    git worktree remove "$WORKTREE_PATH"
else
    # If folder exists but not a worktree, just remove the folder
    if [ -d "$WORKTREE_PATH" ]; then
        echo "Removing orphaned folder at ${WORKTREE_PATH}..."
        rm -rf "$WORKTREE_PATH"
    else
        echo "No worktree found for ${REF_TYPE}: ${REF_VALUE}"
    fi
fi

# Prune stale worktree references
echo "Pruning stale worktree references..."
git worktree prune

# Handle branch cleanup based on ref type
case $REF_TYPE in
    pr)
        # For PRs, delete the worktree-prefixed branch (with confirmation)
        # Check for new-style branch first
        if git branch --list "$WORKTREE_BRANCH_NAME" | grep -q "$WORKTREE_BRANCH_NAME"; then
            if confirm "Delete local branch '${WORKTREE_BRANCH_NAME}'?"; then
                echo "Deleting local branch ${WORKTREE_BRANCH_NAME}..."
                git branch -D "$WORKTREE_BRANCH_NAME"
            else
                echo "Keeping branch ${WORKTREE_BRANCH_NAME}"
            fi
        # Check for old-style branch (backwards compatibility)
        elif git branch --list "$OLD_BRANCH_NAME" | grep -q "$OLD_BRANCH_NAME"; then
            if confirm "Delete local branch '${OLD_BRANCH_NAME}'?"; then
                echo "Deleting local branch ${OLD_BRANCH_NAME}..."
                git branch -D "$OLD_BRANCH_NAME"
            else
                echo "Keeping branch ${OLD_BRANCH_NAME}"
            fi
        else
            echo "No PR branch found to delete"
        fi
        ;;
    branch)
        # For branches, only delete worktree-prefixed branches we created
        # NEVER delete the original branch
        if git branch --list "$WORKTREE_BRANCH_NAME" | grep -q "$WORKTREE_BRANCH_NAME"; then
            if confirm "Delete local branch '${WORKTREE_BRANCH_NAME}'?"; then
                echo "Deleting local branch ${WORKTREE_BRANCH_NAME}..."
                git branch -D "$WORKTREE_BRANCH_NAME"
            else
                echo "Keeping branch ${WORKTREE_BRANCH_NAME}"
            fi
        else
            echo "No worktree branch to delete (original branch '${ORIGINAL_BRANCH_NAME}' preserved)"
        fi
        ;;
    tag|commit)
        # Tags and commits use detached HEAD, but we may have created a worktree branch
        if git branch --list "$WORKTREE_BRANCH_NAME" | grep -q "$WORKTREE_BRANCH_NAME"; then
            if confirm "Delete local branch '${WORKTREE_BRANCH_NAME}'?"; then
                echo "Deleting local branch ${WORKTREE_BRANCH_NAME}..."
                git branch -D "$WORKTREE_BRANCH_NAME"
            else
                echo "Keeping branch ${WORKTREE_BRANCH_NAME}"
            fi
        fi
        ;;
esac

echo ""
echo "Cleanup complete for ${REF_TYPE}: ${REF_VALUE}"
