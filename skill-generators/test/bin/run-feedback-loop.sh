#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ITERATIONS_DIR="$ROOT_DIR/iterations"
MAX_ITERATIONS="${MAX_ITERATIONS:-5}"

mkdir -p "$ITERATIONS_DIR"
LOOP_LOG="$ITERATIONS_DIR/feedback-loop.log.md"
: > "$LOOP_LOG"

cat >> "$LOOP_LOG" <<EOF
# Feedback Loop

EOF

for i in $(seq 1 "$MAX_ITERATIONS"); do
  iteration_name="$(printf 'iter-%03d' "$i")"
  "$ROOT_DIR/bin/run-iteration.sh" "$iteration_name"
  cat >> "$LOOP_LOG" <<EOF
## ${iteration_name}

- Iteration artifacts: [${iteration_name}](./${iteration_name})
- Evaluation: [${iteration_name}/evaluation.md](./${iteration_name}/evaluation.md)
- Required updates: [${iteration_name}/required-updates.md](./${iteration_name}/required-updates.md)
EOF

  if python3 - <<'PY' "$ROOT_DIR/iterations/$iteration_name/report.json"
import json, sys
report = json.load(open(sys.argv[1], encoding="utf-8"))
raise SystemExit(0 if report["passed"] else 1)
PY
  then
    cat >> "$LOOP_LOG" <<EOF
- Result: passed

EOF
    printf 'Feedback loop passed at %s\n' "$iteration_name"
    exit 0
  fi

  if [[ "$i" -eq "$MAX_ITERATIONS" ]]; then
    cat >> "$LOOP_LOG" <<EOF
- Result: failed after max iterations

EOF
    printf 'Feedback loop reached max iterations without passing\n' >&2
    exit 1
  fi

  "$ROOT_DIR/bin/update-skill-from-iteration.sh" "$iteration_name"
  cat >> "$LOOP_LOG" <<EOF
- Result: skill updated
- Skill update log: [${iteration_name}/skill-update.log.md](./${iteration_name}/skill-update.log.md)

EOF
done
