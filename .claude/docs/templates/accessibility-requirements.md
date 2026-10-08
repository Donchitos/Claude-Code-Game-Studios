# Accessibility Requirements: [Game Title]

> Authoring guidance: .claude/docs/templates/guidance/accessibility-requirements-guide.md (load per-section as you author — do not read entirely).

> **Status**: Draft | Committed | Audited | Certified
> **Author**: [user + ux-designer]
> **Last Updated**: [Date]
> **Accessibility Tier Target**: [Basic / Standard / Comprehensive / Exemplary]
> **Platform(s)**: [PC / Xbox / PlayStation 5 / Nintendo Switch / iOS / Android]
> **External Standards Targeted**:
> - WCAG 2.1 Level [A / AA / AAA]
> - AbleGamers CVAA Guidelines
> - Xbox Accessibility Guidelines (XAG) [Yes / No / Partial]
> - PlayStation Accessibility (Sony Guidelines) [Yes / No / Partial]
> - Apple / Google Accessibility Guidelines [Yes / No / N/A — mobile only]
> **Accessibility Consultant**: [Name and organization, or "None engaged"]
> **Linked Documents**: `design/gdd/systems-index.md`, `design/ux/interaction-patterns.md`

> **Why this document exists**: Per-screen accessibility annotations belong in
> UX specs. This document captures the project-wide accessibility commitments,
> the feature matrix across all systems, the test plan, and the audit history.
> It is created once during Technical Setup by the UX designer with
> `/ux-design accessibility` — you pick the tier, against the criteria
> accessibility-specialist sets and audits against — then updated as features
> are added and audits are completed. If a feature conflicts with a commitment
> made here, this document wins — change the feature, not the commitment,
> unless the producer approves a formal revision.
>
> **When to update**: After each `/gate-check` pass, after any accessibility
> audit, and whenever a new game system is added to `systems-index.md`.

---

## Accessibility Tier Definition

### Tier Definitions

| Tier | Core Commitment | Typical Effort |
|------|----------------|----------------|
| **Basic** | Critical player-facing text is readable at standard resolution. No feature requires color discrimination alone. Volume controls exist for music, SFX, and voice independently. The game is completable without photosensitivity risk. | Low — primarily design constraints |
| **Standard** | All of Basic, plus: full input remapping on all platforms, subtitle support with speaker identification, adjustable text size, at least one colorblind mode, and no timed input that cannot be extended or toggled. | Medium — requires dedicated implementation work |
| **Comprehensive** | All of Standard, plus: screen reader support for menus, mono audio option, difficulty assist modes, HUD element repositioning, reduced motion mode, and visual indicators for all gameplay-critical audio. | High — requires platform API integration and significant UI architecture |
| **Exemplary** | All of Comprehensive, plus: full subtitle customization (font, size, color, background, position), high contrast mode, cognitive load assist tools, tactile/haptic alternatives for all audio-only cues, and external third-party accessibility audit. | Very High — requires dedicated accessibility budget and specialist consultation |

### This Project's Commitment

**Target Tier**: [Basic / Standard / Comprehensive / Exemplary]

**Rationale**: [3-5 sentences justifying the tier choice — genre barriers, target audience, platform requirements, team capacity, cost of dropping a tier. See guide for the reasoning checklist and a worked example.]

**Features explicitly in scope (beyond tier baseline)**:
- [Feature elevated above the tier baseline + why]

**Features explicitly out of scope**:
- [Feature excluded + why — must also appear in Known Intentional Limitations]

---

## Visual Accessibility

