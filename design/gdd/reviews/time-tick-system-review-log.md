# Review Log — Time & Tick System

## Review — 2026-07-10 — Verdict: APPROVED (with patches, applied in-session)
Scope signal: S
Specialists: systems-designer, qa-lead, godot-specialist + creative-director (senior synthesis; Foundation-batch review with scene-world-management, voxel-world, camera-input)
Blocking items: 0 | Recommended: ~7 (all applied)
Summary: The clock design (game_delta formula, drift-free subtract-not-reset
accumulator in _physics_process, max_ticks_per_frame=10 discard cap,
self-owned instead of Engine.time_scale/SceneTree.paused) judged sound.
Patches applied: max_raw_delta clamp folded into the canonical game_delta
formula (was Edge-Cases-only, formula read as unclamped); Consumer caveat
added under the discard cap — "exactly N ticks" invariants downstream hold
only barring a discard event (reciprocal caveat added to
villager-ai-behavior.md's heartbeat clock model, reciprocal OQ added both
sides); physics_ticks_per_second=60 assumption + float64 accumulator note;
AC19–23 added (pause idempotency, pause-survives-warp-change,
accumulator-untouched-by-warp-change, single-global-broadcast, 10k-tick
drift bound). Contract change from the SWM revision absorbed: the
time-warp-reset function is RETIRED (warp persists across transitions);
AC8 replaced accordingly, dependency/cross-ref rows updated. Forbidden
Patterns (SceneTree.paused, Engine.time_scale) registered in
technical-preferences.md.
Prior verdict resolved: First review
