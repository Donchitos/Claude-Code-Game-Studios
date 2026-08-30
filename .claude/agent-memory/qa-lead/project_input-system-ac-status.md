---
name: project-input-system-ac-status
description: Adversarial review findings on design/gdd/input.md Acceptance Criteria (AC 1-25), as of 2026-08-19 — DEATH_HOLD/pause contradiction with Permadeath, AC22 not headlessly automatable, AC19-21 unclassified
metadata:
  type: project
---

`design/gdd/input.md` Acceptance Criteria section (AC 1-25, GIVEN-WHEN-THEN) reviewed
adversarially on 2026-08-19. Same pattern as [[project-heroes-system-ac-status]] and
[[project-troop-system-ac-status]]: found a cross-GDD contract contradiction plus several
testability/coverage gaps not yet actioned in the file.

**Cross-GDD contradiction (highest priority, confirmed against source):**
- `input.md` Edge Cases (line 105) states gamepad disconnect mid-game **unconditionally**
  "pausa automáticamente el juego" (consola AND PC), with no `DEATH_HOLD` exception.
- `permadeath.md` Regla 4 / AC-P07c (line 81, 267-268) is explicit: during a `HOLDING` beat,
  "ninguna pausa real del motor puede iniciarse" — the pause-menu action itself is suppressed,
  `SceneTree.paused` must stay `false` the entire time.
- `input.md` AC 17 only covers the `RTS_COMMAND` case ("GIVEN contexto RTS_COMMAND (en consola
  o PC)") — it never tests a disconnect while `DEATH_HOLD` is active, so the contradiction is
  invisible to the AC suite even though the prose asserts behavior that would violate Permadeath's
  own AC-P07c if implemented literally.
- **Fix**: add AC 17b — GIVEN `DEATH_HOLD` active (Permadeath `HOLDING`), WHEN the active gamepad
  disconnects, THEN the reconnect-prompt signal still fires, but no real-engine-pause request is
  emitted/honored (`SceneTree.paused` stays `false`) — any pause is deferred until Permadeath
  releases the beat. Also patch the Edge Cases prose (line 105) to carve out this exception
  explicitly rather than stating it as unconditional.

**Other findings (not yet actioned):**
1. **AC 22 (performance/latency) is not automatable as a headless unit test.** It requires "cualquier
   evento de input físico por el OS" measured over a real 60-second sample with 0 dropped/delayed
   events — this needs hardware-in-the-loop / real OS input capture, which directly conflicts with
   the project's own Testing Standards ("Determinism: no time-dependent assertions" and "What NOT
   to Automate: platform-specific... test on target hardware, not headlessly"). The classification
   table (line 225) tags it "Logic/perf" and BLOQUEANTE but never names an evidence location (every
   other row in that table does). This is the single BLOCKING gate for Foundation sign-off and it's
   currently ungated — recommend reclassifying as Integration/Performance with an instrumented
   on-device test in `tests/performance/input/`, not `tests/unit/input/`.
2. **AC 3's exclusivity claim ("ningún otro contexto permanece activo simultáneamente") is only
   operationalizable once you know the internal representation is a single `current_context` field**
   — but that field name is only revealed later, in AC 4. As written, AC 3 alone doesn't tell a test
   author what to assert. Minor doc-ordering fix: state the single-field representation once, in
   Core Rule 2 or AC 3 itself.
3. **AC 4's "el cambio es rechazado" doesn't specify the rejection mechanism** (exception thrown vs.
   silent no-op vs. assertion) — needed for a deterministic unit test assertion.
4. **Edge case coverage gap**: the Edge Cases prose bullet "Si un valor de zoom queda fuera de
   `[zoom_min, zoom_max]` por un cambio de configuración... se hace clamp al rango válido en el
   siguiente frame" has **no corresponding AC**. AC 24/25 only test the player-driven boundary case
   (pressing zoom-in/out while already at the limit), not the external-cause case (a config change
   putting zoom out of bounds, clamped on the next input frame). Propose AC 24b.
5. **AC 19-21 are missing from the story-type classification table** (line 222-226). The table
   only buckets DEATH_HOLD edge cases, gamepad disconnect, input-method-mid-action, performance, and
   AC 23-25 — it never assigns a type/gate to AC 19 (pause during `BLESSING_SELECT`), AC 20 (button
   conflict resolved by context), or AC 21 (click on unit border). Per this project's hard
   Logic/Integration test-evidence gate, an unclassified AC has no defined evidence requirement and
   could silently ship without test coverage. All three read as Logic (pure state-machine/routing
   behavior, no external system needed) — recommend adding them to the Logic bucket explicitly.

**Open Questions cross-check**: the one fully-open question ("¿El gamepad es opcional en PC o se
asume conectado?... falta definir el flujo de 'jugar sin gamepad conectado' en PC") does not
block any of the 25 existing ACs — AC 17 presupposes a gamepad was already connected and then
disconnects, which is well-defined regardless of the open question. But note the flow the open
question describes (booting the game on PC with no gamepad ever connected) has **zero AC
coverage** today — worth flagging so whoever resolves the open question also adds the AC.

**How to apply**: when `input.md` is revised, check that AC 17b lands and cross-references
`permadeath.md` AC-P07c by name (mirrors how `permadeath.md` itself cross-references Input/Combate/
Kaiju contracts). Re-run this check if `permadeath.md` Regla 4 changes.
