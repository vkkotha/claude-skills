# Claude Skills Collection

A collection of reusable skills for [Claude Code](https://claude.ai/claude-code) - Anthropic's official CLI for Claude.

## Available Skills

| Skill | Description |
|-------|-------------|
| [bitbucket-pr-reviewer](./skills/bitbucket-pr-reviewer/) | Review Bitbucket pull requests with AI-powered code review, inline comments, and git worktree support |

## Installation

### Option 1: Install a Single Skill

Copy the skill folder to your project's `.claude/skills/` directory or `~/.claude/skills/` for global access:

```bash
# Clone the repo
git clone https://github.com/vkkotha/claude-skills.git

# Copy a specific skill to your project
cp -r claude-skills/skills/bitbucket-pr-reviewer /path/to/your/project/.claude/skills/

# Or install globally
cp -r claude-skills/skills/bitbucket-pr-reviewer ~/.claude/skills/
```

### Option 2: Install All Skills

```bash
# Clone and copy all skills globally
git clone https://github.com/vkkotha/claude-skills.git
cp -r claude-skills/skills/* ~/.claude/skills/
```

## Usage

Once installed, skills are automatically available in Claude Code. You can invoke them by:

1. **Using the skill name**: `/bitbucket-pr-reviewer`
2. **Natural language**: "Review PR 123" or "Help me review a pull request"

## Skill Structure

Each skill follows the standard Claude Code skill format:

```
skills/
└── skill-name/
    ├── SKILL.md          # Skill definition and instructions
    ├── *.sh              # Optional helper scripts
    └── README.md         # Optional documentation
```

## Contributing

Contributions are welcome! To add a new skill:

1. Fork this repository
2. Create a new folder under `skills/` with your skill name
3. Add a `SKILL.md` file following the [Claude Code skill format](https://docs.anthropic.com/claude-code/skills)
4. Submit a pull request

## License

MIT License - See [LICENSE](./LICENSE) for details.
