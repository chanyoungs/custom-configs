# Operations Workspace

This workspace contains a small recurring operations batch and supervision setup.

Key properties:

- `tasks-src/` contains the canonical seed job wrappers.
- `tasks-runtime/` is rebuilt from `tasks-src/` for each test run.
- The supervisor should repair only `tasks-runtime/` and `configs-runtime/`.
- Dependency scripts live in `/home/chanyoungs/custom-configs/skill-generators/test-external-deps` and should be treated as external contract code.
- A 1-minute scheduled supervisor and immediate error-triggered supervisor are both supported.

Quick start:

```bash
cd /home/chanyoungs/custom-configs/skill-generators/test
./bin/init-harness.sh
./bin/run-all-tasks.sh
```

Optional cron install:

```bash
./bin/install-cron.sh
```

Expected outcome:

- the internal recurring jobs should either complete successfully or be classified with clear evidence
- the customer dataset import should remain blocked until the missing external input is provided
