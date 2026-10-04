# Agent Test Spec: accessibility-specialist

## Agent Summary
Domain: Input remapping, text scaling, colorblind modes, screen reader support, and accessibility standards compliance (WCAG, platform certifications).
Does NOT own: overall UX flow design (ux-designer), visual art style direction (art-director).
No gate IDs assigned.

---

## Static Assertions (Structural)

- [ ] `description:` field is present and domain-specific (references accessibility / inclusive design / WCAG)
- [ ] `tools:` list includes Read, Write, Edit, Bash, Glob, Grep
- [ ] Model tier is `inherit` — frontmatter `model:` reads exactly `inherit` (tiers: `.claude/docs/model-tiers.md`)
- [ ] Agent definition does not claim authority over UX flow or visual art style

---

## Test Cases

### Case 1: In-domain request — appropriate output
**Input:** "Review the player HUD for accessibility."
**Expected behavior:**
- Audits the HUD spec or screenshot for:
  - Contrast ratio (flags any text below 4.5:1 and any UI element below 3:1 — its Visual Accessibility minimums at the default AA target)
  - Alternative representation for color-coded information (e.g., enemy health bars use only color, no shape distinction)
  - Text size (flags any text below 18px at 1080p, or text that cannot scale up to 200%)
  - Screen reader or TTS annotation availability for key status elements
- Produces a prioritized finding list in its Findings Format table (Finding / WCAG Criterion / Severity / Gate / Recommendation) with specific element names and the criteria they fail
- Rates Severity on the project's S1 Critical / S2 High / S3 Medium / S4 Low scale and labels each finding's Gate BLOCKING (fails the AA target, or leaves gameplay-critical information in one channel) or ADVISORY — never a severity word such as HIGH in the Gate column
- Does NOT redesign the HUD — produces findings for ux-designer and ui-programmer to act on

### Case 2: Out-of-domain request — redirects correctly
**Input:** "Design the overall game flow: main menu → character select → loading → gameplay → pause → results."
**Expected behavior:**
- Does NOT produce UX flow architecture — flow design is not among its Core Responsibilities (audit, standards, input review, text readability, color safety, assistive-feature recommendations), and the project coordination rules bar binding decisions outside an agent's domain
- Explicitly states that overall game flow design belongs to `ux-designer` — the partner its Coordination section names for interaction patterns
- Redirects the request to `ux-designer`
- Anything it offers in place of the flow is from its own domain — e.g., an accessibility review of the flow once it is designed (time limits under SC 2.2.1 Timing Adjustable, its Cognitive Accessibility rules such as pause available at all times) — never flow architecture

### Case 3: Colorblind mode conflict
**Input:** "The proposed colorblind mode for deuteranopia replaces the enemy red health bars with orange, but the art palette already uses orange for friendly units."
**Expected behavior:**
- Identifies the conflict: orange collision between colorblind mode and the established friendly-unit palette
- Does NOT unilaterally change the art palette (that belongs to art-director)
- Flags the conflict to `art-director` with the specific visual overlap described
- Proposes alternative differentiation strategies that don't require palette changes (e.g., shape/icon overlay, pattern fill, iconography)

### Case 4: UI state requirement for accessibility feature
**Input:** "Screen reader support for the inventory requires the system to expose item names and quantities as accessible text nodes."
**Expected behavior:**
- Defines the requirement (its Core Responsibility: "Define and enforce accessibility standards"): for each inventory element (slot, item, quantity, empty slot) the accessible name and value a screen reader must announce
- Cites the governing criterion by number and short name, per its WCAG citation rule (e.g., SC 4.1.2 Name, Role, Value; SC 1.3.1 Info and Relationships)
- Identifies that implementing accessible text nodes requires UI system changes
- Hands implementation to `ui-programmer` — the UI implementer its Coordination section names — rather than taking it on
- Does NOT implement the UI system changes itself

### Case 5: Context pass — WCAG 2.1 targets
**Input:** Project accessibility target provided in context: WCAG 2.1 AA compliance. Request: "Review the dialogue system for accessibility."
**Expected behavior:**
- References specific WCAG 2.1 AA success criteria relevant to dialogue (e.g., 1.4.3 Contrast Minimum, 1.4.4 Resize Text, 2.2.1 Timing Adjustable for auto-advancing dialogue)
- Uses exact criterion numbers and names from the standard, not paraphrases
- Flags each finding with the specific criterion it fails
- Checks its own dialogue rules as well: subtitles with speaker identification, at least 3 subtitle size options
- Does not report an AAA-only criterion (e.g., SC 1.4.6 Contrast (Enhanced) at 7:1, SC 2.2.3 No Timing) as a failure against the AA target; if it mentions one, it labels it AAA and outside the stated target, with Gate ADVISORY

---

## Protocol Compliance

- [ ] Stays within declared domain (remapping, text scaling, colorblind modes, screen reader, standards compliance)
- [ ] Redirects overall flow design to ux-designer and art palette decisions to art-director — the partners its Coordination section names for those areas
- [ ] Returns structured findings with specific element names, contrast ratios, and criterion references
- [ ] Does not implement UI changes — coordinates with ui-programmer for implementation
- [ ] References specific WCAG criteria by number when compliance target is provided
- [ ] Flags conflicts between accessibility requirements and art decisions to art-director
- [ ] Asks "May I write this to [filepath]?" naming the file (e.g., `production/qa/accessibility/[screen-or-feature]-audit-[date].md`) before writing any audit or requirements document

---

## Coverage Notes
- HUD audit (Case 1) should produce findings trackable as accessibility stories in the sprint backlog
- Colorblind conflict (Case 3) confirms the agent respects art-director's authority over the palette
- WCAG criteria (Case 5) verifies the agent uses standards precisely, not generically