| Feature | Target Tier | Scope | Status | Implementation Notes |
|---------|-------------|-------|--------|---------------------|
| Minimum text size — menu UI | Standard | All menu screens | Not Started | 24px minimum at 1080p. At 4K, scale proportionally. Reference: WCAG 2.1 SC 1.4.4 requires text resizable to 200% without loss of content. |
| Minimum text size — subtitles | Standard | All voiced/captioned content | Not Started | 32px minimum at 1080p. Players viewing on TV at 3m are the constraint. |
| Minimum text size — HUD | Standard | In-game HUD | Not Started | 20px minimum for critical information (health, ammo, objective). Non-critical HUD elements may be smaller. |
| Text contrast — UI text on backgrounds | Standard | All UI text | Not Started | Minimum 4.5:1 ratio for body text (WCAG AA). 3:1 for large text (18px+ or 14px bold). Test with automated contrast checker on final color values. |
| Text contrast — subtitles | Standard | Subtitle display | Not Started | Minimum 7:1 ratio (WCAG AAA) for subtitles — players read them quickly and cannot control background. Use drop shadow or opaque background box by default. |
| Colorblind mode — Protanopia | Standard | All color-coded gameplay | Not Started | Red-green — affects ~6% of men. Primary concern: health bars, enemy indicators, map markers. Shift red signals to orange/yellow; shift green signals to teal. |
| Colorblind mode — Deuteranopia | Standard | All color-coded gameplay | Not Started | Green-red — affects ~1% of men. Similar to Protanopia in practical impact. Often the same palette adjustment covers both. Verify with Coblis or Colour Blindness Simulator. |
| Colorblind mode — Tritanopia | Standard | All color-coded gameplay | Not Started | Blue-yellow — rarer (~0.001%). Shift blue UI elements to purple; shift yellow to orange. |
| Color-as-only-indicator audit | Basic | All UI and gameplay | Not Started | List every place color is the SOLE differentiator in the table below. Each must have a non-color backup (icon, shape, pattern, text label) before shipping. |
| UI scaling | Standard | All UI elements | Not Started | Range: 75% to 150%. Default: 100%. Scaling must not break layout — test all screens at min and max. HUD scaling should be independent from menu scaling. |
| High contrast mode | Comprehensive | Menus (minimum); HUD (preferred) | Not Started | Replace all semi-transparent backgrounds with fully opaque. Replace mid-tone UI colors with black/white/system-high-contrast colors. All interactive elements outlined. |
| Brightness/gamma controls | Basic | Global | Not Started | Exposed in graphics settings. Include a reference calibration image (a gradient or symbol barely visible at correct calibration). Range: -50% to +50% from default. |
| Screen flash / strobe warning | Basic | All cutscenes, VFX | Not Started | (1) Pre-launch warning screen with photosensitivity seizure notice. (2) Audit all flash-heavy VFX against Harding FPA standard (no more than 3 flashes per second above luminance threshold). (3) Optional: flash reduction mode that lowers flash amplitude by 80%. |
| Motion/animation reduction mode | Standard | All UI transitions, camera shake, VFX | Not Started | Reduce or eliminate: screen shake, camera bob, motion blur, parallax scrolling in menus, looping background animations. Cannot fully eliminate: player movement animation (would break readability). Toggle in accessibility settings. |
| Subtitles — on/off | Basic | All voiced content | Not Started | Default: OFF (industry standard — many players prefer immersion). Prominently offered at first launch. |
| Subtitles — speaker identification | Standard | All voiced content | Not Started | Speaker name displayed before dialogue line. Color-coded by speaker IF colors differ by more than hue alone (test for colorblind compatibility). |
| Subtitles — style customization | Comprehensive | Subtitle display | Not Started | Font size (4 sizes minimum), background opacity (0–100%), text color (white / yellow / custom), position (bottom / top / player-relative). |
| Subtitles — sound effect captions | Comprehensive | Gameplay-critical SFX | Not Started | See Auditory Accessibility section for which SFX qualify. Format: [SOUND DESCRIPTION] in brackets, distinct from dialogue. |

### Color-as-Only-Indicator Audit

> Fill in every gameplay or UI element where color is currently the sole
> differentiator. Resolve each before shipping. A resolved entry has a non-color
> backup that works in all three colorblind modes above. See guide for example rows.

| Location | Color Signal | What It Communicates | Non-Color Backup | Status |
|----------|-------------|---------------------|-----------------|--------|
| [Add row for each color-coded element] | | | | |

---

## Motor Accessibility

