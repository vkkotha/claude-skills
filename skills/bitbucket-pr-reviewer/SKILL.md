---
name: bitbucket-pr-reviewer
description: Review Bitbucket pull requests by checking out PR code into a git worktree, opening your editor, and generating a comprehensive code review. Use when user says "review PR", "PR review", or mentions reviewing a pull request. (project)
---

# Bitbucket PR Reviewer Skill

Review Bitbucket pull requests using a **Bitbucket MCP server** for seamless Bitbucket integration, combined with git worktrees for local code inspection.

**Supports both Bitbucket Cloud and Bitbucket Data Center/Server.**

## Prerequisites: MCP Server Setup

Before using this skill, ensure a **Bitbucket MCP server** is configured.

### Step 0: Check if MCP Tools are Available

**IMPORTANT:** Before starting a PR review, verify the MCP server is running by checking if Bitbucket MCP tools are available (tools starting with `mcp__bitbucket`).

If the tools are NOT available, guide the user through the setup below.

### Check MCP Configuration

Look for `.mcp.json` in the project root (or `~/.claude/.mcp.json` for global config).

**For Bitbucket Data Center/Server:**
```json
{
  "mcpServers": {
    "bitbucket": {
      "command": "npx",
      "args": ["-y", "@nexus2520/bitbucket-mcp-server"],
      "env": {
        "BITBUCKET_USERNAME": "${BITBUCKET_USERNAME}",
        "BITBUCKET_BASE_URL": "${BITBUCKET_BASE_URL}",
        "BITBUCKET_TOKEN": "${BITBUCKET_TOKEN}"
      }
    }
  }
}
```

**For Bitbucket Cloud:**
```json
{
  "mcpServers": {
    "bitbucket": {
      "command": "npx",
      "args": ["-y", "@nexus2520/bitbucket-mcp-server"],
      "env": {
        "BITBUCKET_USERNAME": "${BITBUCKET_USERNAME}",
        "BITBUCKET_APP_PASSWORD": "${BITBUCKET_APP_PASSWORD}"
      }
    }
  }
}
```

The configuration uses environment variable references (`${VAR_NAME}`) which Claude Code will resolve from your shell environment.

### If MCP is Not Configured

Guide the user to set it up based on their Bitbucket edition:

#### For Bitbucket Data Center/Server

1. **Set environment variables** in your shell profile (`.bashrc`, `.zshrc`, etc.):
   ```bash
   export BITBUCKET_USERNAME="your.email@company.com"  # Use full email for approval actions
   export BITBUCKET_TOKEN="your-http-access-token"
   export BITBUCKET_BASE_URL="https://bitbucket.yourcompany.com"
   ```

2. **Generate a Bitbucket HTTP Access Token:**
   - Go to your Bitbucket Server → Profile → Personal Access Tokens (or HTTP Access Tokens)
   - Create a new token with **Read** and **Write** permissions for repositories and pull requests
   - Copy the token value

3. **Create `.mcp.json`** in the project root (or `~/.claude/.mcp.json` for global config):
   ```json
   {
     "mcpServers": {
       "bitbucket": {
         "command": "npx",
         "args": ["-y", "@nexus2520/bitbucket-mcp-server"],
         "env": {
           "BITBUCKET_USERNAME": "${BITBUCKET_USERNAME}",
           "BITBUCKET_BASE_URL": "${BITBUCKET_BASE_URL}",
           "BITBUCKET_TOKEN": "${BITBUCKET_TOKEN}"
         }
       }
     }
   }
   ```

#### For Bitbucket Cloud

1. **Set environment variables** in your shell profile (`.bashrc`, `.zshrc`, etc.):
   ```bash
   export BITBUCKET_USERNAME="your-username"  # Your Bitbucket username (not email)
   export BITBUCKET_APP_PASSWORD="your-app-password"
   ```

2. **Generate a Bitbucket App Password:**
   - Go to: https://bitbucket.org/account/settings/app-passwords/
   - Click "Create app password"
   - Give it a label (e.g., "Claude Code MCP")
   - Select permissions: **Account** (Read), **Repositories** (Read, Write), **Pull requests** (Read, Write)
   - Click "Create" and copy the password immediately

3. **Create `.mcp.json`** in the project root (or `~/.claude/.mcp.json` for global config):
   ```json
   {
     "mcpServers": {
       "bitbucket": {
         "command": "npx",
         "args": ["-y", "@nexus2520/bitbucket-mcp-server"],
         "env": {
           "BITBUCKET_USERNAME": "${BITBUCKET_USERNAME}",
           "BITBUCKET_APP_PASSWORD": "${BITBUCKET_APP_PASSWORD}"
         }
       }
     }
   }
   ```

