#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET_WINDOW="${SUPERVISOR_TMUX_WINDOW:-}"
TARGET_PANE_FILE="$ROOT_DIR/state/supervisor-pane-id"
TRIGGER="${SUPERVISION_TRIGGER:-schedule}"
FAILED_TASK="${FAILED_TASK_ID:-none}"

if [[ -z "$TARGET_WINDOW" ]] || ! command -v tmux >/dev/null 2>&1; then
  "$ROOT_DIR/supervision/run-supervisor.sh"
  exit 0
fi

mkdir -p "$ROOT_DIR/state"

command_string=$(cat <<EOF
cd "$ROOT_DIR" && SUPERVISION_RUN_IN_TMUX_PANE=1 SUPERVISION_TRIGGER="$TRIGGER" FAILED_TASK_ID="$FAILED_TASK" FAILED_ATTEMPT="${FAILED_ATTEMPT:-}" "$ROOT_DIR/supervision/run-supervisor.sh"; printf '\n[supervisor complete] press Enter to keep pane reusable...\n'; read -r
EOF
)

if [[ -f "$TARGET_PANE_FILE" ]]; then
  pane_id="$(cat "$TARGET_PANE_FILE")"
  if tmux list-panes -a -F '#{pane_id}' | grep -Fx "$pane_id" >/dev/null 2>&1; then
    tmux respawn-pane -k -t "$pane_id" "$command_string"
    exit 0
  fi
fi

pane_id="$(tmux split-window -v -t "$TARGET_WINDOW" -P -F '#{pane_id}' "$command_string")"
printf '%s\n' "$pane_id" > "$TARGET_PANE_FILE"
