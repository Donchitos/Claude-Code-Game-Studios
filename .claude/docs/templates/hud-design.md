# HUD Design: [Game Name]

> Authoring guidance: .claude/docs/templates/guidance/hud-design-guide.md (load per-section as you author — do not read entirely).

> **Status**: Draft | In Review | Approved | Implemented
> **Author**: [Name or agent — e.g., ux-designer]
> **Last Updated**: [Date]
> **Game**: [Game name — this is a single document per game, not per element]
> **Platform Targets**: [All platforms this HUD must work on — e.g., PC, PS5, Xbox Series X, Steam Deck]
> **Related GDDs**: [Every system that exposes information through the HUD — e.g., `design/gdd/combat.md`, `design/gdd/progression.md`, `design/gdd/quests.md`]
> **Accessibility Tier**: Basic | Standard | Comprehensive | Exemplary
> **Style Reference**: [Link to art bible HUD section if it exists — e.g., `design/art/art-bible.md § 7. UI/HUD Visual Direction`]
> **Template**: HUD Design

> **Note — Scope boundary**: This document specifies all elements that overlay the
> game world during active gameplay — health bars, ammo counters, minimaps, quest
> trackers, subtitles, damage numbers, and notification toasts. For menu screens,
> pause menus, inventory, and dialogs that the player navigates explicitly, use
> `ux-spec.md` instead. The test: if it appears while the player is directly
> controlling their character, it belongs here.

---

## 1. HUD Philosophy

**What is this game's relationship with on-screen information?**

[One-paragraph design statement — see guide Section 1 for framing and examples]

**Visibility principle** — when in doubt, show or hide?

[Default resolution for ambiguous cases: HIDE / SHOW / CONTEXTUAL — see guide]

**The Rule of Necessity for this game**:

["A HUD element earns its place when ______________." — see guide for examples]

---

## 2. Information Architecture

> Categorize EVERY piece of information the game generates — this is the master
> inventory of game information, not just HUD information. See guide Section 2
> for a worked example covering typical information types.

| Information Type | Always Show | Contextual (show when relevant) | On Demand (menu/button) | Hidden (environmental / diegetic) | Reasoning |
|-----------------|-------------|--------------------------------|------------------------|----------------------------------|-----------|
| [Information type — e.g., Health, resource, minimap, quest objective, subtitles, status effects, timer, XP] | [ ] | [ ] | [ ] | [ ] | [Why this presentation category] |

---

## 3. Layout Zones

### 3.1 Zone Diagram

```
[Draw your HUD layout zones. Customize this to match your game's actual layout.
 Axes represent approximate screen percentage. Adjust zone names and sizes.]

 0%                                             100%
 ┌──────────────────────────────────────────────────┐  0%
 │  [SAFE MARGIN — 10% from edge on all sides]      │
 │  ┌────────────────────────────────────────────┐  │
 │  │ [TOP-LEFT]              [TOP-CENTER]  [TOP-RIGHT] │  ~15%
 │  │  Health, resource       Quest name    Ammo, magazine │
 │  │                                              │  │
 │  │                                              │  │
 │  │               [CENTER-SCREEN]               │  │  ~50%
 │  │                Crosshair / reticle           │  │
 │  │               (minimize HUD here)            │  │
 │  │                                              │  │
 │  │                                              │  │
 │  │ [BOTTOM-LEFT]     [BOTTOM-CENTER]   [BOTTOM-RIGHT] │  ~85%
 │  │  Minimap          Subtitles          Notifications │
 │  │  Ability icons    Tutorial prompts             │  │
 │  └────────────────────────────────────────────┘  │
 │                                                  │
 └──────────────────────────────────────────────────┘  100%
```

> Rule for zone placement: the center 40% of the screen (both horizontally and
> vertically) is the player's primary focus area. Keep this zone as clear as
> possible at all times. HUD elements that appear in the center zone — crosshairs,
> interaction prompts, hit markers — must be minimal, high-contrast, and brief.

### 3.2 Zone Specification Table

