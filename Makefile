.PHONY: install-all install-codex install-claude install-gemini install-opencode install-tmux

ROOT_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
INSTALL_TREE := $(ROOT_DIR)utils/install_tree.sh
BACKUP_DIR := $(ROOT_DIR)backup

install-all: install-codex install-claude install-gemini install-opencode install-tmux
	@echo "All configuration symlinks installed."

install-codex:
	@"$(INSTALL_TREE)" "$(ROOT_DIR).codex" "$(HOME)/.codex" "$(BACKUP_DIR)/.codex" "skills"

install-claude:
	@"$(INSTALL_TREE)" "$(ROOT_DIR).claude" "$(HOME)/.claude" "$(BACKUP_DIR)/.claude"

install-gemini:
	@"$(INSTALL_TREE)" "$(ROOT_DIR).gemini" "$(HOME)/.gemini" "$(BACKUP_DIR)/.gemini"

install-opencode:
	@"$(INSTALL_TREE)" "$(ROOT_DIR)opencode" "$(HOME)/.config/opencode" "$(BACKUP_DIR)/.config/opencode"

install-tmux:
	@"$(INSTALL_TREE)" "$(ROOT_DIR)tmux" "$(HOME)" "$(BACKUP_DIR)"
