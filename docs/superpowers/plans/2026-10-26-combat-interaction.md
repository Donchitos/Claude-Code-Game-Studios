# Combat and Interaction Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Implement the explicitly selected P1-01A acceptance scenarios, P1-02 combat lab, and P1-04A interaction foundation.
**Architecture:** Keep locomotion/camera untouched. Add data-driven weapon profiles and a weapon controller; damageable world props receive ray hits and team-filtered damage. An interaction controller owns selection, range/occlusion and hold/cancel state; world stations provide actual effects. Lab wires these components into existing state, HUD, pause and reset.
**Tech Stack:** Godot 4.6.3 Mono (installed editor), GDScript, standalone SceneTree tests; no dependencies.
**Spec:** User-approved roadmap in this conversation: P1-01A, all P1-02A–D and P1-04A. User selected implementation on 2026-10-26.

## Global Constraints

- Preserve WASD, Space jump, Shift slow walk, C camera center, F5 reset, Esc pause; no dash.
- Pistol remains seven rounds; R refills unlimited lab supply. Other weapon capacities/tuning are prototype data, not user-approved final balance.
- Keep black/red nonnumeric health bar, simple white +, corner ammo. No scatter ring replacing +.
- No enemies/AI/roles/inventory/multiplayer. Targets, damage pad, shield station and cover are lab samples.
- User subjective movement/feel acceptance remains pending even when tests pass.
- Preserve all existing uncommitted changes; no commit/push, dependency install, global config edits or unrelated hook fixes.

## Review Focus

- Ray hits stop at solid geometry; friendly targets receive no damage; invalid damage is rejected.
- Held input never repeatedly fires semi-auto pistol; cooldown/switch/pause/reset do not leak effects or rounds.
- Shield overflow, recharge delay, stun and zero-health prevent invalid player actions.
- Holding/toggle interaction cancels on lost target, range/occlusion, pause/focus loss; completion is one-shot.
- Reset restores damaged/destroyed world props, selection, timers and HUD with no stale effects.

## Task 1 — Combat state and profiles

Files: modify src/combat/player_combat.gd; create src/combat/weapon_profile.gd, assets/data/weapons/*.tres; tests/unit/player/test_combat_systems.gd.
Interfaces: apply_damage(amount, source_team=-1); advance(delta); apply_stun(duration); shield_changed/current max; select_weapon profile via controller. Damage first shield then health, friendly player-team damage ignored. Four profiles: pistol7, shock8, shotgun5 (6 pellets), carbine12; adjustable ranges/damage/spread/noise/cooldown.
- [ ] Write/run failing contract assertions before implementation.
- [ ] Implement shield/recharge/stun and profiles, retain old reset/ammo/health contracts.
- [ ] Run new suite and existing movement/combat/keyboard suites.

## Task 2 — World combat and feedback

Files: src/combat/damageable_prop.gd, weapon_controller.gd; lab wiring, player_hud extensions.
Interfaces: prop.receive_hit(amount, source_team, stun); reset_target(); weapon.fire_at(origin,direction,moving)->bool; select_weapon(index); advance(delta); reset_weapon(); signals hit/noise/shot.
- [ ] Add failing actual-physics tests for target hits, wall occlusion, team filter, cooldown, empty and reset.
- [ ] Implement four selectable profiles (1–4), low/high/breakable cover, target labels, hazard and shield refill sample; procedural tracer/sparks and audio/noise signal, reduced flash/shake/audio controls.
- [ ] Preserve pistol node recoil/flash; no enemy hit-stop freezing inputs. Brief cosmetic flash on impact.

## Task 3 — Interaction

Files: src/interaction/lab_interactable.gd, interaction_controller.gd; assets/data/lab_rules.tres; lab/UI and input additions.
Interfaces: set_candidate(target, player_point, clear_los); step(pressed,held,delta); cancel(); target.activate()->bool; reset_target(); contextual label/progress/reason.
- [ ] Write/run failing tests for hold release, toggle, invalid range, occlusion, one completion and reset.
- [ ] Build ray-picked terminal/door/shield station; E commands, toggle option T, short reason/progress without changing +. F5/pause/focus reset/cancel consistently.

## Task 4 — Acceptance and final verification

Files: tests/integration/player/test_phase_packages.gd; production/qa/phase-packages-2026-10-26.md.
- [ ] Real scene movement, 45/75cm obstacle traversal and high wall, pause/reset/focus behavior; preserve pure movement suite.
- [ ] Actual scene shot/cover/damage/shield and E short/hold/toggle/occlusion tests.
- [ ] Import, run all suites, visible run with retained screenshots, diff check. Record failures/limits without claiming feel approval.

## Execution record

Execution inline in existing approved feat/pistol-health-hud checkout. Prototype tuning is builder choice and remains external data. Existing shell/toolkit audit fixes are out of scope.

- Tasks 1–3 functional implementation and Task 4 automated/visible verification delivered; detailed evidence and limits in `production/qa/phase-packages-2026-10-26.md`.
- Unit results: keyboard7, movement94, combat60, combat_systems24, interaction11; zero failures. Visible combat22, packages26, movement6, jump10; zero failures in final completed runs. Combat teardown repeated three times without previous audio warning after mixer retirement wait.
- Ruling: instant unlimited R remains default; finite-reserve scenario is F7 opt-in. Cost if wrong: remove scenario or revise UI.
- Ruling: shield starts empty and recharges; station fills it. Cost if wrong: change reset default and baseline damage tests.
- Ruling: use procedural audio/silhouettes and weapon-pose-only hit-stop, never global freeze. Cost if wrong: prototype feedback replaced after user playtest.
- Terminal fixture moved off existing movement acceptance lane to preserve traversal.
- User feel approval remains pending. Timed reload animation and production layered audio are not delivered; P1-02 must not be labelled fully final.
- Independent review unavailable: incorrectly requested worktree agent isolation from parent cwd failed. Only author review/tests claimed; no independent approval.
- No commits/pushes. Existing user modifications preserved.

