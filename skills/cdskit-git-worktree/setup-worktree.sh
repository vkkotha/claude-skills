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
#                        "auto"    - Auto-detect IDE from environment (default)
#                        "skip"    - Don't open any editor
#   --editor-cmd <CMD> - Override editor command (optional):
#                        "code"    - VSCode
#                        "idea"    - IntelliJ IDEA
#                        "claude"  - Claude Code CLI
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
EDITOR_MODE="auto"
EDITOR_CMD=""

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
            echo "  --editor <MODE>    How to open: auto (default), skip"
            echo "  --editor-cmd <CMD> Override editor: code, idea, claude, or custom command"
            echo "  -h, --help         Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0 --pr 558"
            echo "  $0 --branch feature/login --editor skip"
            echo "  $0 --tag v1.2.3 --editor-cmd idea"
            echo "  $0 --commit abc123def --editor-cmd claude"
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

# Detect IDE context from environment
# Returns: vscode, jetbrains, or cli
detect_ide_context() {
    # VS Code detection (includes Cursor, Windsurf which set similar vars)
    if [ -n "$VSCODE_GIT_IPC_HANDLE" ] || [ -n "$VSCODE_IPC_HOOK" ] || \
       [ "$TERM_PROGRAM" = "vscode" ]; then
        echo "vscode"
        return
    fi

    # JetBrains IDE detection
    if [ -n "$IDEA_INITIAL_DIRECTORY" ] || [ -n "$JETBRAINS_IDE" ] || \
       [ -n "$__INTELLIJ_COMMAND_HISTFILE__" ]; then
        echo "jetbrains"
        return
    fi

    # Default to CLI
    echo "cli"
}

# Get the appropriate command for opening in detected IDE
get_ide_command() {
    local context=$1
    case $context in
        vscode)
            # Try to find the right VS Code variant
            if command -v code >/dev/null 2>&1; then
                echo "code"
            else
                echo ""
            fi
            ;;
        jetbrains)
            # JetBrains IDEs use 'idea' or specific commands
            for cmd in idea pycharm webstorm phpstorm goland clion rider rubymine; do
                if command -v "$cmd" >/dev/null 2>&1; then
                    echo "$cmd"
                    return
                fi
            done
            echo ""
            ;;
        cli)
            # Claude Code CLI
            if command -v claude >/dev/null 2>&1; then
                echo "claude"
            else
                echo ""
            fi
            ;;
    esac
}

