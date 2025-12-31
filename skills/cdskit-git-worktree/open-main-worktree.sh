#!/usr/bin/env bash

# Open Main Worktree Script
# Usage: ./open-main-worktree.sh [EDITOR_MODE] [EDITOR_CMD]
#
# Arguments:
#   EDITOR_MODE - Optional. How to open:
#                 "auto"    - Auto-detect IDE from environment (default)
#                 "skip"    - Don't open any editor, just print path
#   EDITOR_CMD  - Optional. Override editor command:
#                 "code"    - VS Code
#                 "idea"    - IntelliJ IDEA
#                 "claude"  - Claude Code CLI
#                 Or any custom command
#
# Cross-platform: Works on macOS, Linux, Windows (Git Bash/WSL)

set -e

EDITOR_MODE=${1:-auto}
EDITOR_CMD=${2:-}

# Detect IDE context from environment
detect_ide_context() {
    # VS Code detection
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
            if command -v code >/dev/null 2>&1; then
                echo "code"
            else
                echo ""
            fi
            ;;
        jetbrains)
            for cmd in idea pycharm webstorm phpstorm goland clion rider rubymine; do
                if command -v "$cmd" >/dev/null 2>&1; then
                    echo "$cmd"
                    return
                fi
            done
            echo ""
            ;;
        cli)
            if command -v claude >/dev/null 2>&1; then
                echo "claude"
            else
                echo ""
            fi
            ;;
    esac
}

IDE_CONTEXT=$(detect_ide_context)

# Get the main worktree path (first entry in git worktree list)
MAIN_WORKTREE=$(git worktree list | head -1 | awk '{print $1}')

if [ -z "$MAIN_WORKTREE" ]; then
    echo "Error: Could not determine main worktree path"
    echo "Make sure you're in a git repository"
    exit 1
fi

echo "Main worktree: ${MAIN_WORKTREE}"

# Handle editor opening based on mode
case "$EDITOR_MODE" in
    skip)
        echo ""
        echo "To open later:"
        echo "  code \"${MAIN_WORKTREE}\"     # VS Code"
        echo "  idea \"${MAIN_WORKTREE}\"     # IntelliJ IDEA"
        echo "  claude \"${MAIN_WORKTREE}\"   # Claude Code CLI"
        ;;
    auto|*)
        # Determine which command to use
        if [ -n "$EDITOR_CMD" ]; then
            OPEN_CMD="$EDITOR_CMD"
        else
            OPEN_CMD=$(get_ide_command "$IDE_CONTEXT")
        fi

        if [ -z "$OPEN_CMD" ]; then
            echo ""
            echo "Note: Could not detect IDE or find editor command."
            echo "Detected context: $IDE_CONTEXT"
            echo ""
            echo "To open manually:"
            echo "  code \"${MAIN_WORKTREE}\"     # VS Code"
            echo "  idea \"${MAIN_WORKTREE}\"     # IntelliJ IDEA"
            echo "  claude \"${MAIN_WORKTREE}\"   # Claude Code CLI"
        elif ! command -v "$OPEN_CMD" >/dev/null 2>&1; then
            echo ""
            echo "Note: '${OPEN_CMD}' command not found in PATH."
            echo ""
            echo "To open manually:"
            echo "  code \"${MAIN_WORKTREE}\"     # VS Code"
            echo "  idea \"${MAIN_WORKTREE}\"     # IntelliJ IDEA"
            echo "  claude \"${MAIN_WORKTREE}\"   # Claude Code CLI"
        else
            echo ""
            echo "Detected IDE context: $IDE_CONTEXT"
            echo "Opening with: $OPEN_CMD"

            case "$OPEN_CMD" in
                claude)
                    # Claude Code CLI: open VS Code with the main worktree
                    # Claude Code will be available in the new window's terminal
                    if command -v code >/dev/null 2>&1; then
                        echo ""
                        echo "Opening main worktree in VS Code (Claude Code available in terminal)..."
                        code "$MAIN_WORKTREE"
                    else
                        # Fallback: copy command to clipboard if possible
                        local cmd="cd \"${MAIN_WORKTREE}\" && claude"
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
                            echo "Main worktree is ready. To start Claude Code:"
                            echo "  $cmd"
                        fi
                    fi
                    ;;
                idea|pycharm|webstorm|phpstorm|goland|clion|rider|rubymine)
                    "$OPEN_CMD" "$MAIN_WORKTREE"
                    ;;
                *)
                    "$OPEN_CMD" "$MAIN_WORKTREE"
                    ;;
            esac
        fi
        ;;
esac
