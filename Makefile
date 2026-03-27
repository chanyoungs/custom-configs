.PHONY: install-all install-codex install-claude install-gemini install-opencode install-tmux

ROOT_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
INSTALL := $(ROOT_DIR)utils/install_symlink.sh
BACKUP_DIR := $(ROOT_DIR)backup

install-all: install-codex install-claude install-gemini install-opencode install-tmux
	@echo "All configuration symlinks installed."

install-codex:
	@mkdir -p "$(HOME)/.codex" "$(HOME)/.codex/skills"
	@if { [ -e "$(HOME)/.codex/config.toml" ] || [ -L "$(HOME)/.codex/config.toml" ]; } && [ ! -e "$(BACKUP_DIR)/.codex/config.toml" ] && [ ! -L "$(BACKUP_DIR)/.codex/config.toml" ]; then \
		mkdir -p "$(BACKUP_DIR)/.codex"; \
		echo "Creating backup: $(BACKUP_DIR)/.codex/config.toml"; \
		cp -a "$(HOME)/.codex/config.toml" "$(BACKUP_DIR)/.codex/config.toml"; \
	fi
	@if { [ -e "$(HOME)/.codex/rules" ] || [ -L "$(HOME)/.codex/rules" ]; } && [ ! -e "$(BACKUP_DIR)/.codex/rules" ] && [ ! -L "$(BACKUP_DIR)/.codex/rules" ]; then \
		mkdir -p "$(BACKUP_DIR)/.codex"; \
		echo "Creating backup: $(BACKUP_DIR)/.codex/rules"; \
		cp -a "$(HOME)/.codex/rules" "$(BACKUP_DIR)/.codex/rules"; \
	fi
	@if { [ -e "$(HOME)/.codex/skills/debate" ] || [ -L "$(HOME)/.codex/skills/debate" ]; } && [ ! -e "$(BACKUP_DIR)/.codex/skills/debate" ] && [ ! -L "$(BACKUP_DIR)/.codex/skills/debate" ]; then \
		mkdir -p "$(BACKUP_DIR)/.codex/skills"; \
		echo "Creating backup: $(BACKUP_DIR)/.codex/skills/debate"; \
		cp -a "$(HOME)/.codex/skills/debate" "$(BACKUP_DIR)/.codex/skills/debate"; \
	fi
	@"$(INSTALL)" "$(HOME)/.codex/config.toml" "$(ROOT_DIR).codex/config.toml" "" "1"
	@"$(INSTALL)" "$(HOME)/.codex/rules" "$(ROOT_DIR).codex/rules" "" "1"
	@"$(INSTALL)" "$(HOME)/.codex/skills/debate" "$(ROOT_DIR).codex/skills/debate" "$(HOME)/.codex/skills" "1"

install-claude:
	@mkdir -p "$(HOME)/.claude"
	@if { [ -e "$(HOME)/.claude/settings.json" ] || [ -L "$(HOME)/.claude/settings.json" ]; } && [ ! -e "$(BACKUP_DIR)/.claude/settings.json" ] && [ ! -L "$(BACKUP_DIR)/.claude/settings.json" ]; then \
		mkdir -p "$(BACKUP_DIR)/.claude"; \
		echo "Creating backup: $(BACKUP_DIR)/.claude/settings.json"; \
		cp -a "$(HOME)/.claude/settings.json" "$(BACKUP_DIR)/.claude/settings.json"; \
	fi
	@if { [ -e "$(HOME)/.claude/agents" ] || [ -L "$(HOME)/.claude/agents" ]; } && [ ! -e "$(BACKUP_DIR)/.claude/agents" ] && [ ! -L "$(BACKUP_DIR)/.claude/agents" ]; then \
		mkdir -p "$(BACKUP_DIR)/.claude"; \
		echo "Creating backup: $(BACKUP_DIR)/.claude/agents"; \
		cp -a "$(HOME)/.claude/agents" "$(BACKUP_DIR)/.claude/agents"; \
	fi
	@"$(INSTALL)" "$(HOME)/.claude/settings.json" "$(ROOT_DIR).claude/settings.json" "" "1"
	@"$(INSTALL)" "$(HOME)/.claude/agents" "$(ROOT_DIR).claude/agents" "" "1"

