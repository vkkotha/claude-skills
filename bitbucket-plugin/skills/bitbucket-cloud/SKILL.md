---
name: "bitbucket-cloud"
description: "Handle Bitbucket Cloud pull request operations. Use when user mentions \"PR\", \"pull request\", \"review\", \"list PRs\", \"get PRs\", \"non-draft PRs\", \"open PRs\", or any PR-related operation and the repository is hosted on Bitbucket Cloud (bitbucket.org)."
---

# Bitbucket Cloud PR Operations

Use the `mcp__plugin_bitbucket-plugin__*` MCP tools for all Bitbucket Cloud operations. Claude Code will automatically select the appropriate tool based on your request.

## Step 1: Auto-Detect Git Platform (REQUIRED FIRST STEP)

**Before any PR operation**, detect the git platform:

```bash
git remote -v
```

**Platform Detection:**

| Remote URL Pattern | Platform | Action |
|-------------------|----------|--------|
| `bitbucket.org` | **Bitbucket Cloud** | ✅ Continue |
| `github.com` | GitHub | ❌ Use `github-pr` skill |
| `bitbucket.<company>.com` or custom domain | Bitbucket Data Center | ❌ Use `bitbucket-datacenter` skill |
| `gitlab.com` | GitLab | ❌ Not supported |

**Extract workspace and repository from the remote URL:**

| Format | Example | Workspace | Repo |
|--------|---------|-----------|------|
| SSH | `git@bitbucket.org:workspace/repo.git` | `workspace` | `repo` |
| HTTPS | `https://bitbucket.org/workspace/repo.git` | `workspace` | `repo` |

---

## Output Formatting

When listing PRs, display results in a markdown table:

| # | Title | Author | Branch | Status | Updated |
|---|-------|--------|--------|--------|---------|
| 123 | Fix auth bug | @user | feature/auth → main | ✅ Open | 2 hours ago |

**Status icons:** ✅ Open | 📝 Draft | 🔀 Merged | ❌ Declined

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
