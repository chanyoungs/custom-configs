#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

declare -a TASKS=(
  "bootstrap_catalog_sync:$ROOT_DIR/tasks-runtime/bootstrap_catalog_sync.py"
  "build_daily_summary:$ROOT_DIR/tasks-runtime/build_daily_summary.py"
  "ingest_vendor_feed:$ROOT_DIR/tasks-runtime/ingest_vendor_feed.py"
  "publish_partner_extract:$ROOT_DIR/tasks-runtime/publish_partner_extract.py"
  "refresh_reporting_cache:$ROOT_DIR/tasks-runtime/refresh_reporting_cache.py"
  "wait_for_upstream_ready:$ROOT_DIR/tasks-runtime/wait_for_upstream_ready.py"
  "import_customer_dataset:$ROOT_DIR/tasks-runtime/import_customer_dataset.py"
)

if [[ ! -d "$ROOT_DIR/tasks-runtime" ]] || [[ ! -f "$ROOT_DIR/tasks-runtime/build_daily_summary.py" ]]; then
  printf 'tasks-runtime is missing; run ./bin/init-harness.sh first\n' >&2
  exit 1
fi

pids=()
for entry in "${TASKS[@]}"; do
  task_id="${entry%%:*}"
  task_script="${entry#*:}"
  "$ROOT_DIR/bin/run-task.sh" "$task_id" "$task_script" &
  pids+=("$!")
  sleep 2
done

status=0
for pid in "${pids[@]}"; do
  if ! wait "$pid"; then
    status=1
  fi
done

exit "$status"
