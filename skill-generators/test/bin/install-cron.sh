#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CRON_TAG="SUPERVISION_STRESS_TEST"
TMP_FILE="$(mktemp)"
{
  crontab -l 2>/dev/null | grep -v "$CRON_TAG" || true
  printf '* * * * * %s/supervision/run-supervisor.sh # %s\n' "$ROOT_DIR" "$CRON_TAG"
} > "$TMP_FILE"
crontab "$TMP_FILE"
rm -f "$TMP_FILE"
printf 'Installed cron entry tagged %s\n' "$CRON_TAG"
