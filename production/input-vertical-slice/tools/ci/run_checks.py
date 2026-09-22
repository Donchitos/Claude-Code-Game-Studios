#!/usr/bin/env python3
"""Run the formal Input vertical-slice checks and emit one JSON report."""

from __future__ import annotations

import argparse
import json
import shutil
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
REPORT = ROOT / "evidence" / "input_vertical_slice_check_report.json"
GODOT_CANDIDATES = (
    Path("/Applications/Godot.app/Contents/MacOS/Godot"),
)


def find_godot() -> str | None:
    for candidate in GODOT_CANDIDATES:
        if candidate.is_file():
            return str(candidate)
    return shutil.which("godot")


def probe_device_tooling() -> dict[str, object]:
    adb = shutil.which("adb")
    xcrun = shutil.which("xcrun")
    simctl = False
    if xcrun is not None:
        try:
            completed = subprocess.run(
                [xcrun, "simctl", "help"],
                capture_output=True,
                text=True,
                timeout=10,
                check=False,
            )
            simctl = completed.returncode == 0
        except (OSError, subprocess.TimeoutExpired):
            simctl = False
    return {
        "adb_available": adb is not None,
        "adb_path": adb,
        "simctl_available": simctl,
        "xcrun_path": xcrun,
        "status": "READY" if adb is not None and simctl else "BLOCKED",
    }


def run_check(name: str, command: list[str], timeout: int = 60) -> dict[str, object]:
    try:
        completed = subprocess.run(
            command,
            cwd=ROOT,
            capture_output=True,
            text=True,
            timeout=timeout,
            check=False,
        )
        output = (completed.stdout + completed.stderr).strip()
        return {
            "name": name,
            "status": "PASS" if completed.returncode == 0 else "FAIL",
            "exit_code": completed.returncode,
            "command": command,
            "output": output[-4000:],
        }
    except subprocess.TimeoutExpired as error:
        return {
            "name": name,
            "status": "FAIL",
            "exit_code": None,
            "command": command,
            "output": f"timeout after {error.timeout}s",
        }


def build_report() -> dict[str, object]:
    godot = find_godot()
    checks: list[dict[str, object]] = []
    if godot is None:
        checks.append({
            "name": "godot_binary",
            "status": "FAIL",
            "exit_code": None,
            "command": [],
            "output": "Godot 4.7.1 binary not found",
        })
    else:
        checks.extend([
            run_check(
                "godot_editor_import",
                [godot, "--headless", "--path", str(ROOT), "--editor", "--quit"],
            ),
            run_check(
                "godot_contract",
                [godot, "--headless", "--path", str(ROOT), "--script", "res://tests/input_vertical_slice_contract.gd"],
            ),
            run_check(
                "godot_smoke",
                [godot, "--headless", "--path", str(ROOT), "--script", "res://tests/input_vertical_slice_smoke.gd"],
            ),
            run_check(
                "godot_touch_order_fixture",
                [godot, "--headless", "--path", str(ROOT), "--script", "res://tests/input_touch_order_fixture.gd"],
            ),
            run_check(
                "gdunit4_input_contract",
                [
                    godot,
                    "--path",
                    str(ROOT),
                    "-s",
                    "res://addons/gdUnit4/bin/GdUnitCmdTool.gd",
                    "-a",
                    "tests/input_system_gdunit4_test.gd",
                    "-rd",
                    "evidence/gdunit4",
                    "-rc",
                    "1000",
                ],
                timeout=120,
            ),
            run_check(
                "gdunit4_touch_scene_runner",
                [
                    godot,
                    "--path",
                    str(ROOT),
                    "-s",
                    "res://addons/gdUnit4/bin/GdUnitCmdTool.gd",
                    "-a",
                    "tests/input_touch_order_gdunit4_test.gd",
                    "-rd",
                    "evidence/gdunit4",
                    "-rc",
                    "1000",
                ],
                timeout=120,
            ),
            run_check(
                "gdunit4_battle_ui_slice",
                [
                    godot,
                    "--path",
                    str(ROOT),
                    "-s",
                    "res://addons/gdUnit4/bin/GdUnitCmdTool.gd",
                    "-a",
                    "tests/battle_ui_gdunit4_test.gd",
                    "-rd",
                    "evidence/gdunit4",
                    "-rc",
                    "1000",
                ],
                timeout=120,
            ),
            run_check(
                "gdunit4_game_root_viewport_route",
                [
                    godot,
                    "--path",
                    str(ROOT),
                    "-s",
                    "res://addons/gdUnit4/bin/GdUnitCmdTool.gd",
                    "-a",
                    "tests/game_root_viewport_gdunit4_test.gd",
                    "-rd",
                    "evidence/gdunit4",
                    "-rc",
                    "1000",
                ],
                timeout=120,
            ),
        ])
    checks.append(
        run_check(
            "static_guard",
            [sys.executable, str(ROOT / "tools" / "ci" / "static_guard_check.py")],
        )
    )
    return {
        "suite": "input_vertical_slice_checks",
        "generated_at_utc": datetime.now(timezone.utc).isoformat(),
        "godot_binary": godot,
        "device_tooling_probe": probe_device_tooling(),
        "status": "PASS" if all(check["status"] == "PASS" for check in checks) else "FAIL",
        "checks": checks,
        "evidence_boundary": {
            "complete_game_root_battle_ui_integration": False,
            "gdunit4_framework_and_slice_contract": all(
                next((check["status"] == "PASS" for check in checks if check["name"] == name), False)
                for name in ("gdunit4_input_contract", "gdunit4_touch_scene_runner", "gdunit4_battle_ui_slice", "gdunit4_game_root_viewport_route")
            ),
            "real_touch_scene_runner": any(
                check["name"] == "gdunit4_touch_scene_runner" and check["status"] == "PASS"
                for check in checks
            ),
            "minimal_battle_ui_slice_integration": any(
                check["name"] == "gdunit4_battle_ui_slice" and check["status"] == "PASS"
                for check in checks
            ),
            "minimal_game_root_viewport_route": any(
                check["name"] == "gdunit4_game_root_viewport_route" and check["status"] == "PASS"
                for check in checks
            ),
            "gdunit4_full_review_gate": False,
            "android_ios_device": False,
            "accessibility_runtime": False,
            "performance_thermal": False,
            "battle_ready": False,
        },
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--write-report", action="store_true")
    args = parser.parse_args()
    report = build_report()
    if args.write_report:
        REPORT.parent.mkdir(parents=True, exist_ok=True)
        REPORT.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        report["report_path"] = str(REPORT)
    print(json.dumps(report, ensure_ascii=False, indent=2))
    return 0 if report["status"] == "PASS" else 1


if __name__ == "__main__":
    sys.exit(main())
