# Codex Supervision Skill Generator

Use this file as a generator spec for creating a reusable `supervision` skill specifically for Codex CLI.

The generated skill should let a user write prompts like:

```text
Task
- do ...
- do ...
- do ...

Use supervision skill to hourly supervise
```

The consuming agent should read this document and create the skill in Codex's native skill format.

## Goal

Generate a Codex skill that sets up unattended recurring supervision for a concrete task list. The skill should:

- create a persistent markdown file that contains the normalized instructions and task checklist
- keep that markdown file updated over time through Codex runs
- install a recurring cron job at the requested cadence, such as hourly
- invoke `codex exec` non-interactively from cron so Codex reads the markdown, inspects progress, fixes issues when possible, and writes updates back
- append all Codex terminal output into one aggregate live log file
- skip the current schedule slot if the previous Codex supervision run is still active
- support immediate supervisor re-entry on job failure or completion when the workflow needs tighter control than cron alone
- remove its own cron entry when all declared tasks are complete

## Trigger Intent

The generated skill should trigger when the user wants recurring supervision, monitoring, or autonomous follow-up on a task list, especially when the user says things like:

- "Use supervision skill to hourly supervise"
- "Set this up and keep checking every hour"
- "Monitor progress and fix issues until all tasks are complete"
- "Create a checklist and keep it updated automatically"

## Required Outputs

When the skill is used, the generated skill should instruct Codex to create at minimum:

- one markdown file for normalized instructions, task state, run history, and next actions
- one wrapper script that cron can execute repeatedly
- one prompt template file for recurring Codex invocations
- one aggregate log file that receives stdout and stderr from every supervising Codex invocation
- one lock file or equivalent overlap-prevention mechanism
- one stable cron tag so the installed job can later be removed safely
- optional helper scripts for supervised job launch and immediate supervisor triggering when the workflow includes long-running jobs

Suggested names:

- `supervision/instructions.md`
- `supervision/run-supervisor.sh`
- `supervision/prompt.txt`
- `supervision/logs/supervisor.log`
- `supervision/supervisor.lock`

## Task Contract

The generated skill should require the supervision markdown file to contain:

- the original user goal
- the supervision cadence
- a normalized task list with stable identifiers
- status per task such as `pending`, `in_progress`, `blocked`, or `done`
- evidence or notes for the current status
- known blockers
- the last supervision timestamp
- the next recommended action
- explicit completion criteria for the whole batch
- the intended human-readable log timezone when local operational time matters

The skill should instruct Codex to normalize loose bullets from the user into a clearer checklist if needed, but not invent major task scope that the user did not ask for.

## Supervision Markdown Behavior

The generated skill should require the supervision markdown file to act as the canonical source of truth for the automation loop.

Each supervising run should:

- read the markdown file first
- inspect the current task statuses
- inspect local files, logs, or repository state needed to verify progress
- update the markdown with fresh findings
- mark completed tasks as done only when there is concrete evidence
- record blockers and failed attempts clearly
- append a short run note with timestamp

Preferred markdown sections:

- `Overview`
- `Cadence`
- `Tasks`
- `Progress Notes`
- `Open Issues`
- `Completion Criteria`
- `Run History`
- `Next Agent Notes`

The generated skill should prefer one canonical markdown file and explicitly direct recurring Codex runs to update that file rather than drifting to ad hoc notes.

## Codex CLI Requirements

The generated skill must be explicit that it is designed for Codex CLI, not a generic agent wrapper.

It should reference concrete Codex behavior:

- use `codex exec` for non-interactive recurring runs
- pass the prompt through stdin by using `-` when a prompt file is used
- use `--cd` to set the working directory
- use `--skip-git-repo-check` when the supervised directory may not be a Git repository
- optionally use `-o` to persist the final agent message separately if useful, but keep the aggregate log as the primary audit trail

Representative invocation pattern:

```bash
codex exec --cd "$WORKDIR" --skip-git-repo-check - < "$PROMPT_FILE" >> "$AGGREGATE_LOG" 2>&1
```

If the local environment needs additional Codex flags, the generated skill may add them, but `codex exec` should remain the core mechanism.

## Cron Wrapper Requirements

The cron-executed wrapper script should:

- set explicit `HOME`, `PATH`, and working directory
- set an explicit `TZ` when the user wants logs in a specific timezone
- acquire a non-blocking lock before starting Codex
- exit successfully and log a skip message if the lock is already held
- refresh or render a deterministic prompt for Codex
- tell Codex to read the supervision markdown, verify progress, fix issues if possible, and update the markdown
- append all stdout and stderr to the aggregate log
- write wrapper start and end markers with timestamps
- optionally enforce an early bootstrap acknowledgment in the markdown or log so hung Codex starts are detected quickly
- check completion conditions after Codex exits
- remove the cron job if all tasks are complete

