---
name: honey-gold-hex-inconsistency
description: RESOLVED 2026-07-06 — Honey Gold hex drift (#FFD060 vs #FFD93D vs #FFD700) found across 7 GDD files, fixed, and confirmed clean by /consistency-check.
metadata:
  type: project
---

**Status: RESOLVED.** Kept for the pattern lesson, not as an open item.

Discovered while drafting Task Management UI (#19)'s Visual/Audio Requirements (2026-07-04+ session): the Art Bible (`design/art/art-bible.md`, Section 4 Color System) defines **Honey Gold = `#FFD060`**. But `design/gdd/seed-buffer.md`'s Visual/Audio Requirements (Seed Bloom animation spec, "Xu particles") uses **`#FFD93D`** for the same named color.

**Why it matters**: Honey Gold is the canonical "reward/coin" color referenced across multiple GDDs (Seed Buffer, Task Management UI, presumably Shop System and Currency System). A silent hex drift here means implementers could end up with two slightly different golds in the shipped app depending which doc's spec they followed.

**How to apply**: When drafting or reviewing any GDD that names "Honey Gold," use the Art Bible's `#FFD060` as canonical unless told otherwise, and flag the seed-buffer.md discrepancy for correction next time that doc is touched (design-review, consistency-check, or asset-spec pass). This is a "found it, didn't fix it" note — not yet resolved as of this memory's creation.

**Update (2026-07-05, drafting Pet Room Screen UI #18)**: A third gold hex found — `pet-equipment.md`'s SHOWING_OFF sparkle spec uses `#FFD700` ("vàng") for `body_outfit`/`hat` sparkles, distinct from both `#FFD060` (art bible) and `#FFD93D` (seed-buffer.md). A repo-wide grep for these three hexes now hits 7 files (`task-management-ui.md`, `main-navigation-shell.md`, `seed-buffer.md`, `pet-state-machine.md`, `art-bible.md`, `pet-equipment.md`, `gacha-loot.md`). This is spreading, not shrinking — worth escalating to a dedicated `/consistency-check` pass rather than continuing to flag-and-defer per-GDD.
