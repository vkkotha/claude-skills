---
name: "cdskit-mcp-setup"
description: Configure and troubleshoot MCP (Model Context Protocol) servers for Claude Code. Use when user needs help setting up MCP servers, fixing MCP issues, or verifying MCP configuration.
---

# cdskit-mcp-setup

Configure and troubleshoot **MCP (Model Context Protocol) servers** for Claude Code.

## What is MCP?

MCP (Model Context Protocol) allows Claude Code to connect to external services via "MCP servers". These servers provide tools that extend Claude's capabilities (e.g., accessing Bitbucket, GitHub, databases, etc.).

## Configuration File

MCP servers are configured in `.mcp.json`:
- **Project-level**: `.mcp.json` in project root (applies to that project only)
- **Global**: `~/.claude/.mcp.json` (applies to all projects)

### Basic Structure

```json
{
  "mcpServers": {
    "server-name": {
      "command": "npx",
      "args": ["-y", "@package/mcp-server"],
      "env": {
        "API_KEY": "${API_KEY}"
      }
    }
  }
}
```

### Configuration Fields

| Field | Description |
|-------|-------------|
| `command` | The command to run (e.g., `npx`, `python`, `node`) |
| `args` | Array of arguments to pass to the command |
| `env` | Environment variables for the server (use `${VAR}` for shell variables) |

## Available Templates

This skill includes templates for common MCP servers. Use the appropriate template based on your needs.

### Bitbucket Data Center / Server

**Template file:** `templates/bitbucket-datacenter.json`

**Required environment variables:**
```bash
export BITBUCKET_USERNAME="your.email@company.com"  # Full email for approval actions
export BITBUCKET_TOKEN="your-http-access-token"
export BITBUCKET_BASE_URL="https://bitbucket.yourcompany.com"
```

**Generate a Bitbucket HTTP Access Token:**
1. Go to Bitbucket Server → Profile → Personal Access Tokens (or HTTP Access Tokens)
2. Create a new token with **Read** and **Write** permissions for repositories and pull requests
3. Copy the token value

**Configuration:**
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

### Bitbucket Cloud

**Template file:** `templates/bitbucket-cloud.json`

**Required environment variables:**
```bash
export BITBUCKET_USERNAME="your-username"  # Bitbucket username (not email)
export BITBUCKET_APP_PASSWORD="your-app-password"
```

**Generate a Bitbucket App Password:**
1. Go to: https://bitbucket.org/account/settings/app-passwords/
2. Click "Create app password"
3. Give it a label (e.g., "Claude Code MCP")
4. Select permissions: **Account** (Read), **Repositories** (Read, Write), **Pull requests** (Read, Write)
5. Click "Create" and copy the password immediately

**Configuration:**
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

## Instructions

### Setting Up a New MCP Server

1. **Choose a template** from the templates above or create a custom configuration

2. **Set environment variables** in your shell profile (`.bashrc`, `.zshrc`, etc.):
   ```bash
   export VAR_NAME="value"
   ```

3. **Create or update `.mcp.json`**:
   - For project-specific: Create in project root
   - For global: Create at `~/.claude/.mcp.json`

4. **Restart your terminal** to load environment variables

5. **Restart Claude Code** to load the MCP server

6. **Verify setup** by checking that MCP tools are available

### Verifying MCP Configuration

To verify an MCP server is working:

1. **Check if tools are available**: MCP tools follow the pattern `mcp__<server-name>__<tool-name>`
   - For Bitbucket: Look for `mcp__bitbucket__get_pull_request`, etc.

2. **Check configuration file**: Verify `.mcp.json` exists and has correct syntax

3. **Check environment variables**: Run `echo $VAR_NAME` to verify variables are set

### Merging Multiple MCP Servers

If you need multiple MCP servers, combine them in one `.mcp.json`:

```json
{
  "mcpServers": {
    "bitbucket": {
      "command": "npx",
      "args": ["-y", "@nexus2520/bitbucket-mcp-server"],
      "env": { "BITBUCKET_TOKEN": "${BITBUCKET_TOKEN}" }
    },
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "/allowed/path"]
    }
  }
}
```

## Troubleshooting

### MCP Tools Not Available

1. **Check `.mcp.json` exists** in project root or `~/.claude/.mcp.json`
2. **Verify JSON syntax** is valid (no trailing commas, proper quotes)
3. **Restart Claude Code** - MCP servers load on startup
4. **Check environment variables** are exported in your shell

### Authentication Errors

1. **Verify credentials** are correct and not expired
2. **Check environment variables** are set: `echo $VAR_NAME`
3. **Ensure variable references** in `.mcp.json` use correct syntax: `${VAR_NAME}`
4. **Restart terminal** after adding/changing environment variables

### Server-Specific Issues

**Bitbucket Data Center/Server:**
- Use full email address for `BITBUCKET_USERNAME` (required for approval actions)
- Ensure `BITBUCKET_BASE_URL` has no trailing slash
- Verify HTTP Access Token has Read/Write permissions

**Bitbucket Cloud:**
- Use Bitbucket username (not email) for `BITBUCKET_USERNAME`
- Ensure App Password has Account, Repositories, and Pull requests scopes

### Windows-Specific Issues

- Ensure Node.js and npm are installed and in PATH
- Use Git Bash or WSL for environment variable syntax
- In PowerShell, set variables with: `$env:VAR_NAME = "value"`

## Quick Reference

| Task | Command/Action |
|------|----------------|
| Check env var | `echo $VAR_NAME` |
| Edit global config | `~/.claude/.mcp.json` |
| Edit project config | `./.mcp.json` |
| Restart Claude Code | Close and reopen Claude Code |
| Verify tools | Look for `mcp__*` tools |
