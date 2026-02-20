# Collaborative Session Examples

This directory contains realistic, end-to-end session transcripts showing how the Game Studio Agent Architecture works in practice. Each example demonstrates the **collaborative workflow** where agents ask questions, present options, and wait for user approval rather than autonomously generating content.

---

## 📚 **Available Examples**

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
- How rules enforce standards automatically
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

## 🎯 **What These Examples Demonstrate**

All examples follow the **collaborative workflow pattern:**

```
Question → Options → Decision → Draft → Approval
```

> **Note:** These examples show the collaborative pattern as conversational text.
> In practice, agents now use the `AskUserQuestion` tool at decision points to
> present structured option pickers (with labels, descriptions, and multi-select).
> The pattern is **Explain → Capture**: agents explain their analysis in
> conversation first, then present a structured UI picker for the user's decision.

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
   - Explicit "May I write to [file]?" before using Write/Edit tools
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
- **Designing a system?** → Read session-design-crafting-system.md
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
- **Agent Roster:** [.claude/docs/agent-roster.md](../../.claude/docs/agent-roster.md)
- **CLAUDE.md (Collaboration Protocol):** [CLAUDE.md](../../CLAUDE.md#collaboration-protocol)
