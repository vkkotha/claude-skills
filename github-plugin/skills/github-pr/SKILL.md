---
name: "github-pr"
description: "Handle GitHub pull request operations. Use when user mentions \"PR\", \"pull request\", \"review\", \"list PRs\", \"get PRs\", \"non-draft PRs\", \"open PRs\", or any PR-related operation and the repository is hosted on GitHub. This skill provides consistent output formatting and workflow for GitHub PRs."
---

# GitHub PR Operations

Use the `mcp__plugin_github-plugin__*` MCP tools for all GitHub operations. Claude Code will automatically select the appropriate tool based on your request.

## Step 1: Auto-Detect Git Platform (REQUIRED FIRST STEP)

**Before any PR operation**, detect the git platform:

```bash
git remote -v
```

**Platform Detection:**

| Remote URL Pattern | Platform | Action |
|-------------------|----------|--------|
| `github.com` | **GitHub** | ✅ Continue |
| `bitbucket.org` | Bitbucket Cloud | ❌ Use `bitbucket-cloud` skill |
| `bitbucket.<company>.com` or custom domain | Bitbucket Data Center | ❌ Use `bitbucket-datacenter` skill |
| `gitlab.com` | GitLab | ❌ Not supported |

**Extract owner and repository from the remote URL:**

| Format | Example | Owner | Repo |
|--------|---------|-------|------|
| SSH | `git@github.com:owner/repo.git` | `owner` | `repo` |
| HTTPS | `https://github.com/owner/repo.git` | `owner` | `repo` |

---

## Output Formatting

When listing PRs, display results in a markdown table:

| # | Title | Author | Branch | Status | Updated |
|---|-------|--------|--------|--------|---------|
| 123 | Fix auth bug | @user | feature/auth → main | ✅ Open | 2 hours ago |

**Status icons:** ✅ Open | 📝 Draft | 🔀 Merged | ❌ Closed

**To exclude drafts**, use search with `draft:false` in the query.

---

## PR Review Workflow

When reviewing a PR:

1. **Fetch PR details and diff**
2. **Analyze for:**
   - Code correctness & bugs (logic errors, null handling, edge cases)
   - Security vulnerabilities (injection, secrets exposure)
   - Performance concerns (N+1 queries, memory leaks)
   - Code quality (style, naming, DRY/SOLID)

3. **Present review:**

```markdown
## PR Review: #<NUMBER> - <TITLE>

**Author:** <author> | **Branch:** <source> → <destination> | **Status:** <status>

### Summary
<Brief description>

### Issues Found
- **[file:line]** <issue description>

### Verdict
**<APPROVE | REQUEST_CHANGES | COMMENT>**
```

4. **Post comments/approve/request changes** if requested by user

---

## Review Comments Workflow

For reviews with inline comments:
1. Create a pending review first
2. Add inline comments to the pending review
3. Submit the pending review with a verdict
