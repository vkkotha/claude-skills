---
name: "cdskit-bitbucket-pr-reviewer"
description: Review Bitbucket pull requests with AI-powered analysis and inline comments. Use when user says "review PR", "PR review", or mentions reviewing a Bitbucket pull request.
---

# cdskit-bitbucket-pr-reviewer

Review Bitbucket pull requests using AI-powered analysis with inline comments and code suggestions.

**Supports both Bitbucket Cloud and Bitbucket Data Center/Server.**

## Prerequisites

### Required: MCP Server Setup

This skill requires a **Bitbucket MCP server** to be configured.

**Check if MCP tools are available:** Look for tools starting with `mcp__bitbucket__` (e.g., `mcp__bitbucket__get_pull_request`).

**If MCP tools are NOT available:** Use the `cdskit-mcp-setup` skill to configure the Bitbucket MCP server. Choose the appropriate template:
- `bitbucket-datacenter` - For Bitbucket Data Center/Server
- `bitbucket-cloud` - For Bitbucket Cloud

### Optional: Local Code Inspection

For local code inspection (running tests, deeper analysis), the `cdskit-pr-worktree` skill can create an isolated git worktree.

## Instructions

### Step 1: Get PR Information

Ask the user for:
- **PR number** (e.g., `558`)
- **Repository name** (if not obvious from context)
- **Workspace/Project key** (if not obvious from context)

If a Bitbucket URL is provided, extract the workspace, repository, and PR number:

**Bitbucket Data Center/Server URL:**
`https://bitbucket.yourcompany.com/projects/PROJ/repos/my-repo/pull-requests/123`
- Workspace: `PROJ`
- Repository: `my-repo`
- PR Number: `123`

**Bitbucket Cloud URL:**
`https://bitbucket.org/workspace/my-repo/pull-requests/123`
- Workspace: `workspace`
- Repository: `my-repo`
- PR Number: `123`

### Step 2: Fetch PR Details

Use `mcp__bitbucket__get_pull_request` to get PR metadata:

```
mcp__bitbucket__get_pull_request(
  workspace: "<PROJECT_KEY>",
  repository: "<repo-name>",
  pull_request_id: <PR_NUMBER>
)
```

This provides: PR title, description, author, source/destination branches, reviewers, approval status, and PR state.

### Step 3: Get PR Diff

Use `mcp__bitbucket__get_pull_request_diff` to get code changes:

```
mcp__bitbucket__get_pull_request_diff(
  workspace: "<PROJECT_KEY>",
  repository: "<repo-name>",
  pull_request_id: <PR_NUMBER>,
  context_lines: 5
)
```

**Optional filters:**
- `file_path`: Get diff for a specific file
- `include_patterns`: Array of glob patterns (e.g., `["*.ts", "*.tsx"]`)
- `exclude_patterns`: Array of glob patterns (e.g., `["*.lock", "package-lock.json"]`)

### Step 4: Get PR Commits (Optional)

Use `mcp__bitbucket__list_pr_commits` for commit history:

```
mcp__bitbucket__list_pr_commits(
  workspace: "<PROJECT_KEY>",
  repository: "<repo-name>",
  pull_request_id: <PR_NUMBER>
)
```

### Step 5: Setup Local Worktree (Optional)

If the user wants to inspect code locally or run tests, use the `cdskit-pr-worktree` skill to create an isolated worktree.

### Step 6: Generate PR Review

Analyze the diff, looking for:

1. **Code Correctness & Bugs**
   - Logic errors
   - Null/undefined handling
   - Edge cases
   - Race conditions

2. **Security Vulnerabilities**
   - Input validation
   - SQL injection
   - XSS vulnerabilities
   - Secrets/credentials exposure
   - Authentication/authorization issues

3. **Performance Concerns**
   - N+1 queries
   - Unnecessary iterations
   - Memory leaks
   - Missing caching opportunities

4. **Code Quality**
   - Code style and consistency
   - Naming conventions
   - DRY principles
   - SOLID principles
   - Test coverage

5. **Documentation**
   - Code comments where needed
   - README updates
   - API documentation

### Step 7: Post Review Comments

**General comment on PR:**
```
mcp__bitbucket__add_comment(
  workspace: "<PROJECT_KEY>",
  repository: "<repo-name>",
  pull_request_id: <PR_NUMBER>,
  comment_text: "Your comment here"
)
```

