# Custom Configs

This repository collates my local CLI and shell configuration repos into a single place:

- `.codex/`
- `.claude/`
- `.gemini/`
- `opencode/`
- `tmux/`

Each config lives in its own folder, and installs are managed from the repo-level `Makefile`. Only stable config files and directories are symlinked back into `$HOME`; runtime state stays local.

## Layout

### `.codex/`
Codex CLI configuration, rules, and the custom debate skill.

### `.claude/`
Claude Code settings and agents.

### `.gemini/`
Gemini Code settings, agents, and policy files.

### `opencode/`
OpenCode configuration that installs to the standard XDG config path at `~/.config/opencode`.

### `tmux/`
Tmux configuration and install script for `~/.tmux.conf`.

## Installation

Install everything at once:

```bash
make install-all
```

Install individual configs:

```bash
make install-codex
make install-claude
make install-gemini
make install-opencode
make install-tmux
```

The install targets create symlinks for the managed config paths:

- `~/.codex/config.toml -> <repo>/.codex/config.toml`
- `~/.codex/rules -> <repo>/.codex/rules`
- `~/.codex/skills/debate -> <repo>/.codex/skills/debate`
- `~/.claude/settings.json -> <repo>/.claude/settings.json`
- `~/.claude/agents -> <repo>/.claude/agents`
- `~/.gemini/settings.json -> <repo>/.gemini/settings.json`
- `~/.gemini/agents -> <repo>/.gemini/agents`
- `~/.gemini/policies -> <repo>/.gemini/policies`
- `~/.config/opencode/opencode.json -> <repo>/opencode/opencode.json`
- `~/.config/opencode/oh-my-opencode.json -> <repo>/opencode/oh-my-opencode.json`
- `~/.tmux.conf -> <repo>/tmux/.tmux.conf`

If a managed file or directory already exists at one of those targets, the Makefile-backed installer will first copy it to a mirrored path under `backup/`, then create the new symlink. If the target is already a symlink to the correct repo path, the installer leaves it unchanged. If it is a symlink to some other location, the symlink itself is backed up and then replaced.

Each install target first creates path-level backups under `backup/` inside this repo, mirroring the original home paths for only the managed files and directories. Examples:

- `~/.codex/config.toml` -> `backup/.codex/config.toml`
- `~/.codex/rules` -> `backup/.codex/rules`
- `~/.claude/agents` -> `backup/.claude/agents`
- `~/.config/opencode/opencode.json` -> `backup/.config/opencode/opencode.json`
- `~/.tmux.conf` -> `backup/.tmux.conf`

After that, the managed paths are replaced in place.

## Migration

Use this flow to migrate existing home-directory configs into this monorepo layout:

1. Run the installer from this repo:

```bash
cd /data/home/chanyoungs/custom-configs
make install-all
```

2. Review the repo for migrated changes and backups:

```bash
git -C /data/home/chanyoungs/custom-configs status --short
find /data/home/chanyoungs/custom-configs/backup -mindepth 1 2>/dev/null
```

Agent notes:

- Each Makefile install target is migration-aware at the path level and first creates mirrored backups under `backup/` in this repo for only the managed files and directories. The managed paths are then replaced in place, so large runtime-heavy directories are not copied.
- If the home path is already a symlink to the correct repo target, the installer exits without changing anything. If it points somewhere else, the symlink itself is backed up and replaced.
- Runtime state such as credentials, histories, caches, databases, temp files, and `node_modules` remains local because the parent tool directories are no longer symlinked wholesale.
- The tmux install target copies the previous `~/.tmux.conf` over the repo-managed `tmux/.tmux.conf`; review diffs before committing if that is not desired.
