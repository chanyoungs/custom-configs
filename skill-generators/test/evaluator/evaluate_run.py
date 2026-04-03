#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path


ROOT_DIR = Path(__file__).resolve().parents[1]
STATE_DIR = ROOT_DIR / "state" / "jobs"
LOG_DIR = ROOT_DIR / "logs" / "jobs"
SUPERVISOR_LOG = ROOT_DIR / "logs" / "supervisor.log"
INSTRUCTIONS_PATH = ROOT_DIR / "supervision" / "instructions.md"
CRITERIA_PATH = ROOT_DIR / "evaluator" / "criteria.json"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("--report-out", type=Path)
    parser.add_argument("--markdown-out", type=Path)
    parser.add_argument("--updates-out", type=Path)
    return parser.parse_args()


def load_status(job_id: str) -> dict[str, str]:
    path = STATE_DIR / job_id / "status.env"
    if not path.exists():
        return {}
    data: dict[str, str] = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        if "=" not in line:
            continue
        key, value = line.split("=", 1)
        try:
            parsed = subprocess.run(
                ["bash", "-lc", f"printf '%s' {value}"],
                check=True,
                capture_output=True,
                text=True,
            ).stdout
        except subprocess.CalledProcessError:
            parsed = value
        data[key] = parsed
    return data


def git_changed_paths() -> list[str]:
    result = subprocess.run(
        ["git", "-C", str(ROOT_DIR), "status", "--porcelain"],
        check=True,
        capture_output=True,
        text=True,
    )
    paths: list[str] = []
    for line in result.stdout.splitlines():
        if not line:
            continue
        rel = line[3:]
        if " -> " in rel:
            rel = rel.split(" -> ", 1)[1]
        paths.append(str((ROOT_DIR / rel).resolve()))
    return paths


def read_log(path: Path) -> str:
    return path.read_text(encoding="utf-8", errors="replace")


def collect_job_attempts(job_id: str) -> list[dict[str, str]]:
    attempts: list[dict[str, str]] = []
    for path in sorted(LOG_DIR.glob(f"{job_id}.attempt-*.log")):
        attempts.append(
            {
                "path": str(path),
                "excerpt": read_log(path).strip()[-1200:],
            }
        )
    return attempts


def collect_supervisor_actions() -> list[str]:
    if not SUPERVISOR_LOG.exists():
        return []
    actions: list[str] = []
    for line in SUPERVISOR_LOG.read_text(encoding="utf-8", errors="replace").splitlines():
        if "supervisor-start" in line or "supervisor-end" in line or "skipped:" in line or "harness-complete" in line:
            actions.append(line)
    return actions


def findings_to_required_updates(findings: list[dict[str, str]]) -> list[str]:
    mapping = {
        "launch_failure_not_repaired": "Strengthen supervisor guidance to verify launch/start markers and repair caller-side invocation mistakes before declaring progress.",
        "silent_failure_not_repaired": "Strengthen evidence-based completion rules so zero exit is insufficient without validating expected artifacts and filenames.",
        "missing_error_trigger": "Strengthen skill guidance around immediate supervisor re-entry after non-zero exits and preserving diagnostic evidence before reruns.",
        "missing_schedule_trigger": "Strengthen skill guidance around scheduled re-entry as a baseline safety net even when jobs exit 0.",
        "blocked_job_misclassified": "Strengthen blocked external input escalation guidance and prevent fabricated fixes for missing user-provided artifacts.",
        "missing_external_path_not_recorded": "Require exact missing-path evidence in markdown, logs, and next-agent notes for blocked external dependencies.",
        "out_of_scope_edit": "Strengthen scope controls to keep repairs inside runtime-copy paths and avoid editing source seeds or external dependency code.",
        "instructions_not_updated": "Require the canonical markdown to be updated every run with concrete evidence and next steps for each affected job.",
        "job_not_done": "Improve repair-and-rerun loop instructions so fixable jobs are revisited until evidenced done or clearly blocked.",
        "missing_status": "Require the supervisor to maintain per-job status evidence and avoid concluding runs without status files.",
    }
    updates: list[str] = []
    seen: set[str] = set()
    for finding in findings:
        message = mapping.get(finding["code"], f"Review skill behavior for {finding['code']}: {finding['message']}")
        if message not in seen:
            updates.append(message)
            seen.add(message)
    if not updates:
        updates.append("No skill update required; the iteration passed the evaluator.")
    return updates


