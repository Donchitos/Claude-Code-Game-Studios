---
name: gate-verdict-history
description: Log of AD phase-gate verdicts for this project, with the reasoning that produced them (so future gate calls stay consistent)
metadata:
  type: project
---

**2026-07-11 — AD-PHASE-GATE (Technical Setup → Pre-Production): NOT READY.**
Blockers: (1) `design/art/art-bible.md` does not exist at all — the gate
formally requires Sections 1-4 (Visual Identity Foundation), and only the
lightweight `visual-direction-note.md` exists, which was explicitly scoped as
an interim anchor, not a substitute (no hex values, no material swatch sheet,
insufficient for a vertical slice to build assets against). (2) Same-day
world-scale change (ADR-0014, 2026-07-11: ~100×100 valley → 2000×2000 large
world with chunked mesher + streamed view window + per-height-band vertex
colors) invalidates load-bearing assumptions in the visual-direction-note:
no fog/horizon treatment, no distant-view-readability statement for the
warmth-contrast rule at streaming range, no biome-variation plan for a large
world + distant dungeons, no color mapping for per-height-band vertex
coloring. See [[project-visual-identity]] for full detail.

**Why this is logged:** so a future gate re-check (once the art bible exists)
can verify these specific gaps were closed rather than re-deriving them from
scratch, and so the verdict is traceable to the exact ADR/note versions that
produced it.

**How to apply:** When re-checking this gate, first confirm
`design/art/art-bible.md` exists and its Sections 1-4 explicitly address the
four large-world gaps above before upgrading the verdict past CONCERNS.

**2026-07-11 — AD-PHASE-GATE RE-REVIEW: CONCERNS (not a blocker).**
`design/art/art-bible.md` Sections 1-4 now exist and are genuinely
production-usable (concrete hex tables in §4, measurable shape rules in §3);
all four previously-logged large-world gaps are closed with quotable text:
Horizon Test (§1 Principle 4), fog/horizon distance-keyed treatment (§2.6),
3-biome launch list (§4.4), 4-band height→color table (§4.3). I independently
re-verified the ADR-0014 citations (380m view radius, 2.6s initial window
build — both exact matches to `docs/architecture/adr-0014-...md` lines
61/82) and computed real WCAG contrast ratios rather than trusting the
document's claims: text `#EDE6DA`/bg `#262220` ≈ 12.8:1, Hearth Gold ≈ 8.0:1,
State Orange ≈ 5.1:1, State Blue ≈ 4.6:1 against the panel bg — all clear
A3's 4.5:1/3:1 thresholds with margin.

**Defect found (worth tracking, not blocking):** §2.4 and §2.6 explicitly
reuse the "State Blue" hue (defined in §4.1/4.2 as "Safe / positive /
confirm," matching `building-ui.md`'s "armed tool blue-accented" = safe/
normal state) for the *dungeon-approach/leaving-home fog* — semantically
backwards (safe-color signaling "danger approaching"), and it contradicts
§4.6's own colorblind backup-mechanism claim that "State color never appears
on world terrain... it only ever sits inside UI chrome with icon shape +
label" (fog is world-space atmosphere with no shape/label pairing possible).
Fix is a simple rename (give the fog a distinct "Threshold Cool" hue, not
the literal State-Blue swatch) — should happen before Deep Threshold /
dungeon-approach assets are built, but does not block Pre-Production entry.

**Why this is logged:** so a future session patching §2.4/§2.6, or writing
Sections 5-9 (which will need a dungeon-threshold environment-color spec),
picks up the fix from here instead of re-discovering it, and so the contrast
math/ADR citation check doesn't need to be redone.