| Zone Name | Screen Position | Safe Zone Compliant | Primary Elements | Max Simultaneous Elements | Notes |
|-----------|----------------|---------------------|-----------------|--------------------------|-------|
| [Zone] | [Position] | [Yes/No + margins] | [Elements assigned] | [N] | [Zone purpose] |

**Safe zone margins by platform**:

| Platform | Top | Bottom | Left | Right | Notes |
|----------|-----|--------|------|-------|-------|
| [Platform] | [%] | [%] | [%] | [%] | [Platform-specific notes] |

---

## 4. HUD Element Specifications

### 4.1 Element Overview Table

> One row per HUD element. This is the master inventory for implementation planning.

| Element Name | Zone | Always Visible | Visibility Trigger | Data Source | Update Frequency | Max Size (% screen W) | Min Readable Size | Overlap Priority | Accessibility Alt |
|-------------|------|---------------|-------------------|-------------|-----------------|----------------------|------------------|-----------------|------------------|
| [Element] | [Zone] | [Yes/No] | [Trigger or N/A] | [Owning system] | [When it updates] | [%] | [px] | [N] | [Non-visual/non-color alternative] |

### 4.2 Element Detail Blocks

> For each element in the table above, write a detail block. Copy and complete
> one block per element. See guide Section 4 for completed Health Bar and
> Minimap examples.

---

**[Element Name]**

- Visual description: [Shape, fill direction, background, color behavior]
- Data displayed: [Values shown, including any numerical text labels]
- Update behavior: [Animation/lerp timing, flash behavior on large changes]
- Urgency states: [Per-threshold visual states, e.g., Normal / Caution / Critical / Zero]
- Interaction: [Interactive or display-only]
- Player customization: [Opacity, repositioning, size options]

---

**[Repeat this block for every element in Section 4.1]**

---

## 5. HUD States by Gameplay Context

> Define the HUD transformation for every gameplay context — at minimum:
> exploration, combat, dialogue/cutscene, and paused/menu. See guide Section 5
> for a worked example covering nine contexts.

| Context | Elements Shown | Elements Hidden | Elements Modified | Transition Into This State |
|---------|---------------|-----------------|------------------|---------------------------|
| [Context — e.g., Exploration / Combat / Dialogue / Cinematic / Menu open / Death / Loading / Tutorial / Boss] | [Shown] | [Hidden] | [Modified] | [Transition timing + trigger] |

---

## 6. Information Hierarchy

> Assign every element a priority tier (MUST KEEP / SHOULD KEEP / CAN HIDE /
> ALWAYS HIDE) with reasoning. See guide Section 6 for a worked example.

| Element | Priority Tier | Reasoning | What Replaces It If Hidden |
|---------|--------------|-----------|---------------------------|
| [Element] | [MUST KEEP / SHOULD KEEP / CAN HIDE / ALWAYS HIDE] | [Why] | [Fallback channel or N/A] |

---

## 7. Visual Budget

> These numbers are hard limits, not guidelines. Every element addition that
> would breach a limit requires explicit approval and must displace or reduce an
> existing element. See guide Section 7 for how to apply the budgets.

| Budget Constraint | Limit | Measurement Method | Current Estimate | Status |
|------------------|-------|--------------------|-----------------|--------|
| Maximum simultaneous active HUD elements | [8] | [Count all visible, non-faded elements at any one frame] | [TBD — verify at implementation] | [To verify] |
| Maximum % of screen occupied by HUD (exploration mode) | [12%] | [Pixel area of all HUD elements / total screen pixels] | [TBD] | [To verify] |
| Maximum % of screen occupied by HUD (combat mode) | [22%] | [Same method — combat adds ammo, crosshair, enemy bars] | [TBD] | [To verify] |
| Maximum % of center screen zone (40% of screen W/H) occupied | [5%] | [Only crosshair and interaction prompt allowed here] | [TBD] | [To verify] |
| Minimum contrast ratio — HUD text on any background | [4.5:1 (WCAG AA)] | [Measured against the darkest and lightest game world areas the element will appear over] | [TBD] | [To verify] |
| Maximum opacity for HUD background panels | [65%] | [Opacity of any panel behind HUD text — must preserve world visibility through panel] | [TBD] | [To verify] |
| Minimum HUD element size at minimum supported resolution | [40px for icons, 18px for text] | [Measure at lowest target resolution] | [TBD] | [To verify] |

