# OpenCode Configuration

This directory contains my OpenCode configuration files.

## What's Included

### `opencode.json`
Primary OpenCode configuration.

### `oh-my-opencode.json`
Additional agent and category configuration.

## Installation

Run the repo-level Make target to symlink the managed OpenCode config files into your home config directory:

```bash
make install-opencode
```

This manages `~/.config/opencode/opencode.json` and `~/.config/opencode/oh-my-opencode.json` from this repo. Local package state such as `node_modules` remains local.
