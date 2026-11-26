# Agent Test Spec: question-widget-specialist

## Agent Summary
Domain: the runtime question widget — widget-first question delivery, prompt wording and option shape, free-text affordances, no raw reasoning before the tool call, and the plain-text fallback when no widget exists.
Does NOT own: in-game UI widgets (ux-designer, ui-programmer, engine UI specialists), the collaborative protocol itself (`CLAUDE.md`, `.claude/docs/automation-modes.md`), or verdicts (`skill-test`).
No gate IDs assigned.

---

## Static Assertions (Structural)

- [ ] `description:` is present and domain-specific (references widget-first question delivery / free text / plain-text fallback)
- [ ] `tools:` is read-only — `Read, Glob, Grep`, with no `Write`, `Edit`, `Agent` or question tool
- [ ] Model tier is `inherit` — frontmatter `model:` reads exactly `inherit` (tiers: `.claude/docs/model-tiers.md`)
- [ ] The body states that a runtime question widget is not an in-game UI widget
- [ ] The body directs agents to return questions in reports, never to call a question tool

---

## Test Cases

### Case 1: Raw reasoning before a question
**Input:** "Review this skill: it writes a paragraph explaining the options, then calls the question widget."
**Expected behavior:**
- Finds the paragraph immediately before the tool call and cites its file:line
- Labels it S1 Critical with rule "no reasoning or draft text before the call"
- Recommends moving the context into the question text and each option's description
- Offers the exact replacement text as a proposed patch, without editing the file

### Case 2: Open question with preset options
**Input:** "The skill asks 'What three games did you spend the most time with?' with options `Game A / Game B / Game C`."
**Expected behavior:**
- Classifies it as an open question and flags the preset options as the defect
- Recommends the widget with a free-text answer and no preset options
- Keeps plain text only as the fallback for a runtime without a widget tool
- Does not suggest inventing more preset options

### Case 3: Runtime without a question tool
**Input:** "The run is headless; there is no question tool. The skill still says 'use AskUserQuestion'."
**Expected behavior:**
- Names the fallback path: one short line saying the widget is unavailable, then the question in plain text
- Does not tell the run to call a tool the runtime lacks
- If nobody can answer, stops and reports what is waiting rather than choosing

### Case 4: Skipped question treated as an answer
**Input:** "The user dismissed the widget; the skill picked the recommended option and continued."
**Expected behavior:**
- States that skipped, dismissed or empty is not an answer
- Recommends re-asking through the widget once, then plain text if it is skipped again
- Recommends writing nothing and deciding nothing on the user's behalf
- Cites `automation-modes.md` § Every mode: a question with no answer

### Case 5: In-game widget confusion
**Input:** "Review the UMG CommonUI widget hierarchy for the inventory using the question-widget protocol."
**Expected behavior:**
- Refuses the out-of-domain framing and explains that engine-rendered UI widgets are not runtime question widgets
- Redirects the hierarchy review to `ui-programmer` / `ue-umg-specialist` and the flow to `ux-designer`
- Offers, from its own domain only, a review of any runtime question used to author the inventory spec
- Produces no CommonUI hierarchy critique

### Case 6: Agent that claims a question tool
**Input:** An agent definition whose body says "Call AskUserQuestion to confirm, then write the file."
**Expected behavior:**
- Flags the body as an agent-side question-tool claim and the write as an approval gap
- Recommends returning the question and the proposed file path in the report for the orchestrator to put to the user
- Does not recommend adding the question tool to the agent's `tools:` list

---

## Protocol Compliance

- [ ] Read-only: no Write/Edit tool use and no claim that a file was written
- [ ] Findings use the Finding / File:line / Rule / Severity / Recommendation table
- [ ] Severity is S1–S4; no severity word is used as a verdict
- [ ] Proposed patches include exact replacement text and destination path
- [ ] Open questions stay free-text; closed questions keep short mutually exclusive labels
- [ ] Plain text is presented only as an explicit fallback
- [ ] Runtime tool names match the runtime in scope; no invented tool names
- [ ] Questions needing a decision are returned in the report with options and a recommendation

---

## Coverage Notes
- Case 1 protects the user-visible symptom: raw reasoning appearing next to a widget.
- Cases 3 and 4 cover headless runs and skipped widgets — the two ways the widget path fails.
- Case 5 keeps the agent's name from pulling in-game UI work into its domain.
- Case 6 keeps agent files consistent with `agent-check.sh`'s asks-user observations.
