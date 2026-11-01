# Pistol and Health HUD Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add the user-approved seven-shot pistol and minimal health/ammunition HUD to the existing Godot mechanics lab.

**Architecture:** Keep movement and camera behavior unchanged. A small injected Resource holds health/pistol state and emits changes; data assets hold gameplay values. A separate HUD owns presentation and health interpolation; a pistol visual owns recoil/flash. The existing lab wires these together.

**Tech Stack:** Godot 4.7.2, GDScript, existing standalone SceneTree tests.

**Spec:** Approved conversation on 2026-10-23, captured below.

## Global Constraints / Approved Spec

- Top-left health display: black frame, red fill, no numeric health text. Damage animates fill toward the new health. No enemy or damage-debug key is added.
- Visible simple pistol on the character, seven rounds initially. One shot per left-click press consumes one round; empty pistol cannot fire. Short recoil and muzzle flash on accepted shots.
- Bottom-right display identifies the pistol and shows current ammunition out of seven.
- Simple white `+` crosshair, no decorative reticle. Existing mouse-aim and movement controls remain unchanged.
- Pause blocks shots and freezes effects. F5 resets health, ammunition, and effects with the lab. No reload, reserve ammunition, enemies, damage to enemies, or network behavior.
- No external dependencies, installs, commits, pushes, global settings edits, or unrelated audit fixes.
- Existing 124 movement assertions must remain green. Baseline: verified on Godot 4.7.2, 124 assertions, zero failures.

## Review Focus

- Empty magazine and repeated held input must not create extra shots or effects.
- Pause, focus loss, and reset must not consume ammunition unexpectedly.
- Repeated damage while the health animation is running must retarget without healing or overshoot.
- HUD must retain corner anchoring on window resize and not overlap existing labels.
- Weapon orientation and crosshair must not silently break the existing cursor-plane aiming controls.

## File Structure

- Create `src/combat/player_combat.gd`: state, reset, damage, shot acceptance and change signals.
- Create `assets/data/player_combat_default.tres`: health, magazine, recoil/flash and health-animation values.
- Create `src/combat/pistol_visual.gd`: low-poly pistol mesh, recoil/flash animation.
- Create `src/ui/player_hud.gd`: framed health bar, ammunition and simple crosshair.
- Modify `src/lab/mechanics_lab.gd`: wiring, focus/pause guarded firing, reset and text/layout updates.
- Modify `project.godot`: left-click `fire` action.
- Create `tests/unit/player/test_combat.gd`: standalone state, resource, InputMap, HUD and scene integration assertions.
- Create `production/qa/evidence/` screenshots and a short verification record only after running the actual application.

## Task 1: Health and ammunition state

**Interfaces:** `reset() -> void`, `try_fire() -> bool`, `apply_damage(amount: float) -> void`; exported maximum health and magazine capacity; read-only-by-convention current health/ammo; `health_changed`, `ammo_changed`, `fired` signals.

- [ ] Write standalone tests for seven accepted shots then rejection; damage clamping, negative damage rejection, reset and real preset values.
- [ ] Run tests and observe missing-feature failures before implementation.
- [ ] Implement injected combat resource and preset.
- [ ] Run combat tests and the existing movement suite; require zero failures.

## Task 2: HUD and pistol presentation

**Interfaces:** HUD `bind_state(state)`, `reset_display()`, `set_paused(value)`; pistol `play_shot()`, `reset_visual()`, `set_paused(value)`.

- [ ] Add tests for nonnumeric black/red health style, retargeted damage animation, corner anchors, seven-round ammunition display, recoil/flash reset.
- [ ] Observe failures, implement presentation components, rerun both suites.

## Task 3: Lab integration and visible verification

- [ ] Add integration tests for actual `fire` action, lab wiring, paused shot rejection, reset and actual loaded state preset.
- [ ] Observe failures; wire lab and input; move old top-left labels below health and update obsolete no-weapons disclaimer.
- [ ] Import project, run both suites and launch the actual lab on Godot 4.7.2.
- [ ] Retain screenshots for initial HUD, consumed ammunition, and damaged animated health via test-only scene driver (not production debug controls).
- [ ] Run `git diff --check`; obtain one focused fresh review of changed files; fix important verified issues and report actual evidence and any remaining limitations.

## Execution Notes

- User approved working in the existing checkout on a separate branch; implemented on `feat/pistol-health-hud`, not main. No commits or pushes.
- State, preset, HUD, pistol visual, lab wiring and input action implemented. Final combat suite: 47 assertions, zero failures. Movement: 124 assertions, zero failures. Visible lab integration: 14 checks, zero failures.
- Ruling: crosshair follows the cursor because the existing lab aims on the cursor plane; centered static reticle would misrepresent aim. User was informed during implementation. Cost if wrong: move reticle/change aiming in a follow-up.
- Ruling: pause wiring preserves velocity so newly connected effect freezing does not retain the old jump-momentum reset bug. Cost if wrong: pause semantics must be revisited.
- Final review: independent agent launch unavailable due incorrectly requested worktree isolation from parent directory; no independent review claimed. Repeated retries were a coordination error, not a game error.
- Verification record: `production/qa/pistol-hud-2026-10-23.md`. Retained screenshots: `production/qa/evidence/pistol-hud-*.png`. Screenshot tool did not return a viewable image payload; user visual sign-off remains pending.
- Deferred: enemy damage/projectiles, reload, gamepad shooting, accessibility sign-off and build export are outside this small delivery.
