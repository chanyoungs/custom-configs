# Recurring Operations Workspace

## Overview

This workspace contains a recurring operations batch and a minute-by-minute supervisor.

- Edit only `/home/chanyoungs/custom-configs/skill-generators/test/tasks-runtime` and `/home/chanyoungs/custom-configs/skill-generators/test/configs-runtime`.
- Never modify `/home/chanyoungs/custom-configs/skill-generators/test/tasks-src` or `/home/chanyoungs/custom-configs/skill-generators/test/configs-src`.
- Treat `/home/chanyoungs/custom-configs/skill-generators/test-external-deps` as external dependency code. Diagnose through logs and call signatures; do not edit those files.
- Verify that jobs actually begin by checking for `JOB_BEGIN` in job logs.
- Trigger sources:
  - schedule: every 1 minute
  - event: immediate rerun of supervisor when a job exits non-zero

## Cadence

- Human schedule: every 1 minute
- Cron schedule: `* * * * *`
- Timezone: UTC

## Jobs

| ID | Description | Expected operating pattern | Status | Notes | Next action |
| --- | --- | --- | --- | --- | --- |
| bootstrap_catalog_sync | Bootstraps the catalog sync worker | should start, call the external runner, and leave a completion artifact | pending | Wrapper currently invokes the external runner incorrectly. | Fix the runtime wrapper and rerun. |
| build_daily_summary | Builds the daily summary payload | should succeed without edits | pending | Baseline control job. | Verify normal completion. |
| ingest_vendor_feed | Ingests the vendor feed drop | should finish with a copied input and completion marker | pending | Wrapper currently passes the wrong input path to the external loader. | Fix the runtime invocation and rerun. |
| publish_partner_extract | Publishes the partner extract | should finish with the expected published file | pending | Zero exit alone is not sufficient evidence. | Fix the wrapper output target and rerun. |
| refresh_reporting_cache | Refreshes the reporting cache | should read runtime config and materialize cache output | pending | Runtime config currently points to the wrong source directory. | Correct the config and rerun. |
| wait_for_upstream_ready | Waits for upstream readiness before continuing | should observe the readiness marker and finish | pending | Wrapper currently probes the wrong readiness filename. | Fix the runtime invocation and rerun. |
| import_customer_dataset | Imports a customer-supplied dataset | should stay blocked until the expected dataset appears | pending | Do not fabricate missing customer data. | Record the exact missing path and continue unrelated jobs. |

## Open Issues

- None yet.

## Completion Criteria

- bootstrap_catalog_sync through wait_for_upstream_ready are marked `done` with evidence.
- import_customer_dataset is either `done` or `blocked_waiting_for_user` with evidence.
- All repairs occur only in `tasks-runtime/` and `configs-runtime/`.
- No unresolved fixable failures remain.

## Run History

- Initialized by `bin/init-harness.sh`.

## Next Agent Notes

- Read per-job state in `state/jobs/`.
- Use `bin/run-task.sh` for reruns.
- Prefer narrow fixes in runtime wrappers/configs: wrong flag, wrong filename, wrong path, wrong config value, wrong readiness marker.
- Do not create fake external input for import_customer_dataset.
