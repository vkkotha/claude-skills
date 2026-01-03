---
name: "git-worktree"
description: Create isolated git worktrees for reviewing pull requests, branches, tags, or commits. Use when user wants to checkout code locally, inspect a ref in isolation, or set up a separate workspace for code review.
---

# Git Worktree

Create isolated git worktrees for reviewing PRs, branches, tags, or commits without affecting the main working directory.

## Scripts

### Setup Worktree

```bash
"${CLAUDE_PLUGIN_ROOT}/skills/git-worktree/setup-worktree.sh" --pr <NUMBER>
"${CLAUDE_PLUGIN_ROOT}/skills/git-worktree/setup-worktree.sh" --branch <NAME>
"${CLAUDE_PLUGIN_ROOT}/skills/git-worktree/setup-worktree.sh" --tag <NAME>
"${CLAUDE_PLUGIN_ROOT}/skills/git-worktree/setup-worktree.sh" --commit <SHA>
```

**Options:** `--editor skip` (don't open IDE) | `--editor-cmd <code|idea|claude>` (override IDE)

### Open Main Worktree

```bash
"${CLAUDE_PLUGIN_ROOT}/skills/git-worktree/open-main-worktree.sh"
```

### Cleanup Worktree

```bash
"${CLAUDE_PLUGIN_ROOT}/skills/git-worktree/cleanup-worktree.sh" --pr <NUMBER>
"${CLAUDE_PLUGIN_ROOT}/skills/git-worktree/cleanup-worktree.sh" --branch <NAME>
```

**Options:** `--yes` or `-y` (skip confirmation)

---

## Behavior

- **Worktrees created at:** `../<project>.worktrees/<folder-name>`
- **IDE auto-detection:** Opens in VS Code, JetBrains, or Claude CLI based on context
- **Branch handling:**
  - Local branches: used directly
  - Remote branches: creates `worktree-branch-<name>`
  - PRs: creates `worktree-pr-<number>`
  - Tags/Commits: detached HEAD

**Windows:** Prefix commands with `bash` (requires Git Bash)
