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
- **Editor** (optional): VSCode, Cursor, Windsurf, or any editor with CLI support

## Instructions

### Setting Up a Worktree

When the user wants to inspect code locally:

1. **Ask for editor preference** using AskUserQuestion:
   ```
   How would you like to open the worktree?

   Question 1 - Editor:
   1. Auto-detect - Use first available (VSCode, Cursor, Windsurf) (Recommended)
   2. VSCode - Use VSCode specifically
   3. Cursor - Use Cursor specifically
   4. Windsurf - Use Windsurf specifically
   5. Terminal only - Don't open any editor

   Question 2 - Window mode (if not "Terminal only"):
   1. New window - Open in a new editor window (Recommended)
   2. Current window - Reuse current editor window
   ```

2. **Run the setup script** with the appropriate ref type:
   ```bash
   # macOS/Linux
   ./.claude/skills/cdskit-git-worktree/setup-worktree.sh --pr <NUMBER>
   ./.claude/skills/cdskit-git-worktree/setup-worktree.sh --branch <NAME>
   ./.claude/skills/cdskit-git-worktree/setup-worktree.sh --tag <NAME>
   ./.claude/skills/cdskit-git-worktree/setup-worktree.sh --commit <SHA>

   # Windows CMD/PowerShell (with Git for Windows)
   bash ./.claude/skills/cdskit-git-worktree/setup-worktree.sh --pr <NUMBER>

   # Windows with WSL
   wsl bash ./.claude/skills/cdskit-git-worktree/setup-worktree.sh --pr <NUMBER>
   ```

### Script Arguments

| Argument | Description |
|----------|-------------|
| `--pr <NUMBER>` | Pull request number (fetches from remote PR refs) |
| `--branch <NAME>` | Branch name (local or remote) |
| `--tag <NAME>` | Tag name |
| `--commit <SHA>` | Commit SHA (full or abbreviated) |
| `--editor <MODE>` | How to open editor: `new` (default), `reuse`, `skip` |
| `--editor-cmd <CMD>` | Editor command: `auto` (default), `code`, `cursor`, `windsurf`, or custom |

### Examples

```bash
# PR worktree (auto-detect editor, new window)
./setup-worktree.sh --pr 558

# Branch worktree with specific editor
./setup-worktree.sh --branch feature/login --editor-cmd cursor

# Tag worktree, no editor
./setup-worktree.sh --tag v1.2.3 --editor skip

# Commit worktree, reuse current window
./setup-worktree.sh --commit abc123def --editor reuse
```

### What the Script Does

1. **Fetches the ref** from the correct remote (handles fork setups with upstream)
2. **Creates a worktree** at `../<project>.worktrees/<folder-name>`
3. **Opens your editor** (based on preference) or provides manual instructions

### Worktree Locations

Worktrees are created with prefixed folder names to avoid collisions:

| Ref Type | Example Input | Folder Name |
|----------|---------------|-------------|
| PR | `--pr 558` | `PR-558` |
| Branch | `--branch feature/login` | `branch-feature-login` |
| Tag | `--tag v1.2.3` | `tag-v1.2.3` |
| Commit | `--commit abc123def` | `commit-abc123de` |

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

### Cleaning Up a Worktree

After the review is complete, clean up with:

```bash
# macOS/Linux
./.claude/skills/cdskit-git-worktree/cleanup-worktree.sh --pr <NUMBER>
./.claude/skills/cdskit-git-worktree/cleanup-worktree.sh --branch <NAME>
./.claude/skills/cdskit-git-worktree/cleanup-worktree.sh --tag <NAME>
./.claude/skills/cdskit-git-worktree/cleanup-worktree.sh --commit <SHA>

# Windows CMD/PowerShell (with Git for Windows)
bash ./.claude/skills/cdskit-git-worktree/cleanup-worktree.sh --pr <NUMBER>

# Windows with WSL
wsl bash ./.claude/skills/cdskit-git-worktree/cleanup-worktree.sh --pr <NUMBER>
```

This will:
- Remove the worktree directory
- Delete the local branch (for PRs and branches)
- Prune stale worktree references

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
   - **VSCode:** Command Palette → "Shell Command: Install 'code' command in PATH"
   - **Cursor:** Command Palette → "Shell Command: Install 'cursor' command in PATH"
   - **Windsurf:** Settings → Install 'windsurf' command in PATH

2. Use `--editor skip` and open manually:
   ```bash
   ./setup-worktree.sh --pr 558 --editor skip
   cd ../myproject.worktrees/PR-558
   code .
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
| Cleanup worktree | `./cleanup-worktree.sh --pr 558` |
| List worktrees | `git worktree list` |
| Prune stale | `git worktree prune` |