**Inline comment on specific code:**
```
mcp__bitbucket__add_comment(
  workspace: "<PROJECT_KEY>",
  repository: "<repo-name>",
  pull_request_id: <PR_NUMBER>,
  comment_text: "Your feedback",
  file_path: "src/path/to/file.ts",
  line_number: 42,
  line_type: "ADDED"  // or "REMOVED" or "CONTEXT"
)
```

**Code suggestion (can be applied in Bitbucket UI):**
```
mcp__bitbucket__add_comment(
  workspace: "<PROJECT_KEY>",
  repository: "<repo-name>",
  pull_request_id: <PR_NUMBER>,
  comment_text: "Consider using a more descriptive name",
  file_path: "src/path/to/file.ts",
  line_number: 42,
  suggestion: "const descriptiveName = value;"
)
```

**Using code snippet for line detection:**
```
mcp__bitbucket__add_comment(
  workspace: "<PROJECT_KEY>",
  repository: "<repo-name>",
  pull_request_id: <PR_NUMBER>,
  comment_text: "This could cause a null pointer exception",
  file_path: "src/path/to/file.ts",
  code_snippet: "const result = data.items.map(item => item.value)"
)
```

### Step 8: Approve or Request Changes

**To approve:**
```
mcp__bitbucket__approve_pull_request(
  workspace: "<PROJECT_KEY>",
  repository: "<repo-name>",
  pull_request_id: <PR_NUMBER>
)
```

**To request changes:**
```
mcp__bitbucket__request_changes(
  workspace: "<PROJECT_KEY>",
  repository: "<repo-name>",
  pull_request_id: <PR_NUMBER>,
  comment: "Please address the feedback before merging"
)
```

### Step 9: Cleanup (Optional)

If a worktree was created, offer to clean it up using the `cdskit-pr-worktree` skill.

## Review Output Format

```markdown
## PR Review: #<PR_NUMBER> - <PR_TITLE>

**Author:** <author_name>
**Branch:** <source_branch> → <destination_branch>
**Status:** <OPEN|MERGED|DECLINED>
**Reviewers:** <list of reviewers with approval status>

### Summary
<Brief description of what the PR does>

### Files Changed (<count> files)
- `path/to/file1.ts` - <brief description>
- `path/to/file2.ts` - <brief description>

### Detailed Review

#### `path/to/file1.ts`
- **Line X-Y**: <feedback>
- **Line Z**: <feedback>

### Security Considerations
<Any security concerns or "No security issues identified">

### Performance Considerations
<Any performance concerns or "No performance issues identified">

### Suggestions
- <Suggestion 1>
- <Suggestion 2>

### Verdict
**<APPROVE | REQUEST_CHANGES | COMMENT>**

<Final summary and recommendation>

---
**Next Steps:**
- [ ] Post comments to Bitbucket?
- [ ] Approve PR?
- [ ] Request changes?
- [ ] Set up local worktree for testing?
```

## Available MCP Tools

| Tool | Purpose |
|------|---------|
| `get_pull_request` | Get PR details (title, description, reviewers, status) |
| `get_pull_request_diff` | Get code changes/diff with optional filtering |
| `list_pr_commits` | List all commits in the PR |
| `add_comment` | Add general, inline, or suggestion comments |
| `approve_pull_request` | Approve a PR |
| `request_changes` | Request changes on a PR |
| `unapprove_pull_request` | Remove approval |
| `remove_requested_changes` | Remove change request |
| `get_file_content` | Get full file content from repository |
| `list_directory_content` | Browse repository file structure |

## Troubleshooting

### MCP Tools Not Available

Use the `cdskit-mcp-setup` skill to configure the Bitbucket MCP server.

### Authentication Errors

**For Bitbucket Data Center/Server:**
- Use full email address for `BITBUCKET_USERNAME`
- Ensure HTTP Access Token has Read/Write permissions
- Check `BITBUCKET_BASE_URL` has no trailing slash

**For Bitbucket Cloud:**
- Use Bitbucket username (not email) for `BITBUCKET_USERNAME`
- Ensure App Password has Account, Repositories, and Pull requests scopes

### PR Not Found

- Verify the workspace/project key is correct (case-sensitive)
- Verify the repository name is correct
- Ensure you have access to the repository

## Example Usage

**User:** "Review PR 558"

**Response flow:**
1. Use `get_pull_request` to fetch PR #558 metadata
2. Use `get_pull_request_diff` to get the code changes
3. Analyze the diff for issues
4. Present structured review to user
5. Ask if user wants to:
   - Post comments to Bitbucket
   - Approve or request changes
   - Set up local worktree for deeper inspection
