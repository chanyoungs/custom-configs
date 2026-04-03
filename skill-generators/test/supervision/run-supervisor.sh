#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROMPT_FILE="$ROOT_DIR/supervision/prompt.txt"
LOG_FILE="$ROOT_DIR/logs/supervisor.log"
LOCK_FILE="$ROOT_DIR/supervision/supervisor.lock"
CRON_TAG="SUPERVISION_STRESS_TEST"

export HOME="${HOME:-/home/chanyoungs}"
export PATH="/usr/local/bin:/usr/bin:/bin:$PATH"
export TZ="UTC"

mkdir -p "$ROOT_DIR/logs"
exec 9>"$LOCK_FILE"
if ! flock -n 9; then
  printf '%s skipped: previous supervisor run still active\n' "$(date -Is)" >> "$LOG_FILE"
  exit 0
fi

printf '%s supervisor-start trigger=%s failed_task=%s\n' \
  "$(date -Is)" "${SUPERVISION_TRIGGER:-schedule}" "${FAILED_TASK_ID:-none}" >> "$LOG_FILE"

if command -v codex >/dev/null 2>&1; then
  codex exec \
    --cd "$ROOT_DIR" \
    --sandbox workspace-write \
    --skip-git-repo-check \
    - < "$PROMPT_FILE" >> "$LOG_FILE" 2>&1 || true
else
  printf '%s codex-not-found; supervisor prompt not executed\n' "$(date -Is)" >> "$LOG_FILE"
fi

complete=1
for task_id in bootstrap_catalog_sync build_daily_summary ingest_vendor_feed publish_partner_extract refresh_reporting_cache wait_for_upstream_ready; do
  status_file="$ROOT_DIR/state/jobs/$task_id/status.env"
  if [[ ! -f "$status_file" ]]; then
    complete=0
    break
  fi
  # shellcheck disable=SC1090
  source "$status_file"
  if [[ "${CLASSIFICATION:-pending}" != "done" ]]; then
    complete=0
    break
  fi
done

status_file="$ROOT_DIR/state/jobs/import_customer_dataset/status.env"
if [[ -f "$status_file" ]]; then
  # shellcheck disable=SC1090
  source "$status_file"
  if [[ "${CLASSIFICATION:-pending}" != "done" && "${CLASSIFICATION:-pending}" != "blocked_waiting_for_user" ]]; then
    complete=0
  fi
else
  complete=0
fi

if [[ "$complete" -eq 1 ]]; then
  tmp_file="$(mktemp)"
  crontab -l 2>/dev/null | grep -v "$CRON_TAG" > "$tmp_file" || true
  crontab "$tmp_file" || true
  rm -f "$tmp_file"
  printf '%s harness-complete cron-removed\n' "$(date -Is)" >> "$LOG_FILE"
fi

printf '%s supervisor-end trigger=%s\n' "$(date -Is)" "${SUPERVISION_TRIGGER:-schedule}" >> "$LOG_FILE"