| Feature | Target Tier | Scope | Status | Implementation Notes |
|---------|-------------|-------|--------|---------------------|
| Full input remapping | Standard | All gameplay inputs, all platforms | Not Started | Every input bound by default must be rebindable. Remapping applies to keyboard, mouse, controller, and any supported peripheral independently. No two actions may be bound to the same input simultaneously (warn on conflict). Persist remapping to player profile. |
| Input method switching | Standard | PC | Not Started | Player must be able to switch between keyboard/mouse and gamepad at any moment without restarting. UI must update prompts dynamically (show correct button icons for active input method). |
| One-hand mode | [Tier] | [Identify which features require two simultaneous hands] | Not Started | Audit every multi-input action. For each: can it be executed with a single hand? If not, provide a toggle alternative or hold-to-toggle version. Specify here which features have a one-hand path and which do not. |
| Hold-to-press alternatives | Standard | All hold inputs | Not Started | Every "hold [button] to [action]" must offer a toggle alternative. Toggle mode: first press activates, second press deactivates. Example: "Hold to sprint" becomes optional "toggle sprint" mode. List all hold inputs in the game here. |
| Rapid input alternatives | Standard | Any button mashing / rapid input sequences | Not Started | Any input requiring more than 3 presses per second sustained must offer a single-press toggle alternative. Example: Hades' "Hold to dash repeatedly" solves this elegantly. |
| Input timing adjustments | Standard | QTEs, timed button presses, rhythm inputs | Not Started | Provide a timing window multiplier in accessibility settings. Minimum range: 0.5x to 3.0x. Default: 1.0x. At 3.0x, a 500ms window becomes 1500ms. Document every timed input in this game and test at all multiplier values. |
| Aim assist | Standard | All ranged combat / targeting | Not Started | Not just on/off — provide granularity: Assist Strength (0–100%), Assist Radius, Aim Magnetism (snap-to-target), and Aim Slowdown (near-target deceleration) as separate sliders. Default values should be tuned to feel helpful, not intrusive. |
| Auto-sprint / movement assists | Standard | Movement systems | Not Started | "Hold to sprint" toggle (covered above). Additionally: auto-run option (hold direction, player continues without input). Specify any movement input that is held continuously in normal gameplay. |
| Platforming / traversal assists | [Tier] | [If game has platforming] | Not Started | Evaluate whether auto-grab (generous ledge detection), coyote time extension, and jump height adjustment are appropriate for this game's design. If platforming is not a game system, mark N/A. |
| HUD element repositioning | Comprehensive | All HUD elements | Not Started | Allow players to move health bars, minimaps, and quest trackers to their preferred screen position. Particularly important for players using head-tracking or eye-gaze hardware who may have reduced peripheral vision coverage. |

---

## Cognitive Accessibility

| Feature | Target Tier | Scope | Status | Implementation Notes |
|---------|-------------|-------|--------|---------------------|
| Difficulty options | Standard | All gameplay difficulty parameters | Not Started | Separate granular sliders where possible (damage dealt, damage received, enemy aggression, enemy speed) rather than a single Easy/Normal/Hard label. Document which parameters are adjustable and which are fixed. Fixed parameters require a design justification. |
| Pause anywhere | Basic | All gameplay states | Not Started | Players must be able to pause during any gameplay state, including cutscenes, dialogue, and tutorial sequences. Document any state where pausing is currently prevented and the design justification for that restriction. Any restriction is a risk. |
| Tutorial persistence | Standard | All tutorials and help text | Not Started | After dismissing a tutorial prompt, the player must be able to retrieve it from a Help section in the menu. Do not rely on players absorbing tutorials on first encounter — AbleGamers research shows many players dismiss prompts on reflex. |
| Quest / objective clarity | Standard | Quest and objective systems | Not Started | The current active objective must be accessible within 2 button presses at all times during gameplay. Display the full objective text on demand, not just a truncated marker. Avoid objectives that require inference ("investigate the northern region" — where exactly?). |
| Visual indicators for audio-only information | Standard | All SFX that carry gameplay information | Not Started | Audit every sound effect that communicates gameplay-critical state. For each: is there a visual equivalent? Directional audio (off-screen enemy) needs a screen-edge indicator. Critical warnings (boss phase transition, trap trigger) need visual cues. See Auditory Accessibility for full list. |
| Reading time for UI | Standard | All auto-dismissing dialogs | Not Started | No dialog, notification, or tooltip that contains actionable information may auto-dismiss in less than 5 seconds. Preferred: do not auto-dismiss at all — require player confirmation. Document every auto-dismissing element here and its current duration. |
| Cognitive load documentation | Comprehensive | Per game system | Not Started | For each system in systems-index.md, document the maximum number of things it asks the player to simultaneously track. Flag any system where the number exceeds 4. This is not a hard rule but a review trigger — high cognitive load systems need compensating UI clarity. See Per-Feature Accessibility Matrix below. |
| Navigation assists | Standard | World navigation | Not Started | Fast travel (to previously visited locations), waypoint system for current objective, optional objective indicator always visible. Document which of these apply to this game's design and which are intentionally omitted. |

