# Pistol and health HUD verification — 2026-10-23

## Scope

Approved change: top-left black-framed red health bar without numeric text; damage animates fill; visible simple pistol with seven initial rounds and one shot per left-click press; recoil/muzzle flash; bottom-right ammunition; simple white plus crosshair. No enemies, damage debug key, reload, reserve ammo, projectile/damage-to-enemy simulation, or network features were added.

## Actual verification

Engine: `4.7.2.stable.official.ed1daf0bf`, executable found at `C:/Users/BISPC7/Desktop/Projeler/teslimat kargo/.tools/godot/Godot_v4.7.2-stable_win64_console.exe`. No installation or global configuration changes.

- Baseline movement suite: 124 assertions, zero failures.
- New combat suite initially failed because the combat state did not exist (1 failure), then on missing HUD/input (2 failures), then on missing lab shooting integration (1 failure).
- Final standalone combat suite: **47 assertions, zero failures**.
- Final movement suite: **124 assertions, zero failures**.
- Godot headless import succeeded.
- Visible Vulkan/Forward+ lab rehearsal on NVIDIA RTX 3060 Laptop GPU: **14 checks, zero failures**. Real InputEventMouseButton presses exercised the actual fire action and lab polling; seven presses depleted the magazine, an eighth was rejected, and pause rejected input. Damage was injected only by the test driver; no production damage key was added.
- Visible rehearsal saved initial, shot, empty, in-animation damage, settled damage and smaller-window screenshots in `production/qa/evidence/pistol-hud-*.png`.
- An initial visible rehearsal exposed `Tween invalid` on pause/resume after a reset. Added a failing lifecycle regression assertion; finished/killed tweens are now cleared. Final visible rerun had no engine errors or that warning.
- `git diff --check` passed. Git reports only the repository's LF/CRLF normalization warning for the generated `.godot/global_script_class_cache.cfg`.

## Follow-up: movement recovery, unlimited reload and HUD cleanup

User reported movement/jump unavailable and requested unlimited R reload plus removal of the title/subtitle below health.

- Reproduced actual visible movement failure: existing `--verify-lab` returned 3 failures (movement, dash and reaching boundary), despite the window being focused.
- Root cause: controller cached window focus before startup focus was acquired; requiring both stale cache and actual focus blocked input. Controller and camera now query current window focus. Focus-loss notification still cancels horizontal motion.
- Added physical D/V/R event regression checks. Temporarily restored the old focus condition: new visible suite failed exactly movement and jump (2 failures). Restored fix and reran.
- R instantly refills the seven-round magazine from unlimited supply, without healing. Repeated reload and paused reload checks included.
- Removed top-left Sector 9 heading and phase subtitle; retained health bar and other existing corner controls/status.
- Follow-up combat unit suite: **56 assertions, zero failures**. Movement suite: **124 assertions, zero failures**. Visible movement rehearsal: **7 checks, zero failures**. Visible jump rehearsal: **10 checks, zero failures**. Expanded visible combat/keyboard rehearsal: **20 checks** (final rerun recorded in session).
- This supersedes the initial no-reload scope below: unlimited reload is now explicitly requested and implemented.

## Follow-up completed: Space jump, no dash, keyboard device compatibility

