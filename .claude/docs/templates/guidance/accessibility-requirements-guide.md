> Authoring guidance for accessibility-requirements.md. Load only the part covering the section currently being authored — not the whole file at once.

# Accessibility Requirements Template — Authoring Guidance

Guidance is organized by template section. When authoring a section of a
project's accessibility requirements document, read only that section's
guidance below. The feature tables themselves (Visual / Motor / Cognitive /
Auditory), the platform API table, the test plan, and the external resources
remain in the template — they are the requirement catalog, not guidance.

---

## Accessibility Tier Definition

> **Why define tiers**: Accessibility is not binary. Defining four tiers gives
> the team a shared vocabulary, forces an explicit commitment at the start of
> production, and prevents scope creep in both directions ("we'll add it later"
> and "we have to support everything"). The tiers below are this project's
> definitions — the industry uses similar but not identical language. Commit to
> a tier with specific feature targets, not just the tier name.

**Authoring the commitment rationale**:

[Write 3-5 sentences justifying the tier choice. Do not simply
state the tier — explain the reasoning. Consider: What is the game's genre and
how does it map to common accessibility barriers (e.g., fast-twitch games have
motor barriers; reading-heavy games have visual barriers)? Who is the target
player and what does the research say about disability prevalence in that group?
What are the platform requirements (Xbox requires XAG compliance for ID@Xbox)?
What is the team's capacity? What would dropping one tier cost the player base,
in concrete terms?

Example: "This is a narrative RPG with turn-based combat targeted at players
25-45. The turn-based structure eliminates the most severe motor barriers common
in action games, but the reading-heavy design creates significant visual and
cognitive barriers. Standard tier addresses all of these. Exemplary tier is not
achievable without a dedicated accessibility engineer. Xbox ID@Xbox program
requires XAG compliance for Game Pass consideration, which Standard meets.
Dropping to Basic would exclude players who rely on colorblind modes or input
remapping, estimated at 8-12% of the target audience based on AbleGamers data."]

**Example in-scope / out-of-scope entries**:

Features explicitly in scope (beyond tier baseline):
- [e.g., "Full subtitle customization — elevated from Comprehensive because our
  game is dialogue-heavy and subtitles are a primary channel"]
- [e.g., "One-hand mode for controller — we have hold inputs critical to combat"]

Features explicitly out of scope:
- [e.g., "Screen reader for in-game world (not menus) — requires engine work
  beyond current capacity. Documented in Known Intentional Limitations."]

---

## Visual Accessibility

> **Why this section comes first**: Visual impairments affect the largest
> proportion of players who use accessibility features. Color vision deficiency
> alone affects approximately 8% of men and 0.5% of women. Text legibility at
> TV viewing distance is frequently the single largest accessibility failure
> in shipped games. Document every visual feature before implementation begins,
> because retrofitting minimum text sizes or color decisions after assets are
> locked is expensive.

**Worked example rows — Color-as-Only-Indicator Audit**:

| Location | Color Signal | What It Communicates | Non-Color Backup | Status |
|----------|-------------|---------------------|-----------------|--------|
| [Health bar] | [Red = low health] | [Player is near death] | [Bar also shows numeric value and flashes] | [Not Started] |
| [Minimap markers] | [Red = enemy, green = ally] | [Unit allegiance] | [Enemy markers are triangles; ally markers are circles] | [Not Started] |
| [Inventory item rarity] | [Color-coded border (grey/blue/purple/gold)] | [Item quality tier] | [Rarity name shown on hover/focus; icon star count] | [Not Started] |

---

## Motor Accessibility

> **Why motor accessibility matters for games**: Games are more motor-demanding
> than most software. A web form requires precise clicks; a game may require
> rapid simultaneous button combinations held for specific durations. Motor
> impairments span a wide range — from tremor (affecting precision) to
> hemiplegia (one functional hand) to RSI (affecting hold duration). The AbleGamers
> Able Assistance program estimates 35 million gamers in the US have a disability
> affecting their ability to play. Many of the features below cost very little
> to implement if planned from the start, and are extremely expensive to add post-launch.

---

## Cognitive Accessibility

> **Why cognitive accessibility is often under-specced**: Cognitive accessibility
> affects players with ADHD, dyslexia, autism spectrum conditions, acquired brain
> injuries, and anxiety disorders — a larger combined population than many studios
> realize. It also benefits all players in high-stress moments. The most common
> failures are: no pause anywhere, tutorial information that can only be seen once,
> and systems that require tracking too many simultaneous states. Games like
> Hades and Celeste have demonstrated that cognitive assist options (god mode,
> persistent reminders, extended text display) do not harm the experience for
> players who don't use them.

---

## Auditory Accessibility

> **Why auditory accessibility matters even for players without hearing loss**:
> 7% of players are deaf or hard of hearing. Additionally, a large portion of
> players regularly play in environments where audio is reduced or absent (commute,
> shared household, infant sleeping). Any gameplay-critical information delivered
> only through audio is a design failure even before accessibility is considered.
> The guiding principle: every sound that changes what the player should DO next
> must have a visual equivalent.

**Worked example rows — Gameplay-Critical SFX Audit**:

| Sound Effect | What It Communicates | Visual Backup | Caption Required | Status |
|-------------|---------------------|--------------|-----------------|--------|
| [Enemy attack windup sound] | [Incoming damage — player should dodge] | [Enemy animation telegraph visible from all camera angles] | [No — visual is sufficient] | [Not Started] |
| [Trap trigger click] | [Trap is about to fire] | [Not always visible depending on camera angle] | [Yes — "[CLICK]" caption with directional indicator] | [Not Started] |
| [Low health heartbeat] | [Player health critical] | [Health bar also shows critical state visually] | [No — visual is sufficient] | [Not Started] |
| [Quest completion chime] | [Objective completed] | [Quest tracker updates visually] | [No — visual is sufficient] | [Not Started] |

---

## Platform Accessibility API Integration

> **Why this section exists**: Each platform provides native accessibility APIs
> that, when used, allow OS-level features (system screen readers, display
> accommodations, motor accessibility services) to work with your game. Ignoring
> these APIs does not break the game, but it means players who rely on OS-level
> accessibility tools get no benefit from them inside your game. Xbox in particular
> requires XAG compliance for certification. Verify platform requirements before
> committing to a tier — platform requirements set a floor, not a ceiling.

---

## Per-Feature Accessibility Matrix

> **Why this matrix exists**: Accessibility is not a list of settings — it is a
> property of every game system. This matrix creates the "accessibility impact"
> view of the game: which systems have which barriers, and whether those barriers
> are addressed. When a new system is added to systems-index.md, a row must be
> added here. If a system has an unaddressed accessibility concern, it cannot be
> marked Approved in the systems index.

**Worked example rows**:

| System | Visual Concerns | Motor Concerns | Cognitive Concerns | Auditory Concerns | Addressed | Notes |
|--------|----------------|---------------|-------------------|------------------|-----------|-------|
| [Combat System] | [Enemy health bars are color-coded; attack animations may cause motion sickness] | [Rapid input required for combos; hold inputs for guard] | [Track enemy patterns + cooldowns + player resources simultaneously] | [Audio cues for off-screen attacks; critical damage warning sounds] | [Partial] | [Colorblind palette applied; hold-to-block toggle needed] |
| [Inventory / Equipment] | [Item rarity conveyed by border color] | [No motor concerns — turn-based] | [Item stats comparison requires reading multiple values] | [None — no critical audio in this system] | [Partial] | [Non-color rarity indicators in progress] |
| [Dialogue System] | [Subtitle display depends on contrast settings] | [No motor concerns] | [Long dialogue trees with time pressure on dialogue choices] | [All dialogue must be subtitled] | [Not Started] | [Timed dialogue choices must support extended timer option] |
| [Navigation / World Map] | [Map marker colors] | [No motor concerns] | [Quest objective clarity; waypoint visibility] | [Audio pings for objectives have no visual equivalent] | [Not Started] | |

---

## Accessibility Test Plan

> **Why testing accessibility separately from QA**: Standard QA tests whether
> features work. Accessibility testing tests whether features work for players
> who use them. These are different tests. A subtitle system can pass QA (it
> displays text) and fail accessibility testing (the text is unreadable at TV
> distance by a player with low vision). Plan for three test types: automated
> (contrast ratios, text sizes), manual internal (team members simulating
> impairments using accessibility simulators), and user testing (players who
> actually use these features).

---

## Known Intentional Limitations

> **Why document what is NOT included**: Omissions left undocumented become
> surprises at certification or in community feedback. Documenting a limitation
> with a rationale demonstrates that it was a deliberate choice, not an oversight.
> It also identifies which players are not served and what the mitigation is.
> Every entry here is a risk — assess it honestly.

**Worked example rows**:

| Feature | Tier Required | Why Not Included | Risk / Impact | Mitigation |
|---------|--------------|-----------------|--------------|------------|
| [Screen reader support for in-game world (NPCs, objects, environmental text)] | Exemplary | Engine (Godot 4.6) AccessKit integration covers menus only; extending to the game world requires a custom spatial audio description system beyond current scope | Affects blind and low-vision players who can navigate menus but cannot independently explore the game world | Ensure all critical world information is duplicated in accessible menu systems (quest log, map); evaluate for post-launch DLC |
| [Full subtitle customization (font/color/background)] | Comprehensive | Scope reduction — targeting Standard tier. Custom font rendering in Godot requires additional asset pipeline work | Affects deaf and hard-of-hearing players with specific legibility needs; particularly affects players with dyslexia who use custom fonts | Provide two preset subtitle styles (default and high-readability) as a partial mitigation; log for post-launch update |
| [Tactile/haptic alternatives for all audio cues] | Exemplary | Platform rumble API integration for non-Xbox platforms is out of scope for v1.0 | Affects deaf players relying on haptic feedback; PC players with non-Xbox controllers get no haptic response | Xbox controller haptic integration is in scope; evaluate PlayStation DualSense haptic API for a post-launch patch |

---

## Audit History

> **Why track audit history**: Accessibility is not certified once and done.
> Platform requirements change. New features may introduce new barriers. Legal
> standards evolve. An audit history demonstrates due diligence and helps identify
> regressions between audits.

**Worked example rows**:

| Date | Auditor | Type | Scope | Findings Summary | Status |
|------|---------|------|-------|-----------------|--------|
| [Date] | [Internal — ux-designer] | Internal review | [Pre-submission checklist against committed tier] | [e.g., "12 items verified, 3 open issues: subtitle contrast below target in 2 scenes, color-only indicator on minimap not resolved"] | [In Progress] |
| [Date] | [External — AbleGamers Player Panel] | User testing | [Motor accessibility — one-hand mode and timing adjustments] | [e.g., "Toggle modes functional. Timed QTE window at 3x still failed for one participant — recommend 5x option."] | [Findings addressed] |

---

## Open Questions

**Worked example questions**:

| Question | Owner | Deadline | Resolution |
|----------|-------|----------|-----------|
| [Does Godot 4.6 AccessKit support dynamic accessibility node updates for HUD elements, or only static menus?] | [ux-designer] | [Before Technical Setup gate] | [Unresolved — check engine-reference/godot/ docs] |
| [What is the Xbox ID@Xbox minimum XAG compliance requirement for our release window?] | [producer] | [Before Pre-Production gate] | [Unresolved] |
| [Will the dialogue system support timed choice extensions without a full architecture change?] | [lead-programmer] | [During Technical Design] | [Unresolved] |
