# Claude Developer Skills Kit (cdskit)

A collection of reusable developer productivity skills for [Claude Code](https://claude.ai/claude-code) - Anthropic's official CLI for Claude.

## Available Skills

| Skill | Description | Dependencies |
|-------|-------------|--------------|
| [cdskit-mcp-setup](./skills/cdskit-mcp-setup/) | Configure and troubleshoot MCP servers for Claude Code | None |
| [cdskit-git-worktree](./skills/cdskit-git-worktree/) | Create isolated git worktrees for PRs, branches, tags, or commits | None |
| [cdskit-bitbucket-pr-reviewer](./skills/cdskit-bitbucket-pr-reviewer/) | Review Bitbucket PRs with AI-powered analysis and inline comments | mcp-setup |

## Quick Start

```bash
# Clone the repository
git clone https://github.com/vkkotha/claude-skills.git
cd claude-skills

# List available skills
./install.sh --list

# Install all skills globally
./install.sh --all

# Or install specific skills
./install.sh bitbucket-pr-reviewer
```

## Installation

### Using the Installer (Recommended)

The installer handles dependencies and applies a configurable prefix to skill names.

```bash
# Install all skills with default prefix (cdskit-)
./install.sh --all

# Install specific skills
./install.sh bitbucket-pr-reviewer pr-worktree

# Install with custom prefix
./install.sh --prefix myteam- --all

# Install without prefix
./install.sh --prefix "" --all

# Install to current project instead of globally
./install.sh --local --all

# Preview what would be installed
./install.sh --dry-run --all
```

### Installer Options

| Option | Description |
|--------|-------------|
| `--list` | List available skills |
| `--all` | Install all skills |
| `--prefix PREFIX` | Set skill name prefix (default: `cdskit-`) |
| `--global` | Install to `~/.claude/skills/` (default) |
| `--local` | Install to `./.claude/skills/` |
| `--dry-run` | Show what would be installed without installing |
| `--help` | Show help message |

## Uninstallation

```bash
# List installed skills
./uninstall.sh --list

# Uninstall all skills with default prefix
./uninstall.sh --all

# Uninstall specific skills
./uninstall.sh bitbucket-pr-reviewer mcp-setup

# Uninstall with custom prefix
./uninstall.sh --prefix myteam- --all

# Preview what would be uninstalled
./uninstall.sh --dry-run --all
```

### Uninstaller Options

| Option | Description |
|--------|-------------|
| `--list` | List installed skills |
| `--all` | Uninstall all skills with current prefix |
| `--prefix PREFIX` | Set skill name prefix (default: `cdskit-`) |
| `--global` | Uninstall from `~/.claude/skills/` (default) |
| `--local` | Uninstall from `./.claude/skills/` |
| `--dry-run` | Show what would be uninstalled without removing |
| `--yes`, `-y` | Skip confirmation prompt |
| `--help` | Show help message |

### Manual Installation (Copy & Paste)

Skills come pre-configured with the default `cdskit-` prefix and matching folder names, so you can simply copy them:

```bash
# Copy skills directly
cp -r skills/cdskit-mcp-setup ~/.claude/skills/
cp -r skills/cdskit-git-worktree ~/.claude/skills/
cp -r skills/cdskit-bitbucket-pr-reviewer ~/.claude/skills/
```

**Note:** When copying manually, remember to also copy dependencies (e.g., `cdskit-mcp-setup` for `cdskit-bitbucket-pr-reviewer`).

## Skill Prefixes

Skills are installed with a configurable prefix to avoid conflicts with other skills:

| Source | Installed As (default) | Installed As (custom) |
|--------|------------------------|----------------------|
| `mcp-setup` | `cdskit-mcp-setup` | `myteam-mcp-setup` |
| `git-worktree` | `cdskit-git-worktree` | `myteam-git-worktree` |
| `bitbucket-pr-reviewer` | `cdskit-bitbucket-pr-reviewer` | `myteam-bitbucket-pr-reviewer` |

## Usage

Once installed, invoke skills in Claude Code:

```
# Using skill command (with default prefix)
/cdskit-bitbucket-pr-reviewer

# Natural language works too
"Review PR 123"
"Help me set up MCP for Bitbucket"
"Create a worktree for PR 456"
```

## Skill Details

### mcp-setup

Foundation skill for configuring MCP (Model Context Protocol) servers. Includes:
- MCP concepts and configuration guide
- Templates for Bitbucket (Cloud and Data Center/Server)
- Troubleshooting guide

### cdskit-git-worktree

Git utility for creating isolated worktrees. Features:
- Supports PRs, branches, tags, and commits
- Cross-platform (macOS, Linux, Windows via Git Bash/WSL)
- Auto-detects IDE context (VS Code, JetBrains, Claude Code CLI)
- Bitbucket and GitHub PR refs support

### bitbucket-pr-reviewer

AI-powered Bitbucket PR review skill. Features:
- Fetch PR details and diffs via MCP
- Analyze code for bugs, security, performance issues
- Post inline comments and suggestions
- Approve or request changes

## Project Structure

```
claude-skills/
├── install.sh              # Installer script
├── uninstall.sh            # Uninstaller script
├── skills.json             # Skills registry
├── README.md
└── skills/
    ├── cdskit-mcp-setup/
    │   ├── SKILL.md        # Skill instructions
    │   ├── skill.json      # Skill metadata
    │   └── templates/      # MCP config templates
    ├── cdskit-git-worktree/
    │   ├── SKILL.md
    │   ├── skill.json
    │   ├── setup-worktree.sh
    │   └── cleanup-worktree.sh
    └── cdskit-bitbucket-pr-reviewer/
        ├── SKILL.md
        └── skill.json
```

## Dependency System

Skills can declare dependencies in their `skill.json`:

```json
{
  "name": "bitbucket-pr-reviewer",
  "dependencies": {
    "required": ["mcp-setup"],
    "optional": ["pr-worktree"]
  }
}
```

The installer automatically resolves and installs dependencies in the correct order.

## Contributing

Contributions are welcome! To add a new skill:

1. Fork this repository
2. Create a new folder under `skills/` named `cdskit-<your-skill-name>`
3. Add required files:
   - `SKILL.md` - Skill definition using `cdskit-` prefix
   - `skill.json` - Metadata and dependencies
4. Update `skills.json` registry
5. Submit a pull request

### Skill Template

Create folder: `skills/cdskit-my-skill/`

```yaml
# SKILL.md
---
name: "cdskit-my-skill"
description: Short description for skill matching
---

# cdskit-my-skill

Detailed instructions...

## Prerequisites

If this skill depends on others:
- Use the `cdskit-mcp-setup` skill for MCP configuration
```

```json
// skill.json
{
  "name": "my-skill",
  "version": "1.0.0",
  "description": "What this skill does",
  "dependencies": {
    "required": [],
    "optional": []
  }
}
```

**Note:** Always use `cdskit-` as the prefix in folder names and file content. The installer will automatically replace it with custom prefixes when users install with `--prefix`.

## License

MIT License - See [LICENSE](./LICENSE) for details.
