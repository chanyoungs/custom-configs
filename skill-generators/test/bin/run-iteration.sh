#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ITERATIONS_DIR="$ROOT_DIR/iterations"
ITERATION_NAME="${1:?iteration name required}"
ITERATION_DIR="$ITERATIONS_DIR/$ITERATION_NAME"
WORKSPACE_TIMEOUT_SECONDS="${WORKSPACE_TIMEOUT_SECONDS:-420}"
SCHEDULE_DELAY_SECONDS="${SCHEDULE_DELAY_SECONDS:-65}"

mkdir -p "$ITERATION_DIR"

"$ROOT_DIR/bin/init-harness.sh"
cp /home/chanyoungs/custom-configs/.codex/skills/supervision/SKILL.md "$ITERATION_DIR/skill.before.md"
git -C /home/chanyoungs/custom-configs diff -- /home/chanyoungs/custom-configs/.codex/skills/supervision/SKILL.md > "$ITERATION_DIR/skill.before.diff.patch" || true

if command -v crontab >/dev/null 2>&1; then
  "$ROOT_DIR/bin/install-cron.sh"
fi

set +e
"$ROOT_DIR/bin/run-all-tasks.sh"
jobs_exit=$?
set -e
printf '%s\n' "$jobs_exit" > "$ITERATION_DIR/jobs.exit_code"

sleep "$SCHEDULE_DELAY_SECONDS"

SUPERVISION_TRIGGER="schedule" "$ROOT_DIR/supervision/run-supervisor.sh" || true

if pgrep -f "codex exec --cd $ROOT_DIR" >/dev/null 2>&1; then
  timeout "$WORKSPACE_TIMEOUT_SECONDS" bash -lc 'while pgrep -f "codex exec --cd '"$ROOT_DIR"'" >/dev/null 2>&1; do sleep 5; done' || true
fi

"$ROOT_DIR/evaluator/evaluate_run.py" \
  --report-out "$ITERATION_DIR/report.json" \
  --markdown-out "$ITERATION_DIR/evaluation.md" \
  --updates-out "$ITERATION_DIR/required-updates.md" || true

cp "$ROOT_DIR/supervision/instructions.md" "$ITERATION_DIR/instructions.final.md"
cp "$ROOT_DIR/supervision/prompt.txt" "$ITERATION_DIR/prompt.used.txt"
cp "$ROOT_DIR/supervision/run-supervisor.sh" "$ITERATION_DIR/run-supervisor.used.sh"
cp "$ROOT_DIR/logs/supervisor.log" "$ITERATION_DIR/supervisor.log" 2>/dev/null || true

mkdir -p "$ITERATION_DIR/state.jobs" "$ITERATION_DIR/logs.jobs"
cp -R "$ROOT_DIR/state/jobs"/. "$ITERATION_DIR/state.jobs/" 2>/dev/null || true
cp -R "$ROOT_DIR/logs/jobs"/. "$ITERATION_DIR/logs.jobs/" 2>/dev/null || true

python3 - <<'PY' "$ROOT_DIR" "$ITERATION_DIR"
import json
import sys
from pathlib import Path

root = Path(sys.argv[1])
iteration_dir = Path(sys.argv[2])
report = json.loads((iteration_dir / "report.json").read_text(encoding="utf-8"))
summary = {
    "iteration": iteration_dir.name,
    "passed": report["passed"],
    "finding_count": len(report["findings"]),
}
(iteration_dir / "summary.json").write_text(json.dumps(summary, indent=2) + "\n", encoding="utf-8")
PY

cat > "$ITERATION_DIR/iteration.log.md" <<EOF
# ${ITERATION_NAME}

## What Ran

- Runtime jobs launched with \`bin/run-all-tasks.sh\`
- Scheduled supervisor forced once after ${SCHEDULE_DELAY_SECONDS}s
- Immediate supervisor triggers were available for non-zero exits

## What the Supervisor Did

See [evaluation.md](./evaluation.md) and [supervisor.log](./supervisor.log).

## What Needs Updating

See [required-updates.md](./required-updates.md).

## How It Was Updated

- Not updated during \`${ITERATION_NAME}\`.
- If a follow-up skill update runs, it should write \`skill.after.md\`, \`skill.diff.patch\`, and \`skill-update.agent.txt\` in this iteration directory.
EOF

printf 'Iteration %s complete\n' "$ITERATION_NAME"
