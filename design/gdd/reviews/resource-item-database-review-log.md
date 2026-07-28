# Review Log — Resource & Item Database

## Review — 2026-07-10 — Verdict: APPROVED (verification pass)
Scope signal: M
Specialists: qa-lead (fresh verification agent, grep-verification per the
project's terminal-cycle discipline — not a full adversarial round)
Blocking items: 0 (1 residual mirror-defect found and fixed in-session) |
Recommended: 0
Summary: All 10 fix areas from the same-day revision VERIFIED with quoted
evidence (tier axis, inert missing_item, Core Rule 9, voxel mapping, field
policy OQ7–12, SWM reciprocity, validation enforcement, staleness sweep,
[assumption] labels, AC quality pass). One residual defect: Edge Case 4
still said "naming both files" after AC3 was harmonized to "entries AND
source files" — the citing location was fixed, the cited one missed (the
known mirror pattern). Patched, re-verified: Edge Case 4 ≡ AC3, no third
divergent restatement (Validating row + AC7 checked). Final call CLEAN.
Bounded staleness hunt (Overview/Summary/Quick-Reference/Edge Cases 2+9)
clean. Status: **APPROVED** (user pre-authorized approve-on-clean).
Prior verdict resolved: Yes (5 decisions + 6 clusters + 1 verification
residue)

## Review — 2026-07-10 — Verdict: NEEDS REVISION
Scope signal: M
Specialists: game-designer, systems-designer, economy-designer, qa-lead
+ creative-director (senior synthesis)
Blocking items: 5 design decisions (Tier A) + 6 mechanical clusters
(Tier B, deduped from 16 raw specialist blockers) | Recommended: ~12
Summary: First full review. Skeleton sound, thin-by-design, correctly
pillar-anchored — but the Foundation schema carries genuine unresolved
CONTRACT decisions other systems will bake against: (A1) single `tier`
int overloaded across two orthogonal Alpha gating systems (Township
prosperity vs Recipe/Blueprint AND-conditions); (A2) `missing_item`
leaves 6 required fields unspecified + hardcodes category
building_material (furniture-retirement desync); (A3) copy-vs-reference
undecided behind AC19 (per-frame query cost); (A4) voxel-world stores
TWO identifiers per cell vs this DB's ONE id namespace — mapping never
stated; (A5) field policy: economy-designer wants base_value/weight
stubbed now, CD adjudicates OQ-track (nullable-later is non-breaking).
Tier B: downstream table stale (GDD predates building-ui/needs-mood/SWM
by one day — Building System listed "Next in design order" though
APPROVED; Needs & Mood + SWM rows missing entirely, violating
bidirectionality); Failed-state "Session ends" contradicts SWM's
terminal boot-HALT; validation checklist omits two declared invariants
(tier ≥ 0, category↔material_family pairing) + the tier-0
≥1-per-family invariant is asserted but unenforced; zero [assumption]
labels on invented tuning values (recurring project provenance defect);
no structured validation-result contract (blocks ~9 ACs as headless
tests); all 22 ACs untagged (Foundation-sibling parity); AC3 vs Edge
Case 4 entries/files mirror mismatch; AC9 conflates MVP logic with
VS-tier Save/Load behavior. qa-lead calibration note: the tag
convention is Foundation-layer parity (4 GDDs), NOT project-universal —
building-system + villager-ai are approved untagged.
Prior verdict resolved: First review

**Post-review revision (same session, 2026-07-10):** all Tier-A decisions
made by the user (all 4 CD-recommended options): (A1) `tier` scoped to
Township's single axis — Recipe & Blueprint Unlocks keys off ids + own
conditions (Core Rule 3 rewritten, Interactions/Dependencies rows split,
schema note, OQ3 narrowed); (A2) `missing_item` FULLY INERT — reserved
non-authorable category `missing` (6th enum), family none, non-stackable,
non-haulable, excluded from ALL listing APIs (Edge Case 1 fully specified,
Core Rules 5+8 updated, AC27); (A3, CD-mechanical) immutability as new
Core Rule 9 (requirement), mechanism → data-architecture ADR, AC19
provisional; (A4) voxel identifier mapping pinned — block-type = DB `id`,
material identifier = `material_family`, no second namespace, no
voxel-world patch needed (opaque-value contract); (A5) field policy =
OQ-track, not stub — OQ7–10 (base_value, weight, footprint, description)
with owners. Tier B: downstream table fully refreshed (Building System
Approved/confirmed, Building UI split+confirmed, SWM + Needs & Mood rows
added); Upstream boot-sequencing dismissal reworded (requirement owned by
SWM, mechanism → ADR); Failed state → TERMINAL boot-HALT (SWM-aligned,
not "Session ends"); Validating checks extended (tier ≥ 0, category↔family
pairing, tier-0 family coverage now BOOT-ENFORCED, reserved-id/ledger
formalized); structured validation-result contract added (unblocks
headless ACs); [assumption] labels on all 4 invented tuning values; Edge
Case 7 warning → silent-expected (anti-noise, AC21 reworked); Cross-Refs
+3. ACs: tags on all (Foundation parity), AC3 entries+files harmonized,
AC4/5/6 sub-cased, AC7 → 3 heterogeneous entries, AC9 split a/b (9b
DEFERRED pending Save/Load), AC13 symmetric, AC17 error-result clarified,
AC18 distinction stated, AC22 provisional-pending-ADR, NEW AC23–29
(negative tier, family pairing, tier-0 coverage, Failed-state contract,
missing_item exclusion, loads-once, advisory palette-distinctness
playtest). New OQ11 (tier-0 free-forever policy) + OQ12 (consumable VS
scheduling, now owned). Propagation sweep grep-VERIFIED — stale wording
survives only as quoted history in revision notes. **Re-review pending**
— run `/design-review design/gdd/resource-item-database.md` in a fresh
session.
