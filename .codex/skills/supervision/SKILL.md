---
name: supervision
description: Set up recurring Codex-based supervision for a user-defined task list by creating a canonical instructions markdown file, installing a cron-driven `codex exec` wrapper, aggregating supervising CLI output into one live log, skipping overlapping runs, and removing the cron job when all tasks are complete.
---

# Supervision

Use this skill when the user wants Codex to keep supervising a task list after the current session ends, for example:

- "Use supervision skill to hourly supervise"
- "Create a checklist and keep checking progress every hour"
- "Monitor this work, fix issues when possible, and stop when everything is done"

This skill is for persistent Codex re-entry through cron, not for one-off status checks.

## Outcome

Create a small supervision workspace that includes:

- one canonical markdown state file
- one recurring wrapper script runnable from cron
- one recurring prompt file for `codex exec`
- one aggregate log file for all supervisor runs
- one lock file or equivalent overlap guard
- one tagged cron entry that can remove itself on completion

Suggested paths:

- `supervision/instructions.md`
- `supervision/prompt.txt`
- `supervision/run-supervisor.sh`
- `supervision/logs/supervisor.log`
- `supervision/supervisor.lock`

Use different paths only if the repo or user already has a stronger convention.

## Required Inputs

Before installing automation, extract or normalize:

- the user's task list
- the requested cadence such as hourly, daily, every 30 minutes, or an explicit cron expression
- the project working directory
- completion criteria for the full batch

If the user provided loose bullets, normalize them into stable task entries. Do not invent substantial new scope. If important details are ambiguous, record that ambiguity in the markdown file instead of silently assuming too much.

## Canonical Markdown File

Create the markdown file first. It is the source of truth for later supervising runs.

The file should include:

- `Overview`
- `Cadence`
- `Tasks`
- `Open Issues`
- `Completion Criteria`
- `Run History`

Each task should have:

- a stable identifier
- a short description
- a status such as `pending`, `in_progress`, `blocked`, or `done`
- notes or evidence
- next action if still incomplete

Each recurring supervision run must:

1. read this markdown file first
2. inspect local state relevant to the tasks
3. verify progress using real evidence
4. fix issues that are clearly in scope and safe
5. update task statuses, notes, blockers, and run history

Never mark work complete without evidence.

## Codex CLI

Use `codex exec` for the recurring non-interactive runs.

Prefer a concrete invocation pattern like:

```bash
codex exec --cd "$WORKDIR" --skip-git-repo-check - < "$PROMPT_FILE" >> "$AGGREGATE_LOG" 2>&1
```

Use `-` so `codex exec` reads the prompt from stdin. Add extra Codex flags only when the environment or task requires them. Keep `codex exec` as the core mechanism.

## Wrapper Script Requirements

Create a wrapper script that cron can execute.

The wrapper must:

- set explicit `HOME`, `PATH`, and working directory
- ensure the log directory exists
- acquire a non-blocking lock before starting Codex
- append stdout and stderr from Codex to one aggregate log file
- log a skip message if the previous run is still active
- pass a deterministic prompt telling Codex to read the markdown, inspect progress, fix issues if possible, and update the markdown
- check completion after Codex exits
- remove only its own tagged cron entry when all completion criteria are met

Recommended overlap guard:

```bash
exec 9>"$LOCK_FILE"
if ! flock -n 9; then
  printf '%s skipped: previous supervisor run still active\n' "$(date -Is)" >> "$AGGREGATE_LOG"
  exit 0
fi
```

Use a PID-file fallback only if `flock` is unavailable.

## Aggregate Logging

Use one aggregate live log file for all recurring supervising runs.

Minimum requirements:

- wrapper lifecycle lines include timestamps
- Codex stdout appends to the same file
- Codex stderr appends to the same file
- skipped overlapping runs append to the same file

Additional logs are optional, but not a replacement for the aggregate supervisor log.

## Prompt File

Create a deterministic prompt file for the recurring `codex exec` runs. Keep it stable across runs.

The prompt should instruct Codex to:

1. open and read the canonical supervision markdown
2. inspect local files, logs, repo state, or outputs relevant to the listed tasks
3. verify whether tasks progressed or completed
4. fix issues that are safe and within the user's scope
5. update the markdown with evidence, blockers, and a short timestamped run note
6. stop once the full completion criteria are satisfied

Do not let the recurring prompt drift into a different workflow over time.

## Cadence

Support at least:

- hourly
- daily
- every 30 minutes
- explicit cron expressions

If the user gives natural language such as "hourly", convert it to cron syntax and record both the human phrase and cron schedule in the markdown file.

## Cron Installation

Install cron with a stable unique tag so only this automation is later removed.

Example hourly schedule:

```cron
0 * * * * /path/to/supervision/run-supervisor.sh # SUPERVISION_TAG
```

Remove only tagged entries:

```bash
tmp="$(mktemp)"
crontab -l 2>/dev/null | grep -v "$CRON_TAG" > "$tmp" || true
crontab "$tmp"
rm -f "$tmp"
```

## Completion Rules

Define explicit batch completion criteria in the markdown file. Examples:

- every task entry is marked `done`
- required outputs exist
- no unresolved blockers remain

When completion is detected:

- append a completion line to the aggregate log
- remove the tagged cron entry or entries
- leave the markdown file as the final audit trail

## Safety Rules

- Do not start a new supervising run if the previous one is still active.
- Do not remove unrelated cron entries.
- Do not claim success without evidence.
- Do not expand the task list beyond the user's intent.
- Do not apply destructive fixes unless they are clearly authorized.
- If the task list is too ambiguous, create the supervision workspace and record the ambiguity instead of faking precision.
