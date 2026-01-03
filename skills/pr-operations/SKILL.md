---
name: "pr-operations"
description: "ALWAYS USE THIS SKILL instead of calling MCP tools directly for ANY pull request operation. Handle pull request operations across multiple platforms (Bitbucket Cloud, Bitbucket Data Center, GitHub). Use when user mentions \"PR\", \"pull request\", \"review\", \"list PRs\", \"get PRs\", \"non-draft PRs\", \"open PRs\", \"merge request\", or any PR-related operation. This skill detects the platform from git remote and routes to the correct backend. Do NOT use mcp__github__, mcp__bitbucket-cloud__, or mcp__bitbucket-datacenter__ tools directly - use this skill instead."
---

# PR Operations

Unified pull request operations across multiple VCS platforms: listing, reviewing, fetching details, and managing PRs with AI-powered analysis.

## Important: Skill Invocation

**Known Limitation:** MCP servers (like GitHub MCP) include embedded instructions in their system prompt that may cause Claude to call MCP tools directly instead of using this skill. This bypasses the skill's unified workflow and output formatting.

**To ensure this skill is used:**

1. **Explicit invocation (recommended):**
   ```
   /pr-operations
   /claude-skills:pr-operations
   ```

2. **Natural language with skill reference:**
   ```
   "Use the pr-operations skill to list PRs"
   "Run /pr-operations to review PR 123"
   ```

When invoked explicitly, this skill provides:
- Automatic platform detection from git remote
- Consistent table output format with status icons
- Unified workflow across GitHub, Bitbucket Cloud, and Bitbucket Data Center

## Supported Platforms

| Platform | Detection | Backend |
|----------|-----------|---------|
| GitHub | `github.com` in remote | MCP tools: `mcp__github__*` |
| Bitbucket Cloud | `bitbucket.org` in remote | MCP tools: `mcp__bitbucket-cloud__*` |
| Bitbucket Data Center | `bitbucket.<company>` in remote | MCP tools: `mcp__bitbucket-datacenter__*` |
| GitLab | `gitlab.com` in remote | `glab` CLI (placeholder) |

## Supported Operations

| User Request | Action |
|--------------|--------|
| "list PRs", "get PRs", "show open PRs" | List pull requests with optional filters |
| "get non-draft PRs", "exclude drafts" | List PRs excluding drafts |
| "review PR 123", "PR review" | Full PR review workflow |
| "get PR details", "show PR 123" | Fetch PR metadata |
| "get PR diff", "show changes" | Fetch PR diff/changes |
| "approve PR", "request changes" | Update PR status |

---

## Instructions

### Step 0: Detect Platform (REQUIRED FIRST STEP)

**Before any PR operation**, determine the platform by checking the git remote:

```bash
git remote -v
```

**Parse the remote URL to determine the platform:**

| Remote URL Pattern | Platform | Tools/CLI |
|-------------------|----------|-----------|
| `github.com` | GitHub | `mcp__github__*` |
| `bitbucket.org` | Bitbucket Cloud | `mcp__bitbucket-cloud__*` |
| `bitbucket.<company>.com` or other custom domain | Bitbucket Data Center | `mcp__bitbucket-datacenter__*` |
| `gitlab.com` or `gitlab.<company>.com` | GitLab | `glab` CLI |

**Extract owner and repository from the remote URL:**

| Format | Example | Owner | Repo |
|--------|---------|-------|------|
| GitHub SSH | `git@github.com:owner/repo.git` | `owner` | `repo` |
| GitHub HTTPS | `https://github.com/owner/repo.git` | `owner` | `repo` |
| Bitbucket Cloud SSH | `git@bitbucket.org:workspace/repo.git` | `workspace` | `repo` |
| Bitbucket Cloud HTTPS | `https://bitbucket.org/workspace/repo.git` | `workspace` | `repo` |
| Bitbucket DC SSH | `git@bitbucket.company.com:7999/PROJ/repo.git` | `PROJ` | `repo` |
| Bitbucket DC HTTPS | `https://bitbucket.company.com/scm/PROJ/repo.git` | `PROJ` | `repo` |
| GitLab SSH | `git@gitlab.com:owner/repo.git` | `owner` | `repo` |
| GitLab HTTPS | `https://gitlab.com/owner/repo.git` | `owner` | `repo` |

**Cache this context** for the rest of the conversation.

---

## GitHub Operations

Use MCP tools with prefix `mcp__github__`.

### Prerequisites

