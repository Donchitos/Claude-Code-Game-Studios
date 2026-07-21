# Example Session: UX Pipeline — $ux-design → $ux-review → $team-ui

**Context:** Solo indie dev, Pre-Production phase. The HUD and inventory screen are the first UI to design. The game has a player journey doc and GDDs for inventory and combat.

**Starting State:**
- `design/gdd/inventory-system.md` — complete
- `design/gdd/combat-system.md` — complete
- `design/player-journey.md` — complete (6-phase arc defined)
- No UX specs yet
- `design/ux/` directory does not exist

**Session Duration:** ~90 minutes across two sessions (HUD design, then inventory screen)
**Turns:** 16
**Outcome:** `design/ux/hud.md` and `design/ux/screens/inventory.md` created and reviewed; team-ui handed off for visual implementation

---

## Part 1: HUD Design with $ux-design

### Turn 1: User Starts HUD Design

**User:**
> $ux-design hud

### Turn 2: Agent Loads Context and Presents the Approach

**Agent (ux-designer, via $ux-design):**
> Starting HUD design. Loading context...
>
> - `design/player-journey.md` read — key states: Calm Exploration, Tension (threat detected), Crisis (low HP/stamina), Combat
> - `design/gdd/combat-system.md` — HUD needs: HP bar, stamina bar, active ability cooldowns (up to 3), damage numbers
> - `design/gdd/inventory-system.md` — HUD needs: quick slots (4 slots), active item indicator
>
> **HUD Philosophy question:** What is the player's primary attention focus during play?
>
> This determines how aggressive the HUD should be:
> - **Option A: Diegetic (low presence)** — HP shown only when damaged, stamina shown only when draining. World-first, HUD recedes unless urgent.
> - **Option B: Persistent minimal** — HP and stamina always visible, small and unobtrusive. Quick reference without mode-switching.
> - **Option C: Full tactical** — All info always visible (HP, stamina, cooldowns, map, inventory slots). Player always has full awareness.
>
> Given your survival game and "lone survivor" fantasy, A or B is most consistent with the genre.

**User:**
> B — I want it always there but minimal. The player is always managing resources.

### Turn 3: Agent Drafts HUD Philosophy Section

**Agent:**
> **HUD Philosophy draft:**
>
> > **Approach: Persistent Minimal**
> > The HUD is always visible but occupies minimal screen real estate. The player is a resource-managing survivor — denying HP/stamina visibility creates frustration, not tension. All critical stats are readable at a glance without interrupting exploration focus. Elements scale in visual weight when they become urgent (HP below 30% pulses, stamina at 0 flashes), then return to minimal state.
>
> May I write this to `design/ux/hud.md` as the Philosophy section?

**User:**
> Yes

**Agent creates `design/ux/hud.md` and writes Philosophy section.**

*(Turns 4–7 continue the section-by-section HUD authoring: Info Architecture, Zones, Element Specs, State Machine, Visual Budget, Platform Adaptation — each drafted, approved, and written to file.)*

---

**Final HUD structure after all sections:**

```
design/ux/hud.md
  - Philosophy: Persistent Minimal
  - Info Architecture: HP (top-left), Stamina (top-left below HP), Quick Slots (bottom-center),
    Ability Cooldowns (bottom-right), Damage Numbers (world-space)
  - Zones: 4 defined (top-left vitals, bottom-center interaction, bottom-right abilities, world-space)
  - Element Specs: 6 elements with dimensions, font sizes, opacity rules
  - State Machine: Calm / Tension / Crisis / Combat (4 states, transition triggers)
  - Visual Budget: Max 8% screen coverage, 3 simultaneous animations
  - Platform Adaptation: Controller (aim reticle added), Mobile (out of scope v1)
```

---

## Part 2: Inventory Screen with $ux-design

### Turn 8: User Starts Inventory Screen

**User:**
> $ux-design screen inventory

### Turn 9: Agent Scans GDD and Player Journey

**Agent:**
> Loading context for inventory screen...
>
> From `design/gdd/inventory-system.md`:
> - Grid inventory, 6×8 slots
> - Items have weight (affects movement) and stack size
> - Player can equip, drop, inspect, split stacks
>
> From `design/player-journey.md`:
> - Inventory opens frequently during Calm Exploration
> - Players should feel "organized and in control" when opening inventory
> - Anxiety moment: "I need to decide what to drop" — should be clear, not panicked
>
> **Player Need (from journey):** *I need to quickly assess what I'm carrying, decide what to keep or drop, and get back into the world.*
>
> **Key design question:** How do players navigate to inventory actions?
> - **Option A: Right-click context menu** — hover item → right-click → menu appears (Escape/common)
> - **Option B: Drag-based** — drag to drop zone to drop; drag to equipment slot to equip (Stardew Valley)
> - **Option C: Inspect panel** — click item → details panel appears on right with action buttons

