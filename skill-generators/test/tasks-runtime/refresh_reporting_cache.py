#!/usr/bin/env python3
from __future__ import annotations

import os
import subprocess
import sys
from pathlib import Path


CONFIGS_DIR = Path(os.environ["CONFIGS_DIR"])
TASK_OUTPUT_DIR = Path(os.environ["TASK_OUTPUT_DIR"])
EXTERNAL_DEPS_DIR = Path(os.environ["EXTERNAL_DEPS_DIR"])
ROOT_DIR = Path(os.environ["ROOT_DIR"])


def main() -> int:
    print("JOB_BEGIN refresh_reporting_cache", flush=True)
    runner = EXTERNAL_DEPS_DIR / "cache_refresher.py"
    cmd = [
        sys.executable,
        str(runner),
        "--root",
        str(ROOT_DIR),
        "--config",
        str(CONFIGS_DIR / "reporting-cache.json"),
        "--output",
        str(TASK_OUTPUT_DIR / "output.ok"),
        "--copy-output",
        str(TASK_OUTPUT_DIR / "config_input.txt"),
    ]
    completed = subprocess.run(cmd)
    if completed.returncode != 0:
        return completed.returncode
    print("JOB_COMPLETE refresh_reporting_cache", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
