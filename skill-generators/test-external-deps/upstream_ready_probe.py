#!/usr/bin/env python3
from __future__ import annotations

import argparse
import time
from pathlib import Path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--signal", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--attempts", type=int, default=10)
    parser.add_argument("--interval", type=int, default=3)
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    signal_path = Path(args.signal)
    output_path = Path(args.output)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    for _ in range(args.attempts):
        if signal_path.exists():
            time.sleep(args.interval)
            output_path.write_text("upstream readiness confirmed\n", encoding="utf-8")
            return 0
        time.sleep(args.interval)
    raise TimeoutError(f"upstream readiness check timed out waiting for {signal_path}")


if __name__ == "__main__":
    raise SystemExit(main())
