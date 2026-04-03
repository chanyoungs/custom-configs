#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export SUPERVISION_TRIGGER="error_exit"
export FAILED_TASK_ID="${1:?task id required}"
export FAILED_ATTEMPT="${2:?attempt required}"
"$ROOT_DIR/supervision/run-supervisor.sh" >/dev/null 2>&1 &