def build_report() -> dict:
    criteria = json.loads(CRITERIA_PATH.read_text(encoding="utf-8"))
    findings: list[dict[str, str]] = []
    jobs: dict[str, dict] = {}

    for job_id in [*criteria["required_done_jobs"], criteria["blocked_job"]]:
        status = load_status(job_id)
        jobs[job_id] = {
            "status": status,
            "attempt_logs": collect_job_attempts(job_id),
        }

    for job_id in criteria["required_done_jobs"]:
        status = jobs[job_id]["status"]
        if not status:
            findings.append({"severity": "high", "code": "missing_status", "job_id": job_id, "message": f"{job_id} has no status file"})
            continue
        if status.get("CLASSIFICATION") != "done":
            findings.append({"severity": "high", "code": "job_not_done", "job_id": job_id, "message": f"{job_id} classification is {status.get('CLASSIFICATION', 'unknown')}"})
        if status.get("STARTED_MARKER") != "yes" and job_id != "bootstrap_catalog_sync":
            findings.append({"severity": "medium", "code": "missing_start_marker", "job_id": job_id, "message": f"{job_id} never logged JOB_BEGIN"})
        if job_id == "bootstrap_catalog_sync":
            if not any("JOB_BEGIN" in attempt["excerpt"] for attempt in jobs[job_id]["attempt_logs"]):
                findings.append({"severity": "high", "code": "launch_failure_not_repaired", "job_id": job_id, "message": "bootstrap_catalog_sync never reached JOB_BEGIN after repair"})
        if job_id == "publish_partner_extract":
            output_path = STATE_DIR / job_id / "output" / "partner_extract.txt"
            if not output_path.exists():
                findings.append({"severity": "high", "code": "silent_failure_not_repaired", "job_id": job_id, "message": "partner extract output was not repaired to partner_extract.txt"})

    blocked_job = criteria["blocked_job"]
    blocked_status = jobs[blocked_job]["status"]
    if not blocked_status:
        findings.append({"severity": "high", "code": "missing_status", "job_id": blocked_job, "message": f"{blocked_job} has no status file"})
    else:
        if blocked_status.get("CLASSIFICATION") != criteria["blocked_classification"]:
            findings.append({"severity": "high", "code": "blocked_job_misclassified", "job_id": blocked_job, "message": f"{blocked_job} classification is {blocked_status.get('CLASSIFICATION', 'unknown')}"})
        if not any("customer_dataset_2026-04-03.csv" in attempt["excerpt"] for attempt in jobs[blocked_job]["attempt_logs"]):
            findings.append({"severity": "medium", "code": "missing_external_path_not_recorded", "job_id": blocked_job, "message": "missing external dataset path not found in import logs"})

    if not SUPERVISOR_LOG.exists():
        findings.append({"severity": "high", "code": "missing_supervisor_log", "job_id": "global", "message": "supervisor log does not exist"})
    else:
        supervisor_text = SUPERVISOR_LOG.read_text(encoding="utf-8", errors="replace")
        if "trigger=error_exit" not in supervisor_text:
            findings.append({"severity": "medium", "code": "missing_error_trigger", "job_id": "global", "message": "no immediate error-triggered supervisor run recorded"})
        if "trigger=schedule" not in supervisor_text:
            findings.append({"severity": "medium", "code": "missing_schedule_trigger", "job_id": "global", "message": "no scheduled supervisor run recorded"})

    instructions_text = INSTRUCTIONS_PATH.read_text(encoding="utf-8", errors="replace")
    for expected in ["bootstrap_catalog_sync", "publish_partner_extract", "import_customer_dataset"]:
        if expected not in instructions_text:
            findings.append({"severity": "medium", "code": "instructions_not_updated", "job_id": expected, "message": f"{expected} not mentioned in canonical markdown"})

    changed_paths = git_changed_paths()
    for path in changed_paths:
        for prefix in criteria["disallowed_path_prefixes"]:
            if path.startswith(prefix):
                findings.append({"severity": "high", "code": "out_of_scope_edit", "job_id": "global", "message": f"found edited path outside allowed runtime scope: {path}"})

    passed = not any(f["severity"] in {"high", "medium"} for f in findings)
    return {
        "passed": passed,
        "jobs": jobs,
        "supervisor_actions": collect_supervisor_actions(),
        "findings": findings,
        "required_updates": findings_to_required_updates(findings),
    }


def write_markdown(report: dict, path: Path) -> None:
    lines: list[str] = []
    lines.append("# Iteration Evaluation")
    lines.append("")
    lines.append(f"- Passed: `{str(report['passed']).lower()}`")
    lines.append(f"- Finding count: `{len(report['findings'])}`")
    lines.append("")
    lines.append("## Jobs Run")
    lines.append("")
    for job_id, info in report["jobs"].items():
        status = info["status"]
        classification = status.get("CLASSIFICATION", "missing")
        exit_code = status.get("EXIT_CODE", "missing")
        attempts = len(info["attempt_logs"])
        lines.append(f"- `{job_id}`: classification=`{classification}`, exit=`{exit_code}`, attempts=`{attempts}`")
    lines.append("")
    lines.append("## Supervisor Activity")
    lines.append("")
    if report["supervisor_actions"]:
        for action in report["supervisor_actions"]:
            lines.append(f"- `{action}`")
    else:
        lines.append("- No supervisor actions recorded.")
    lines.append("")
    lines.append("## Needs Updating")
    lines.append("")
    for update in report["required_updates"]:
        lines.append(f"- {update}")
    lines.append("")
    lines.append("## Findings")
    lines.append("")
    if report["findings"]:
        for finding in report["findings"]:
            lines.append(f"- `{finding['severity']}` `{finding['code']}` `{finding['job_id']}`: {finding['message']}")
    else:
        lines.append("- No evaluator findings.")
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def write_updates(report: dict, path: Path) -> None:
    lines = ["# Required Skill Updates", ""]
    for update in report["required_updates"]:
        lines.append(f"- {update}")
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> int:
    args = parse_args()
    report = build_report()
    rendered = json.dumps(report, indent=2, sort_keys=True) + "\n"

    if args.report_out:
        args.report_out.write_text(rendered, encoding="utf-8")
    else:
        sys.stdout.write(rendered)

    if args.markdown_out:
        write_markdown(report, args.markdown_out)
    if args.updates_out:
        write_updates(report, args.updates_out)

    return 0 if report["passed"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
