#!/usr/bin/env bash

# Setup Git Worktree Script
# Usage: ./setup-worktree.sh --pr <NUMBER> | --branch <NAME> | --tag <NAME> | --commit <SHA> [OPTIONS]
#
# Ref Types (one required):
#   --pr <NUMBER>      - Pull request number (fetches from remote PR refs)
#   --branch <NAME>    - Branch name (local or remote)
#   --tag <NAME>       - Tag name
#   --commit <SHA>     - Commit SHA (full or abbreviated)
#
# Options:
#   --editor <MODE>    - How to open the editor:
#                        "new"     - Open in new window (default)
#                        "reuse"   - Open in current window
#                        "skip"    - Don't open any editor
#   --editor-cmd <CMD> - Editor command to use:
#                        "auto"    - Auto-detect available editor (default)
#                        "code"    - VSCode
#                        "cursor"  - Cursor
#                        "windsurf" - Windsurf
#                        Or any custom command
#
# PR Support:
#   - Bitbucket: refs/pull-requests/<PR>/from
#   - GitHub: refs/pull/<PR>/head
#
# Cross-platform: Works on macOS, Linux, Windows (Git Bash/WSL)

set -e

# Default values
REF_TYPE=""
REF_VALUE=""
EDITOR_MODE="new"
EDITOR_CMD="auto"

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
        --editor)
            EDITOR_MODE="$2"
            shift 2
            ;;
        --editor-cmd)
            EDITOR_CMD="$2"
            shift 2
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
            echo "  --editor <MODE>    How to open editor: new (default), reuse, skip"
            echo "  --editor-cmd <CMD> Editor command: auto (default), code, cursor, windsurf, or custom"
            echo "  -h, --help         Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0 --pr 558"
            echo "  $0 --branch feature/login --editor skip"
            echo "  $0 --tag v1.2.3 --editor-cmd cursor"
            echo "  $0 --commit abc123def --editor reuse"
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

# Auto-detect editor if set to "auto"
detect_editor() {
    for editor in code cursor windsurf; do
        if command -v "$editor" >/dev/null 2>&1; then
            echo "$editor"
            return
        fi
    done
    echo ""
}

if [ "$EDITOR_CMD" = "auto" ]; then
    EDITOR_CMD=$(detect_editor)
fi

# Get project name and set base path
PROJECT_NAME=$(basename "$(pwd)")
WORKTREE_BASE="../${PROJECT_NAME}.worktrees"

# Determine the correct remote
if git remote | grep -q "^upstream$"; then
    GIT_REMOTE="upstream"
else
    GIT_REMOTE="origin"
fi

# Generate worktree folder name and branch name based on ref type
# Folder names use prefixes to avoid collisions
generate_names() {
    case $REF_TYPE in
        pr)
            FOLDER_NAME="PR-${REF_VALUE}"
            BRANCH_NAME="pr-${REF_VALUE}"
            ;;
        branch)
            # Convert slashes to dashes for folder name
            SANITIZED=$(echo "$REF_VALUE" | tr '/' '-')
            FOLDER_NAME="branch-${SANITIZED}"
            BRANCH_NAME="worktree-branch-${SANITIZED}"
            ;;
        tag)
            FOLDER_NAME="tag-${REF_VALUE}"
            BRANCH_NAME="worktree-tag-${REF_VALUE}"
            ;;
        commit)
            # Use first 8 characters of commit SHA
            SHORT_SHA="${REF_VALUE:0:8}"
            FOLDER_NAME="commit-${SHORT_SHA}"
            BRANCH_NAME="worktree-commit-${SHORT_SHA}"
            ;;
    esac
    WORKTREE_PATH="${WORKTREE_BASE}/${FOLDER_NAME}"
}

generate_names

echo "Setting up worktree for ${REF_TYPE}: ${REF_VALUE}..."
echo "Using remote: ${GIT_REMOTE}"
echo "Worktree path: ${WORKTREE_PATH}"

