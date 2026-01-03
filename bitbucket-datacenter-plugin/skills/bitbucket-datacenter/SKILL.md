---
name: "bitbucket-datacenter"
description: "Handle Bitbucket Data Center/Server pull request operations. Use when user mentions \"PR\", \"pull request\", \"review\", \"list PRs\", \"get PRs\", \"non-draft PRs\", \"open PRs\", or any PR-related operation and the repository is hosted on self-hosted Bitbucket Server or Data Center."
---

# Bitbucket Data Center PR Operations

Use the `mcp__plugin_bitbucket-datacenter-plugin__*` MCP tools for all Bitbucket Data Center operations. Claude Code will automatically select the appropriate tool based on your request.

## Step 1: Auto-Detect Git Platform (REQUIRED FIRST STEP)

**Before any PR operation**, detect the git platform:

```bash
git remote -v
```

**Platform Detection:**

| Remote URL Pattern | Platform | Action |
|-------------------|----------|--------|
| `bitbucket.<company>.com` or custom domain (NOT `bitbucket.org`) | **Bitbucket Data Center** | ✅ Continue |
| `bitbucket.org` | Bitbucket Cloud | ❌ Use `bitbucket-cloud` skill |
| `github.com` | GitHub | ❌ Use `github-pr` skill |
| `gitlab.com` | GitLab | ❌ Not supported |

**Extract project key and repository from the remote URL:**

| Format | Example | Project Key | Repo |
|--------|---------|-------------|------|
| SSH | `git@bitbucket.company.com:7999/PROJ/repo.git` | `PROJ` | `repo` |
| HTTPS | `https://bitbucket.company.com/scm/PROJ/repo.git` | `PROJ` | `repo` |

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
