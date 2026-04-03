#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
task_id="${1:?task id required}"
task_output_dir="$ROOT_DIR/state/jobs/$task_id/output"

case "$task_id" in
  bootstrap_catalog_sync|build_daily_summary|ingest_vendor_feed|refresh_reporting_cache|wait_for_upstream_ready|import_customer_dataset)
    if [[ -f "$task_output_dir/output.ok" ]]; then
      printf 'HEALTH_RESULT=pass\n'
      printf 'HEALTH_REASON=expected_output_present\n'
    else
      printf 'HEALTH_RESULT=fail\n'
      printf 'HEALTH_REASON=missing_output_ok\n'
    fi
    ;;
  publish_partner_extract)
    if [[ -f "$task_output_dir/partner_extract.txt" ]] && grep -q '^STATUS=ready$' "$task_output_dir/partner_extract.txt"; then
      printf 'HEALTH_RESULT=pass\n'
      printf 'HEALTH_REASON=expected_result_present\n'
    else
      printf 'HEALTH_RESULT=fail\n'
      printf 'HEALTH_REASON=missing_expected_partner_extract\n'
    fi
    ;;
  *)
    printf 'HEALTH_RESULT=fail\n'
    printf 'HEALTH_REASON=unknown_task\n'
    exit 1
    ;;
esac