---

## Auditory Accessibility

| Feature | Target Tier | Scope | Status | Implementation Notes |
|---------|-------------|-------|--------|---------------------|
| Subtitles for all spoken dialogue | Basic | All voiced content | Not Started | 100% coverage — no exceptions. Include narration, in-engine dialogue, radio/environmental dialogue heard from a distance. Test subtitle sync against voice acting timing. |
| Closed captions for gameplay-critical SFX | Comprehensive | Identified SFX list (below) | Not Started | Not all SFX need captions — only those that communicate state the player cannot infer visually. See the SFX audit table below. |
| Mono audio option | Comprehensive | Global audio output | Not Started | Folds stereo/spatial audio to mono. Preserves volume balance between channels rather than summing to full volume on both sides. Essential for players with single-sided deafness. |
| Independent volume controls | Basic | Music / SFX / Voice / UI audio buses | Not Started | Four independent sliders minimum. Persist to player profile. Range: 0–100%, default 80%. Expose in both main settings and the pause menu. |
| Visual representations for directional audio | Comprehensive | All off-screen threats and audio events | Not Started | Screen-edge indicator pointing toward the audio source. Opacity scales with audio volume (closer = more opaque). Two variants: threat indicators (red) and information indicators (neutral). Example: The Last of Us Part II uses screen-edge indicators for off-screen enemy positions. |
| Hearing aid compatibility mode | Standard | High-frequency audio cues | Not Started | Audit all audio cues for frequency range. Any cue that communicates critical information only through high-frequency sound (above 4kHz) must have a low-frequency or visual equivalent. Hearing aids often filter high frequencies. |

### Gameplay-Critical SFX Audit

> Identify every sound effect that communicates state the player needs to act on.
> Each entry in this table requires either a confirmed visual backup or a caption.
> See guide for example rows.

| Sound Effect | What It Communicates | Visual Backup | Caption Required | Status |
|-------------|---------------------|--------------|-----------------|--------|
| [Add each SFX that changes what the player should do] | | | | |

---

## Platform Accessibility API Integration

| Platform | API / Standard | Features Planned | Status | Notes |
|----------|---------------|-----------------|--------|-------|
| Xbox (GDK) | Xbox Game Core Accessibility / XAG | [Input remapping via Xbox Ease of Access, high contrast support, narrator integration for menus] | Not Started | XAG compliance is required for ID@Xbox Game Pass consideration. Review XAG checklist at https://docs.microsoft.com/gaming/accessibility/guidelines |
| PlayStation 5 | Sony Accessibility Guidelines / AccessibilityNode API | [Screen reader passthrough for menus, mono audio, high contrast] | Not Started | PS5 natively supports system-level audio description and mono audio if the game exposes AccessibilityNode data on UI elements. |
| Steam (PC) | Steam Accessibility Features / SDL | [Controller input remapping via Steam Input, subtitle support] | Not Started | Steam Input allows system-level remapping independent of in-game remapping. In-game remapping still required for keyboard/mouse. |
| iOS | UIAccessibility / VoiceOver | [VoiceOver support for menus if mobile port planned] | N/A | Only required if mobile release is in scope. |
| Android | AccessibilityService / TalkBack | [TalkBack support for menus if mobile port planned] | N/A | Only required if mobile release is in scope. |
| PC (Screen Reader) | JAWS / NVDA / Windows Narrator | [Menu navigation announcements] | Not Started | Requires UI elements to expose accessible names and roles via platform UI layer. Godot 4.5+ AccessKit integration covers this for supported control types. Verify against engine-reference/godot/ docs. |

---

## Per-Feature Accessibility Matrix

> When a new system is added to systems-index.md, a row must be added here. If a
> system has an unaddressed accessibility concern, it cannot be marked Approved
> in the systems index. See guide for example rows.

| System | Visual Concerns | Motor Concerns | Cognitive Concerns | Auditory Concerns | Addressed | Notes |
|--------|----------------|---------------|-------------------|------------------|-----------|-------|
| [Add system from systems-index.md] | | | | | | |

---

