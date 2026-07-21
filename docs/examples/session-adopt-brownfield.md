# Example Session: $adopt — Brownfield Project Onboarding

**Context:** Developer has been building a game for 3 months before discovering this agent system. They have code, some design docs, and rough notes — but nothing in the right format for the skills to use.

**Starting State:**
- `src/gameplay/` — ~4000 lines of Godot 4.6 GDScript
- `design/` — 3 markdown files with rough design notes (not in GDD template format)
- No `design/gdd/` directory
- No `docs/architecture/` directory
- No `production/` directory
- No `design/gdd/systems-index.md`
- AGENTS.md exists (engine configured: Godot 4.6)

**Session Duration:** ~30 minutes
**Turns:** 8
**Outcome:** Adoption plan written, most urgent gap (missing system index) fixed immediately

---

## Turn 1: User Invokes $adopt

**User:**
> $adopt

## Turn 2: Agent Detects Project State

**Delegated review (`technical-director` role profile, coordinated by `$adopt`):**
> Running brownfield audit...
>
> **Phase 1: Project State Detection**
>
> | Artifact Category | Found | Notes |
> |------------------|-------|-------|
> | Engine configuration | ✅ | Godot 4.6 in AGENTS.md |
> | Source code | ✅ | ~4000 lines in `src/gameplay/` |
> | Design docs | ⚠️ | 3 files in `design/`, not in GDD format |
> | Architecture docs | ❌ | `docs/architecture/` missing |
> | Systems index | ❌ | `design/gdd/systems-index.md` missing |
> | Production tracking | ❌ | `production/` directory missing |
> | Sprint/story files | ❌ | None |
>
> **Phase 2: Format Audit (existing files)**
>
> Checking internal structure of the 3 design files...
>
> *`design/combat-notes.md`:*
> - Has informal notes, no GDD template sections
> - Contains: some rule descriptions, a damage formula, rough balance numbers
> - Missing from GDD template: Overview, Player Fantasy, Edge Cases, Dependencies, Tuning Knobs, Acceptance Criteria (6 of 8 sections)
>
> *`design/crafting-ideas.md`:*
> - Brainstorm-style notes, no structure
> - No formulas, no acceptance criteria
> - Represents early concept thinking — useful as input for a GDD, not yet a GDD
>
> *`design/inventory.md`:*
> - Closest to a GDD — has Overview and Rules sections
> - Missing: Player Fantasy, Formulas, Edge Cases, Tuning Knobs, Acceptance Criteria (5 of 8 sections)
>
> **Phase 3: Gap Classification**
>
> | Gap | Severity | Reason |
> |-----|----------|--------|
> | No systems index | BLOCKING | `$design-system`, `$create-stories`, `$gate-check` all require it |
> | GDD files not in template format | HIGH | Skills cannot reference TR-IDs from malformed GDDs |
> | No architecture docs | HIGH | Cannot run `$architecture-review` or `$create-control-manifest` |
> | No production tracking | MEDIUM | Sprint and story skills won't work, but not needed until production phase |
> | `design/crafting-ideas.md` — pre-GDD content | LOW | Useful as input; needs full GDD authoring before it blocks anything |

## Turn 3: Agent Presents the Migration Plan

**Agent:**
> **Phase 4: Migration Plan**
>
> 7 ordered steps to bring your project into full alignment. NEVER overwrites your existing content — each step fills gaps only.
>
> | # | Step | Skill | Priority | Notes |
> |---|------|-------|----------|-------|
> | 1 | Create `design/gdd/systems-index.md` | `$map-systems` or `$adopt` inline | BLOCKING | Unblocks all downstream skills |
> | 2 | Retrofit `design/inventory.md` → GDD format | `$design-system retrofit design/inventory.md` | HIGH | Adds 5 missing sections, keeps your existing content |
> | 3 | Retrofit `design/combat-notes.md` → GDD format | `$design-system retrofit design/combat-notes.md` | HIGH | Adds 6 missing sections |
> | 4 | Convert `design/crafting-ideas.md` → full GDD | `$design-system crafting` (new authoring, uses ideas as input) | MEDIUM | Not a retrofit — too informal to retrofit |
> | 5 | Create architecture ADRs from existing code | `$reverse-document` + `$architecture-decision` | HIGH | Captures decisions already made in code |
> | 6 | Create master architecture document | `$create-architecture` | HIGH | After ADRs |
> | 7 | Set up production tracking | `$sprint-plan new` | MEDIUM | After architecture phase |
>
> **Important:** Step 1 must happen before any other step. Everything else can be done in parallel or reordered based on your priorities.
>
> May I write this plan to `docs/adoption-plan-2026-03-12.md`?

