#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TASK_ID="${1:?task id required}"
TASK_SCRIPT="${2:?task script required}"

STATE_DIR="$ROOT_DIR/state/jobs/$TASK_ID"
OUTPUT_DIR="$STATE_DIR/output"
LOG_DIR="$ROOT_DIR/logs/jobs"
mkdir -p "$STATE_DIR" "$OUTPUT_DIR" "$LOG_DIR"

ATTEMPT_FILE="$STATE_DIR/attempt-count"
if [[ -f "$ATTEMPT_FILE" ]]; then
  ATTEMPT=$(( $(cat "$ATTEMPT_FILE") + 1 ))
else
  ATTEMPT=1
fi
printf '%s\n' "$ATTEMPT" > "$ATTEMPT_FILE"

STARTED_AT="$(date -Is)"
LOG_FILE="$LOG_DIR/$TASK_ID.attempt-$ATTEMPT.log"
write_status_kv() {
  printf '%s=%q\n' "$1" "$2" >> "$STATE_DIR/status.env"
}

: > "$STATE_DIR/status.env"
write_status_kv STARTED_AT "$STARTED_AT"
write_status_kv JOB_ID "$TASK_ID"
write_status_kv ATTEMPT "$ATTEMPT"
write_status_kv SCRIPT_PATH "$TASK_SCRIPT"

export ROOT_DIR
export FIXTURES_DIR="$ROOT_DIR/fixtures"
export CONFIGS_DIR="$ROOT_DIR/configs-runtime"
export EXTERNAL_DEPS_DIR="/home/chanyoungs/custom-configs/skill-generators/test-external-deps"
export TASK_STATE_DIR="$STATE_DIR"
export TASK_OUTPUT_DIR="$OUTPUT_DIR"
export TASK_ID

set +e
"$TASK_SCRIPT" >"$LOG_FILE" 2>&1
EXIT_CODE=$?
set -e

ENDED_AT="$(date -Is)"
RUNTIME_SECONDS=$(( $(date -d "$ENDED_AT" +%s) - $(date -d "$STARTED_AT" +%s) ))
HEALTH_OUTPUT="$("$ROOT_DIR/bin/check-task-health.sh" "$TASK_ID" || true)"
eval "$HEALTH_OUTPUT"

STARTED_MARKER="no"
if grep -q 'JOB_BEGIN' "$LOG_FILE" 2>/dev/null; then
  STARTED_MARKER="yes"
fi

CLASSIFICATION="running"
NEXT_ACTION="inspect"
case "$TASK_ID" in
  bootstrap_catalog_sync)
    if [[ "$EXIT_CODE" -ne 0 && "$STARTED_MARKER" = "no" ]]; then
      CLASSIFICATION="launch_failed_fixable"
      NEXT_ACTION="fix runtime worker path and rerun"
    elif [[ "$EXIT_CODE" -eq 0 && "${HEALTH_RESULT:-fail}" = "pass" ]]; then
      CLASSIFICATION="done"
      NEXT_ACTION="none"
    fi
    ;;
  publish_partner_extract)
    if [[ "$EXIT_CODE" -eq 0 && "${HEALTH_RESULT:-fail}" != "pass" ]]; then
      CLASSIFICATION="failed_silent_fixable"
      NEXT_ACTION="fix wrapper output filename and rerun"
    elif [[ "$EXIT_CODE" -eq 0 && "${HEALTH_RESULT:-fail}" = "pass" ]]; then
      CLASSIFICATION="done"
      NEXT_ACTION="none"
    fi
    ;;
  wait_for_upstream_ready)
    if [[ "$EXIT_CODE" -ne 0 ]]; then
      CLASSIFICATION="stalled_fixable"
      NEXT_ACTION="fix wrapper readiness probe and rerun"
    elif [[ "$EXIT_CODE" -eq 0 && "${HEALTH_RESULT:-fail}" = "pass" ]]; then
      CLASSIFICATION="done"
      NEXT_ACTION="none"
    fi
    ;;
  import_customer_dataset)
    if [[ "$EXIT_CODE" -ne 0 ]]; then
      CLASSIFICATION="blocked_waiting_for_user"
      NEXT_ACTION="wait for user to provide missing dataset"
    elif [[ "$EXIT_CODE" -eq 0 && "${HEALTH_RESULT:-fail}" = "pass" ]]; then
      CLASSIFICATION="done"
      NEXT_ACTION="none"
    fi
    ;;
  *)
    if [[ "$EXIT_CODE" -ne 0 ]]; then
      CLASSIFICATION="failed_explicit_fixable"
      NEXT_ACTION="diagnose and repair"
    elif [[ "$EXIT_CODE" -eq 0 && "${HEALTH_RESULT:-fail}" = "pass" ]]; then
      CLASSIFICATION="done"
      NEXT_ACTION="none"
    elif [[ "$EXIT_CODE" -eq 0 && "${HEALTH_RESULT:-fail}" != "pass" ]]; then
      CLASSIFICATION="failed_silent_fixable"
      NEXT_ACTION="repair output expectations and rerun"
    fi
    ;;
esac

{
  write_status_kv ENDED_AT "$ENDED_AT"
  write_status_kv EXIT_CODE "$EXIT_CODE"
  write_status_kv RUNTIME_SECONDS "$RUNTIME_SECONDS"
  write_status_kv HEALTH_RESULT "${HEALTH_RESULT:-fail}"
  write_status_kv HEALTH_REASON "${HEALTH_REASON:-unknown}"
  write_status_kv STARTED_MARKER "$STARTED_MARKER"
  write_status_kv CLASSIFICATION "$CLASSIFICATION"
  write_status_kv NEXT_ACTION "$NEXT_ACTION"
}

printf '%s attempt=%s exit=%s classification=%s health=%s/%s\n' \
  "$(date -Is)" "$ATTEMPT" "$EXIT_CODE" "$CLASSIFICATION" "${HEALTH_RESULT:-fail}" "${HEALTH_REASON:-unknown}" >> "$STATE_DIR/attempts.log"

if [[ "$EXIT_CODE" -ne 0 ]]; then
  "$ROOT_DIR/bin/trigger-supervisor-on-error.sh" "$TASK_ID" "$ATTEMPT"
fi

exit "$EXIT_CODE"
