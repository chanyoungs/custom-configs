#!/usr/bin/env python3
from __future__ import annotations

import os
import subprocess
import sys
from pathlib import Path


ROOT_DIR = Path(os.environ["ROOT_DIR"])
TASK_OUTPUT_DIR = Path(os.environ["TASK_OUTPUT_DIR"])
EXTERNAL_DEPS_DIR = Path(os.environ["EXTERNAL_DEPS_DIR"])


def main() -> int:
    print("JOB_BEGIN bootstrap_catalog_sync", flush=True)
    runner = EXTERNAL_DEPS_DIR / "bootstrap_catalog_runner.py"
    cmd = [
        sys.executable,
        str(runner),
        "--workspace",
        str(ROOT_DIR),
        "--output",
        str(TASK_OUTPUT_DIR / "output.ok"),
    ]
    completed = subprocess.run(cmd)
    if completed.returncode != 0:
        return completed.returncode
    print("JOB_COMPLETE bootstrap_catalog_sync", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
