---
name: "bitbucket-datacenter"
description: "Handle Bitbucket Data Center/Server PR operations. Use for \"PR\", \"pull request\", \"review\" when repo is on self-hosted Bitbucket (NOT bitbucket.org)."
---

# Bitbucket Data Center PR Operations

Use `mcp__plugin_bitbucket-datacenter-plugin__*` MCP tools.
## Platform Detection (REQUIRED)

Run `git remote -v` to verify this is Bitbucket Data Center (self-hosted, not bitbucket.org):
- SSH format: `git@bitbucket.company.com:7999/PROJ/repo.git`
- HTTPS format: `https://bitbucket.company.com/scm/PROJ/repo.git`
- Extract: workspace = `PROJ`, repository = `repo`

## Status Indicators

When listing or displaying PRs, use these status emojis based on PR state:

| Condition | Status |
|-----------|--------|
| `is_draft === true` | 📝 Draft |
| `state === "MERGED"` | 🔀 Merged |
| `state === "DECLINED"` | ❌ Declined |
| `state === "OPEN"` | ✅ Open |

## Output Format

Display PRs in a table with columns: `| # | Title | Author | Branch | Status | Updated |`

Example:
```
| 549 | PCM-15125: integrated ray cluster | Brindha T | PCM-15125 | ✅ Open | 1/22/2026 |
| 566 | campaign_post_processor updates | Brindha T | PCM-14672 | 📝 Draft | 12/23/2025 |
```

## PR Review

When reviewing a PR:
1. Fetch PR details and diff
2. Analyze for bugs, security issues, performance, and code quality
3. Present findings as: `## PR Review: #<NUM> - <TITLE>`
4. List issues with file references: `file_path:line_number`
5. Provide verdict: APPROVE, REQUEST_CHANGES, or COMMENT
6. Post comments/approve via MCP tools if requested
