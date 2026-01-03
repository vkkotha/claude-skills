#!/usr/bin/env node
// Post-installation reminder for claude-skills plugin

const message = `
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Claude Skills Plugin - Configuration Reminder
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  This plugin includes MCP servers for GitHub and Bitbucket. Please:

  1. DISABLE the servers you don't need (use /mcp command)
     - github               → For GitHub (github.com)
     - bitbucket-cloud      → For Bitbucket Cloud (bitbucket.org)
     - bitbucket-datacenter → For self-hosted Bitbucket Server

  2. SET required environment variables:

     For GitHub:
       export GITHUB_PERSONAL_ACCESS_TOKEN="your-token"
       (Create at: https://github.com/settings/tokens)

     For Bitbucket Cloud:
       export BITBUCKET_USERNAME="your-username"
       export BITBUCKET_APP_PASSWORD="your-app-password"

     For Bitbucket Data Center:
       export BITBUCKET_USERNAME="your-username"
       export BITBUCKET_TOKEN="your-token"
       export BITBUCKET_BASE_URL="https://your-server.com"

  Run /claude-skills:help for detailed configuration instructions.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
`;

console.log(message);