---

## 8. Feedback & Notification Systems

> One row per notification type. Every notification must have queue/priority
> behavior defined. See guide Section 8 for a worked example table and queue rules.

| Notification Type | Trigger System | Screen Position | Duration (ms) | Animation In / Out | Max Simultaneous | Priority | Queue Behavior | Dismissible? |
|------------------|---------------|-----------------|--------------|-------------------|-----------------|----------|---------------|-------------|
| [Type] | [System] | [Zone] | [ms] | [In / out animation + timing] | [N] | [Priority] | [Queue/merge/preempt behavior] | [Yes/No] |

**Notification queue rules**:
1. [Combat-aware queue rule — which priorities are held during combat and how the queue flushes]
2. [Merge rule — when identical notification types merge into one]
3. [Critical bypass rule — which notifications are never queued, never merged]

---

## 9. Platform Adaptation

> Every target platform requires explicit layout testing before certification.
> See guide Section 9 for a worked example.

| Platform | Safe Zone | Resolution Range | Input Method | HUD-Specific Notes |
|----------|-----------|-----------------|-------------|-------------------|
| [Platform] | [Margin] | [Min–max resolution] | [Input] | [Platform-specific HUD constraints] |

**HUD repositionability requirement**: Players must be able to reposition at minimum the following elements using an in-game HUD layout editor (required for accessibility compliance on console):
- [Health bar]
- [Minimap]
- [Ability bar (if present)]

Repositioning saves to player profile, not to a single slot. Applies across play sessions.

---

## 10. Accessibility

> HUD-specific requirements only — refer to the project's
> `design/accessibility-requirements.md` for the full project standard.

### 10.1 Colorblind Modes

| Element | Color-Only Information Risk | Colorblind Mode Fix |
|---------|----------------------------|---------------------|
| [Element] | [Where color alone carries meaning] | [Non-color alternative: shape, icon, symbol, text] |

### 10.2 Text Scaling

[Describe what happens at 150% UI text scale: which elements reflow, clip, or are architecturally blocked from scaling — see guide Section 10 for an example narrative]

**Text scaling test matrix**:

| Element | 100% (baseline) | 125% | 150% | Overflow behavior |
|---------|----------------|------|------|-------------------|
| [Element] | [Pass/Fail/TBD] | [Pass/Fail/TBD] | [Pass/Fail/TBD] | [What happens on overflow] |

### 10.3 Motion Sensitivity

| Animation / Motion Element | Severity | Disabled by Reduced Motion Setting? | Replacement Behavior |
|---------------------------|----------|-------------------------------------|---------------------|
| [Animated element] | [Mild/Moderate/High] | [Yes/No/Optional] | [Static replacement] |

### 10.4 Subtitles Specification

> Subtitles are the highest-impact accessibility feature in the HUD. Specify them
> with the same rigor as the rest of the HUD. Do not leave subtitle behavior to
> implementation discretion.

