# Collaborative Session Examples

This directory contains realistic, end-to-end session transcripts showing how the Codex Game Studios workflow works in practice. Each example demonstrates the **collaborative workflow** where agents ask questions, present options, and wait for user approval rather than autonomously generating content.

---

## Visual Reference

**New to the system? Start here:**
[Skill Flow Diagrams](skill-flow-diagrams.md) — visual maps of all 7 phases and how skills chain together.

---

## 📚 **Available Examples**

### CORE WORKFLOW

### [Skill Flow Diagrams](skill-flow-diagrams.md)
**Type:** Visual Reference
**Complexity:** All levels

Full pipeline overview (zero to ship), plus detailed chain diagrams for:
design-system, story lifecycle, UX pipeline, and brownfield onboarding.
**Start here if you want to understand how the pieces fit together.**

---

### [Session: Authoring a GDD with $design-system](session-design-system-skill.md)
**Type:** Design (skill-driven)
**Skill:** `$design-system`
**Duration:** ~60 minutes (14 turns)
**Complexity:** Medium

**Scenario:**
Dev runs `$design-system movement` after `$map-systems` produced the systems index. The skill loads context from the game concept and dependency GDDs, runs a technical feasibility pre-check, then guides through all 8 GDD sections one at a time — drafting, approving, and writing each section to disk before moving to the next.

**Key Moments:**
- Technical feasibility pre-check flags Jolt physics default change (Godot 4.6)
- Incremental writing: each section on disk immediately after approval
- Session crash during section 5 → agent resumes from first empty section
- Dependency signals (stamina, inventory) surfaced during the Dependencies section
- Ends with explicit handoff: "run `$design-review` before the next system"

**Learn:**
- How `$design-system` is different from asking an agent to "write a GDD"
- How the section-by-section cycle prevents 30k-token context bloat
- How incremental file writing survives session crashes
- How the skill surfaces downstream dependency contracts

---

### [Session: Full Story Lifecycle](session-story-lifecycle.md)
**Type:** Full Workflow
**Skills:** `$story-readiness` → implementation → `$story-done`
**Duration:** ~50 minutes (13 turns)
**Complexity:** Medium

**Scenario:**
Dev picks up a story from the sprint backlog. `$story-readiness` catches a roll-direction ambiguity before any code is written. After implementation, `$story-done` verifies 9 acceptance criteria, identifies 2 deferred criteria (inventory not integrated yet), and closes the story with notes.

**Key Moments:**
- `$story-readiness` catches spec ambiguity in Turn 2 — resolved before implementation starts
- ADR status check: story would be BLOCKED if ADR was still Proposed
- Manifest version check: confirms story's guidance hasn't drifted from current architecture
- Deferred criteria tracked (not lost) when integration not yet possible
- `sprint-status.yaml` updated at story close, next ready story surfaced automatically

**Learn:**
- Why `$story-readiness` prevents late-implementation ambiguity
- How deferred criteria work (COMPLETE WITH NOTES vs. BLOCKED)
- How TR-ID references prevent false deviation flags
- The full loop from backlog → implemented → closed

---

### [Session: Gate Check and Phase Transition](session-gate-check-phase-transition.md)
**Type:** Phase Gate
**Skill:** `$gate-check`
**Duration:** ~20 minutes (7 turns)
**Complexity:** Low

**Scenario:**
Dev completes the Systems Design phase and runs `$gate-check` to advance. The gate finds all 6 MVP GDDs complete, cross-review passed with one low-severity concern. Gate passes, `stage.txt` updated, and the agent provides a specific ordered checklist for Technical Setup.

**Key Moments:**
- Gate validates artifact presence AND internal completeness (8 sections per GDD)
- CONCERNS ≠ FAIL: low-severity cross-review note passes the gate
- stage.txt update changes what `$help`, `$sprint-status`, and all skills see going forward
- Agent surfaces the cross-review concern as a concrete ADR to write next
- Next phase checklist is specific and ordered, not generic

**Learn:**
- What a gate check actually validates (not just "do files exist?")
- How PASS/CONCERNS/FAIL verdicts work
- Why stage.txt is the authority for phase tracking
- What changes after a phase transition

---

### [Session: UX Pipeline — $ux-design → $ux-review → $team-ui](session-ux-pipeline.md)
**Type:** UX Design Pipeline
**Skills:** `$ux-design`, `$ux-review`, `$team-ui`
**Duration:** ~90 minutes (16 turns)
**Complexity:** Medium-High

**Scenario:**
Dev designs the HUD and inventory screen. `$ux-design` reads the player journey and GDDs to ground decisions in player emotional state. `$ux-review` catches a blocking accessibility gap (no keyboard alternative to drag-drop) and an advisory colorblind issue. After fixes, `$team-ui` accepts the handoff.

