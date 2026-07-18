# Accessibility Requirements

> **Status**: Committed baseline (proposed 2026-07-08) — review & adjust as needed
> **Author**: derived from `technical-preferences.md` (Input & Platform) + `design/art/art-bible.md` (Section 4 Color System, Colorblind Safety) + the 6–10yo target audience
> **Committed Tier**: **Kid-Touch Baseline** (WCAG 2.1 AA-aligned where applicable to a touch game for children, plus child-specific ergonomics)

---

## Why a committed tier (and why this one)

The gate requires a *committed* accessibility tier — "even Basic is acceptable; undefined is not." PetQuest's audience (children ~6–10) and platform (touch-only mobile) make several accessibility requirements non-optional ergonomics rather than nice-to-haves: large tap targets, no color-only meaning, no timing pressure, and simple language. So the committed tier is **"Kid-Touch Baseline"** — WCAG 2.1 AA as the reference standard for the things that apply to a canvas+widget touch game, plus child-specific rules the Art Bible and tech-prefs already imply. This is a baseline the team can *raise* (e.g., add screen-reader support, dyslexia-friendly fonts) but should not drop below.

This document is derived from decisions already made elsewhere — it does not invent new constraints, it consolidates and commits them:
- **`technical-preferences.md` → Input & Platform**: touch-only, no hover, minimum 48×48dp tap targets (Material).
- **`design/art/art-bible.md` → Section 4 + Colorblind Safety**: no pure red/black in primary UI; warning/normal distinctions use an icon, never red/green alone.
- **Per-system GDDs**: ≥80×80dp hit-area for the pet sprite (pet-interaction #14 / pet-room #18); ✓/✕ icons on approve/reject (parent-dashboard #21); no countdown/urgency timers (time-decay #2).

---

## Committed Requirements (the baseline)

### 1. Touch target size
- **Minimum 48×48dp** for every interactive widget (Material guideline; tech-prefs).
- **≥80×80dp** for the primary play target (Mochi sprite hit-area), regardless of visual sprite size — a child's tap is less precise (pet-interaction #14 Core Rule 7, delegated to pet-room #18).
- Adequate spacing between adjacent targets so a mis-tap doesn't hit the wrong control (esp. Shop item cards, task cards, numpad).

### 2. Color is never the only signal
- **No information conveyed by color alone** (WCAG 1.4.1). Every state that uses color also uses an icon or shape: approve/reject show ✓/✕ (parent-dashboard #21), warnings use ⚠️ (Art Bible Colorblind Safety).
- **No pure red or pure black in primary UI** (Art Bible Section 4). "Sensitive" actions (Reset PIN, Reject) use Lavender Soft accent + an icon, not red — this is both a brand rule and a colorblind-safety rule.
- Energy bar and mood indicator communicate via fill level + mood icon, never red-when-low (time-decay #2 Visual Requirements).

### 3. Text legibility
- **Minimum body text 14sp**; labels no smaller than 11sp (nav labels) — and only where paired with an icon.
- **Contrast**: text on its background meets **WCAG AA 4.5:1** (normal text) / **3:1** (large text ≥18pt/14pt-bold).

  ⚠️ **Contrast audit RUN 2026-07-13** (real WCAG relative-luminance calculation across all 4 text roles × 7 background colors from Art Bible §4, `design/art/art-bible.md`; two-gate-overdue item from `/gate-check` 2026-07-13 Pre-Production→Production exit-criteria #3). Full results:

  | Text role | Hex | Passes 4.5:1 against | Fails against |
  |---|---|---|---|
  | Primary text (warm dark brown) | `#3D2B1F` | **All 7 backgrounds** (ratios 6.2–13.4) | None |
  | Secondary text (warm medium brown) | `#9B7060` | None at 4.5:1; passes 3:1 (large text) only on Cream Ivory (4.21) and Cloud White (4.30) | Mint Breeze, Peach Glow, Petal Pink, Lavender Soft, Honey Gold — even at large-text 3:1 |
  | Disabled text (warm light brown) | `#C0A898` | None | **All 7 backgrounds**, even at 3:1 (ratios 1.04–2.26) |
  | On-color text (white, for buttons) | `#FFFFFF` | None | **All 7 backgrounds**, even at 3:1 (ratios 1.00–2.17) — this is the worst finding: white text is not usable directly on ANY current palette color |

  **Findings and resolution**:
  1. **Primary text is the only role safe on the pastel palette as-is.** It remains the default for all body/label text on any pastel background.
  2. ✅ **RESOLVED 2026-07-13**: On-color (white) button text failed universally — no pastel background in the 7-color palette is dark/saturated enough to host white text at any WCAG tier. **Decision (user, 2026-07-13)**: option (a) — on-color buttons always use Primary text (`#3D2B1F`), never white, over any current palette fill. Applied to Art Bible §"Text Colors" (the "On-color text (buttons) = White" row struck through and replaced) and to the one real GDD call site that hedged this (`task-management-ui.md` line ~162, previously "text đổi trắng hoặc dark-brown tùy độ tương phản" — now a firm rule, always Primary text).
  3. ✅ **RESOLVED 2026-07-14**: Secondary and Disabled text roles were unsafe on every background. Both darkened (worst-case-background contrast ratio, i.e. checked against the single hardest of the 7 backgrounds, not an average):
     - Secondary: `#9B7060` (worst-case 1.99:1) → **`#553826`** (worst-case 4.89:1) — passes AA normal-text 4.5:1 on all 7 backgrounds.
     - Disabled: `#C0A898` (worst-case 1.04:1) → **`#644A3C`** (worst-case 3.75:1) — passes AA large-text/UI-component 3:1 on all 7 backgrounds (WCAG 1.4.3 exempts inactive controls from the stricter 4.5:1, but this project's Disabled role is sometimes informational, so it was still raised to a real, legible minimum rather than left at the exemption floor).
     - Visual hierarchy preserved: Primary (`#3D2B1F`, darkest) > Secondary (`#553826`) > Disabled (`#644A3C`, lightest) — same ordering as before, just no longer light enough to fail contrast.
     - Applied to Art Bible §"Text Colors" and the one other real call site found (`shop-reward-ui.md`'s Chest badge muted state, which explicitly borrowed "Art Bible's canonical Disabled-text hex" — updated to the new value for consistency, 3 occurrences).

  **Audit scope note**: this pass (2026-07-13 + 2026-07-14) resolved all 3 findings from the original contrast audit. No further open items from this audit.
- No raw numbers shown to the child where a visual suffices (energy = bar, not "37/100") — reduces reading load for early readers.

### 4. No timing pressure (child-cognitive)
- **No countdown timers, no "hurry" states, no auto-dismissing content the child must act on** (time-decay #2 anti-pattern; Pillar design). The one lockout timer (PIN 60s) is a *cool-down the child waits out*, not a task deadline, and shows a clear countdown.
- Triggered animations are short and never block required input beyond their brief duration (pet-state-machine #7 durations 1–3s).

### 5. Language & comprehension
- UI copy uses simple, concrete language appropriate for ~6–10yo readers (and assumes some children can't read fluently — hence icon+label pairing everywhere).
- Quest framing ("Nạp trí tuệ cho Mochi") supports comprehension; it must not replace a clear action label.

### 6. Motion
- **Reduced-motion support**: honor the OS "Reduce Motion" setting — the ceremony/celebration animations (Chest Open, level-up, Mochi bounce) must have a reduced-motion variant (shortened/cross-fade instead of large scale/spin) to avoid vestibular discomfort. (New requirement flagged for the animation-owning ADRs/specs.)

### 7. Interaction robustness
- **No hover-only interactions** (touch platform — tech-prefs).
- Double-tap / rapid-tap must never cause a destructive double-action — single-flight guards are already required (Shop purchase ADR-0008; Gacha/Approve double-tap guards). This is an accessibility concern too: children tap repeatedly.
- All destructive/sensitive actions (delete profile, reset PIN, spend) require a confirm step (auth #1, parent-dashboard #21).

---

## Explicitly OUT of the MVP baseline (deferred, not forgotten)

These are real accessibility features intentionally **not** committed for MVP — listed so the omission is a decision, not an oversight:
- **Full screen-reader (TalkBack/VoiceOver) support** of the Flame canvas — the pet canvas is not screen-reader-navigable in MVP. The Flutter widget chrome (buttons, lists) inherits Flutter's default semantics, but no custom `Semantics` authoring is committed. *Defer to Alpha; revisit if targeting low-vision users.*
- **Dynamic Type / OS font-scaling** beyond layout not breaking at +30% — full reflow at extreme scales is not guaranteed for MVP.
- **Switch-access / external assistive input** — touch-only.
- **Localization of accessibility copy** — MVP is Vietnamese-first; see each UX spec's Localization section.

---

## How this tier is enforced

- **Per-screen UX specs** (`design/ux/*.md`): each spec's Accessibility section must show it meets these baseline items for that screen; `/ux-review` checks against this file.
- **Interaction pattern library** (`design/ux/interaction-patterns.md`): patterns bake in the target-size, color-independence, and confirm-on-destructive rules so screens inherit them.
- **`/gate-check`**: this file existing with a committed tier satisfies the pre-production gate's accessibility artifact; the quality check verifies key-screen specs address the tier.

## Open Questions (for the team to confirm/adjust)
- Confirm the committed tier name/scope ("Kid-Touch Baseline") — or formally adopt "WCAG 2.1 AA, touch subset" as the label.
- Reduced-motion (item 6) is newly flagged here — confirm the animation-owning specs (Pet Room, Shop/Reward ceremony, Pet Leveling) will each define a reduced-motion variant.
- Is any screen-reader support (even widget-layer only) wanted for MVP, or firmly Alpha?
- ~~Contrast audit of the pastel palette against 4.5:1~~ — **DONE 2026-07-13, all findings resolved 2026-07-14**, see "Text legibility" section above. On-color/white button text and Secondary/Disabled text roles were all darkened/reassigned to real WCAG-passing values.
