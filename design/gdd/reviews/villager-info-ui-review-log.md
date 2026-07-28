# Review Log: Villager Info UI

Target: `design/gdd/villager-info-ui.md`

## Review — 2026-07-11 — Verdict: NEEDS REVISION → revised → APPROVED
Scope signal: S
Specialists: game-designer, systems-designer, ai-programmer, ux-designer, godot-specialist, ui-programmer, qa-lead + creative-director (synthesis) + fresh qa-lead verification pass (14 points)
Blocking items: 8 | Recommended: 6
Summary: The last unreviewed MVP GDD. Every finding was contract-alignment
against siblings this small mirror-doc predates (Building UI's rebuilt
model, Villager AI's post-review state table), not architecture. Sharpest:
"five AI states" was factually SIX (Breather added by villager-ai's own
review; its UI Requirements text was stale — upstream citation drift
inherited here); the no-bed distress flag was silently dropped (3-way);
the why-string precedence was consumed "verbatim" but never architected
(3-way); the HUD-hover-suppression seam was ambiguous enough that three
specialists derived three different failure modes (CD adjudicated
ui-programmer's dissent as substantially right: authorable + reciprocal
Rule 11 generalization). Same signal-vs-poll contradiction class as
Building UI round 1.
Prior verdict resolved: First review

### User rulings (2)
- **No-bed flag: FOLD into ground-sleeping** — Rule 12 has no
  awake-no-bed limbo; bedlessness surfaces as ground-sleeping exactly
  when it matters; the why-string still names the cause verbatim. Icon
  for a currently-fine bedless villager would violate "only genuine
  distress earns an icon." Reciprocal villager-ai flag-list fix + AC25
  (negative half).
- **Keyboard selection: STATED EXEMPTION + OQ** — 3D spatial targeting
  is a different class from HUD chrome; MVP ships mouse-only as an
  explicit, rationaled exemption in Rule 1; the keyboard path
  (select-cycle / focus-nearest-distressed) is committed to the VS
  revision with the roster view (OQ1).

### Fixes applied (all verified — CLEAN after 2 residual mirror defects)
1. Six-state mapping (Rule 2: Deciding→"Thinking" for completeness,
   Breather→"Taking a break"); AC6 rewritten; reciprocal villager-ai UI
   Requirements correction. Grep-swept: no surviving "five".
2. No-bed fold (Rule 4 + rationale + AC25 + reciprocal).
3. HUD-hover gate (Rule 1 clause + AC21) + reciprocal building-ui Rule
   11 generalization ("the flag is the SHARED gate for EVERY world-pick
   consumer").
4. Esc routing two-step (Rule 1 + AC22) — residual defect found by
   verification: the Esc-releases-focus semantic wasn't defined in
   building-ui Rule 9b → reciprocal clause added → re-verified.
5. State-over-events (Rule 3 rewrite: re-read state per update, signals
   = wake hints; AC17 now valid) — residual mirror defect: Overview
   still said "via their signals" → patched → re-verified.
6. Why-slot precedence (new Rule 2b: one slot, Needs Core Rule 11
   consumed whole — distress > need-why > structural, strongest-drain +
   schema-order tiebreak; distress flag = icon companion) + AC23/24.
7. Raycast separation + epsilon (Edge Case 2: dedicated villager
   collision layer, parametric-distance merge, pick_tie_epsilon
   [assumption]; EC3 processing-order tiebreak; AC26; Tuning Knobs
   acknowledges the constant; Building's raycast ignores villager layer).
8. Minors: colorblind SHAPE+label mechanism for mood/distress icons;
   pre-click hover affordance required; one-manager icon architecture
   note; selection-handle identity [assumption] (OQ4); OQ6 proactive
   distress alerting at scale; OQ7 flicker hold-time; UX-flag
   minimal-by-design guidance; all 5 upstream rows → Approved (3rd
   recurrence of the staleness class, grep-swept).

### Verification pass
Fresh qa-lead, 14 points + AC21-26 citation check: 12 VERIFIED + 2
mirror defects (Esc/Rule 9b one-sided commitment; Overview signal
phrasing) → patched → re-verified CLEAN. ACs now 26 (17+6 blocking /
3 advisory).

**Villager Info UI = APPROVED 2026-07-11** (user pre-authorized
approve-on-clean via the review path decision).

## 🎉 MILESTONE: ALL 11 MVP GDDs APPROVED (2026-07-11)
voxel-world · camera-input · time-tick · scene-world-management ·
resource-item-database · building-system · villager-ai-behavior ·
needs-mood · build-validation-navigability · building-ui ·
villager-info-ui. Next: /gate-check systems-design.
