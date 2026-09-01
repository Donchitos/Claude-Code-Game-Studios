# Review Log — Sistema de Input (`design/gdd/input.md`)

Revision history for `/design-review` runs on the Input GDD. Newest entries first.

## Review — 2026-08-19 — Verdict: NEEDS REVISION (blockers applied same session; pending re-review)
Scope signal: L (bordering XL — Foundation doc, 5 formulas, 5+ downstream dependents, likely needs 1 ADR + a camera-zoom-ownership decision)
Specialists: game-designer, systems-designer, qa-lead, performance-analyst, godot-specialist, ux-designer + creative-director (senior synthesis)
Blocking items: 7 | Recommended: ~12 (several folded in same session)

Summary: First formal review. Architecture judged sound (abstraction layer, single-active-context state machine, intention-only signals) but not implementable-as-written: a literal implementation would (a) fire an engine pause during DEATH_HOLD, violating permadeath AC-P07c; (b) build a zoom system failing its own AC 13/AC 24; (c) chase an unmeasurable perf gate (AC 22). Creative-director's through-line: the doc claims Pilar 1 but contradicted it at the exact moment Pilar 1 matters most (a hero's death). Key adjudication: KEEP the DEATH_HOLD input discard (replaying a pre-death order violates the fiction) — the *silence* was the defect, not the discard. Pilar 1 guarantee reframed from an absolute single-doc claim to a distributed cross-system invariant with named owners.

7 blockers resolved this session:
1. Gamepad-disconnect × DEATH_HOLD — carved exception + AC 17b; named `joy_connection_changed` + GUID identity.
2. Zoom direction — locked scroll-up = zoom-in → scalar toward 0.5; split `±` into two expressions; fixed AC 13, added 13a/13b; Camera2D mapping handed to camera GDD (OQ-INPUT-2).
3. DEATH_HOLD lockout feedback — `input_lockout_active` + firm cursor-hide + art-bible 7.3 cross-ref; AC 15b.
4. Pilar 1 distributed invariant — Player Fantasy reworded; frame-order race → OQ-INPUT-1.
5. AC 22 — reclassified on-device Integration/Performance (`tests/performance/input/`), harness specified; frame-budget gap → OQ-INPUT-4.
6. Formulas — `stick_dead_zone` remap expression + `drag_threshold_px` DPI-scaling formula added; `drag_threshold_px` added to accessibility knobs.
7. Bidirectionality — Input registered in ui-hud.md, reliquias-bendiciones.md, and systems-index (enumeration + Dependency Map); stale provisional notes refreshed.

Also folded in: `current_context` enforcement pattern (OQ-INPUT-5 ADR), central per-context gating, dual-focus scope correction, device-switch debounce (AC 5c), first-launch platform default (AC 5b), "acción en curso" generalization, classification of AC 19/20/21.

Open contracts carried forward: OQ-INPUT-1 (Pilar 1 invariant / frame order — ADR candidate), OQ-INPUT-2 (Camera2D.zoom mapping), OQ-INPUT-3 (no-gamepad flow), OQ-INPUT-4 (frame-time budget), OQ-INPUT-5 (current_context ADR).

Prior verdict resolved: First review.
Next: re-review in a clean session (`/clear` then `/design-review design/gdd/input.md`) to confirm the 7 fixes hold and the distributed-invariant reframing introduced no new cross-GDD issues.