IDE_CONTEXT=$(detect_ide_context)

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
# All branches created by this script use "worktree-" prefix to distinguish them
# from user's existing branches
generate_names() {
    case $REF_TYPE in
        pr)
            FOLDER_NAME="PR-${REF_VALUE}"
            BRANCH_NAME="worktree-pr-${REF_VALUE}"
            ;;
        branch)
            # Convert slashes to dashes for folder/branch name
            SANITIZED=$(echo "$REF_VALUE" | tr '/' '-')
            FOLDER_NAME="branch-${SANITIZED}"
            # For branches, we'll track whether we're using an existing local branch
            # or creating a new worktree-prefixed branch for remote
            BRANCH_NAME="$REF_VALUE"  # May be overridden for remote branches
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
        # Check if branch exists locally first
        if git show-ref --verify --quiet "refs/heads/${REF_VALUE}" 2>/dev/null; then
            echo "Using existing local branch: ${REF_VALUE}"
            GIT_REF="$REF_VALUE"
            BRANCH_NAME="$REF_VALUE"
            USING_EXISTING_BRANCH=true
        else
            # Fetch from remote and create local worktree-prefixed branch
            git fetch "$GIT_REMOTE" "${REF_VALUE}" 2>/dev/null || true
            # Check if remote branch exists
            if git show-ref --verify --quiet "refs/remotes/${GIT_REMOTE}/${REF_VALUE}" 2>/dev/null; then
                # Use worktree- prefix for branches we create from remote
                SANITIZED=$(echo "$REF_VALUE" | tr '/' '-')
                BRANCH_NAME="worktree-branch-${SANITIZED}"
                echo "Creating worktree branch '${BRANCH_NAME}' from: ${GIT_REMOTE}/${REF_VALUE}"
                git branch "$BRANCH_NAME" "${GIT_REMOTE}/${REF_VALUE}" 2>/dev/null || true
                git branch --set-upstream-to="${GIT_REMOTE}/${REF_VALUE}" "$BRANCH_NAME" 2>/dev/null || true
                GIT_REF="$BRANCH_NAME"
                USING_EXISTING_BRANCH=false
            else
                echo "Error: Branch '${REF_VALUE}' not found locally or on ${GIT_REMOTE}"
                exit 1
            fi
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
        pr)
            git worktree add "$WORKTREE_PATH" "$GIT_REF"
            ;;
        branch)
            # Branch worktrees always use a local branch (either existing or tracking)
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
        echo "To open later:"
        echo "  code \"${WORKTREE_PATH}\"     # VS Code"
        echo "  idea \"${WORKTREE_PATH}\"     # IntelliJ IDEA"
        echo "  claude \"${WORKTREE_PATH}\"   # Claude Code CLI"
        ;;
    auto|*)
        # Determine which command to use
        if [ -n "$EDITOR_CMD" ]; then
            # User specified a command
            OPEN_CMD="$EDITOR_CMD"
        else
            # Auto-detect from IDE context
            OPEN_CMD=$(get_ide_command "$IDE_CONTEXT")
        fi

        if [ -z "$OPEN_CMD" ]; then
            echo ""
            echo "Note: Could not detect IDE or find editor command."
            echo "Detected context: $IDE_CONTEXT"
            echo ""
            echo "To open manually:"
            echo "  code \"${WORKTREE_PATH}\"     # VS Code"
            echo "  idea \"${WORKTREE_PATH}\"     # IntelliJ IDEA"
            echo "  claude \"${WORKTREE_PATH}\"   # Claude Code CLI"
        elif ! command -v "$OPEN_CMD" >/dev/null 2>&1; then
            echo ""
            echo "Note: '${OPEN_CMD}' command not found in PATH."
            echo ""
            echo "To open manually:"
            echo "  code \"${WORKTREE_PATH}\"     # VS Code"
            echo "  idea \"${WORKTREE_PATH}\"     # IntelliJ IDEA"
            echo "  claude \"${WORKTREE_PATH}\"   # Claude Code CLI"
        else
            echo ""
            echo "Detected IDE context: $IDE_CONTEXT"
            echo "Opening with: $OPEN_CMD"

            # Open based on command type
            case "$OPEN_CMD" in
                claude)
                    # Claude Code CLI: open VS Code with the worktree folder
                    # Claude Code will be available in the new window's terminal
                    if command -v code >/dev/null 2>&1; then
                        echo ""
                        echo "Opening worktree in VS Code (Claude Code available in terminal)..."
                        code "$WORKTREE_PATH"
                    else
                        # Fallback: copy command to clipboard if possible
                        local cmd="cd \"${WORKTREE_PATH}\" && claude"
                        if command -v pbcopy >/dev/null 2>&1; then
                            echo "$cmd" | pbcopy
                            echo ""
                            echo "Command copied to clipboard. Paste to start Claude Code:"
                            echo "  $cmd"
                        elif command -v xclip >/dev/null 2>&1; then
                            echo "$cmd" | xclip -selection clipboard
                            echo ""
                            echo "Command copied to clipboard. Paste to start Claude Code:"
                            echo "  $cmd"
                        else
                            echo ""
                            echo "Worktree is ready. To start Claude Code:"
                            echo "  $cmd"
                        fi
                    fi
                    ;;
                idea|pycharm|webstorm|phpstorm|goland|clion|rider|rubymine)
                    # JetBrains IDEs
                    "$OPEN_CMD" "$WORKTREE_PATH"
                    ;;
                *)
                    # VS Code and others
                    "$OPEN_CMD" "$WORKTREE_PATH"
                    ;;
            esac
        fi
        ;;
esac