**User:**
> B — drag-based. I want it tactile.

*(Turns 10–12 continue section-by-section for the inventory screen spec: Player Need, Layout Zones, States, Interaction Map, Data Requirements, Events Fired, Accessibility, Localization.)*

---

## Part 3: $ux-review

### Turn 13: User Runs Review

**User:**
> $ux-review design/ux/

### Turn 14: Agent Reviews Both Documents

**Agent (via $ux-review):**
> Reviewing all UX specs in `design/ux/`...
>
> ---
> **HUD Review (`hud.md`):**
>
> | Check | Status | Notes |
> |-------|--------|-------|
> | GDD alignment — all required elements present | ✅ | HP, stamina, quick slots, cooldowns all specced |
> | State machine coverage | ✅ | All 4 gameplay states covered |
> | Accessibility tier | ⚠️ | No colorblind mode specified for HP/stamina bars (red/yellow convention) |
> | Visual budget | ✅ | 8% screen coverage, within budget |
> | Platform notes | ✅ | Controller variant documented |
>
> **Inventory Screen Review (`screens/inventory.md`):**
>
> | Check | Status | Notes |
> |-------|--------|-------|
> | Player Need stated | ✅ | |
> | All GDD actions covered | ✅ | Equip, drop, inspect, split all in interaction map |
> | Drag-drop interaction fully specified | ⚠️ | Drop target behavior when inventory is full not defined — what happens? |
> | Accessibility: keyboard alternative for drag | ❌ | MISSING — drag-only with no keyboard path fails motor accessibility |
> | Localization: all strings tagged | ✅ | |
> | Data events fired | ✅ | `item_equipped`, `item_dropped`, `stack_split` all mapped |
>
> ---
> **Verdict: NEEDS REVISION**
>
> Two issues must be resolved before handoff to $team-ui:
>
> 1. **BLOCKING (Accessibility):** Inventory screen has no keyboard alternative to drag-drop. Motor accessibility requires a non-drag interaction path. Add a "press X to pick up / press X again to place" toggle, or a details panel with keyboard-accessible action buttons.
>
> 2. **ADVISORY (HUD):** HP/stamina bars use color alone to convey state. Add a secondary indicator (shape, icon, or pattern) for colorblind users. Can be resolved in visual pass.
> 3. **ADVISORY (Inventory):** Full-inventory drop behavior is unspecified. Resolve in GDD before implementation, or document as out-of-scope.

### Turn 15: User Resolves Blocking Issue

**User:**
> For keyboard: press F to pick up item at cursor, press F again on target slot to place it. Add this to the inventory spec.

**Agent:**
> Adding to Interaction Map under "Keyboard / Controller Path":
>
> > Press F (or South button) to pick up item at cursor. Item enters "held" state with visual indicator. Press F again on target slot to place. Press Escape to cancel and return item.
>
> May I write this to `design/ux/screens/inventory.md` and re-run the accessibility check?

**User:**
> Yes

**Agent writes update. Re-checks accessibility — now passes.**

---

## Part 4: Handoff to $team-ui

### Turn 16: User Kicks Off Team UI

**User:**
> $team-ui

**Agent (via $team-ui):**
> Running UX pipeline context check...
>
> - `design/ux/hud.md` — reviewed ✅
> - `design/ux/screens/inventory.md` — reviewed ✅
> - `$ux-review` verdict: NEEDS REVISION was resolved — current state: APPROVED ✅
>
> Proceeding to **Phase 2: Visual Design**
>
> Handing off to `art-director` for visual spec (color palette, typography, iconography aligned to art bible)...
>
> *(team-ui continues through visual design → layout implementation → accessibility audit → final review)*

---

## What This Example Demonstrates

- **Context-driven design**: agent reads player-journey.md to ground HUD decisions in player emotional state, not just feature lists
- **UX review is a hard gate**: `$team-ui` checks for a passing `$ux-review` before proceeding to visual design
- **Accessibility caught early**: the missing keyboard alternative was flagged by review, not discovered by a QA tester in the final week
- **Blocking vs. advisory**: the missing keyboard path was BLOCKING (stops handoff); the colorblind colors were ADVISORY (can be fixed in visual pass)
- **Section-by-section UX authoring**: same incremental pattern as `$design-system` — each section written to file before moving on
- **Separate HUD and screen files**: `design/ux/hud.md` is the whole-game HUD; per-screen specs live in `design/ux/screens/`
- **Pattern library enforced by $team-ui**: after this session, inventory drag-drop becomes a documented pattern in `design/ux/interaction-patterns.md` for all future screens to reference
