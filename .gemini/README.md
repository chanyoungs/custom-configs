# Gemini Code Configuration

This repository contains my personal Gemini Code CLI configuration and customizations.

## What's Included

### `settings.json`
Core configuration settings for Gemini Code, including preferences, display options, and behavior settings.

### `agents/`
Custom agent definitions for specialized tasks:
- `log-analyst.md` - Expert log analysis agent for parsing and summarizing lengthy outputs

### `policies/`
Policy configurations that control behavior and rules:
- `auto-saved.toml` - Auto-saved policy configurations

## What's NOT Included

For privacy and security, the following are excluded via `.gitignore`:
- OAuth credentials (`oauth_creds.json`)
- Account information (`google_accounts.json`)
- Installation ID (`installation_id`)
- Runtime state (`state.json`)
- Temporary files (`tmp/`)
- Git directory (`.git/`)

## Installation

Run the repo-level Make target to symlink the managed Gemini config paths into your home directory:

```bash
make install-gemini
```

This manages `~/.gemini/settings.json`, `~/.gemini/agents`, and `~/.gemini/policies` from this repo. Runtime files in `~/.gemini` remain local.

## Customization

- **Settings**: Edit `settings.json` for shared preferences
- **Custom Agents**: Add new `.md` files to `agents/` directory
- **Policies**: Add or modify `.toml` files in `policies/` directory

## Security Note

Sensitive files like OAuth credentials, account information, and runtime state are excluded via `.gitignore` to prevent accidentally committing private data.
