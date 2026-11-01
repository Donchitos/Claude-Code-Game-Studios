# P1-01A / P1-02 / P1-04A — implementation evidence

## Scope and status

User explicitly requested these three packages. Existing movement/camera math and Space/no-dash decisions are preserved. No AI/roles/inventory/multiplayer or progression was added. No commits/pushes/installations.

- **P1-01A: technical acceptance implemented; user feel approval pending.** Existing movement/jump rehearsals plus actual 45/75cm obstacle traversal pass. Camera jump-height anchor preserved. No human feel approval inferred.
- **P1-02: functional combat lab implemented; polish and user sound/feel approval pending.** Four external weapon profiles; world ray hits/solid occlusion; per-weapon magazines; cooldown, movement/recoil spread; shock stun, multi-pellet shotgun; team filtering; shield-first overflow, recharge delay, stun/dead fire blocking; damage pad, shield station; low/high/breakable cover; tracer, hit marker, flash/recoil, procedural audio/noise signal and reduced-effects mode. R remains instant unlimited by default. F7 explicitly enables a finite-reserve sample. No enemy hit reactions/AI, full ammo economy, timed reload animation, layered production audio, dynamic muzzle light or hit-stop are claimed.
- **P1-04A: interaction foundation implemented.** E short/hold/release cancel; T toggle mode; target loss/range/LOS/repeated completion rejection; candidate priority; door, terminal that opens linked door, shield station; separate contextual reason/progress while simple + is retained. No inventory/cases/partner interaction claimed.

## Follow-up — automatic two-second reload

The user's latest request supersedes instant refill: the final round automatically starts a **2.0-second reload** and R uses the same timed path. Shooting is blocked during reload; HUD displays the countdown. Reserve remains unlimited by default; F7 sample consumes finite reserve only upon completion. Weapon switching cancels unfinished reload without creating rounds; selecting an empty weapon starts a fresh reload. Pause freezes the timer, F5 cancels/reset restores the pistol, zero health cancels reload. Full magazines and no-reserve samples do not start repeated reloads.

Verification: missing reload state first produced a failing test; final `test_reload` 26 checks, `test_combat` 60, `test_combat_systems` 24, interaction 11, movement 94, keyboard 7 — **222 unit checks, zero failures**. Visible combat rehearsal **29 checks** and selected-package rehearsal **27 checks**, zero failures. This updates the older instant-R descriptions below; no new installs or commits.

## Controls

WASD move, Shift slow, Space jump, C center, left click fire, R refill, 1–4 weapon, E interact, T hold/toggle, F6 reduced effects, F7 finite/unlimited lab ammunition, F5 reset, Esc pause.

Targets and cover are at the north-west range (negative X/Z). Terminal at (4,0.5,7), shield station at (-4,0.5,5), door at (12.5,1.1,4), red damage pad at (-10,0.1,6). Approach and point cursor at a station before E. Starting shield is empty and recharges after delay; station supplies full shield. Prototype balance is external data, not approved final balance.

## Verification on Godot 4.6.3 Mono / Vulkan Forward+ / NVIDIA RTX 3060 Laptop GPU

- Existing keyboard mappings: 7 checks, zero failures.
- Existing movement/camera/jump unit suite: 94 assertions, zero failures.
- Existing combat/HUD suite: 56 assertions, zero failures.
- New combat systems suite: 24 checks, zero failures.
- New interaction suite: 11 checks, zero failures.
- Visible selected-package suite: 26 checks, zero failures.
- Visible existing movement rehearsal: 6 checks, zero failures.
- Visible existing jump rehearsal: 10 checks, zero failures.
- Existing visible combat/HUD suite: 22 checks, zero failures after accounting for the new real 0.20s fire cadence with 0.22s between test presses.
- Screenshot retained at `production/qa/evidence/phase-packages/lab.png`. Image-reading tool returned no viewable payload, so screenshot aesthetic approval is not claimed.

## Failures observed and addressed

1. New contract suites were RED for missing combat advance/controller and missing interaction controller before implementation.
2. New scene integration was RED for missing world weapon/interaction wiring.
3. E visible rehearsal initially failed: a single Godot synthetic mouse event was overwritten by OS mouse motion. Test-only viewport cursor pinning targets the actual terminal each frame; E goes through real InputMap polling and the scene controller. No production focus or range checks bypassed.
4. Stun reload test failed, then command admission was corrected; final 26-check visible suite passed.
5. New terminal initially obstructed preexisting straight-line movement acceptance path at z=5; moved fixture to z=7, leaving baseline gameplay/collision code unchanged. Existing movement then passed.
6. One combined headless run intermittently reported ObjectDB instances leaked at exit; two verbose reruns of combat suite did not reproduce the leak warning. Root cause not established; not reported as resolved. Verbose Mono also reports no C# project assembly (this project uses GDScript).

## Rulings / limitations

- Ruling: preserve unlimited instant R; finite reserve is an explicit F7 test mode, not a default economy change. Cost if wrong: remove/test-mode UI can be revised.
- Ruling: shield starts empty on reset, recharges after configured delay; preserves old health-only damage regression behavior while station demonstrates full shield. Cost if wrong: shield default and tests need changing.
- Ruling: prototype capacities/damage/spread/ranges are builder defaults in assets/data/weapons, not user balance approval.
- Ruling: terminal sample opens a linked existing door; this supplies a visible result without implementing role hacking.
- Final follow-up adds distinct procedural barrel silhouettes for shotgun/shock/carbine, real OmniLight3D muzzle illumination, and weapon-pose-only hit-stop (movement/input/world time never freeze). Reduced mode suppresses flash/light and hit-stop. These are prototype representations, not final weapon assets.
- Existing combat suite now has **60 assertions**, zero failures. An AudioStreamWAV/playback leak at rapid headless exit was traced with verbose logs. Feedback now stops/detaches audio on exit; test teardown waits 0.2s for the audio mixer. Three consecutive final combat-suite runs passed without the ObjectDB warning. Earlier warning-bearing runs remain recorded above.
- Timed reload animation and production layered audio remain unfinished P1-02 presentation items. R still refills immediately as previously requested; no final audio/feel approval is claimed.
- No independent reviewer ran: worktree-isolated Agent launch failed because session root is the parent of the repository. Author review and tests are the evidence; do not describe this as independent approval.
- No user feel/sound/accessibility approval, target-hardware profiling or export build is claimed. Do not mark all Phase 1 complete.
