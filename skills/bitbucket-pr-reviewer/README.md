# Bitbucket PR Reviewer

A Claude Code skill for reviewing Bitbucket pull requests with AI-powered code analysis.

## Features

- **Multi-platform support**: Works with both Bitbucket Cloud and Bitbucket Data Center/Server
- **MCP Integration**: Uses Bitbucket MCP server for seamless API access
- **Git Worktrees**: Creates isolated local checkouts for deeper code inspection
- **Inline Comments**: Post comments directly on specific lines of code
- **Code Suggestions**: Provide actionable code suggestions that can be applied in Bitbucket UI
- **Approval Workflow**: Approve PRs or request changes directly from Claude Code
- **Cross-platform Scripts**: Works on macOS, Linux, and Windows (Git Bash/WSL)
- **Editor Agnostic**: Supports VSCode, Cursor, Windsurf, or terminal-only workflows

## Prerequisites

1. **Bitbucket MCP Server** - Required for API access
2. **Git** - For worktree functionality
3. **Bash** - For helper scripts (Git Bash on Windows)

## Installation

### Copy to your project

```bash
# Copy the skill folder to your project
cp -r bitbucket-pr-reviewer /path/to/your/project/.claude/skills/
```

### Or install globally

```bash
# Copy to global skills directory
cp -r bitbucket-pr-reviewer ~/.claude/skills/
```

## Configuration

### 1. Set up environment variables

**For Bitbucket Data Center/Server:**
```bash
# Add to ~/.bashrc, ~/.zshrc, or equivalent
export BITBUCKET_USERNAME="your.email@company.com"
export BITBUCKET_TOKEN="your-http-access-token"
export BITBUCKET_BASE_URL="https://bitbucket.yourcompany.com"
```

**For Bitbucket Cloud:**
```bash
export BITBUCKET_USERNAME="your-username"
export BITBUCKET_APP_PASSWORD="your-app-password"
```

### 2. Configure MCP server

Create `.mcp.json` in your project root or `~/.claude/.mcp.json` for global config:

**For Bitbucket Data Center/Server:**
```json
{
  "mcpServers": {
    "bitbucket": {
      "command": "npx",
      "args": ["-y", "@nexus2520/bitbucket-mcp-server"],
      "env": {
        "BITBUCKET_USERNAME": "${BITBUCKET_USERNAME}",
        "BITBUCKET_BASE_URL": "${BITBUCKET_BASE_URL}",
        "BITBUCKET_TOKEN": "${BITBUCKET_TOKEN}"
      }
    }
  }
}
```

**For Bitbucket Cloud:**
```json
{
  "mcpServers": {
    "bitbucket": {
      "command": "npx",
      "args": ["-y", "@nexus2520/bitbucket-mcp-server"],
      "env": {
        "BITBUCKET_USERNAME": "${BITBUCKET_USERNAME}",
        "BITBUCKET_APP_PASSWORD": "${BITBUCKET_APP_PASSWORD}"
      }
    }
  }
}
```

### 3. Restart Claude Code

Restart Claude Code to load the MCP server.

## Usage

### Basic usage

```
Review PR 123
```

### With repository context

```
Review PR 123 in the my-repo repository
```

### With full URL

```
Review https://bitbucket.org/myworkspace/my-repo/pull-requests/123
```

### Using skill command

```
/bitbucket-pr-reviewer
```

## What the skill does

1. **Fetches PR metadata** - Title, description, author, reviewers, status
2. **Gets code diff** - All file changes with context
3. **Analyzes code** - Looks for bugs, security issues, performance problems, code quality
4. **Generates review** - Structured feedback with specific line references
5. **Posts comments** - Inline comments directly on the PR (optional)
6. **Sets up worktree** - Local checkout for running tests (optional)
7. **Approves/Requests changes** - Final verdict (optional)

## Helper Scripts

### setup-pr-worktree.sh

Creates a git worktree for local code inspection:

```bash
# Basic usage (auto-detect editor, new window)
./setup-pr-worktree.sh 123

# Specify editor mode and command
./setup-pr-worktree.sh 123 new code      # VSCode, new window
./setup-pr-worktree.sh 123 reuse cursor  # Cursor, reuse window
./setup-pr-worktree.sh 123 skip          # No editor (CLI users)
```

### cleanup-pr-worktree.sh

Removes the worktree after review:

```bash
./cleanup-pr-worktree.sh 123
```

## Troubleshooting

### MCP tools not available

1. Check `.mcp.json` exists and has correct values
2. Verify environment variables are set: `echo $BITBUCKET_USERNAME`
3. Restart Claude Code

### Authentication errors

- **Data Center/Server**: Use full email as username, verify token has read/write permissions
- **Cloud**: Use Bitbucket username (not email), verify app password has correct scopes

### Scripts not working on Windows

Install Git for Windows (includes Git Bash) and run:
```cmd
bash ./setup-pr-worktree.sh 123
```

## License

MIT