## Accessibility Test Plan

| Feature | Test Method | Test Cases | Pass Criteria | Responsible | Status |
|---------|------------|------------|--------------|-------------|--------|
| Text contrast ratios | Automated — contrast analyzer tool on all UI screenshots | All text/background combinations at all game states | All body text ≥ 4.5:1; all large text ≥ 3:1; subtitle backgrounds ≥ 7:1 | ux-designer | Not Started |
| Colorblind modes | Manual — Coblis simulator on all game screenshots with modes enabled | Gameplay screenshots in exploration, combat, inventory in each mode | No essential information is lost in any mode; player can complete all objectives without color discrimination | ux-designer | Not Started |
| Input remapping | Manual — remap all inputs to non-default bindings, complete tutorial and first level | All default inputs rebound; gameplay functions correctly; no binding conflict possible | All actions accessible after remapping; conflict prevention works; bindings persist across restart | qa-tester | Not Started |
| Subtitle accuracy | Manual — verify against voice script, check all lines | All voiced content; subtitle timing; speaker identification | 100% of voiced lines subtitled; speaker identified for all multi-character scenes; no subtitle display for more than 3 seconds after line ends | qa-tester | Not Started |
| Hold input toggles | Manual — enable all toggle alternatives, complete all combat and traversal sequences | All hold inputs in toggle mode | All hold actions completable in toggle mode; no gameplay state requires sustained hold when toggle is enabled | qa-tester | Not Started |
| Reduced motion mode | Manual — enable mode, navigate all menus and complete first hour of gameplay | All menu transitions; all HUD animations; all camera shake events | No looping animations in menus; no camera shake above threshold; all screen transitions are cross-fade or cut | ux-designer | Not Started |
| Platform screen reader (menu) | Manual — enable OS screen reader, navigate all menus | Main menu, settings, pause menu, inventory, map | All interactive menu elements have screen reader announcements; navigation order is logical; no element unreachable by keyboard/D-pad | ux-designer | Not Started |
| User testing — colorblind | User testing with colorblind participants | Full game session with each colorblind mode | Participants complete all content without requesting color clarification; no session-stopping confusion | producer | Not Started |
| User testing — motor impairment | User testing with participants using one hand or adaptive controllers | Full game session with toggle and extended timing modes enabled | Participants complete all MVP content within tolerance of able-bodied completion time | producer | Not Started |

---

## Known Intentional Limitations

> Every entry here is a risk — assess it honestly. See guide for example rows.

| Feature | Tier Required | Why Not Included | Risk / Impact | Mitigation |
|---------|--------------|-----------------|--------------|------------|
| [Add any intentionally excluded accessibility feature] | | | | |

---

## Audit History

> See guide for example rows.

| Date | Auditor | Type | Scope | Findings Summary | Status |
|------|---------|------|-------|-----------------|--------|
| [Add row for each audit] | | | | | |

---

## External Resources

| Resource | URL | Relevance |
|----------|-----|-----------|
| WCAG 2.1 (Web Content Accessibility Guidelines) | https://www.w3.org/TR/WCAG21/ | Foundational accessibility standard — contrast ratios, text sizing, input requirements |
| Game Accessibility Guidelines | https://gameaccessibilityguidelines.com | Comprehensive game-specific checklist organized by category and cost |
| AbleGamers Player Panel | https://ablegamers.org/player-panel/ | User testing service and consulting with disabled gamers |
| Xbox Accessibility Guidelines (XAG) | https://docs.microsoft.com/gaming/accessibility/guidelines | Required reading for Xbox certification; well-structured feature checklist |
| PlayStation Accessibility Guidelines | https://www.playstation.com/en-us/accessibility/ | Sony platform requirements; also contains well-written design guidance |
| Colour Blindness Simulator (Coblis) | https://www.color-blindness.com/coblis-color-blindness-simulator/ | Free tool for simulating colorblind modes on screenshots |
| Accessible Games Database | https://accessible.games | Research and examples of accessible game design decisions |
| CVAA (21st Century Communications and Video Accessibility Act) | https://www.fcc.gov/consumers/guides/21st-century-communications-and-video-accessibility-act-cvaa | US legal requirement for games with communication features (voice chat, messaging) |

---

## Open Questions

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|-----------|
| [Add question] | [Owner] | [Deadline] | [Resolution] |