- **Default setting**: [ON or OFF — document your game's default and the rationale. Industry standard is ON by default.]
- **Position**: [Zone, alignment, relationship to safe zone margin]
- **Max characters per line**: [e.g., 42 characters — the readable limit at minimum text size on TV viewing distance]
- **Max simultaneous lines**: [e.g., 2 lines before scrolling]
- **Speaker identification**: [Name display method — never rely on color alone]
- **Background**: [Panel treatment ensuring contrast against any game world background]
- **Font size minimum**: [px at reference resolution — scales with text scale setting]
- **Line break behavior**: [Break at natural language pause points — never mid-word]
- **Subtitle persistence**: [Hold duration relative to spoken line — never disappear while audio is still playing]
- **Non-dialogue captions**: [Whether ambient sounds, music, and SFX are captioned, and where these appear]

### 10.5 HUD Opacity and Visibility Controls

The following player-adjustable settings must be available from the Accessibility menu:

| Setting | Range | Default | Effect |
|---------|-------|---------|--------|
| [HUD Opacity — Global] | [0% (HUD hidden) to 100%] | [100%] | [Scales all HUD element opacities simultaneously] |
| [HUD Text Scale] | [75% to 150%] | [100%] | [Scales all HUD text elements; layout adapts] |
| [Damage Number Visibility] | [On / Off] | [On] | [Enables or disables all floating damage numbers] |
| [Minimap Visibility] | [On / Off / Compass Only] | [On] | [Compass strip shown as fallback when minimap off] |
| [Notification Verbosity] | [All / Important Only / Off] | [All] | [All = all toasts; Important Only = quest + level up; Off = no toasts] |
| [Motion Reduction] | [On / Off] | [Off] | [When On, replaces all animated HUD transitions with instant state changes] |
| [High Contrast Mode] | [On / Off] | [Off] | [Applies high contrast visual theme to all HUD elements — see art bible for HC variants] |

---

## 11. Tuning Knobs

> Document all tunable parameters before implementation so the programmer knows
> which values to externalize. See guide Section 11 for a worked example.

| Parameter | Current Value | Range | Effect of Increase | Effect of Decrease | Player Adjustable? | Notes |
|-----------|-------------|-------|-------------------|-------------------|-------------------|-------|
| [Parameter] | [Value] | [Min–max] | [Effect] | [Effect] | [Yes/No + how exposed] | [Tuning notes] |

---

## 12. Acceptance Criteria

> These criteria are the certification checklist for the HUD. Every item must
> pass before the HUD can be marked Approved. QA must be able to verify each
> item independently.

**Layout & Visibility**
- [ ] All HUD elements are within platform safe zone margins on all target platforms
- [ ] No two HUD elements overlap in any documented gameplay context
- [ ] HUD occupies less than [12]% of screen area in exploration context (measure at reference resolution)
- [ ] HUD occupies less than [22]% of screen area in combat context
- [ ] No HUD element occupies the center [40]% of screen during exploration (crosshair excepted during combat)
- [ ] All HUD elements are visible and legible at minimum supported resolution on all platforms

**Per-Context Correctness**
- [ ] HUD correctly shows only specified elements in every context defined in Section 5
- [ ] Context transitions (combat enter/exit, dialogue, cinematic) show correct elements within transition timing spec
- [ ] Boss health bar appears correctly on boss encounter trigger and disappears after boss defeat
- [ ] Death state correctly hides all gameplay HUD elements

**Accessibility**
- [ ] All HUD text elements meet 4.5:1 contrast ratio against all backgrounds they appear over (test light AND dark scenes)
- [ ] No HUD element uses color as the ONLY differentiator (verify: remove color from each element and confirm information is still communicated)
- [ ] Subtitles appear for all voiced lines and ambient dialogue when subtitle setting is enabled
- [ ] Subtitle text never disappears while audio is still playing
- [ ] Reduced Motion setting disables all HUD animations listed in Section 10.3
- [ ] Text Scale 150% does not cause any HUD text to overflow its container or overlap another element
- [ ] All player-adjustable HUD settings in Section 10.5 are functional and persist between sessions

**Notifications**
- [ ] Notifications of the same type that fire within 500ms merge into a single notification
- [ ] Low-priority notifications are queued (not displayed) during combat and released post-combat
- [ ] Critical warnings (low health, hazard) appear immediately regardless of queue state or combat state
- [ ] No more than [3] notification toasts are visible simultaneously
- [ ] Notification queue is cleared correctly on level transition (no stale notifications from previous area)

**Platform**
- [ ] All elements respect 10% safe zone margins on console (test on physical TV — not monitor)
- [ ] HUD displays correctly at 1280x720 (Steam Deck) with no element clipping or overlap
- [ ] HUD elements are repositionable (Health, Minimap, Ability Bar) and reposition settings persist
- [ ] Controller disconnection during play does not cause HUD state corruption

---

## 13. Open Questions

> Track unresolved design questions here. All questions must be resolved before
> the HUD design document can be marked Approved. See guide Section 13 for
> example questions.

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|-----------|
| [Add question] | [Owner] | [Deadline] | [Resolution] |