**Key Moments:**
- HUD philosophy choice (diegetic vs. persistent vs. tactical) grounded in survival genre conventions
- `$ux-review` distinguishes BLOCKING (stops handoff) vs. ADVISORY (can fix in visual pass)
- Accessibility caught before implementation, not during QA
- Keyboard alternative added in one turn; review re-runs and passes
- `$team-ui` checks for a passing `$ux-review` before starting visual design

**Learn:**
- How `$ux-design` uses player journey context to ground UI decisions
- What `$ux-review` actually checks (not just "does a spec exist?")
- The difference between HUD doc (`design/ux/hud.md`) and per-screen specs
- How accessibility issues are handled at design time vs. implementation time

---

### [Session: Brownfield Onboarding with $adopt](session-adopt-brownfield.md)
**Type:** Brownfield Adoption
**Skill:** `$adopt`
**Duration:** ~30 minutes (8 turns)
**Complexity:** Low-Medium

**Scenario:**
Dev has 3 months of existing code and rough design notes but nothing in the right format. `$adopt` audits format compliance (not just file existence), classifies 4 gaps by severity, builds an ordered 7-step migration plan, and immediately fixes the BLOCKING gap (missing systems index) by inferring it from the codebase.

**Key Moments:**
- FORMAT audit distinguishes "file exists" from "file has required internal structure"
- BLOCKING gap identified: missing systems index prevents 4+ skills from running
- Migration plan is ordered: blocking gaps first, then high, then medium
- Systems index bootstrapped from code structure — brownfield code contains the answer
- Retrofit mode vs. new authoring: `$design-system retrofit` fills gaps without overwriting

**Learn:**
- The difference between `$adopt` and `$project-stage-detect`
- How format compliance is checked (section detection, not just file presence)
- How brownfield projects can onboard without losing existing work
- When to use retrofit mode vs. full authoring

---

### FOUNDATIONAL EXAMPLES

### [Session: Designing the Crafting System](session-design-crafting-system.md)
**Type:** Design
**Agent:** game-designer
**Duration:** ~45 minutes (12 turns)
**Complexity:** Medium

**Scenario:**
Solo dev needs to design a crafting system that serves Pillar 2 ("Emergent Discovery Through Experimentation"). The agent guides them through question/answer, presents 3 design options with game theory analysis, incorporates user modifications, and iteratively drafts the GDD with approval at each step.

**Key Collaborative Moments:**
- Agent asks 5 clarifying questions upfront
- Presents 3 distinct options with pros/cons + MDA alignment
- User modifies recommended option, agent incorporates immediately
- Edge case flagged proactively ("what if non-recipe combo?")
- Each GDD section shown for approval before moving to next
- Explicit "May I write to [file]?" before creating file

**Learn:**
- How design agents ask about goals, constraints, references
- How to present options using game design theory (MDA, SDT, Bartle)
- How to iterate on drafts section-by-section
- When to delegate to specialists (systems-designer, economy-designer)

---

### [Session: Implementing Combat Damage Calculation](session-implement-combat-damage.md)
**Type:** Implementation
**Agent:** gameplay-programmer
**Duration:** ~30 minutes (10 turns)
**Complexity:** Low-Medium

**Scenario:**
User has a complete design doc and wants the damage calculation implemented. Agent reads the spec, identifies 7 ambiguities/gaps, asks clarifying questions, proposes architecture for approval, implements with rule enforcement, and proactively writes tests.

**Key Collaborative Moments:**
- Agent reads design doc first, identifies 7 spec ambiguities
- Architecture proposed with code samples BEFORE implementation
- User requests type safety, agent refines and re-proposes
- Rules catch issues (hardcoded values), agent fixes transparently
- Tests written proactively following verification-driven development
- Agent offers options for next steps rather than assuming