**User:**
> Yes. Write it.

**Agent writes adoption plan.**

## Turn 4: Agent Offers to Fix the Most Urgent Gap

**Agent:**
> The BLOCKING gap is the missing `design/gdd/systems-index.md`.
>
> I can create one now by reading your existing code and design docs to infer what systems you've built. This is faster than running `$map-systems` from scratch — I'll populate it based on what already exists, then you confirm or adjust.
>
> Would you like me to do that now?

**User:**
> Yes, do it.

## Turn 5: Agent Reads Codebase and Drafts Systems Index

**Agent:**
> Reading `src/gameplay/` to infer systems...
>
> Found these system boundaries in the code:
>
> - `src/gameplay/combat/` — damage calculation, hit detection, status effects
> - `src/gameplay/inventory/` — item management, weight, stacks
> - `src/gameplay/crafting/` — recipe lookup, result generation (references inventory)
> - `src/gameplay/movement/` — CharacterBody2D, terrain modifiers (referenced by combat for positioning)
> - `src/gameplay/ui/` — HUD, inventory screen, dialogue box
> - `src/gameplay/world/` — tile map, terrain types, chunk loading
>
> **Draft systems index:**
>
> | System | Category | Priority | Dependencies | GDD Status |
> |--------|----------|----------|--------------|------------|
> | Movement | Foundation | MVP | None | ❌ Missing |
> | World/Terrain | Foundation | MVP | Movement | ❌ Missing |
> | Combat | Core | MVP | Movement | ⚠️ Needs retrofit |
> | Inventory | Core | MVP | None | ⚠️ Needs retrofit |
> | Crafting | Feature | MVP | Inventory | ❌ Pre-GDD only |
> | UI / HUD | Presentation | MVP | Combat, Inventory, Movement | ❌ Missing |
>
> Does this look right? Anything I missed or miscategorized?

**User:**
> Looks right. Add a Stamina system — it's in combat/ but should be its own system.

**Agent:**
> Added Stamina as a Core / MVP system:
>
> | Stamina | Core | MVP | Movement, Combat | ❌ Missing |
>
> Updated dependency: Movement depends on Stamina (movement drains it).
>
> May I write this to `design/gdd/systems-index.md`?

## Turn 6: User Approves

**User:**
> Yes

**Agent writes `design/gdd/systems-index.md`.**

## Turn 7: Agent Shows What's Now Unlocked

**Agent:**
> `design/gdd/systems-index.md` created.
>
> **BLOCKING gap resolved.** The following skills can now run:
>
> - ✅ `$design-system [name]` — guided GDD authoring for any system
> - ✅ `$design-system retrofit [path]` — fill missing sections in existing docs
> - ✅ `$gate-check` — now has a systems index to validate
> - ✅ `$help` — can now show correct phase workflow
>
> **Recommended next steps (from adoption plan):**
>
> 1. Run `$design-system retrofit design/inventory.md` — your most complete existing doc, easiest win
> 2. Run `$design-system retrofit design/combat-notes.md`
> 3. Run `$design-system crafting` — author crafting GDD using your ideas file as input
>
> After those 3, you'll have 5 of 7 systems with complete GDDs. Then run `$review-all-gdds` to catch cross-system consistency issues before architecture work.

## Turn 8: User Confirms Plan

**User:**
> Perfect. I'll start with the inventory retrofit.

**Agent:**
> Run:
> ```
> $design-system retrofit design/inventory.md
> ```
>
> The skill will detect your existing Overview and Rules sections, show you which of the 8 sections are missing, and run the section cycle only for the gaps. Your existing content won't be touched.

---

## What This Example Demonstrates

- **FORMAT audit, not existence audit**: `$adopt` doesn't just check whether files exist — it checks whether their internal structure matches what skills expect. A file named `gdd.md` with no template sections is flagged as a gap.
- **Migration, not replacement**: existing content is never overwritten. The plan fills gaps only.
- **BLOCKING gaps surface first**: the missing systems index is identified as BLOCKING because it prevents the most skills from functioning.
- **Inline creation of the urgent gap**: rather than just reporting the gap, the agent offers to fix it immediately in the same session.
- **Inferred from code**: the systems index is bootstrapped from the codebase structure, not written from scratch — brownfield code already contains the answer.
- **Retrofit vs. new authoring**: `$design-system retrofit` handles existing-but-incomplete docs; full `$design-system` handles net-new docs. The adoption plan distinguishes which applies to each file.
- **Optional thread fork**: before a large adoption audit, use `codex fork` when
  you want the audit isolated from the original thread. `$adopt` does not imply
  that the client forks automatically.
