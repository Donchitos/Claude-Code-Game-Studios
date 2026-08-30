# Review Log — permadeath.md

## Review — 2026-08-12 — Verdict: MAJOR REVISION NEEDED
Scope signal: L (trending XL — driven by a cross-document contract pass, not by Permadeath's own size)
Specialists: game-designer, systems-designer, qa-lead, godot-specialist, creative-director (senior synthesis)
Blocking items: 5 | Recommended: 5 | Nice-to-have: 3
Prior verdict resolved: First review

### Summary (creative-director synthesis)
The core loop design is sound and the pillars are well-served in intent, but the
document made a cluster of load-bearing claims about state, data, and ownership it
does not actually control — several provably false against the very Approved GDDs it
depends on. Three silently voided Pilar 2 ("every death yields a relic") or Pilar 1
(death-as-tragedy) at runtime. Root cause: Permadeath is architected as a *thin
orchestration layer* yet repeatedly asserts authority over state it doesn't own
(Héroes' DYING/DEAD lifecycle), data it doesn't produce (relic_quality), and calls it
doesn't make (Guardado's autosave) — and those false claims live in already-Approved
GDDs, so fixing Permadeath in isolation only relocates the contradiction.

### Blocking items (all 5 addressed in this revision)
1. **Payload/relic_quality contradiction** (systems-designer, qa-lead, game-designer —
   3 independent flags). Héroes AC-H12 exposes only D/T/P; Permadeath Rule 1/5 + AC-P02
   assumed relic_quality already in the payload. AC-P01 and AC-P16 Givens were mutually
   unsatisfiable. → **Fix**: decided Héroes computes H4 at the DYING snapshot and includes
   relic_quality in the payload. Updated Overview, Rule 1, AC-P01, AC-P02. Cross-GDD edit
   to Héroes AC-H12 logged as OQ-P6.
2. **Crash during HOLDING → hero stuck in DYING with no relic** (systems-designer,
   game-designer; CD elevated to #1 — save corruption, hardest to detect in production).
   Autosave fires at DYING (before Permadeath gets payload), persisting state=DYING;
   relic only produced at RESOLVED. AC-P18/Héroes AC-H27's "loads as DEAD" was false. →
   **Fix**: new Rule 8b (load-time DYING→DEAD coercion) + Rule 6 now requires the DYING
   autosave to persist the full payload incl. relic_quality. Rewrote crash Edge Case and
   AC-P18. Cross-GDD edits to Héroes/Guardado logged as OQ-P6.
3. **Pause-mechanism ambiguity** (godot-specialist — fresh blocker none of the others
   caught). GDD never said whether "pausa global" = real SceneTree.paused. If so, the
   hero's resolution animation (feeding animation_done) freezes and EVERY death falls to
   the 8s timeout, masking AC-P04's normal path; or consumers can't poll the flag. →
   **Fix**: Rule 4 now mandates cooperative flag-polling, never SceneTree.paused; beat
   node PROCESS_MODE_ALWAYS; hero animation must too. Edge Case corollary + new AC-P07b.
4. **AC-P17 circular/untestable** (qa-lead). "resolves once, doesn't reprocess" named no
   observable. → **Fix**: rewrote — DEAD confirmation invoked exactly once AND Forja
   receive_relic exactly once, even if release fires on multiple ticks.
5. **QUEUED battlefield visual unspecified** (game-designer — Pilar 1 gap). Doc never
   said what a queued dying hero looks like (frozen mid-collapse vs. unwitnessed). →
   **Fix**: Rule 3 + States table — hero holds at collapse threshold, full V-5→V-6 beat
   plays only on entering HOLDING. New AC-P22.

### Recommended (all addressed)
- Autosave-ownership three-way disagreement reconciled (Rule 6 + cross-GDD action list).
- Pilar 3 pacing safeguard added: Rule 8 total-lockout cap + 2 tuning knobs
  (death_hold_total_lockout_cap_s, death_hold_min_compressed_s) + AC-P21.
- AC-P07 now asserts isolation (frozen consumer clock), not just beat progress.
- OQ-P4 downgraded from "settled" to open contract (Temporizador GDD only defines the
  global menu pause, never game_time_paused); crash Edge Case softened accordingly.
- OQ-P5 gains an era-reset design sub-question (does the FIFO queue persist across eras?).

### Nice-to-have (addressed)
- Section B framing tightened (the beat seals/reveals a decision already made at the
  HP-zero snapshot; it is not the deciding instant).
- AC-P09/P11 recategorized Integration → Logic/unit.
- (Left open) Kaiju mid-STRIKING lands an unpaused hit today — already tracked in OQ-P1/AC-P14.

### Outstanding after this revision
Blockers #1 and #2 are specified inside permadeath.md but **not closed at the system
boundary** — they require a cross-GDD contract pass (OQ-P6) re-opening the Approved GDDs
Héroes (AC-H12 payload, crash coercion), Guardado (autosave owner + payload persistence),
and Kaiju (game_time_paused consumption). Likely via /propagate-design-change, coordinated
with the producer. Next action chosen by user: re-review in a fresh session (/clear first).

---

## Review — 2026-08-14 — Verdict: NEEDS REVISION (re-review, then revised same session)
Scope signal: L (fixes are a focused patch, but carry cross-GDD contract growth + a new ADR-adjacent decision)
Specialists: game-designer, systems-designer, qa-lead, godot-specialist, creative-director (senior synthesis)
Blocking items: 4 (new) | Recommended: 5 | Nice-to-have: 1
Prior verdict resolved: **Yes** — all 5 prior blockers (2026-08-12) confirmed genuinely addressed. The 4 new blockers were introduced/left-open by that revision, not carryovers.

### Summary (creative-director synthesis)
The prior payload/crash/pause-mechanism/serialization fixes hold with real rigor — a
strong document. But the revision introduced a tight cluster of NEW blockers, three
touching the pillars the system serves. Not a rewrite; a focused patch. Strongest signal:
Rule 8 compression was hit from three independent angles (math, determinism, dramatic
weight) — highest-priority fix.

### New blocking items (all 4 addressed in this same-session revision)
1. **Pause-menu × DEATH_HOLD** [godot-specialist]. AC-P07b only proved SceneTree.paused
   stays false because Permadeath never sets it — said nothing about Guardado's global pause
   menu (Temporizador AC-T22) firing mid-beat, which could resolve DEAD off-screen. → **Fix**:
   Rule 4 suppresses the pause action during HOLDING (no real engine pause can start); new
   AC-P07c; PU-2/Input updated; hero-animation PROCESS_MODE_ALWAYS requirement hoisted into
   OQ-P6 (was only in an Edge Case). User decision: suppress the menu (beat uninterruptible,
   Pillar 1; only 2-8s).
2. **Formula P1 no minimum margin** [systems-designer]. Legal config (min=4.0, timeout=4.0001)
   gives a sub-frame animation window → every death silently falls to timeout, masking AC-P04.
   → **Fix**: constraint now timeout ≥ min + min_animation_window; new knob
   death_hold_min_animation_window_s (0.5); AC-P08 rewritten to test the margin.
3. **Rule 8 compression broken** [systems-designer ×2 + game-designer]. Cap provably violated
   (4.0+1.2+1.2=6.4 > 6.0), non-deterministic ("se acerca" unquantified), hero_id duration
   favoritism, AND compression hit the LAST/heaviest death (inverting Pillar 1 at its peak).
   → **Fix**: uniform compression — all beats use clamp(cap/N, min_compressed, min_duration),
   cap met by construction, no favoritism (chosen over "protect last death" to preserve PU-3
   anti-editorializing). Load-time feasibility loud-fail (AC-P08b). AC-P21 rewritten with
   regression case; new AC-P21b.
4. **AC-P18 not ownable** [qa-lead]. Coercion runs entirely in Héroes+Guardado. → **Fix**:
   narrowed AC-P18 to Permadeath scope (empty queue, no resume); split coercion into AC-P18-ext,
   relocated to Héroes/Guardado via OQ-P6.

### Recommended (all addressed)
- Force V-6 relic reveal under timeout path (Rule 2 + PV-5 + AC-P06b) [game-designer].
- Signal-push hybrid (game_time_paused_changed) + 4.6 editor spike before OQ-P5 ADR [godot].
- Drop AC-P17's untestable "más en general" clause; add AC-P17b (dequeue-before-invoke no-op);
  trim AC-P07b restatement/unobserved assertion [qa-lead].
- Design note on the no-accelerate-on-retry tradeoff [game-designer].

### Disagreement adjudicated
- Witness "tell" (tremor/glow on QUEUED hero) [game-designer] vs PU-3 understatement. User
  chose NO tell — kept understatement; recorded as a conscious decision in Rule 3.

### Nice-to-have (addressed)
- Combate/Kaiju process_mode flagged as open risk in OQ-P1 rather than assumed [godot].

### Outstanding after this revision
OQ-P6 cross-GDD reconciliation still open by design — B1/B4 + prior payload/crash blockers
require re-opening Approved Héroes/Guardado/Kaiju GDDs (now 5 items incl. the animation
PROCESS_MODE_ALWAYS hoist and AC-P18-ext relocation). Likely /propagate-design-change with
the producer. Next action chosen by user: re-review in a fresh session (/clear first).

---

## Review — 2026-08-14 #2 — Verdict: NEEDS REVISION (re-review, then revised same session)
Scope signal: L (focused patch, but carries cross-GDD contract growth — Datos de Era now a 6th OQ-P6 target)
Specialists: game-designer, systems-designer, qa-lead, godot-specialist, creative-director (senior synthesis)
Blocking items: 3 (new) | Recommended: 4 | Nice-to-have: 1
Prior verdict resolved: **Yes** — all 9 prior blockers (2026-08-12 ×5, 2026-08-14 ×4) confirmed genuinely addressed. The 3 new blockers were introduced/left-open by the prior revision, not carryovers.

### Summary (creative-director synthesis)
Core loop and both prior rounds' fixes hold — a strong document, not a rewrite; a focused cluster.
Highest priority is a regression of last round's OWN fix: uniform compression closed the cap
violation only under simultaneous arrival, not staggered arrival. The N_max read (hit independently
by 3 specialists + main review) is mostly cheap reconciliation but surfaces facets OQ-P6 didn't track.

### New blocking items (all 3 addressed in this same-session revision)
1. **Rule 8 cap still exceeded under staggered arrival** [systems-designer, CD-confirmed]. With DEFAULT
   knobs (min=2.0, cap=9.0, min_compressed=1.2) + N_max=5, staggered arrivals give 2.0+4×1.8=9.2 > cap.
   The "muerte tardía recomputa N" clause (line 52) was the bug. → **Fix**: since Rule 4's game_time_paused
   freezes all game-time damage during HOLDING, no death can join a chain mid-beat — so **N is fixed at
   chain formation** (same-frame multi-kill). Removed the recompute clause; uniform cap/N over fixed N holds
   the cap exactly (load-check now provably sufficient, per-era). Defensive "new chain" path for contract
   violations. New AC-P21c (the exact 9.2 regression config). Preserves round 2's uniform/no-favoritism decision.
   Ties the cap guarantee explicitly to OQ-P1 (Kaiju must honor game_time_paused — no longer cosmetic).
2. **N_max unsourceable + bidirectional-dependency violation** [systems-designer + qa-lead + godot-specialist,
   3-way convergence]. EraDefinition schema (Datos de Era AC-1) has no hero-roster-count field; the dependency
   is absent from both GDDs' tables and systems-index.md; load-order race vs LOADING→LOADED; per-era vs global
   cardinality; AC-P08b mislabeled [Logic/unit] non-blocked. → **Fix**: declared Datos de Era dependency in
   Permadeath's upstream table (⚠️ provisional); cardinality = **per-era, read on era-LOADED signal** (not
   _ready() — closes race); AC-P08b rewritten to inject N_max as a parameter (unit-testable now); new AC-P08c
   (blocked) for real wiring; cross-GDD action #6 + OQ-P6 (field + reverse dependency + systems-index row).
   User decision: per-era, re-validate on LOAD.
3. **PV-2 "art breathes" guarantee silently voids under compression** [game-designer]. → **Fix**: PV-2 now
   states the guarantee is relative to the *effective* floor; under compression it drops to min_compressed
   by design (Pilar 3 wins the rare worst case). User decision: keep the cap (compress), metronome risk logged
   as an explicit playtest metric in Rule 8.

### Recommended (all addressed)
- Metronome differentiation → playtest watch-metric in Rule 8 (can player still name all 3 fallen heroes?) [game-designer].
- No-accelerate-on-retry habituation → concrete signal: suppressed-input attempts correlated with retry count [game-designer].
- 8s silent timeout reads as a hang → non-editorializing "still-alive" cue candidate in timeout Edge Case [game-designer].
- OQ-P5 era-reset → explicit Permadeath.reset_queue() (no passive Godot 4.6 "era changed" hook); fold into 4.6 spike [godot-specialist].

### Disagreement adjudicated
- game-designer's B2 remedy ("legibility floor, let chain exceed cap") vs Rule 8's Pilar 3 pacing purpose.
  Real Pilar 1 vs Pilar 3 tension. User chose KEEP THE CAP (compress); concern kept as playtest metric, remedy downgraded.

### Nice-to-have (addressed)
- Explicit N ≥ 1 assertion added to Rule 8 (guards division-by-zero) [systems-designer].

### Outstanding after this revision
OQ-P6 cross-GDD reconciliation still open by design — now **6 items** (added: Datos de Era hero-roster-count
field + reverse dependency + systems-index row). Requires re-opening Approved/Designed Héroes/Guardado/Kaiju/
Datos de Era GDDs. Likely /propagate-design-change with the producer. Next action chosen by user: re-review
in a fresh session (/clear first).

---

## Review — 2026-08-15 (4th round) — Verdict: NEEDS REVISION (re-review, then revised same session)
Scope signal: M (doc patch) / L (the cross-GDD propagation the doc patch could not close)
Specialists: game-designer, systems-designer, qa-lead, godot-specialist, creative-director (senior synthesis)
Blocking items: 5 (new) | Recommended: 6 | Nice-to-have: 0
Prior verdict resolved: **Yes** — all 12 prior blockers (2026-08-12 ×5, 2026-08-14 ×4, 2026-08-14 #2 ×3)
confirmed genuinely addressed. The 5 new blockers were introduced/left-open by that revision, not carryovers.

### Summary (creative-director synthesis)
Prior rounds' fixes hold. Root cause repeats in a 4th place: Rule 8's total-lockout cap only bounds the
*floors* of a compressed chain, not a beat that falls to the animation-bug timeout path — same failure mode
(asserting a guarantee over wall-clock time Permadeath doesn't fully control) as the payload/crash/pause
issues from rounds 1-3. Two specialists (game-designer, systems-designer) found this independently via
different methods. Verdict: fix what Permadeath owns, then stop re-reviewing this document in isolation —
the remaining risk lives in 4 sibling GDDs (OQ-P6).

### New blocking items (4 addressed in this same-session revision; OQ-P6 explicitly left for propagation)
1. **Rule 8 cap ignores the timeout path** [game-designer + systems-designer, independent convergence]. A
   compressed chain where even one beat falls to the 8s animation-bug timeout can blow the cap 1.7x-4.4x.
   User chose: scope the cap's guarantee to the bug-free path (no formula changes — tightening the timeout
   under compression would reintroduce the sub-frame-window risk AC-P08 was hardened against). New "Alcance
   de la garantía del cap" paragraph in Rule 8 + caveat on AC-P21.
2. **AC-P01/AC-P02/AC-P06b testability gap** [qa-lead]. AC-P01 asserted a payload contract (`relic_quality`)
   that Héroes' real AC-H12 contradicted, without the `(bloqueado)` marker other blocked ACs carry. → Fix:
   AC-P01/AC-P06b marked `(bloqueado)` + Mock Contract Assumption notes, moved to Integration (bloqueado)
   gate row; AC-P02 kept Logic/unit (genuinely fixture-testable) with its own assumption note.
3. **`reset_queue()` softlock gap** [game-designer, elevated by creative-director]. Only fires on era-LOADED;
   a mid-era retry/reload could leave `HOLDING`/`QUEUED` state with input permanently suppressed. → Fix:
   OQ-P5 invariant broadened to "empty at every point the game resumes control from a load," not just eras.
4. **OQ-P5 engine spike only gated the ADR, not Approved** [godot-specialist], despite Rules/ACs already
   treating its assumptions as settled fact (PROCESS_MODE_ALWAYS + game_time_paused). → Fix: spike elevated
   to a hard gate before Approved; scope expanded to cover `Engine.time_scale` interaction.
5. **OQ-P6 cross-GDD reconciliation — still fully unactioned after 3 prior rounds** [qa-lead + creative-director,
   independently re-verified against the actual sibling GDD files, not the doc's own claims]. Not fixable by
   editing permadeath.md alone. → Left explicitly for a follow-up propagation pass (see below).

### Recommended (all addressed)
Float-tolerance caveat on AC-P21's cap claim; MVP defaults only tolerate N_max≤7 (sanity-check flagged);
camera framing during QUEUED/HOLDING flagged as unspecified (cross-GDD candidate to Héroes); PROCESS_MODE_ALWAYS
vs. Engine.time_scale conflation flagged; PU-2 mouse-focus path under 4.6 dual-focus routing flagged; habituation
playtest metric flagged as ownerless (needs an Input logging path that doesn't exist).

### Outstanding after this revision
OQ-P6 (6 items) not closable inside permadeath.md — resolved in a follow-up session the same day, see below.

---

## Cross-GDD Reconciliation — 2026-08-16 (OQ-P6, all 6 items)

`/propagate-design-change` was invoked but didn't fit: `design/gdd/` has no git history (untracked) to diff,
and `docs/architecture/` has no ADRs yet — both of that skill's preconditions were absent. Resolved instead by
editing the 4 sibling GDDs directly, one at a time, each shown as a diff and approved before writing (same
draft → approval → write protocol as everywhere else in this project).

1. **Sistema de Héroes** (`design/gdd/sistema-de-heroes.md`): AC-H12 now exposes `relic_quality` (evaluated via
   H4 at the snapshot frame); AC-H26 now requires the full death payload marked "pending seal"; new AC-H27c
   implements the DYING→DEAD crash-coercion + relic-forging contract (AC-P18-ext lives here, not in Permadeath);
   V-5/V-6 section documents the `PROCESS_MODE_ALWAYS` requirement for the resolution-animation node and its
   particle/audio/tween children. Does not reopen the Approved verdict (additive, no prior decision contradicted).
2. **Guardado/Persistencia** (`design/gdd/guardado-persistencia.md`): fixed the same autosave-trigger
   misattribution in 6 places (Rule 1, Interactions table, provisional-GDD note, a design note, Dependencies
   table, AC-01/AC-01b) — Sistema de Héroes triggers the autosave at `DYING` (AC-H26), never Permadeath.
3. **Encuentro con Kaiju** (`design/gdd/encuentro-con-kaiju.md`): new Core Rule 11 — the kaiju's entire intention
   cycle (SEEKING/TELEGRAPHING/STRIKING/STAGGERED, all its internal clocks) freezes cooperatively while
   `game_time_paused=true`, read via polling, never `SceneTree.paused`. New AC-K89. Closes OQ-P1.
4. **Datos de Era/Civilización** (`design/gdd/datos-de-era-civilizacion.md`): `EraDefinition` gains
   `get_hero_roster_count()` — a derived accessor computed from `unit_roster`'s hero portion at `LOADED` time,
   not a new authored field (avoids a second source of truth that could desync from the real roster). New
   AC-1b. Permadeath added to both the Interactions and Dependencies tables.

Permadeath itself was then updated to close the loop: OQ-P1 and OQ-P6 marked ✅ resolved; AC-P01, AC-P08c, and
AC-P14 reclassified from `(bloqueado)` back to normal Integration (contract confirmed, pending only
implementation, not design) — moved out of the "Integration (bloqueado)" gate row, which now holds only
AC-P06b (blocked on OQ-P2, unrelated) and AC-P16 (blocked on Forja de Legado, which still has no GDD).
`systems-index.md`'s Permadeath row updated to match.

### Outstanding
Not yet Approved. Remaining before that gate: the OQ-P5 engine spike (now a hard gate, not yet run), OQ-P2
(exact `animation_done`/force-reveal signal shape), OQ-P3/AC-P16 (Forja de Legado has no GDD yet), and a
formal re-review in a clean session to confirm the reconciliation pass didn't introduce anything new. Next
action: user's call — likely `/clear` then `/design-review design/gdd/permadeath.md` once ready.
