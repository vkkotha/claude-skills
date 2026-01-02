# Claude Skills

A Claude Code plugin providing developer productivity skills for Bitbucket PR review and git worktree management.

## Available Skills

| Skill | Description |
|-------|-------------|
| [bitbucket-pr-reviewer](./skills/bitbucket-pr-reviewer/) | Review Bitbucket PRs with AI-powered analysis and inline comments |
| [git-worktree](./skills/git-worktree/) | Create isolated git worktrees for PRs, branches, tags, or commits |

## Installation

### Quick Install (Recommended)

```bash
# Add the marketplace
/plugin marketplace add https://github.com/vkkotha/claude-skills

# Install the plugin
/plugin install claude-skills@claude-skills-marketplace
```

### Development Mode

For testing or development, load the plugin directly without installing:

```bash
# Clone the repository
git clone https://github.com/vkkotha/claude-skills.git

# Run Claude Code with the plugin
claude --plugin-dir ./claude-skills
```

## Post-Installation Setup

After installing, run the help command for detailed configuration instructions:

```
/claude-skills:help
```

**Important:** This plugin includes two Bitbucket MCP servers. Disable the one you don't need:

1. Run `/mcp` in Claude Code
2. Toggle off the server you don't use:
   - `bitbucket-cloud` - For Bitbucket Cloud (bitbucket.org)
   - `bitbucket-datacenter` - For self-hosted Bitbucket Server

## Configuration

### Bitbucket MCP Server

This plugin includes two [Bitbucket MCP server](https://github.com/vkkotha/bitbucket-mcp-server) configurations:

| Server | Use Case | MCP Tools Prefix |
|--------|----------|------------------|
| `bitbucket-cloud` | Bitbucket Cloud (bitbucket.org) | `mcp__bitbucket-cloud__` |
| `bitbucket-datacenter` | Bitbucket Server/Data Center | `mcp__bitbucket-datacenter__` |

Enable the one you need by setting the appropriate environment variables:

**For Bitbucket Cloud:**
```bash
export BITBUCKET_USERNAME="your-username"
export BITBUCKET_APP_PASSWORD="your-app-password"
```

**For Bitbucket Server/Data Center:**
```bash
export BITBUCKET_USERNAME="your.email@company.com"
export BITBUCKET_TOKEN="your-http-access-token"
export BITBUCKET_BASE_URL="https://bitbucket.yourcompany.com"
```

Only the server with valid credentials will be active.

### Creating Bitbucket Credentials

**Bitbucket Cloud (App Password):**
1. Go to https://bitbucket.org/account/settings/app-passwords/
2. Click "Create app password"
3. Select permissions: Account (Read), Repositories (Read/Write), Pull requests (Read/Write)
4. Copy the generated password

**Bitbucket Server (HTTP Access Token):**
1. Go to your Bitbucket Server profile settings
2. Navigate to HTTP Access Tokens
3. Create a token with Repository Read/Write and Pull Request Read/Write permissions

## Usage

Once installed, the skills are automatically available in Claude Code:

```
# Natural language invocation
"Review PR 123"
"Create a worktree for PR 456"
"Help me inspect branch feature/login"

# Skills are triggered automatically based on context
```

## Skills

### bitbucket-pr-reviewer

AI-powered Bitbucket PR review skill. Features:
- Fetch PR details and diffs via MCP
- Analyze code for bugs, security, performance issues
- Post inline comments and suggestions
- Approve or request changes
- Supports both Bitbucket Cloud and Data Center/Server

**Prerequisites:** Requires a Bitbucket MCP server to be configured.

### git-worktree

Git utility for creating isolated worktrees. Features:
- Supports PRs, branches, tags, and commits
- Cross-platform (macOS, Linux, Windows via Git Bash/WSL)
- Auto-detects IDE context (VS Code, JetBrains, Claude Code CLI)
- Bitbucket and GitHub PR refs support
- Worktree auto-cleanup with confirmation

**Prerequisites:** Git 2.5+ and Bash.

## Development

### Testing the Plugin

```bash
# Load plugin for development/testing
claude --plugin-dir ./claude-skills

# Load multiple plugins
claude --plugin-dir ./claude-skills --plugin-dir ./another-plugin
```

### Plugin Environment Variables

In hooks, MCP servers, and skill scripts, use `${CLAUDE_PLUGIN_ROOT}` to reference the plugin directory:

```bash
"${CLAUDE_PLUGIN_ROOT}/skills/git-worktree/setup-worktree.sh" --pr 558
```

## Contributing

Contributions are welcome! To add a new skill:

1. Fork this repository
2. Create a new folder under `skills/` named `<your-skill-name>`
3. Add a `SKILL.md` file with YAML frontmatter and instructions
4. Update `README.md` with skill documentation
5. Submit a pull request

### Skill Template

Create folder: `skills/my-skill/`

```yaml
# SKILL.md
---
name: "my-skill"
description: Short description for skill matching. Use when user wants to...
---

# My Skill

Detailed instructions for the skill...

## Prerequisites

List any requirements...

## Instructions

Step-by-step instructions for Claude to follow...
```

## License

MIT License - See [LICENSE](./LICENSE) for details.