#### Final Steps (Both Editions)

4. **Restart your terminal** to load the environment variables

5. **Restart Claude Code** to load the MCP server

6. **Verify setup** by checking that Bitbucket MCP tools are available (e.g., `mcp__bitbucket__get_pull_request`)

## Instructions

When the user wants to review a PR, follow these steps:

### Step 1: Get PR Information

Ask the user for:
- **PR number** (e.g., `558`)
- **Repository name** (if not obvious from context)
- **Workspace/Project key** (if not obvious from context)

If a Bitbucket URL is provided, extract the workspace, repository, and PR number from it.

**Bitbucket Data Center/Server URL format:**
`https://bitbucket.yourcompany.com/projects/PROJ/repos/my-repo/pull-requests/123`
- Workspace: `PROJ`
- Repository: `my-repo`
- PR Number: `123`

**Bitbucket Cloud URL format:**
`https://bitbucket.org/workspace/my-repo/pull-requests/123`
- Workspace: `workspace`
- Repository: `my-repo`
- PR Number: `123`

### Step 2: Fetch PR Details Using MCP

Use the `mcp__bitbucket__get_pull_request` tool to get PR metadata:

```
mcp__bitbucket__get_pull_request(
  workspace: "<PROJECT_KEY>",
  repository: "<repo-name>",
  pull_request_id: <PR_NUMBER>
)
```

This provides:
- PR title and description
- Author information
- Source and destination branches
- Reviewers and approval status
- PR state (OPEN, MERGED, DECLINED)

### Step 3: Get PR Diff Using MCP

Use the `mcp__bitbucket__get_pull_request_diff` tool to get the code changes:

```
mcp__bitbucket__get_pull_request_diff(
  workspace: "<PROJECT_KEY>",
  repository: "<repo-name>",
  pull_request_id: <PR_NUMBER>,
  context_lines: 5
)
```

**Optional filters:**
- `file_path`: Get diff for a specific file only
- `include_patterns`: Array of glob patterns to include (e.g., `["*.ts", "*.tsx"]`)
- `exclude_patterns`: Array of glob patterns to exclude (e.g., `["*.lock", "*.svg", "package-lock.json"]`)

### Step 4: Get PR Commits (Optional)

Use `mcp__bitbucket__list_pr_commits` to understand the commit history:

```
mcp__bitbucket__list_pr_commits(
  workspace: "<PROJECT_KEY>",
  repository: "<repo-name>",
  pull_request_id: <PR_NUMBER>
)
```

### Step 5: Setup Local Worktree (Optional)

If the user wants to inspect the code locally or run tests, set up a git worktree.

**Before running the script, ask the user about their editor preference:**

Use the AskUserQuestion tool to ask:
```
How would you like to open the PR worktree?

Question 1 - Editor:
1. Auto-detect - Use first available (VSCode, Cursor, Windsurf) (Recommended)
2. VSCode - Use VSCode specifically
3. Cursor - Use Cursor specifically
4. Terminal only - Don't open any editor (CLI users)

Question 2 - Window mode (if not "Terminal only"):
1. New window - Open in a new editor window (Recommended)
2. Current window - Reuse current editor window
```

**Script usage:**
```bash
./.claude/skills/bitbucket-pr-reviewer/setup-pr-worktree.sh <PR_NUMBER> [EDITOR_MODE] [EDITOR_CMD]

# EDITOR_MODE options:
#   new   - Open in new editor window (default)
#   reuse - Open in current editor window
#   skip  - Don't open any editor (for CLI/terminal users)

# EDITOR_CMD options:
#   auto     - Auto-detect available editor (default)
#   code     - VSCode
#   cursor   - Cursor
#   windsurf - Windsurf
#   <cmd>    - Any custom editor command
```

**Cross-platform execution examples:**

```bash
# macOS/Linux - Auto-detect editor
./.claude/skills/bitbucket-pr-reviewer/setup-pr-worktree.sh 558 new auto
./.claude/skills/bitbucket-pr-reviewer/setup-pr-worktree.sh 558 new code
./.claude/skills/bitbucket-pr-reviewer/setup-pr-worktree.sh 558 new cursor
./.claude/skills/bitbucket-pr-reviewer/setup-pr-worktree.sh 558 skip

# Windows CMD/PowerShell with Git for Windows
bash ./.claude/skills/bitbucket-pr-reviewer/setup-pr-worktree.sh 558 new auto

# Windows with WSL
wsl bash ./.claude/skills/bitbucket-pr-reviewer/setup-pr-worktree.sh 558 new auto
```

