---
name: "github-pr"
description: "Handle GitHub PR operations. Use for \"PR\", \"pull request\", \"review\" when repo is on github.com."
---

# GitHub PR Operations

Use `mcp__plugin_github-plugin__*` MCP tools.

## Step 1: Detect Platform (REQUIRED)

Run `git remote -v` to identify platform:
- `github.com` → ✅ GitHub (continue)
- `bitbucket.org` → Use `bitbucket-cloud` skill
- `bitbucket.<company>.com` or custom domain → Use `bitbucket-datacenter` skill

**Extract from URL:**
- SSH: `git@github.com:owner/repo.git` → owner=`owner`, repo=`repo`
- HTTPS: `https://github.com/owner/repo.git` → owner=`owner`, repo=`repo`

## Output Format

List PRs as table: `| # | Title | Author | Branch | Status | Updated |`
Status: ✅ Open | 📝 Draft | 🔀 Merged | ❌ Closed

To exclude drafts, use search with `draft:false`.

## PR Review

1. Fetch PR details + diff
2. Analyze: bugs, security, performance, code quality
3. Present: `## PR Review: #<NUM> - <TITLE>` with Summary, Issues Found (`[file:line]`), Verdict (APPROVE/REQUEST_CHANGES/COMMENT)
4. Post comments/approve if requested

## Inline Review Comments

For reviews with inline comments: create pending review → add inline comments → submit with verdict.