install-gemini:
	@mkdir -p "$(HOME)/.gemini"
	@if { [ -e "$(HOME)/.gemini/settings.json" ] || [ -L "$(HOME)/.gemini/settings.json" ]; } && [ ! -e "$(BACKUP_DIR)/.gemini/settings.json" ] && [ ! -L "$(BACKUP_DIR)/.gemini/settings.json" ]; then \
		mkdir -p "$(BACKUP_DIR)/.gemini"; \
		echo "Creating backup: $(BACKUP_DIR)/.gemini/settings.json"; \
		cp -a "$(HOME)/.gemini/settings.json" "$(BACKUP_DIR)/.gemini/settings.json"; \
	fi
	@if { [ -e "$(HOME)/.gemini/agents" ] || [ -L "$(HOME)/.gemini/agents" ]; } && [ ! -e "$(BACKUP_DIR)/.gemini/agents" ] && [ ! -L "$(BACKUP_DIR)/.gemini/agents" ]; then \
		mkdir -p "$(BACKUP_DIR)/.gemini"; \
		echo "Creating backup: $(BACKUP_DIR)/.gemini/agents"; \
		cp -a "$(HOME)/.gemini/agents" "$(BACKUP_DIR)/.gemini/agents"; \
	fi
	@if { [ -e "$(HOME)/.gemini/policies" ] || [ -L "$(HOME)/.gemini/policies" ]; } && [ ! -e "$(BACKUP_DIR)/.gemini/policies" ] && [ ! -L "$(BACKUP_DIR)/.gemini/policies" ]; then \
		mkdir -p "$(BACKUP_DIR)/.gemini"; \
		echo "Creating backup: $(BACKUP_DIR)/.gemini/policies"; \
		cp -a "$(HOME)/.gemini/policies" "$(BACKUP_DIR)/.gemini/policies"; \
	fi
	@"$(INSTALL)" "$(HOME)/.gemini/settings.json" "$(ROOT_DIR).gemini/settings.json" "" "1"
	@"$(INSTALL)" "$(HOME)/.gemini/agents" "$(ROOT_DIR).gemini/agents" "" "1"
	@"$(INSTALL)" "$(HOME)/.gemini/policies" "$(ROOT_DIR).gemini/policies" "" "1"

install-opencode:
	@mkdir -p "$(HOME)/.config/opencode"
	@if { [ -e "$(HOME)/.config/opencode/opencode.json" ] || [ -L "$(HOME)/.config/opencode/opencode.json" ]; } && [ ! -e "$(BACKUP_DIR)/.config/opencode/opencode.json" ] && [ ! -L "$(BACKUP_DIR)/.config/opencode/opencode.json" ]; then \
		mkdir -p "$(BACKUP_DIR)/.config/opencode"; \
		echo "Creating backup: $(BACKUP_DIR)/.config/opencode/opencode.json"; \
		cp -a "$(HOME)/.config/opencode/opencode.json" "$(BACKUP_DIR)/.config/opencode/opencode.json"; \
	fi
	@if { [ -e "$(HOME)/.config/opencode/oh-my-opencode.json" ] || [ -L "$(HOME)/.config/opencode/oh-my-opencode.json" ]; } && [ ! -e "$(BACKUP_DIR)/.config/opencode/oh-my-opencode.json" ] && [ ! -L "$(BACKUP_DIR)/.config/opencode/oh-my-opencode.json" ]; then \
		mkdir -p "$(BACKUP_DIR)/.config/opencode"; \
		echo "Creating backup: $(BACKUP_DIR)/.config/opencode/oh-my-opencode.json"; \
		cp -a "$(HOME)/.config/opencode/oh-my-opencode.json" "$(BACKUP_DIR)/.config/opencode/oh-my-opencode.json"; \
	fi
	@"$(INSTALL)" "$(HOME)/.config/opencode/opencode.json" "$(ROOT_DIR)opencode/opencode.json" "$(HOME)/.config/opencode" "1"
	@"$(INSTALL)" "$(HOME)/.config/opencode/oh-my-opencode.json" "$(ROOT_DIR)opencode/oh-my-opencode.json" "$(HOME)/.config/opencode" "1"

install-tmux:
	@if { [ -e "$(HOME)/.tmux.conf" ] || [ -L "$(HOME)/.tmux.conf" ]; } && [ ! -e "$(BACKUP_DIR)/.tmux.conf" ] && [ ! -L "$(BACKUP_DIR)/.tmux.conf" ]; then \
		mkdir -p "$(BACKUP_DIR)"; \
		echo "Creating backup: $(BACKUP_DIR)/.tmux.conf"; \
		cp -a "$(HOME)/.tmux.conf" "$(BACKUP_DIR)/.tmux.conf"; \
	fi
	@"$(INSTALL)" "$(HOME)/.tmux.conf" "$(ROOT_DIR)tmux/.tmux.conf" "" "1"
