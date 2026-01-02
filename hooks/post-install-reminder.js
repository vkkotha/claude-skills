#!/usr/bin/env node
// Post-installation reminder for claude-skills plugin

const message = `
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Claude Skills Plugin - Configuration Reminder
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  This plugin includes two Bitbucket MCP servers. Please:

  1. DISABLE the server you don't need (use /mcp command)
     - bitbucket-cloud      → For Bitbucket Cloud (bitbucket.org)
     - bitbucket-datacenter → For self-hosted Bitbucket Server

  2. SET required environment variables:

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