- On resuming, `project.godot` again contained device 16 for legacy keyboard actions, Space dash and V jump. No Godot processes were open at the time; the cause of the intervening file rewrite was not established. Other external edits (including phase-plan.md and project feature/Mono settings) were preserved.
- Re-ran keyboard binding suite on **Godot 4.6.3 Mono**, the editor version previously observed: **6 expected failures before correction**, **7 checks / zero failures after correction**.
- Keyboard actions now use device 0. Jump is physical Space (32). Dash action binding removed; controller no longer polls dash input and the actual movement preset has zero dash values. Legacy pure dash helpers/tests remain for compatibility, but no playable dash is available.
- Removed dash cooldown/status text and replaced the visible Space/V instructions with Space jump. Updated lab movement rehearsal to verify no dash instead of requiring one.
- Unit checks on Godot 4.6.3: **124 movement assertions and 56 combat assertions, zero failures**.
- Final visible rehearsals on Godot 4.6.3: **22 combat/keyboard checks**, **7 movement checks**, **10 jump checks**, all zero failures. Tests also verify Space does not dash and V no longer jumps.
- Added `tests/integration/player/test_windows_keyboard.gd`, which observes actual Window input and player displacement without calling Input.parse_input_event/action_press. An external Windows scan-code driver focused the game and sent D and Space: observed device **0**, D physical code **68**, Space physical code **32**, horizontal displacement **5.987 m**, jump height **1.009 m**; both checks true and stderr empty.
- First Windows-driver attempt found no received keys; another attempt could not yet find the game window. These were unsuccessful driver/focus attempts, not successful game verification. Waiting for the real window and setting it foreground produced the result above.
- Screenshot evidence was refreshed by the final visible combat rehearsal. User's own keyboard/feel confirmation remains pending; Windows-generated keyboard events are stronger than Godot-injected actions but not a human playtest.

## Unused-code cleanup — 2026-10-24

- Removed the unreachable gameplay dash branch, dash timers/direction/expiry state, dash-only resource properties and preset entries. Horizontal movement now has a three-argument `simulate_motion(axis, slow, delta)` interface; every code caller was updated.
- Removed write-only player/camera focus caches and the camera notification handler that only maintained the unused cache. Player focus-loss cancellation remains.
- Removed the unused `is_airborne` accessor after checking code references. Kept collision/floor invalidation state, which is required by jump/reset handling.
- Removed obsolete dash-only tests and the engine-enum comparison test that never read InputMap. Real keyboard mapping suite remains, alongside movement/air-control, focus, camera, jump and reset tests. Lower assertion totals reflect removed-feature tests, not skipped current tests.
- After cleanup: movement **94 assertions** (final run in session), combat **56**, keyboard **7**. Visible combat **22**, movement **6**, jump **10** checks; zero failures in completed runs.
- Retained scene rehearsal/capture code: it is invoked by verification flags and is not unused. Retained combat damage API: called by integration tests and intentionally provided for future damage sources. No toolkit agents/skills/hooks deleted based solely on absence from runtime gameplay.
- Remaining tooling checks: Godot test-run dry-run still blocks on gdUnit4 despite standalone commands.test; configured editor executable absent; no export preset or CI workflow found. 51 hooks/scripts passed Git Bash syntax checks. An initial Python-launched `bash` resolved to unavailable WSL and failed before checking source; corrected to Git Bash, so those environment errors are not counted as script defects.
- No edits made to the user-modified phase-plan.md. Its existing stale status and `/resume` fragments are reported rather than silently rewritten.

## Decisions and limitations

- Work remained in the user-approved existing checkout on branch `feat/pistol-health-hud`. No commits or pushes.
- Crosshair follows the existing mouse cursor, rather than fixing it at screen center: movement already aims at a cursor-plane point and this preserves the aiming controls. This is an implementation choice, not an independently approved center-reticle redesign.
- Health/ammo state is separate from the display. Future damage callers use `lab.combat.apply_damage(amount)`.
- Pause now preserves player velocity rather than deleting jump momentum; this is in the touched pause wiring.
- Independent reviewer could not be started because worktree isolation was incorrectly requested from the non-repository parent directory. No independent review is claimed. Repeated attempts were an assistant coordination mistake.
- Screenshot files were retained, but the tool returned no viewable image payload to this session; detailed visual aesthetic sign-off remains with the user. Automated HUD checks verified styles, placement anchors, contents and live animation values.
- No user feel/accessibility sign-off, build export, gamepad firing, enemy hits, or full combat roadmap completion is claimed.