Recommended overlap guard:

```bash
exec 9>"$LOCK_FILE"
if ! flock -n 9; then
  printf '%s skipped: previous supervisor run still active\n' "$(date -Is)" >> "$AGGREGATE_LOG"
  exit 0
fi
```

The skill may use a PID file fallback only if `flock` is unavailable.

## Aggregate Logging

The generated skill should require a single aggregate log file for all supervising runs.

Requirements:

- all Codex stdout goes to that file
- all Codex stderr goes to that file
- skip events are appended to that file
- wrapper lifecycle messages are appended to that file
- timestamps are included for every wrapper-generated line
- wrapper timestamps should honor the configured `TZ`

If the supervised workflow dispatches long-running train, eval, import, or tmux jobs, the generated skill should prefer status files and tmux-dispatch logs so later runs can distinguish running, success, failure, and interruption.

## Prompt Template Requirements

The wrapper should generate or maintain a deterministic prompt for `codex exec`.

The prompt should instruct Codex to:

1. open and read the supervision markdown
2. inspect local state relevant to the listed tasks
3. verify whether tasks have progressed or completed
4. fix issues that are safe and clearly within scope
5. update the markdown with status changes, evidence, blockers, and a brief run note
6. stop creating new work once all tasks are complete

For long-running jobs, the prompt should also instruct Codex to:

7. avoid dispatching overlapping jobs
8. treat status files, tmux panes, and result artifacts as first-class evidence
9. decide explicitly whether a failed job should resume or restart from clean artifacts, and record that decision
10. update `Next Agent Notes` with the concrete next step for the following supervising run

The generated skill should explicitly tell Codex not to let the recurring prompt drift over time. It should be rendered from a stable template with only the minimum runtime substitutions such as file paths, cadence, or working directory.

## Completion Detection

The generated skill should require explicit batch completion criteria. Examples:

- every task row is marked `done`
- required output files exist
- no open blockers remain

Once the completion condition is met, the wrapper must remove only its own cron entry or entries, using a stable unique tag.

Recommended pattern:

```bash
tmp="$(mktemp)"
crontab -l 2>/dev/null | grep -v "$CRON_TAG" > "$tmp" || true
crontab "$tmp"
rm -f "$tmp"
```

It should also append a completion message to the aggregate log.

## Cadence Handling

The generated skill should support at least:

- hourly
- daily
- every 30 minutes
- custom cron expressions when the user provides one

For the prompt example "hourly supervise", the generated skill should install an hourly cron job.

If the user gives only a natural-language cadence, the skill should normalize it to a cron schedule and record both the human phrase and the cron form in the supervision markdown.

Cron cadence should be treated as the baseline safety net, not necessarily the only re-entry path. If job launchers can detect completion or failure immediately, the generated skill should allow helper scripts to trigger `run-supervisor.sh` right away instead of waiting for the next cron slot.

## Safety Rules

The generated skill should instruct Codex to:

- avoid overlapping supervision runs
- avoid removing unrelated cron entries
- avoid claiming completion without evidence
- avoid expanding the task list beyond the user's intent
- avoid destructive fixes unless the user or existing instructions clearly permit them
- record unresolved blockers instead of looping blindly
- avoid silently converting an interrupted run into a clean restart without recording whether checkpoints were preserved, resumed, or discarded
- avoid writing timestamps in an implicit timezone when the user expects a specific local timezone

If the requested task list is too ambiguous to supervise safely, the skill should still create the markdown skeleton and record the ambiguity rather than inventing hidden assumptions.

## Minimal Workflow

The generated skill should teach Codex to follow this workflow:

1. Parse the user's task bullets and requested cadence.
2. Create the supervision markdown as the canonical state file.
3. Create the recurring prompt template and wrapper script.
4. Install a tagged cron entry for the cadence.
5. On each run, execute `codex exec`, read the markdown, inspect progress, attempt in-scope fixes, and update the markdown.
6. Skip the run if the previous Codex process is still active.
7. If job launchers can detect completion or failure immediately, optionally trigger supervisor re-entry right away.
8. Remove the tagged cron entry when all completion criteria are satisfied.

## Instruction To The Consuming Agent

If you are the agent reading this file, generate a Codex-native local skill that implements the behavior above. Keep the skill concise and operational. Prefer small scripts, explicit file paths, deterministic prompts, one canonical markdown state file, one aggregate supervising log, one lock-protected cron wrapper, and a concrete `codex exec` invocation instead of vendor-neutral abstractions.
