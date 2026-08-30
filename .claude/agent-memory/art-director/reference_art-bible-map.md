---
name: reference-art-bible-map
description: Location and section map of the project's art bible — check before any visual-direction consultation to cite correct section numbers.
metadata:
  type: reference
---

`design/art/art-bible.md` — "What the Gods Left Behind" (Gótico Pixelado Sagrado), ~485 lines, 9 sections, v1.0 as of 2026-07-23, owned by art-director.

Section map (verify line numbers still match before citing — file may grow):
1. Visual Identity Statement — Principle A (Legado es Luz, gold reserved for permadeath-derived), Principle B (scale), Principle C (camera holds gaze on death), reference anchors (Blasphemous 2 / Dark Souls / Hollow Knight)
2. Mood & Atmosphere — per game-state (Preparación, Clímax, Muerte/Sacrificio, Salón Conmemorativo, Transición de Era, Victoria) — 2.2 established the "screen-edge stained-glass crack" motif for kaiju attacks, reusable for any kaiju-telegraph HUD work
3. Shape Language — 3.1 archetypal silhouettes (tropa=vertical astilla uniform, héroe=silueta interrumpida via ONE asymmetric element, kaiju=low/wide horizon-breaker, esbirros=kaiju-family angular flattened), 3.3 UI is fully diegetic (no neutral HUD layer, tradeoff noted), 3.4 eye-priority hierarchy (kaiju > hero > troops > environment)
4. Color System — 4.1 the 7-color palette (6 muted + Oro Reliquia `#F4C542`/`#FFE9A8` exclusive to permadeath-derived elements), 4.2 semantic assignments (Sangre Vieja=active cost/health, Acero Violeta-Ceniza=threat/kaiju/dread, Hueso=living player ally, gold=earned/legendary only), 4.4 UI palette (health bar Hueso→Sangre Vieja drain, selection outline = Acero thin contour no fill, ability-ready gold ONLY for relic-derived abilities), 4.5 colorblind-safety table (gold's redundant channels: bloom/pulse + particle VFX + frame-shape change — never hue alone)
7. UI/HUD Visual Direction — 7.1 two-track typography (Tallada display / Clara numeric — numerics MUST use Clara during combat), 7.2 icon tiers (base=flat silhouette, relic-derived=gold leaded-line detail inside silhouette, panel=full stained-glass, status/debuff=flat max-contrast never gold), 7.3 animation feel (glass/wood-metal physicality, no elastic/bounce easing — reads as arcade), 7.4 frame ornamentation tiers 0-3 (0=no frame/cool marker, 1=simple leaded rect+Hueso ready-edge, 2=leaded+corner tracery+gold only when ready, 3=full stained-glass saturated gold, reserved for Memorial/relic panels only — no 5th tier allowed), 7.5 UX mitigations already agreed (threshold-triggered diegetic events for multi-hero health reading in Climax, distinct rare chime for relic-ability-ready vs. base-ability, opt-in high-contrast accessibility toggle deferred to design/ux/accessibility-requirements.md)
5-6, 8-9: character design direction, environment language, asset standards (naming `[category]_[name]_[variant]_[size]`, Aseprite→lossless PNG, Nearest filtering, no mipmaps on pixel sprites), reference direction (Blasphemous 2/Dark Souls/Hollow Knight/Shadow of Colossus/Godzilla/Pacific Rim — each with explicit "extract this, avoid that" pairs, see 9.7-9.8 anti-redundancy table)

Useful for: any UI/HUD, VFX, or character-visual consultation on this project — the 7-color palette and 7.4 frame-tier system in particular recur across almost every HUD-adjacent design question.