**Auto-detection logic for Claude:**
1. Check if running on Windows: `os.platform() === 'win32'` or check for `C:\` paths
2. On Windows, try `bash` first (Git Bash), fall back to `wsl bash` if needed
3. On macOS/Linux, run the script directly

This will:
- Fetch the PR branch from Bitbucket
- Create a worktree at `../<project_name>.worktrees/PR-<PR_NUMBER>`
- Open the editor based on user's preference (or skip for CLI users)

### Step 6: Generate PR Review

Analyze the diff from Step 3, looking for:

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

### Step 7: Post Review Comments Using MCP

Use the MCP server to post inline comments directly to the PR:

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

**Using code snippet for line detection (auto-finds line number):**
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

**To approve the PR:**
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

After the review is complete, offer to clean up the local worktree.

**Cross-platform execution:** Use the same platform detection as Step 5:

```bash
# macOS/Linux
./.claude/skills/bitbucket-pr-reviewer/cleanup-pr-worktree.sh <PR_NUMBER>

# Windows CMD/PowerShell with Git for Windows
bash ./.claude/skills/bitbucket-pr-reviewer/cleanup-pr-worktree.sh <PR_NUMBER>

# Windows with WSL
wsl bash ./.claude/skills/bitbucket-pr-reviewer/cleanup-pr-worktree.sh <PR_NUMBER>
```

## Available MCP Tools Reference

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

## Review Output Format

```markdown
## PR Review: #<PR_NUMBER> - <PR_TITLE>

**Author:** <author_name>
**Branch:** <source_branch> → <destination_branch>
**Status:** <OPEN|MERGED|DECLINED>
**Reviewers:** <list of reviewers with approval status>

### Summary
<Brief description of what the PR does based on description and changes>

### Files Changed (<count> files)
- `path/to/file1.ts` - <brief description of changes>
- `path/to/file2.ts` - <brief description of changes>

### Detailed Review

#### `path/to/file1.ts`
- **Line X-Y**: <feedback>
- **Line Z**: <feedback>

#### `path/to/file2.ts`
- **Line A**: <feedback>

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

## Troubleshooting

### MCP Server Not Working

1. **Check if MCP tools are available:** The tools should start with `mcp__bitbucket__`
2. **Verify configuration:** Check `.mcp.json` exists and has correct values
3. **Restart Claude Code:** MCP servers are loaded on startup
4. **Check token permissions:** Ensure the Bitbucket token has read access to PRs

### Authentication Errors

**For Bitbucket Data Center/Server:**
- Verify the `BITBUCKET_TOKEN` environment variable is set and the token is not expired
- Ensure `BITBUCKET_USERNAME` is your full email address (required for approval actions)
- Check `BITBUCKET_BASE_URL` is correct (no trailing slash)

**For Bitbucket Cloud:**
- Verify the `BITBUCKET_APP_PASSWORD` environment variable is set
- Ensure `BITBUCKET_USERNAME` is your Bitbucket username (not email)

**Both editions:**
- Confirm environment variables are exported in your shell: `echo $BITBUCKET_USERNAME`
- Restart Claude Code after changing environment variables

### PR Not Found

- Verify the workspace/project key is correct (case-sensitive)
- Verify the repository name is correct
- Ensure you have access to the repository

### Windows Script Execution Issues

The worktree scripts require bash. On Windows:

1. **Git for Windows (recommended):** Install [Git for Windows](https://git-scm.com/download/win) which includes Git Bash
   - The `bash` command will be available in CMD/PowerShell
   - Run: `bash ./.claude/skills/bitbucket-pr-reviewer/setup-pr-worktree.sh <PR_NUMBER>`

2. **WSL (Windows Subsystem for Linux):** If you have WSL installed
   - Run: `wsl bash ./.claude/skills/bitbucket-pr-reviewer/setup-pr-worktree.sh <PR_NUMBER>`

3. **Check bash availability:**
   ```cmd
   where bash
   ```
   If not found, install Git for Windows or enable WSL

4. **Editor not opening:** Ensure the editor command is in your PATH
   - **VSCode:** Command Palette → "Shell Command: Install 'code' command in PATH"
   - **Cursor:** Command Palette → "Shell Command: Install 'cursor' command in PATH"
   - **Windsurf:** Settings → Install 'windsurf' command in PATH
   - **CLI users:** Use `skip` mode and navigate manually: `cd <worktree_path>`
