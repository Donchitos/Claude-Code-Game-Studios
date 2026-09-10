#!/usr/bin/env python3
"""Static contract guard for the formal Input vertical slice."""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
PROJECT = ROOT / "project.godot"
SCENE = ROOT / "main.tscn"
GAME_ROOT = ROOT / "src" / "input_slice_root.gd"
INPUT_SYSTEM = ROOT / "src" / "input_system.gd"
HOST = ROOT / "src" / "virtual_joystick_host.gd"
FOCUS_MANIFEST = ROOT / "src" / "directional_focus_manifest.gd"
BATTLE_UI = ROOT / "src" / "battle_ui_slice.gd"
TOUCH_FIXTURE = ROOT / "tests" / "input_touch_order_fixture.gd"
GDUNIT_PLUGIN = ROOT / "addons" / "gdUnit4" / "plugin.cfg"
GDUNIT_TEST = ROOT / "tests" / "input_system_gdunit4_test.gd"
GDUNIT_TOUCH_TEST = ROOT / "tests" / "input_touch_order_gdunit4_test.gd"
GDUNIT_UI_TEST = ROOT / "tests" / "battle_ui_gdunit4_test.gd"
GDUNIT_GAME_ROOT_TEST = ROOT / "tests" / "game_root_viewport_gdunit4_test.gd"

MOVEMENT = (
    "touch_move_left",
    "touch_move_right",
    "touch_move_up",
    "touch_move_down",
)
META = (
    "ui_focus_next",
    "ui_focus_previous",
    "ui_focus_left",
    "ui_focus_right",
    "ui_activate",
    "ui_back",
    "ui_increment",
    "ui_decrement",
)


def check() -> list[str]:
    errors: list[str] = []
    required = (PROJECT, SCENE, GAME_ROOT, INPUT_SYSTEM, HOST, FOCUS_MANIFEST, BATTLE_UI, TOUCH_FIXTURE, GDUNIT_PLUGIN, GDUNIT_TEST, GDUNIT_TOUCH_TEST, GDUNIT_UI_TEST, GDUNIT_GAME_ROOT_TEST)
    errors.extend(f"missing required file: {path}" for path in required if not path.is_file())
    if errors:
        return errors

    project = PROJECT.read_text(encoding="utf-8")
    scene = SCENE.read_text(encoding="utf-8")
    game_root = GAME_ROOT.read_text(encoding="utf-8")
    input_system = INPUT_SYSTEM.read_text(encoding="utf-8")
    host = HOST.read_text(encoding="utf-8")
    focus_manifest = FOCUS_MANIFEST.read_text(encoding="utf-8")
    battle_ui = BATTLE_UI.read_text(encoding="utf-8")
    touch_fixture = TOUCH_FIXTURE.read_text(encoding="utf-8")
    gdunit_plugin = GDUNIT_PLUGIN.read_text(encoding="utf-8")
    gdunit_test = GDUNIT_TEST.read_text(encoding="utf-8")
    gdunit_touch_test = GDUNIT_TOUCH_TEST.read_text(encoding="utf-8")
    gdunit_ui_test = GDUNIT_UI_TEST.read_text(encoding="utf-8")
    gdunit_game_root_test = GDUNIT_GAME_ROOT_TEST.read_text(encoding="utf-8")

    if 'config/features=PackedStringArray("4.7")' not in project:
        errors.append("project is not pinned to Godot 4.7")
    if 'run/main_scene="res://main.tscn"' not in project:
        errors.append("main scene is not res://main.tscn")
    if 'ext_resource type="Script" path="res://src/input_slice_root.gd"' not in scene:
        errors.append("main scene does not use input_slice_root.gd")
    if 'CanvasLayer.new()' not in game_root:
        errors.append("GameRoot has no BattleUI CanvasLayer route")
    if 'pointing/emulate_touch_from_mouse=false' not in project:
        errors.append("mouse-to-touch emulation is not explicitly disabled")
    if 'buffering/agile_event_flushing=false' not in project:
        errors.append("agile event flushing is not explicitly disabled")

    for action in MOVEMENT:
        block = re.search(rf"(?m)^{re.escape(action)}=\{{\n(.*?)\n\}}", project, re.DOTALL)
        if not block:
            errors.append(f"missing movement InputMap row: {action}")
            continue
        if '"deadzone": 0.0' not in block.group(0) or '"events": []' not in block.group(0):
            errors.append(f"movement InputMap row is not empty/zero-deadzone: {action}")

    for action in META:
        if not re.search(rf"(?m)^{re.escape(action)}=\{{", project):
            errors.append(f"missing Meta UI InputMap row: {action}")

    forbidden = ("Input.action_press", "Input.action_release", "Input.parse_input_event")
    for path, source in ((INPUT_SYSTEM, input_system), (HOST, host)):
        for token in forbidden:
            if token in source:
                errors.append(f"forbidden writer {token} in {path}")
    if "ClassDB.instantiate(&\"VirtualJoystick\")" not in host:
        errors.append("host does not instantiate the built-in VirtualJoystick")
    if "registered_active_vj_count()" not in input_system:
        errors.append("InputSystem does not enforce active VJ count postcondition")
    for token in ("InputEventScreenTouch", "InputEventScreenDrag", "press.pressed = true", "release.pressed = false"):
        if token not in touch_fixture:
            errors.append(f"touch-order fixture missing {token}")
    if 'version="6.2.1"' not in gdunit_plugin:
        errors.append("GDUnit4 plugin is not pinned to v6.2.1")
    if not re.search(r"(?m)^extends GdUnitTestSuite$", gdunit_test):
        errors.append("GDUnit4 input test does not extend GdUnitTestSuite")
    if "DirectionalFocusNeighborManifestV1.algorithm.v1" not in focus_manifest:
        errors.append("directional focus manifest algorithm version is missing")
    if battle_ui.count("ui_") < 8:
        errors.append("BattleUI does not expose the eight Meta UI actions")
    for source, label in ((gdunit_touch_test, "touch GDUnit4 test"), (gdunit_ui_test, "UI GDUnit4 test")):
        if not re.search(r"(?m)^extends GdUnitTestSuite$", source):
            errors.append(f"{label} does not extend GdUnitTestSuite")
    for token in ("scene_runner", "simulate_screen_touch_press", "simulate_screen_touch_drag", "simulate_screen_touch_release"):
        if token not in gdunit_touch_test:
            errors.append(f"touch GDUnit4 test missing {token}")
    if "gui_disable_input" not in game_root or "ACTIVATION_SUCCESS" not in game_root or "replace_battle_scope" not in game_root:
        errors.append("GameRoot does not own the root Viewport activation gate")
    if not re.search(r"(?m)^extends GdUnitTestSuite$", gdunit_game_root_test):
        errors.append("GameRoot Viewport GDUnit4 test does not extend GdUnitTestSuite")
    return errors


def main() -> int:
    errors = check()
    result = {
        "guard": "input_vertical_slice_static_guard",
        "project": str(PROJECT),
        "status": "PASS" if not errors else "FAIL",
        "errors": errors,
    }
    print(json.dumps(result, ensure_ascii=False, indent=2))
    return 0 if not errors else 1


if __name__ == "__main__":
    sys.exit(main())
