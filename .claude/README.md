# Claude Code Configuration

This repository contains my personal Claude Code CLI configuration and customizations.

## What's Included

### `settings.json`
Core configuration settings for Claude Code, including preferences, display options, and behavior settings.

### `agents/`
Custom agent definitions for specialized tasks:
- `log-analyzer.md` - Expert log analysis agent for parsing and summarizing lengthy outputs

## What's NOT Included

For privacy and security, the following are excluded via `.gitignore`:
- Authentication credentials (`.credentials.json`)
- Conversation history (`history.jsonl`)
- Session data and file history
- Cache files and temporary data
- Personal work items (todos, plans)
- Machine-specific settings (`settings.local.json`)

## Installation

Run the repo-level Make target to symlink the managed Claude config paths into your home directory:

```bash
make install-claude
```

This manages `~/.claude/settings.json` and `~/.claude/agents` from this repo. Plugins and runtime files in `~/.claude` remain local.

## Customization

- **Settings**: Edit `settings.json` for shared preferences
- **Local Overrides**: Use `settings.local.json` for machine-specific settings (not tracked)
- **Custom Agents**: Add new `.md` files to `agents/` directory
- **Plugins**: Keep plugin configurations local under `~/.claude/plugins`

## Security Note

Sensitive files and runtime state are excluded via explicit ignore rules in the root monorepo `.gitignore`.
