#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ITERATION_NAME="${1:?iteration name required}"
ITERATION_DIR="$ROOT_DIR/iterations/$ITERATION_NAME"
CURRENT_LINK="$ROOT_DIR/iterations/CURRENT"
PROMPT_FILE="$ROOT_DIR/prompts/update-supervision-skill.txt"

if [[ ! -f "$ITERATION_DIR/report.json" ]]; then
  printf 'missing report for %s\n' "$ITERATION_NAME" >&2
  exit 1
fi

rm -f "$CURRENT_LINK"
ln -s "$ITERATION_DIR" "$CURRENT_LINK"

cp /home/chanyoungs/custom-configs/.codex/skills/supervision/SKILL.md "$ITERATION_DIR/skill.before.update.md"

codex exec \
  --cd /home/chanyoungs/custom-configs \
  --sandbox workspace-write \
  --skip-git-repo-check \
  -o "$ITERATION_DIR/skill-update.agent.txt" \
  - < "$PROMPT_FILE"

cp /home/chanyoungs/custom-configs/.codex/skills/supervision/SKILL.md "$ITERATION_DIR/skill.after.md"
git -C /home/chanyoungs/custom-configs diff -- /home/chanyoungs/custom-configs/.codex/skills/supervision/SKILL.md > "$ITERATION_DIR/skill.diff.patch" || true

cat > "$ITERATION_DIR/skill-update.log.md" <<EOF
# Skill Update ${ITERATION_NAME}

## Inputs

- [report.json](./report.json)
- [required-updates.md](./required-updates.md)
- [skill.before.update.md](./skill.before.update.md)

## Agent Output

- [skill-update.agent.txt](./skill-update.agent.txt)

## Result

- [skill.after.md](./skill.after.md)
- [skill.diff.patch](./skill.diff.patch)
EOF
