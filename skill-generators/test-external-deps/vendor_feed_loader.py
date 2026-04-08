#!/usr/bin/env python3
from __future__ import annotations

import argparse
import shutil
import time
from pathlib import Path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--copy-output", required=True)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    input_path = Path(args.input)
    if not input_path.exists():
        raise FileNotFoundError(f"vendor feed ingestion failed: missing input {input_path}")
    output_path = Path(args.output)
    copy_output_path = Path(args.copy_output)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    copy_output_path.parent.mkdir(parents=True, exist_ok=True)
    time.sleep(30)
    output_path.write_text("ok\n", encoding="utf-8")
    shutil.copyfile(input_path, copy_output_path)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
