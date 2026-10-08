# /prototype — Phase 1: Define the Question

> Part of `/prototype`. `SKILL.md` names when to read this file; the settings it
> resolved and the rules under its later headings still apply here.

## Phase 1: Define the Question

Every `AskUserQuestion` call follows `.claude/docs/automation-modes.md`
(collaborative asks always · guided major-only · autonomous logs and proceeds;
`automation_always_ask` categories always prompt).

**Check for spike mode:** If `--spike` was passed, skip to the **Spike Mode** section
at the bottom of this skill.

**Check for a carry-forward note:** Glob `prototypes/*/PIVOT-NOTE.md`. If one
exists for this concept (or an earlier version of it), read it and start from its
revised hypothesis instead of forming one from scratch — say which note you used.

Then, unless `--spike` sent you to Spike Mode, use `AskUserQuestion` to confirm
intent before proceeding — with or without a carry-forward note:

- **Prompt**: "How would you like to use this prototype session?"
- **Options**:
  - `Prototype this concept` — build a throwaway build to validate the core idea is fun before writing GDDs (1–3 days)
  - `Skip — concept already proven` — I have enough evidence this works; log it and proceed directly to design
  - `Mid-production spike` — I'm already in Production and want to test a specific mechanic or technical question quickly (~4 hours, no phase gate implications)

**If "Skip — concept already proven":**
Ask (plain text, not a widget): "What evidence do you have that the concept works?"
Record the one-line answer, then stop. Note: "Concept prototype skipped — evidence:
[answer]." Suggest next step: `/map-systems` or `/design-system [mechanic]`.

**If "Mid-production spike"**: skip to the **Spike Mode** section below.

**If "Prototype this concept"**: continue with Phase 1 below.

---

**A note on prototype strategy:** The research on successful indie development
is consistent — building 2-3 concept variants and letting the best one win is
far more likely to succeed than iterating one concept until it works. This is
your first prototype, not necessarily your only one. If this prototype produces
a PIVOT verdict, consider whether to refine this concept OR start fresh with a
different angle on the same game idea and prototype that instead.

**Game jam as a prototype vehicle:** If you're planning a concept prototype anyway,
consider timing it to a game jam (Ludum Dare, GMTK Game Jam, Global Game Jam). Jams
provide a forced timebox (48-72 hours), instant distribution to thousands of players
who rate and review early builds, and a deadline that prevents scope creep by design.
Many shipped games (Celeste, VVVVVV) began as jam prototypes. Not required — but
worth considering if the timing is right.

Read the concept description from the argument. Before building anything, define
the **falsifiable hypothesis** this prototype must answer:

> *"If the player [does X], they will feel [Y] — we will know this is true if [measurable signal Z]."*

Good: "If the player swings on grapple hooks, traversal will feel fluid — we'll know if
players chain 3+ swings without stopping within 2 minutes of picking it up."

Bad: "Does this feel fun?" ← not testable, not falsifiable.

**If the concept is too vague to form a hypothesis, stop here.** Ask the user to
narrow the question before proceeding. A prototype without a clear question wastes time.

Also ask: **"What is the riskiest assumption in this concept?"** That is the first
thing the prototype should test — not the easiest part, the riskiest.

---
