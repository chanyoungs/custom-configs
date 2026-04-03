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
    print("JOB_BEGIN build_daily_summary", flush=True)
    runner = EXTERNAL_DEPS_DIR / "summary_builder.py"
    cmd = [
        sys.executable,
        str(runner),
        "--source",
        str(FIXTURES_DIR / "inputs" / "source_data.txt"),
        "--output",
        str(TASK_OUTPUT_DIR / "output.ok"),
        "--copy-output",
        str(TASK_OUTPUT_DIR / "copied_input.txt"),
    ]
    completed = subprocess.run(cmd)
    if completed.returncode != 0:
        return completed.returncode
    print("JOB_COMPLETE build_daily_summary", flush=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
