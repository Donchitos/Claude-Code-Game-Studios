# Quick Design Spec: Login Screen Mochi Mascot + Visual Polish

**Type**: Addition
**System**: Auth & Account UI (Login Screen)
**GDD Reference**: `design/gdd/auth-account.md` (#1); UX spec `design/ux/login-screen.md`
**Date**: 2026-07-17

## Change Summary

Replace the generic `Icons.pets` placeholder in the Login Screen's header zone with the existing Mochi Baby HAPPY sprite as a welcoming mascot, and bring the screen's shape/color language into compliance with Art Bible §3 (UI Shape Grammar) — which the current implementation deviates from (sharp-cornered text fields). No new sprite art is generated; this reuses `design/assets/generated/mochi_baby/spec_compliant/mochi_baby_happy_idle.png` (already "Done" per the asset manifest).

## Motivation

User feedback after running the current build: the login screen "feels too monotonous" (icon-only header, flat sharp-cornered fields, no character presence). This is also the **first screen in the actual Flutter app to wire up any character sprite art** — until now `mochi_baby_*` sprites exist only as generated files, never referenced from `src/`. Landing this here establishes the asset pipeline (repo-root `assets/` → `pubspec.yaml` → `Image.asset`) that later screens (Pet Room, Child Profile Selection) will reuse.

## Design Delta

Current UX spec says (`design/ux/login-screen.md`, Component Inventory):

> | Header | App logo/mascot | Image | Icon nhỏ + tên "PetQuest" | Không | — |

Current implementation (`src/lib/ui/login_screen.dart:114`):

> `const Icon(Icons.pets, size: 48, color: AppColors.lavenderSoft),`

This spec changes both to:

> **Header zone**: static Mochi Baby HAPPY sprite (first frame of `mochi_baby_happy_idle.png`, 96×96dp render size — above the 48px "icon" scale since it is now a mascot illustration, not a system icon) + "PetQuest" title text, unchanged position/order.

Current implementation's text fields use bare `OutlineInputBorder()` (Material default ~4dp corner radius), which violates Art Bible §3 UI Shape Grammar: *"Cards/panels: corner radius 12–20dp... UI echoes world aesthetic — dùng cùng màu palette và round language."*

This spec changes field borders to:

> `OutlineInputBorder(borderRadius: BorderRadius.circular(16))` on both email and password fields — 16dp sits mid-range of the spec's 12–20dp card/panel radius band.

## New Rules / Values

1. **Mascot asset wiring** (new — establishes the pipeline):
   - Copy `design/assets/generated/mochi_baby/spec_compliant/mochi_baby_happy_idle.png` to `src/assets/sprites/mochi_baby_happy_idle.png`. **Correction (verified in browser 2026-07-17)**: a `src/pubspec.yaml` asset entry pointing outside the Flutter project root (`../assets/sprites/`) produces an asset key with a literal `../` in it, which the Flutter web engine 404s on (path can't escape its serving root). Assets must live inside `src/` itself — `src/assets/sprites/` is the runtime asset location, `design/assets/generated/` remains the design-authoring/staging source. This supersedes `directory-structure.md`'s implied repo-root `assets/` for anything Flutter actually loads at runtime.
   - Add to `src/pubspec.yaml`'s `flutter: assets:` section: `- assets/sprites/`
   - Render only the **first frame** of the 4-frame HAPPY strip (216×216px per-frame, 3x baseline) as a static image — this screen does not animate the mascot; that is out of scope (see Affected Systems).
2. **Header layout**: mascot image (96×96dp) replaces the `Icon.pets`, same position (above "PetQuest" title, centered), same 8dp gap before title.
3. **Field shape**: both `TextField`s get `borderRadius: 16` on their `OutlineInputBorder` (email field and password field, matching each other).
4. **Header warmth accent** (new, small): wrap the mascot in a 120×120dp circular soft-fill backdrop using `AppColors.peachGlow` at reduced opacity (`withValues(alpha: 0.4)`), consistent with Art Bible §3 "Hero vs. Supporting Shapes" (circles = hero shape for character focal points) and §4 Per-Area Color Temperature guidance for warm/welcoming contexts. This is purely decorative, non-interactive.

No changes to: form logic, validation, error handling, button behavior, navigation, or any of the screen's existing acceptance criteria — this is presentation-only.

## Affected Systems

| System | Impact | Action Required |
|--------|--------|-----------------|
| `design/ux/login-screen.md` | Component Inventory + Layout Zones header entry updated | Update GDD/UX spec (this quick-spec's own follow-up) |
| `src/pubspec.yaml` | New `assets:` section (first asset entry in the whole Flutter project) | Update — part of this story |
| `src/lib/ui/login_screen.dart` | Header `Icon` → `Image.asset`; both `TextField` borders get radius | Update — part of this story |
| Register Screen (`src/lib/ui/register_screen.dart`) | Mirrors Login Screen per its own design note — will visually diverge until it gets the same treatment | No action required now — flagged as a follow-up, not a regression (register screen is out of this addition's scope) |
| Future screens needing sprite art (Pet Room, etc.) | None yet — but this establishes the `assets/sprites/` + pubspec pattern they'll follow | No action required now |

## Acceptance Criteria

- [ ] Login screen header shows the Mochi HAPPY sprite (static first frame) at 96×96dp instead of `Icons.pets`
- [ ] Mascot sits inside a 120×120dp soft Peach Glow circular backdrop, centered, same position as the old icon
- [ ] Email and password field borders render with 16dp corner radius (visually rounded, not the sharp Material default)
- [ ] `assets/sprites/mochi_baby_happy_idle.png` exists at repo root and is declared in `src/pubspec.yaml`
- [ ] `flutter analyze` clean; existing login screen widget tests still pass unmodified (no behavioral change)
- [ ] Visual check via screenshot: mascot renders correctly (no stretch/distortion, transparent background intact against Cream Ivory)
- [ ] No regression: all existing Acceptance Criteria in `design/ux/login-screen.md` (submit flow, error states, single-flight guard, tap targets) remain unaffected

## GDD Update Required?

**Yes** — `design/ux/login-screen.md`:
- **Component Inventory** table, Header row: change "Icon nhỏ + tên PetQuest" → "Mochi Baby HAPPY sprite (static, 96×96dp) + tên PetQuest"
- **Layout Zones** §1 Header zone: change "logo/mascot nhỏ (không full-bleed)" → "Mochi Baby HAPPY sprite mascot (96×96dp, static frame) trong Peach Glow soft backdrop, không full-bleed"
- **ASCII Wireframe**: `[logo]` → `[Mochi mascot]`
