---
name: shop-reward-ui-muted-badge-wording
description: RESOLVED 2026-07-06 — shop-reward-ui.md Core Rule 3 now reads "warm neutral #C0A898" (not "xám nhạt"), reconciled with Visual/Audio Requirements before merge.
metadata:
  type: project
---

**Status: RESOLVED.** Current file text (Core Rule 3) already reads "desaturate về warm neutral `#C0A898`... KHÔNG dùng grey thuần" — the wording/hex mismatch this memory flagged no longer exists. Kept for the pattern lesson: [[project_honey-gold-hex-inconsistency]] — loose color wording drifting from Art Bible canonical hex was a recurring risk this session; both instances were caught and closed via the same `/consistency-check` pass (confirmed 18/18 registry entries clean, 11/11 `#FFD` hits correct, per shop-reward-ui.md Open Question #3).

Discovered while drafting Shop & Reward UI (#20)'s Visual/Audio Requirements (2026-07-06 session). `design/gdd/shop-reward-ui.md` Core Rule 3 (chest badge tap when `chestCount == 0`) currently reads: "badge hiển thị trạng thái muted (không pulse, **màu xám nhạt**)" — i.e. describes the muted color as literal light grey.

That contradicts Art Bible's cross-cutting rule that nothing in primary UI uses pure black/grey — all disabled/dark/shadow elements use warm-brown tones instead (`design/art/art-bible.md` Section 4: "Không dùng `#000000` thuần — tất cả shadow và dark elements dùng warm dark brown"; Text Colors table already defines a canonical **Disabled text = warm light brown `#C0A898`** for exactly this kind of muted-state use).

My Visual/Audio Requirements contribution for #20 specs the muted chest badge using `#C0A898` (not grey) for fill/icon-outline, consistent with how #13's own "Còn thiếu"/"Đã có" muted states already desaturate toward palette neutrals rather than introducing grey.

**How to apply**: When #20's Visual/Audio Requirements gets merged into the file, flag that Core Rule 3's "màu xám nhạt" phrase should be updated to reference `#C0A898` explicitly (or at minimum, "xám nhạt" should be understood as this warm hue, not literal cool grey) so Core Rules and Visual/Audio Requirements don't silently disagree on the actual color. Related: [[project_honey-gold-hex-inconsistency]] — same category of "loose color wording drifting from Art Bible canonical hex" recurring across this project's GDDs; worth folding into the same future `/consistency-check` pass.
