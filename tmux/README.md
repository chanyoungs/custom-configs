# tmux configuration

Tmux configuration file.

## Installation

Run the repo-level Make target to symlink `.tmux.conf` to your home directory:

```bash
make install-tmux
```

This will create `~/.tmux.conf -> <repo>/tmux/.tmux.conf`. If a file already exists at `~/.tmux.conf`, it will be backed up to `~/.tmux.conf.bak`.
