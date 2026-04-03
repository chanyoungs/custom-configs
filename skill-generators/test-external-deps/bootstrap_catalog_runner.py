#!/usr/bin/env python3
from __future__ import annotations

import argparse
import time
from pathlib import Path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--workspace", required=True)
    parser.add_argument("--output", required=True)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    output_path = Path(args.output)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    time.sleep(30)
    output_path.write_text("catalog bootstrap complete\n", encoding="utf-8")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
