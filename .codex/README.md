# Codex Configuration

This directory contains my Codex CLI configuration and custom debate skill.

## What's Included

### `config.toml`
Core Codex configuration.

### `rules/`
Rules loaded by Codex.

### `skills/debate/`
Custom debate skill, including supporting scripts and agent definitions.

## Installation

Run the repo-level Make target to symlink the managed Codex config paths into your home directory:

```bash
make install-codex
```

This manages `~/.codex/config.toml`, `~/.codex/rules`, and `~/.codex/skills/debate` from this repo. Runtime files in `~/.codex` remain local.
