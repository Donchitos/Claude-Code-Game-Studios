# Agent Test Spec: accessibility-specialist

## Agent Summary
Domain: Input remapping, text scaling, colorblind modes, screen reader support, and accessibility standards compliance (WCAG, platform certifications).
Does NOT own: overall UX flow design (ux-designer), visual art style direction (art-director).
No fixed model routing is required; the caller selects the available Codex model.
No gate IDs assigned.

---

## Static Assertions (Structural)

- [ ] `description:` field is present and domain-specific (references accessibility / inclusive design / WCAG)
- [ ] Role boundaries and file ownership match the stated domain
- [ ] Does not require fixed model routing; the calling Codex client selects the available model
- [ ] Agent definition does not claim authority over UX flow or visual art style

---

## Test Cases

### Case 1: In-domain request — appropriate output
**Input:** "Review the player HUD for accessibility."
**Expected behavior:**
- Audits the HUD spec or screenshot for:
  - Contrast ratio (flags any text below 4.5:1 for AA or 7:1 for AAA)
  - Alternative representation for color-coded information (e.g., enemy health bars use only color, no shape distinction)
  - Text size (flags any text below 16px equivalent at 1080p)
  - Screen reader or TTS annotation availability for key status elements
- Produces a prioritized finding list with specific element names and the criteria they fail
- Does NOT redesign the HUD — produces findings for ux-designer and ui-programmer to act on

### Case 2: Out-of-domain request — redirects correctly
**Input:** "Design the overall game flow: main menu → character select → loading → gameplay → pause → results."
**Expected behavior:**
- Does NOT produce UX flow architecture
- Explicitly states that overall game flow design belongs to `ux-designer`
- Redirects the request to `ux-designer`
- May note it can review the flow for accessibility concerns (e.g., time limits, cognitive load) once the flow is designed

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
- Produces an accessibility requirements spec defining the required accessible text properties for each inventory element
- Identifies that implementing accessible text nodes requires UI system changes
- Coordinates with `ui-programmer` to implement the required accessible text node exposure
- Does NOT implement the UI system changes itself

### Case 5: Context pass — WCAG 2.1 targets
**Input:** Project accessibility target provided in context: WCAG 2.1 AA compliance. Request: "Review the dialogue system for accessibility."
**Expected behavior:**
- References specific WCAG 2.1 AA success criteria relevant to dialogue (e.g., 1.4.3 Contrast Minimum, 1.4.4 Resize Text, 2.2.1 Timing Adjustable for auto-advancing dialogue)
- Uses exact criterion numbers and names from the standard, not paraphrases
- Flags each finding with the specific criterion it fails
- Notes which criteria are out of scope for AA (AAA-only) so they are not incorrectly flagged as failures

---

## Protocol Compliance

- [ ] Stays within declared domain (remapping, text scaling, colorblind modes, screen reader, standards compliance)
- [ ] Redirects UX flow design to ux-designer, art palette decisions to art-director
- [ ] Returns structured findings with specific element names, contrast ratios, and criterion references
- [ ] Does not implement UI changes — coordinates with ui-programmer for implementation
- [ ] References specific WCAG criteria by number when compliance target is provided
- [ ] Flags conflicts between accessibility requirements and art decisions to art-director

---

## Coverage Notes
- HUD audit (Case 1) should produce findings trackable as accessibility stories in the sprint backlog
- Colorblind conflict (Case 3) confirms the agent respects art-director's authority over the palette
- WCAG criteria (Case 5) verifies the agent uses standards precisely, not generically
