---
name: "cdskit-git-worktree"
description: Create isolated git worktrees for reviewing pull requests, branches, tags, or commits. Use when user wants to checkout code locally, inspect a ref in isolation, or set up a separate workspace for code review.
---

# cdskit-git-worktree

Create isolated **git worktrees** for reviewing pull requests, branches, tags, or commits without affecting your main working directory.

## What is a Git Worktree?

A git worktree allows you to check out multiple branches/refs simultaneously in separate directories. This is useful for:
- Reviewing PR code without stashing your current work
- Running tests on a different branch while continuing development
- Comparing code between branches/tags side-by-side
- Inspecting code at a specific commit

## Prerequisites

- **Git** (with worktree support - Git 2.5+)
- **Bash** (Git Bash on Windows, native on macOS/Linux)
- **Claude Code** running in VS Code, JetBrains IDE, or CLI

## Instructions

### Setting Up a Worktree

When the user wants to inspect code locally, **run the setup script** with the appropriate ref type. The script auto-detects the IDE context and opens appropriately:

```bash
# macOS/Linux (global install)
"$HOME/.claude/skills/cdskit-git-worktree/setup-worktree.sh" --pr <NUMBER>
"$HOME/.claude/skills/cdskit-git-worktree/setup-worktree.sh" --branch <NAME>
"$HOME/.claude/skills/cdskit-git-worktree/setup-worktree.sh" --tag <NAME>
"$HOME/.claude/skills/cdskit-git-worktree/setup-worktree.sh" --commit <SHA>

# Local install (if using --local during installation)
./.claude/skills/cdskit-git-worktree/setup-worktree.sh --pr <NUMBER>

# Windows CMD/PowerShell (with Git Bash)
bash "%USERPROFILE%\.claude\skills\cdskit-git-worktree\setup-worktree.sh" --pr <NUMBER>
```

### Script Arguments

| Argument | Description |
|----------|-------------|
| `--pr <NUMBER>` | Pull request number (fetches from remote PR refs) |
| `--branch <NAME>` | Branch name (local or remote) |
| `--tag <NAME>` | Tag name |
| `--commit <SHA>` | Commit SHA (full or abbreviated) |
| `--editor <MODE>` | How to open: `auto` (default), `skip` |
| `--editor-cmd <CMD>` | Override editor: `code`, `idea`, `claude`, or custom |

### IDE Auto-Detection

The script automatically detects your IDE context:

| Context | Detection | Opens With |
|---------|-----------|------------|
| VS Code | `VSCODE_*` env vars, `TERM_PROGRAM=vscode` | `code` command |
| JetBrains | `IDEA_*`, `JETBRAINS_*` env vars | `idea` (or specific IDE) |
| CLI | Default fallback | `claude` (new CLI session) |

### Examples

```bash
# PR worktree (auto-detects IDE and opens)
./setup-worktree.sh --pr 558

# Branch worktree with specific editor override
./setup-worktree.sh --branch feature/login --editor-cmd idea

# Tag worktree, no editor
./setup-worktree.sh --tag v1.2.3 --editor skip

# Commit worktree, force Claude Code CLI
./setup-worktree.sh --commit abc123def --editor-cmd claude
```

### What the Script Does

1. **Fetches the ref** from the correct remote (handles fork setups with upstream)
2. **Creates a worktree** at `../<project>.worktrees/<folder-name>`
3. **Auto-detects IDE** and opens the worktree (VS Code, JetBrains, or Claude CLI)

**Branch handling:**
- **Local branches:** Used directly without modification (your existing branches are preserved)
- **Remote branches:** Creates a `worktree-branch-<name>` branch to avoid modifying your local branches
- **PRs:** Creates a `worktree-pr-<number>` branch
- **Tags/Commits:** Use detached HEAD (read-only inspection)

### Worktree Locations

Worktrees are created with prefixed folder names to avoid collisions:

| Ref Type | Example Input | Folder Name | Branch Created |
|----------|---------------|-------------|----------------|
| PR | `--pr 558` | `PR-558` | `worktree-pr-558` |
| Branch (local) | `--branch feature/login` | `branch-feature-login` | *(uses existing branch)* |
| Branch (remote) | `--branch feature/login` | `branch-feature-login` | `worktree-branch-feature-login` |
| Tag | `--tag v1.2.3` | `tag-v1.2.3` | *(detached HEAD)* |
| Commit | `--commit abc123def` | `commit-abc123de` | *(detached HEAD)* |

