#!/usr/bin/env bash

# Cleanup Git Worktree Script
# Usage: ./cleanup-worktree.sh --pr <NUMBER> | --branch <NAME> | --tag <NAME> | --commit <SHA>
#
# Ref Types (one required):
#   --pr <NUMBER>      - Pull request number
#   --branch <NAME>    - Branch name
#   --tag <NAME>       - Tag name
#   --commit <SHA>     - Commit SHA (full or abbreviated)
#
# Cross-platform: Works on macOS, Linux, Windows (Git Bash/WSL)

set -e

# Default values
REF_TYPE=""
REF_VALUE=""

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
        -h|--help)
            echo "Usage: $0 --pr <NUMBER> | --branch <NAME> | --tag <NAME> | --commit <SHA>"
            echo ""
            echo "Ref Types (one required):"
            echo "  --pr <NUMBER>      Pull request number"
            echo "  --branch <NAME>    Branch name"
            echo "  --tag <NAME>       Tag name"
            echo "  --commit <SHA>     Commit SHA"
            echo ""
            echo "Examples:"
            echo "  $0 --pr 558"
            echo "  $0 --branch feature/login"
            echo "  $0 --tag v1.2.3"
            echo "  $0 --commit abc123def"
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
    echo "Usage: $0 --pr <NUMBER> | --branch <NAME> | --tag <NAME> | --commit <SHA>"
    echo "Use --help for more information"
    exit 1
fi

# Get project name and set base path
PROJECT_NAME=$(basename "$(pwd)")
WORKTREE_BASE="../${PROJECT_NAME}.worktrees"

# Generate folder name and branch name based on ref type
generate_names() {
    case $REF_TYPE in
        pr)
            FOLDER_NAME="PR-${REF_VALUE}"
            BRANCH_NAME="pr-${REF_VALUE}"
            ;;
        branch)
            SANITIZED=$(echo "$REF_VALUE" | tr '/' '-')
            FOLDER_NAME="branch-${SANITIZED}"
            BRANCH_NAME="worktree-branch-${SANITIZED}"
            ;;
        tag)
            FOLDER_NAME="tag-${REF_VALUE}"
            BRANCH_NAME="worktree-tag-${REF_VALUE}"
            ;;
        commit)
            SHORT_SHA="${REF_VALUE:0:8}"
            FOLDER_NAME="commit-${SHORT_SHA}"
            BRANCH_NAME="worktree-commit-${SHORT_SHA}"
            ;;
    esac
    WORKTREE_PATH="${WORKTREE_BASE}/${FOLDER_NAME}"
}

generate_names

echo "Cleaning up worktree for ${REF_TYPE}: ${REF_VALUE}..."

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

# Delete the local branch if it exists (not applicable for tags/commits with detached HEAD)
if [ "$REF_TYPE" = "pr" ] || [ "$REF_TYPE" = "branch" ]; then
    if git branch --list "$BRANCH_NAME" | grep -q "$BRANCH_NAME"; then
        echo "Deleting local branch ${BRANCH_NAME}..."
        git branch -D "$BRANCH_NAME"
    else
        echo "No local branch ${BRANCH_NAME} found"
    fi
fi

echo ""
echo "Cleanup complete for ${REF_TYPE}: ${REF_VALUE}"
