---
name: feedback-honey-gold-hex-drift
description: Recurring cross-GDD bug pattern where GDD authors invent a plausible-looking gold hex instead of citing the Art Bible's canonical Honey Gold value — always grep for it
metadata:
  type: feedback
---

Across the 21 MVP GDD authoring/review sessions, the same class of bug recurred 4 times:
a GDD author would write a "gold" color for coins/rewards/sparkles using a plausible but
wrong hex (`#FFD93D`, `#FFD700`, generic "gold") instead of the Art Bible's canonical
Honey Gold `#FFD060` (Section 4). Found in `seed-buffer.md`, `pet-equipment.md`,
`gacha-loot.md`, `main-navigation-shell.md` — each time by the art-director doing a
Visual/Audio pass, not by the GDD author self-checking.

**Why**: no single GDD author has the full canonical palette memorized, and "gold" has an
obvious-enough default value in most people's head that it doesn't feel worth double-checking
against the source doc. This is a silent-drift risk specifically because the wrong values are
visually close enough not to be caught by eyeballing.

**How to apply**: whenever reviewing a GDD's Visual/Audio Requirements section (or doing a
gate/consistency check), grep the corpus for `#FFD` (and by extension, spot-check the other
canonical hexes: Lavender Soft `#C5A3E0`, Peach Glow `#FFCBA4`, Mint Breeze `#A8E6CF`, Cream
Ivory `#FFFDF0`, Cloud White `#FFFFFF`) rather than trusting prose citations like "(Art Bible
canonical hex)" at face value — the citation itself has been wrong before. A full-corpus grep
of `#FFD` on 2026-07-11 found 11 references, all correctly `#FFD060` — confirms the 4 known
fixes were the complete set as of that date, but re-run this check after any new GDD is
authored rather than assuming it stays clean.