All worktrees are created under:
```
../<project-name>.worktrees/
```

For example, if your project is at `/home/user/myapp`:
```
/home/user/myapp.worktrees/
├── PR-558/
├── branch-feature-login/
├── tag-v1.2.3/
└── commit-abc123de/
```

### Navigating Back to Main Worktree

When the user is in a worktree and wants to go back to the main repository (e.g., "open main worktree", "go back to main repo"):

```bash
# Auto-detects IDE and opens main worktree
"$HOME/.claude/skills/cdskit-git-worktree/open-main-worktree.sh"

# Skip opening, just show path
"$HOME/.claude/skills/cdskit-git-worktree/open-main-worktree.sh" skip

# Force specific editor
"$HOME/.claude/skills/cdskit-git-worktree/open-main-worktree.sh" auto idea
```

**How it works:** Git tracks the main worktree (the original clone location) and `git worktree list` always shows it first. This works from any worktree in the same repository.

### Cleaning Up a Worktree

After the review is complete, clean up with:

```bash
# macOS/Linux (global install)
"$HOME/.claude/skills/cdskit-git-worktree/cleanup-worktree.sh" --pr <NUMBER>
"$HOME/.claude/skills/cdskit-git-worktree/cleanup-worktree.sh" --branch <NAME>
"$HOME/.claude/skills/cdskit-git-worktree/cleanup-worktree.sh" --tag <NAME>
"$HOME/.claude/skills/cdskit-git-worktree/cleanup-worktree.sh" --commit <SHA>

# Windows CMD/PowerShell (with Git Bash)
bash "%USERPROFILE%\.claude\skills\cdskit-git-worktree\cleanup-worktree.sh" --pr <NUMBER>
```

**Options:**
- `--yes` or `-y`: Skip confirmation prompts

This will:
- Remove the worktree directory
- Prune stale worktree references
- **Ask for confirmation** before deleting any `worktree-*` branches created by this skill
- **Never delete** your existing local branches (only `worktree-*` prefixed branches are candidates for deletion)

## Platform Detection

When running scripts, detect the platform:

**macOS/Linux:** Run scripts directly
```bash
./script.sh <args>
```

**Windows:** Use `bash` (Git Bash) or `wsl bash`
```bash
bash ./script.sh <args>
# or
wsl bash ./script.sh <args>
```

## Troubleshooting

### Script Not Executable

```bash
chmod +x ./.claude/skills/cdskit-git-worktree/*.sh
```

### Ref Not Found

- **PR:** Verify the PR number and access to the repository
  - Bitbucket: refs at `refs/pull-requests/<PR>/from`
  - GitHub: refs at `refs/pull/<PR>/head`
- **Branch:** Ensure branch exists locally or on remote
- **Tag:** Run `git fetch --tags` first
- **Commit:** Ensure commit exists (may need to fetch history)

### Editor Not Opening

1. Ensure the editor CLI is in your PATH:
   - **VS Code:** Command Palette → "Shell Command: Install 'code' command in PATH"
   - **JetBrains:** Tools → Create Command-line Launcher

2. Use `--editor skip` and open manually:
   ```bash
   ./setup-worktree.sh --pr 558 --editor skip
   cd ../myproject.worktrees/PR-558
   code .   # or: idea . / claude
   ```

### Worktree Already Exists

The script handles this automatically by updating the existing worktree. If you encounter issues:

```bash
# Manual cleanup
git worktree remove ../myproject.worktrees/PR-558
git branch -D pr-558
git worktree prune
```

### Windows-Specific Issues

1. **Git Bash not found:** Install [Git for Windows](https://git-scm.com/download/win)
2. **Line ending issues:** The scripts use LF line endings (handled by `.gitattributes`)
3. **Path issues:** Use forward slashes or escape backslashes

## Quick Reference

| Action | Command |
|--------|---------|
| Setup PR worktree | `./setup-worktree.sh --pr 558` |
| Setup branch worktree | `./setup-worktree.sh --branch feature/x` |
| Setup tag worktree | `./setup-worktree.sh --tag v1.0.0` |
| Setup commit worktree | `./setup-worktree.sh --commit abc123` |
| Open main worktree | `./open-main-worktree.sh` |
| Cleanup worktree | `./cleanup-worktree.sh --pr 558` |
| List worktrees | `git worktree list` |
| Prune stale | `git worktree prune` |
