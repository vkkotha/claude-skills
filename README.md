# Claude Developer Skills Kit

A collection of developer productivity skills for Claude Code including GitHub, Bitbucket PR review and git worktree management.

## Available Plugins

| Plugin | Description |
|--------|-------------|
| [git-plugin](./git-plugin/) | Create isolated git worktrees for PRs, branches, tags, or commits |
| [bitbucket-plugin](./bitbucket-plugin/) | PR operations for Bitbucket Cloud (bitbucket.org) |
| [bitbucket-datacenter-plugin](./bitbucket-datacenter-plugin/) | PR operations for self-hosted Bitbucket Server/Data Center |
| [github-plugin](./github-plugin/) | PR operations for GitHub |

## Installation

### Quick Install (Recommended)

```bash
# Add the marketplace
/plugin marketplace add https://github.com/vkkotha/claude-skills

# Install individual plugins
/plugin install git-plugin@cdskit-marketplace
/plugin install bitbucket-plugin@cdskit-marketplace
/plugin install bitbucket-datacenter-plugin@cdskit-marketplace
/plugin install github-plugin@cdskit-marketplace
```

### Development Mode

For testing or development, load a plugin directly without installing:

```bash
# Clone the repository
git clone https://github.com/vkkotha/claude-skills.git

# Run Claude Code with a specific plugin
claude --plugin-dir ./claude-skills/git-plugin
claude --plugin-dir ./claude-skills/bitbucket-plugin
claude --plugin-dir ./claude-skills/bitbucket-datacenter-plugin
claude --plugin-dir ./claude-skills/github-plugin
```

## Plugins

### git-plugin

Git utility for creating isolated worktrees. Features:
- Supports PRs, branches, tags, and commits
- Cross-platform (macOS, Linux, Windows via Git Bash/WSL)
- Auto-detects IDE context (VS Code, JetBrains, Claude Code CLI)
- Bitbucket and GitHub PR refs support
- Worktree auto-cleanup with confirmation

**Prerequisites:** Git 2.5+ and Bash.

**Usage:**
```
"Create a worktree for PR 456"
"Help me inspect branch feature/login"
```

### bitbucket-plugin

Pull request operations for Bitbucket Cloud (bitbucket.org). Features:
- List PRs in table format with status icons
- Fetch PR details and diffs via MCP
- AI-powered code review for bugs, security, performance issues
- Post inline comments and suggestions
- Approve, request changes, or merge PRs

**Prerequisites:** Requires the Bitbucket Cloud MCP server.

```bash
export BITBUCKET_USERNAME="your-username"
export BITBUCKET_APP_PASSWORD="your-app-password"
```

**Usage:**
```
"Review PR 123"
"List open PRs"
"Approve PR 456"
```

### bitbucket-datacenter-plugin

Pull request operations for self-hosted Bitbucket Server/Data Center. Features:
- List PRs in table format with status icons
- Fetch PR details and diffs via MCP
- AI-powered code review for bugs, security, performance issues
- Post inline comments and suggestions
- Approve, request changes, or merge PRs

**Prerequisites:** Requires the Bitbucket Data Center MCP server.

```bash
export BITBUCKET_USERNAME="your.email@company.com"
export BITBUCKET_TOKEN="your-http-access-token"
export BITBUCKET_BASE_URL="https://bitbucket.yourcompany.com"
```

**Usage:**
```
"Review PR 123"
"List open PRs"
"Approve PR 456"
```

### github-plugin

Pull request operations for GitHub. Features:
- List PRs in table format with status icons
- Fetch PR details and diffs via MCP
- AI-powered code review for bugs, security, performance issues
- Post inline comments and suggestions
- Approve, request changes, or merge PRs

**Prerequisites:** Requires the GitHub MCP server.

```bash
export GITHUB_PERSONAL_ACCESS_TOKEN="your-token"
```

**Creating a GitHub Personal Access Token:**
1. Go to https://github.com/settings/tokens
2. Click "Generate new token" (classic or fine-grained)
3. For classic tokens, select scopes: `repo`, `read:org`, `read:user`
4. For fine-grained tokens, grant access to the repositories you need
5. Copy the generated token

**Usage:**
```
"Review PR 123"
"List open PRs"
"Approve PR 456"
```

## Development

### Testing a Plugin

```bash
# Load plugin for development/testing
claude --plugin-dir ./claude-skills/git-plugin

# Load multiple plugins
claude --plugin-dir ./claude-skills/git-plugin --plugin-dir ./claude-skills/github-plugin
```

### Plugin Environment Variables

In hooks, MCP servers, and skill scripts, use `${CLAUDE_PLUGIN_ROOT}` to reference the plugin directory:

```bash
"${CLAUDE_PLUGIN_ROOT}/skills/git-worktree/setup-worktree.sh" --pr 558
```

## Contributing

Contributions are welcome! To add a new skill:

1. Fork this repository
2. Create a new folder named `<your-skill-name>`
3. Add `.claude-plugin/plugin.json` with plugin metadata
4. Add `skills/<skill-name>/SKILL.md` with YAML frontmatter and instructions
5. Update `marketplace.json` with the new plugin
6. Update `README.md` with skill documentation
7. Submit a pull request

### Skill Template

Create folder structure:
```
my-skill/
├── .claude-plugin/
│   └── plugin.json
└── skills/
    └── my-skill/
        └── SKILL.md
```

**plugin.json:**
```json
{
  "name": "my-skill",
  "version": "1.0.0",
  "description": "Short description of the skill",
  "author": { "name": "your-name" },
  "repository": "https://github.com/your-repo",
  "license": "MIT",
  "skills": ["./skills/"]
}
```

**SKILL.md:**
```yaml
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
