# Example Session: $gate-check Phase Transition — Systems Design → Technical Setup

**Context:** Solo indie dev, end of week 5. The Systems Design phase feels complete — 6 MVP GDDs written, cross-review done, engine set up. User wants to formally advance to Technical Setup.

**Starting State:**
- `production/stage.txt` — currently `systems-design`
- `design/gdd/systems-index.md` — 6 MVP systems listed, all marked `Status: GDD Complete`
- `design/gdd/` — 6 GDD files present
- `design/gdd/gdd-cross-review-2026-03-10.md` — cross-review report, verdict: CONCERNS (1 low-priority note)
- Engine configured (Godot 4.6, `$setup-engine` complete)

**Session Duration:** ~20 minutes
**Turns:** 7
**Outcome:** Gate passed, `stage.txt` updated to `technical-setup`, clear list of what comes next

---

## Turn 1: User Initiates Gate Check

**User:**
> $gate-check

## Turn 2: Agent Detects Current Phase and Runs the Check

**Agent (via $gate-check):**
> Reading `production/stage.txt` — current phase: **systems-design**
>
> Running gate: **Systems Design → Technical Setup**
>
> ---
> **Required Artifacts Checklist:**
>
> | Artifact | Requirement | Status |
> |----------|-------------|--------|
> | `design/gdd/systems-index.md` | Exists, all MVP systems listed | ✅ |
> | Per-system GDDs | All MVP systems have a GDD | ✅ (6/6) |
> | `$design-review` per GDD | Each GDD reviewed | ✅ (6/6 review comments found) |
> | Cross-GDD review report | `design/gdd/gdd-cross-review-*.md` exists | ✅ |
> | Cross-review verdict | PASS or CONCERNS (not FAIL) | ✅ CONCERNS |
> | Engine configured | `production/stage.txt` or AGENTS.md engine entry | ✅ Godot 4.6 |
>
> ---
> **Content Scan:**
>
> Checking GDD completeness (8 required sections each)...
>
> | GDD | Missing Sections |
> |-----|-----------------|
> | movement-system.md | None ✅ |
> | stamina-system.md | None ✅ |
> | combat-system.md | None ✅ |
> | inventory-system.md | None ✅ |
> | crafting-system.md | None ✅ |
> | exploration-system.md | None ✅ |
>
> ---
> **Cross-Review Concerns (from `gdd-cross-review-2026-03-10.md`):**
>
> 1. ⚠️ LOW — Crafting and inventory both define "item stack size" independently with different defaults (crafting: 99, inventory: 64). One system should be the authority; the other should reference it. Not blocking — can resolve in ADR.
>
> ---
> **Verdict: PASS**
>
> All required artifacts present. Cross-review concern is LOW severity and can be resolved during Technical Setup via an ADR. This is a normal finding at this stage.
>
> **May I advance `production/stage.txt` to `technical-setup`?**

## Turn 3: User Confirms

**User:**
> Yes, advance it.

## Turn 4: Agent Updates Stage and Presents Next Steps

**Agent:**
> Updated `production/stage.txt` → `technical-setup`
>
> ---
> **You are now in: Technical Setup**
>
> This phase establishes the technical foundation before production coding starts. Your goal is a complete, approved architecture so that every story written in Pre-Production has clear, unambiguous technical guidance.
>
> **Required steps this phase (in order):**
>
> 1. **`$create-architecture`** — Author the master architecture document. Covers system decomposition, data flow, layer boundaries, and module responsibilities.
>
> 2. **`$architecture-decision` (one per significant technical choice)** — At minimum:
>    - Rendering approach (2D camera, viewport, etc.)
>    - Save/load strategy
>    - Audio bus architecture
>    - The "item stack size authority" issue from cross-review (crafting vs inventory)
>
> 3. **`$architecture-review`** — Validates all ADRs for completeness, dependency ordering, and GDD traceability. Produces the TR-registry.
>
> 4. **`$create-control-manifest`** — Converts Accepted ADRs into a flat programmer rules sheet. This is what implementation agents will consult during coding.
>
> 5. **`$gate-check`** — Technical Setup → Pre-Production gate. Requires: architecture doc, all ADRs Accepted, control manifest, and dependency ordering resolved.
>
> **Optional but recommended:**
> - `$tech-debt` scan if you have any prototype code you plan to carry forward
> - `$setup-engine` re-run if you haven't yet fetched Godot 4.6 API snapshots
>
> **Tip:** Start with `$architecture-decision` for the item stack size conflict. It's a quick win that closes an open question before it creates ambiguity in two ADRs later.

## Turn 5: User Asks About the Cross-Review Concern

**User:**
> What do I actually write in the ADR for the stack size conflict?

## Turn 6: Agent Advises

**Agent:**
> The ADR decision is: **which system owns the canonical `max_stack_size` value?**
>
> Two options to consider:
>
> **Option A: Inventory owns it**
> - `ItemData` resource (owned by inventory) gets `max_stack_size: int = 64`
> - Crafting system reads from `ItemData`, never sets its own value
> - Pros: inventory is the source of truth for all item properties
> - Cons: crafting team needs to know to look at inventory data
>
> **Option B: Item data resource owns it (shared resource)**
> - `ItemData.max_stack_size` is the authority for both systems
> - Both crafting and inventory import from `ItemData`
> - Pros: single source, no coupling between crafting and inventory modules
> - Cons: one more thing in the shared data layer
>
> Most studios go with B (shared resource) once they have >2 systems touching item data. But either is valid for a solo project.
>
> Run `$architecture-decision` and it will guide you through the ADR format, including the Dependencies section that links this ADR back to the two GDDs.

## Turn 7: User Wraps Up

**User:**
> Got it. I'll start with $architecture-decision for this.

**Agent:**
> Good starting point. The ADR will document the decision, the reasoning, and the GDD requirements it addresses — so when you write code months from now, the rationale is preserved.
>
> Your phase gate is logged. Run `$help` at any time during Technical Setup to see your current progress against the required checklist.

---

## What This Example Demonstrates

- **Gate check is automated, not manual**: agent reads artifacts and checks them — user doesn't fill out a form
- **CONCERNS ≠ FAIL**: the cross-review concern is LOW severity and passes the gate. A FAIL would require resolution before advancing.
- **Stage.txt is the authority**: `$help` and phase-aware skills read from `production/stage.txt` - updating it here changes what subsequent workflow checks see
- **Next steps are phase-specific**: the agent doesn't give a generic "good luck" — it gives the ordered checklist for Technical Setup specifically
- **Gate check surfaces carry-forward work**: the stack size conflict was a cross-review note; the gate check ensures it becomes a concrete ADR rather than getting lost
- **One advance per gate**: the user confirmed advancement explicitly. The gate doesn't auto-advance; human confirmation is required.