**Learn:**
- How implementation agents clarify specs before coding
- How to propose architecture with code samples for approval
- How scoped instructions guide implementation review
- How to handle spec gaps (ask, don't assume)
- Verification-driven development (tests prove it works)

---

### [Session: Scope Crisis - Strategic Decision Making](session-scope-crisis-decision.md)
**Type:** Strategic Decision
**Agent:** creative-director
**Duration:** ~25 minutes (8 turns)
**Complexity:** High

**Scenario:**
Solo dev faces crisis: Alpha milestone in 2 weeks, crafting system needs 3 weeks, investor demo is make-or-break. Creative director gathers context, frames the decision, presents 3 strategic options with honest trade-off analysis, makes recommendation but defers to user, then documents decision with ADR and demo script.

**Key Collaborative Moments:**
- Agent reads context docs before proposing solutions
- Asks 5 questions to understand decision constraints
- Frames decision properly (what's at stake, evaluation criteria)
- Presents 3 options with risk analysis and historical precedent
- Makes strong recommendation but explicitly: "this is your call"
- Documents decision + provides demo script to support user

**Learn:**
- How leadership agents frame strategic decisions
- How to present options with trade-off analysis
- How to use game dev precedent and theory in recommendations
- How to document decisions (ADRs)
- How to cascade decisions to affected departments

---

### [Reverse Documentation Workflow](reverse-document-workflow-example.md)
**Type:** Brownfield Documentation
**Agent:** game-designer
**Duration:** ~20 minutes
**Complexity:** Low

**Scenario:**
Developer built a skill tree system but never wrote a design doc. Agent reads the code, infers the design intent, asks clarifying questions about ambiguous decisions, and produces a retroactive GDD.

---

## 🎯 **What These Examples Demonstrate**

All examples follow the **collaborative workflow pattern:**

```
Question → Options → Decision → Draft → Approval
```

> **Note:** These examples use ordinary conversation so they remain valid across Codex clients. A structured question control may be used when available, but the workflow depends only on explaining options and recording the user's decision.

### ✅ **Collaborative Behaviors Shown:**

1. **Agents Ask Before Assuming**
   - Design agents ask about goals, constraints, references
   - Implementation agents clarify spec ambiguities
   - Leadership agents gather full context before recommending

2. **Agents Present Options, Not Dictates**
   - 2-4 options with pros/cons
   - Reasoning based on theory, precedent, project pillars
   - Recommendation made, but user decides

3. **Agents Show Work Before Finalizing**
   - Design drafts shown section-by-section
   - Architecture proposals shown before implementation
   - Strategic analysis presented before decisions

4. **Agents Get Approval Before Writing Files**
   - Explicit "May I write to [file]?" before writing files
   - Multi-file changes list all affected files first
   - User says "Yes" before any file is created

5. **Agents Iterate on Feedback**
   - User modifications incorporated immediately
   - No defensiveness when user changes recommendations
   - Celebrate when user improves agent's suggestion

---

## 📖 **How to Use These Examples**

### For New Users:
Read these examples BEFORE your first session. They show realistic expectations for how agents work:
- Agents are consultants, not autonomous executors
- You make all creative/strategic decisions
- Agents provide expert guidance and options

### For Understanding Specific Workflows:
- **New to the system?** → Read skill-flow-diagrams.md first
- **Running $design-system for the first time?** → Read session-design-system-skill.md
- **Picking up a story?** → Read session-story-lifecycle.md
- **Finishing a phase?** → Read session-gate-check-phase-transition.md
- **Starting UI work?** → Read session-ux-pipeline.md
- **Have an existing project?** → Read session-adopt-brownfield.md
- **Designing a system (agent-driven)?** → Read session-design-crafting-system.md
- **Implementing code?** → Read session-implement-combat-damage.md
- **Making strategic decisions?** → Read session-scope-crisis-decision.md

### For Training:
If you're teaching someone to use this system, walk through one example turn-by-turn to show:
- What good questions look like
- How to evaluate presented options
- When to approve vs. request changes
- How to maintain creative control while leveraging AI expertise

---

## 🔍 **Common Patterns Across All Examples**

### Turn 1-2: **Understand Before Acting**
- Agent reads context (design docs, specs, constraints)
- Agent asks clarifying questions
- No assumptions or guesses

### Turn 3-5: **Present Options with Reasoning**
- 2-4 distinct approaches
- Pros/cons for each
- Theory/precedent supporting the analysis
- Recommendation made, decision deferred to user

### Turn 6-8: **Iterate on Drafts**
- Show work incrementally
- Incorporate feedback immediately
- Flag edge cases or ambiguities proactively

### Turn 9-10: **Approval and Completion**
- "May I write to [file]?"
- User: "Yes"
- Agent writes files
- Agent offers next steps (tests, review, integration)

---

## 🚀 **Try It Yourself**

After reading these examples, try this exercise:

1. Pick one of your game systems (combat, inventory, progression, etc.)
2. Ask the relevant agent to design or implement it
3. Notice if the agent:
   - ✅ Asks clarifying questions upfront
   - ✅ Presents options with reasoning
   - ✅ Shows drafts before finalizing
   - ✅ Requests approval before writing files

If the agent skips any of these, remind it:
> "Please follow the collaborative protocol from docs/COLLABORATIVE-DESIGN-PRINCIPLE.md"

---

## 📝 **Additional Resources**

- **Full Principle Documentation:** [docs/COLLABORATIVE-DESIGN-PRINCIPLE.md](../COLLABORATIVE-DESIGN-PRINCIPLE.md)
- **Workflow Guide:** [docs/WORKFLOW-GUIDE.md](../WORKFLOW-GUIDE.md)
- **Role Profile Roster:** [docs/studio/agent-roster.md](../studio/agent-roster.md)
- **AGENTS.md (Collaboration Protocol):** [AGENTS.md](../../AGENTS.md#collaboration-protocol)
