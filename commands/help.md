---
description: Show help and configuration instructions for the claude-skills plugin
---

# Claude Skills Plugin Help

This plugin includes MCP servers for Bitbucket integration. Please configure the servers you need and disable those you don't.

## MCP Servers Included

This plugin installs **two** Bitbucket MCP servers. You likely only need **one** of them:

| Server | Use Case |
|--------|----------|
| `bitbucket-cloud` | For Bitbucket Cloud (bitbucket.org) |
| `bitbucket-datacenter` | For self-hosted Bitbucket Data Center/Server |

**Important:** Disable the MCP server you don't need to avoid unnecessary resource usage and potential authentication errors.

## How to Disable Unused MCP Servers

Run this command in Claude Code:
```
/mcp
```
Then select the server you want to disable and toggle it off.

## Required Environment Variables

### For Bitbucket Cloud (`bitbucket-cloud`)

Set these in your shell profile (~/.zshrc, ~/.bashrc, etc.):

```bash
export BITBUCKET_USERNAME="your-bitbucket-username"
export BITBUCKET_APP_PASSWORD="your-app-password"
```

To create an App Password:
1. Go to Bitbucket Cloud → Personal Settings → App passwords
2. Create a new app password with appropriate permissions (repository read/write, PR read/write)

### For Bitbucket Data Center (`bitbucket-datacenter`)

```bash
export BITBUCKET_USERNAME="your-username"
export BITBUCKET_TOKEN="your-personal-access-token"
export BITBUCKET_BASE_URL="https://your-bitbucket-server.com"
```

To create a Personal Access Token:
1. Go to your Bitbucket Data Center instance → Profile → Personal Access Tokens
2. Create a new token with appropriate permissions

## Verify Your Configuration

After setting environment variables, restart your terminal and Claude Code, then run:

```bash
echo $BITBUCKET_USERNAME
```

If the variable is set correctly, you should see your username.

## Troubleshooting

- **MCP server fails to start**: Check that required environment variables are set
- **Authentication errors**: Verify your credentials and token permissions
- **Both servers showing errors**: Disable the one you don't need using `/mcp`