Requires the `github` MCP server to be configured. See [GitHub MCP Server](https://github.com/github/github-mcp-server) for setup instructions.

**Configuration options:**
- **Remote server (recommended):** Uses OAuth or PAT via `https://api.githubcopilot.com/mcp/`
- **Local server (Docker):** Uses `GITHUB_PERSONAL_ACCESS_TOKEN` environment variable

**Generate a GitHub PAT:**
1. Go to https://github.com/settings/tokens
2. Click **Generate new token** → **Fine-grained tokens** (recommended)
3. Set token name and expiration
4. Under **Repository access**, select your repos
5. Under **Permissions** → **Repository permissions**, enable:
   - **Pull requests**: Read and write
   - **Contents**: Read-only
   - **Metadata**: Read-only (required)
6. Click **Generate token** and copy it
7. Set environment variable:
   ```bash
   export GITHUB_PERSONAL_ACCESS_TOKEN="ghp_your_token_here"
   ```

### List Pull Requests

```
mcp__github__list_pull_requests(
  owner: "<owner>",
  repo: "<repo>",
  state: "open",              // open, closed, all
  sort: "created",            // created, updated, popularity, long-running
  direction: "desc",          // asc, desc
  perPage: 25,
  page: 1
)
```

**To exclude drafts**, filter the results or use search:

```
mcp__github__search_pull_requests(
  query: "repo:<owner>/<repo> is:pr is:open draft:false",
  perPage: 25
)
```

**Output Format:** Display results in a markdown table:

```markdown
| # | Title | Author | Branch | Status | Updated |
|---|-------|--------|--------|--------|---------|
| 123 | Fix authentication bug | @user | feature/auth → main | ✅ Open | 2 hours ago |
| 122 | Add dark mode support | @user2 | feature/dark-mode → main | 📝 Draft | 1 day ago |
| 121 | Update dependencies | @user3 | chore/deps → main | 🔀 Merged | 3 days ago |
```

**Status icons:**
- ✅ Open (ready for review)
- 📝 Draft
- 🔀 Merged
- ❌ Closed/Declined

### Get PR Details

```
mcp__github__pull_request_read(
  owner: "<owner>",
  repo: "<repo>",
  pullNumber: <PR_NUMBER>,
  method: "get"               // get, get_diff, get_status, get_files, get_review_comments, get_reviews, get_comments
)
```

**Available methods:**
- `get` - Get PR details (title, description, author, branches, state)
- `get_diff` - Get the diff of the PR
- `get_status` - Get build/check status of head commit
- `get_files` - Get list of files changed
- `get_review_comments` - Get review comment threads
- `get_reviews` - Get reviews on the PR
- `get_comments` - Get general comments on the PR

### Get PR Diff

```
mcp__github__pull_request_read(
  owner: "<owner>",
  repo: "<repo>",
  pullNumber: <PR_NUMBER>,
  method: "get_diff"
)
```

### Get PR Files Changed

```
mcp__github__pull_request_read(
  owner: "<owner>",
  repo: "<repo>",
  pullNumber: <PR_NUMBER>,
  method: "get_files",
  perPage: 100
)
```

### Create Review (Approve / Request Changes / Comment)

```
mcp__github__pull_request_review_write(
  owner: "<owner>",
  repo: "<repo>",
  pullNumber: <PR_NUMBER>,
  method: "create",           // create, submit, delete
  event: "APPROVE",           // APPROVE, REQUEST_CHANGES, COMMENT
  body: "Optional review comment"
)
```

### Add Inline Review Comment

First create a pending review, then add comments:

```
mcp__github__add_comment_to_pending_review(
  owner: "<owner>",
  repo: "<repo>",
  pullNumber: <PR_NUMBER>,
  path: "src/file.ts",
  line: 42,
  side: "RIGHT",              // LEFT (old), RIGHT (new)
  body: "Your feedback here",
  subjectType: "line"         // line, file
)
```

Then submit the review:

```
mcp__github__pull_request_review_write(
  owner: "<owner>",
  repo: "<repo>",
  pullNumber: <PR_NUMBER>,
  method: "submit",
  event: "COMMENT",
  body: "Review summary"
)
```

### Merge PR

```
mcp__github__merge_pull_request(
  owner: "<owner>",
  repo: "<repo>",
  pullNumber: <PR_NUMBER>,
  merge_method: "squash",     // merge, squash, rebase
  commit_title: "Optional custom title",
  commit_message: "Optional custom message"
)
```

### Create PR

```
mcp__github__create_pull_request(
  owner: "<owner>",
  repo: "<repo>",
  title: "PR Title",
  head: "feature-branch",
  base: "main",
  body: "PR description",
  draft: false
)
```

### Update PR

```
mcp__github__update_pull_request(
  owner: "<owner>",
  repo: "<repo>",
  pullNumber: <PR_NUMBER>,
  title: "New title",
  body: "New description",
  state: "open",              // open, closed
  draft: false                // true to convert to draft, false for ready for review
)
```

---

## Bitbucket Cloud Operations

Use MCP tools with prefix `mcp__bitbucket-cloud__`.

### Prerequisites

Requires the `bitbucket-cloud` MCP server to be configured with:
- `BITBUCKET_USERNAME`: Your Bitbucket username
- `BITBUCKET_APP_PASSWORD`: App password with repository and PR scopes

### List Pull Requests

```
mcp__bitbucket-cloud__list_pull_requests(
  workspace: "<workspace>",
  repository: "<repo>",
  state: "OPEN",           // OPEN, MERGED, DECLINED, ALL
  exclude_drafts: true,    // Filter out draft/WIP PRs
  limit: 25
)
```

**Output Format:** Display results in a markdown table:

```markdown
| # | Title | Author | Branch | Status | Updated |
|---|-------|--------|--------|--------|---------|
| 123 | Fix authentication bug | @user | feature/auth → main | ✅ Open | 2 hours ago |
| 122 | Add dark mode support | @user2 | feature/dark-mode → main | 📝 Draft | 1 day ago |
| 121 | Update dependencies | @user3 | chore/deps → main | 🔀 Merged | 3 days ago |
```

**Status icons:**
- ✅ Open (ready for review)
- 📝 Draft
- 🔀 Merged
- ❌ Declined

### Get PR Details

```
mcp__bitbucket-cloud__get_pull_request(
  workspace: "<workspace>",
  repository: "<repo>",
  pull_request_id: <PR_NUMBER>
)
```

### Get PR Diff

```
mcp__bitbucket-cloud__get_pull_request_diff(
  workspace: "<workspace>",
  repository: "<repo>",
  pull_request_id: <PR_NUMBER>,
  context_lines: 5,
  exclude_patterns: ["*.lock", "package-lock.json"]
)
```

### Add Comment

```
mcp__bitbucket-cloud__add_comment(
  workspace: "<workspace>",
  repository: "<repo>",
  pull_request_id: <PR_NUMBER>,
  comment_text: "Your feedback",
  file_path: "src/file.ts",      // Optional: for inline comment
  line_number: 42,                // Optional: for inline comment
  line_type: "ADDED",             // ADDED, REMOVED, or CONTEXT
  suggestion: "const x = 1;"      // Optional: code suggestion
)
```

### Approve / Request Changes

```
mcp__bitbucket-cloud__approve_pull_request(
  workspace: "<workspace>",
  repository: "<repo>",
  pull_request_id: <PR_NUMBER>
)

mcp__bitbucket-cloud__request_changes(
  workspace: "<workspace>",
  repository: "<repo>",
  pull_request_id: <PR_NUMBER>,
  comment: "Please address the feedback"
)
```

### Merge PR

```
mcp__bitbucket-cloud__merge_pull_request(
  workspace: "<workspace>",
  repository: "<repo>",
  pull_request_id: <PR_NUMBER>,
  merge_strategy: "squash",       // merge-commit, squash, fast-forward
  close_source_branch: true
)
```

---

## Bitbucket Data Center Operations

Use MCP tools with prefix `mcp__bitbucket-datacenter__`.

### Prerequisites

Requires the `bitbucket-datacenter` MCP server to be configured with:
- `BITBUCKET_BASE_URL`: Your Bitbucket Server URL (no trailing slash)
- `BITBUCKET_USERNAME`: Your full email address
- `BITBUCKET_TOKEN`: HTTP Access Token with repo read/write permissions

### List Pull Requests

```
mcp__bitbucket-datacenter__list_pull_requests(
  workspace: "<PROJECT_KEY>",
  repository: "<repo>",
  state: "OPEN",
  exclude_drafts: true,
  limit: 25
)
```

**Output Format:** Display results in a markdown table:

```markdown
| # | Title | Author | Branch | Status | Updated |
|---|-------|--------|--------|--------|---------|
| 123 | Fix authentication bug | @user | feature/auth → main | ✅ Open | 2 hours ago |
| 122 | Add dark mode support | @user2 | feature/dark-mode → main | 📝 Draft | 1 day ago |
| 121 | Update dependencies | @user3 | chore/deps → main | 🔀 Merged | 3 days ago |
```

**Status icons:**
- ✅ Open (ready for review)
- 📝 Draft
- 🔀 Merged
- ❌ Declined

### Get PR Details

```
mcp__bitbucket-datacenter__get_pull_request(
  workspace: "<PROJECT_KEY>",
  repository: "<repo>",
  pull_request_id: <PR_NUMBER>
)
```

### Get PR Diff

```
mcp__bitbucket-datacenter__get_pull_request_diff(
  workspace: "<PROJECT_KEY>",
  repository: "<repo>",
  pull_request_id: <PR_NUMBER>,
  context_lines: 5
)
```

### Add Comment

```
mcp__bitbucket-datacenter__add_comment(
  workspace: "<PROJECT_KEY>",
  repository: "<repo>",
  pull_request_id: <PR_NUMBER>,
  comment_text: "Your feedback",
  file_path: "src/file.ts",
  line_number: 42,
  line_type: "ADDED",
  suggestion: "const x = 1;"
)
```

### Approve / Request Changes

```
mcp__bitbucket-datacenter__approve_pull_request(
  workspace: "<PROJECT_KEY>",
  repository: "<repo>",
  pull_request_id: <PR_NUMBER>
)

mcp__bitbucket-datacenter__request_changes(
  workspace: "<PROJECT_KEY>",
  repository: "<repo>",
  pull_request_id: <PR_NUMBER>,
  comment: "Please address the feedback"
)
```

### Merge PR

```
mcp__bitbucket-datacenter__merge_pull_request(
  workspace: "<PROJECT_KEY>",
  repository: "<repo>",
  pull_request_id: <PR_NUMBER>,
  merge_strategy: "squash",
  close_source_branch: true
)
```

---

## GitLab Operations (Placeholder)

GitLab support is planned. Use the `glab` CLI if available:

```bash
# List merge requests
glab mr list

# View MR details
glab mr view <MR_NUMBER>

# Approve MR
glab mr approve <MR_NUMBER>
```

---

## Full PR Review Workflow

For comprehensive PR reviews on any platform:

### Step 1: Detect Platform & Get Context
Run `git remote -v` and extract platform, owner, and repo.

### Step 2: Fetch PR Details
Get PR metadata (title, description, author, branches, reviewers).

### Step 3: Get PR Diff
Fetch the code changes, optionally filtering by file patterns.

### Step 4: Analyze the Diff

Look for:

1. **Code Correctness & Bugs**
   - Logic errors, null handling, edge cases, race conditions

2. **Security Vulnerabilities**
   - Input validation, injection attacks, secrets exposure

3. **Performance Concerns**
   - N+1 queries, unnecessary iterations, memory leaks

4. **Code Quality**
   - Style consistency, naming, DRY/SOLID principles

5. **Documentation**
   - Comments where needed, README updates

### Step 5: Present Review

```markdown
## PR Review: #<NUMBER> - <TITLE>

**Platform:** <GitHub|Bitbucket Cloud|Bitbucket DC>
**Author:** <author>
**Branch:** <source> → <destination>
**Status:** <OPEN|MERGED|etc>

### Summary
<Brief description>

### Files Changed
- `path/to/file.ts` - <description>

### Issues Found
- **[file:line]** <issue description>

### Security Considerations
<concerns or "None identified">

### Performance Considerations
<concerns or "None identified">

### Verdict
**<APPROVE | REQUEST_CHANGES | COMMENT>**

---
**Next Steps:**
- [ ] Post comments?
- [ ] Approve/Request changes?
- [ ] Set up local worktree for testing?
```

### Step 6: Post Review (if requested)
Use platform-specific commands to post comments, approve, or request changes.

---

## Local Code Inspection

For deeper analysis, use the `git-worktree` skill to create an isolated worktree:

```bash
"${CLAUDE_PLUGIN_ROOT}/skills/git-worktree/setup-worktree.sh" --pr <NUMBER>
```

---

## Troubleshooting

### GitHub: MCP tools not available
Configure the `github` MCP server. Options:
- **Remote (recommended):** Add to MCP settings:
  ```json
  {
    "github": {
      "type": "http",
      "url": "https://api.githubcopilot.com/mcp/"
    }
  }
  ```
- **Local (Docker):** See [GitHub MCP Server installation](https://github.com/github/github-mcp-server)

### GitHub: Authentication errors
- Ensure `GITHUB_PERSONAL_ACCESS_TOKEN` is set in your environment
- PAT needs these permissions: Pull requests (read/write), Contents (read), Metadata (read)
- Generate a new token at: https://github.com/settings/tokens

### Bitbucket: MCP tools not available
Configure the appropriate MCP server (`bitbucket-cloud` or `bitbucket-datacenter`) in Claude Code settings.

### Bitbucket: Authentication errors
- **Cloud:** Use username (not email), ensure App Password has correct scopes
- **Data Center:** Use full email, ensure HTTP Access Token has read/write permissions

### Platform not detected
If `git remote -v` doesn't show a recognized platform, ask the user which platform they're using.
