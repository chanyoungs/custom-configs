#!/usr/bin/env python3
from __future__ import annotations

import os
import subprocess
import sys
from pathlib import Path


FIXTURES_DIR = Path(os.environ["FIXTURES_DIR"])
TASK_OUTPUT_DIR = Path(os.environ["TASK_OUTPUT_DIR"])
EXTERNAL_DEPS_DIR = Path(os.environ["EXTERNAL_DEPS_DIR"])


def main() -> int:
    print("JOB_BEGIN wait_for_upstream_ready", flush=True)
    runner = EXTERNAL_DEPS_DIR / "upstream_ready_probe.py"
    cmd = [
        sys.executable,
        str(runner),
        "--signal",
        str(FIXTURES_DIR / "inputs" / "ready.signal"),
        "--output",
        str(TASK_OUTPUT_DIR / "output.ok"),
        "--attempts",
        "10",
        "--interval",
        "3",
    ]
    completed = subprocess.run(cmd)
    if completed.returncode != 0:
        return completed.returncode
    print("JOB_COMPLETE wait_for_upstream_ready", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