# Fetch and setup based on ref type
case $REF_TYPE in
    pr)
        echo "Fetching PR branch..."
        if git fetch "$GIT_REMOTE" "refs/pull-requests/${REF_VALUE}/from:${BRANCH_NAME}" 2>/dev/null; then
            echo "Fetched from Bitbucket PR refs"
        elif git fetch "$GIT_REMOTE" "refs/pull/${REF_VALUE}/head:${BRANCH_NAME}" 2>/dev/null; then
            echo "Fetched from GitHub PR refs"
        else
            echo "Error: Could not fetch PR #${REF_VALUE}"
            echo "Tried:"
            echo "  - Bitbucket: refs/pull-requests/${REF_VALUE}/from"
            echo "  - GitHub: refs/pull/${REF_VALUE}/head"
            echo ""
            echo "Verify the PR number and your access to the repository."
            exit 1
        fi
        GIT_REF="$BRANCH_NAME"
        ;;
    branch)
        echo "Fetching branch..."
        # Try to fetch the branch from remote first
        if git fetch "$GIT_REMOTE" "${REF_VALUE}:${BRANCH_NAME}" 2>/dev/null; then
            echo "Fetched branch from ${GIT_REMOTE}"
            GIT_REF="$BRANCH_NAME"
        elif git show-ref --verify --quiet "refs/heads/${REF_VALUE}" 2>/dev/null; then
            # Branch exists locally
            echo "Using local branch"
            GIT_REF="$REF_VALUE"
            BRANCH_NAME="$REF_VALUE"
        else
            echo "Error: Branch '${REF_VALUE}' not found locally or on ${GIT_REMOTE}"
            exit 1
        fi
        ;;
    tag)
        echo "Fetching tags..."
        git fetch "$GIT_REMOTE" --tags 2>/dev/null || true
        if git show-ref --verify --quiet "refs/tags/${REF_VALUE}" 2>/dev/null; then
            echo "Found tag: ${REF_VALUE}"
            GIT_REF="tags/${REF_VALUE}"
        else
            echo "Error: Tag '${REF_VALUE}' not found"
            exit 1
        fi
        ;;
    commit)
        echo "Verifying commit..."
        # Fetch recent history if commit not found
        if ! git cat-file -t "$REF_VALUE" >/dev/null 2>&1; then
            echo "Fetching from remote..."
            git fetch "$GIT_REMOTE" --depth=100 2>/dev/null || git fetch "$GIT_REMOTE" 2>/dev/null || true
        fi
        if git cat-file -t "$REF_VALUE" >/dev/null 2>&1; then
            # Get full SHA
            FULL_SHA=$(git rev-parse "$REF_VALUE")
            echo "Found commit: ${FULL_SHA}"
            GIT_REF="$FULL_SHA"
        else
            echo "Error: Commit '${REF_VALUE}' not found"
            exit 1
        fi
        ;;
esac

# Also fetch latest main/master for reference
echo "Fetching latest main branch..."
git fetch "$GIT_REMOTE" main 2>/dev/null || git fetch "$GIT_REMOTE" master 2>/dev/null || true

# Check if worktree already exists
if git worktree list | grep -q "${FOLDER_NAME}"; then
    echo "Worktree already exists. Updating..."
    case $REF_TYPE in
        pr)
            if git -C "$WORKTREE_PATH" fetch "$GIT_REMOTE" "refs/pull-requests/${REF_VALUE}/from:${BRANCH_NAME}" 2>/dev/null; then
                :
            elif git -C "$WORKTREE_PATH" fetch "$GIT_REMOTE" "refs/pull/${REF_VALUE}/head:${BRANCH_NAME}" 2>/dev/null; then
                :
            fi
            git -C "$WORKTREE_PATH" reset --hard "$BRANCH_NAME"
            ;;
        branch)
            git -C "$WORKTREE_PATH" fetch "$GIT_REMOTE" "${REF_VALUE}" 2>/dev/null || true
            git -C "$WORKTREE_PATH" reset --hard "$GIT_REF"
            ;;
        tag|commit)
            git -C "$WORKTREE_PATH" reset --hard "$GIT_REF"
            ;;
    esac
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
    case $REF_TYPE in
        pr|branch)
            git worktree add "$WORKTREE_PATH" "$GIT_REF"
            ;;
        tag|commit)
            # Tags and commits create detached HEAD worktrees
            git worktree add --detach "$WORKTREE_PATH" "$GIT_REF"
            ;;
    esac
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
        if [ -n "$EDITOR_CMD" ] && command -v "$EDITOR_CMD" >/dev/null 2>&1; then
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
        echo "Warning: Unknown editor mode '${EDITOR_MODE}'. Use 'new', 'reuse', or 'skip'."
        echo "To open manually: code \"${WORKTREE_PATH}\""
        ;;
esac
