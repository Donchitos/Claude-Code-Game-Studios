# Skill Test Spec: /brainstorm

## Skill Summary

`/brainstorm` facilitates guided game concept ideation. It branches on the
resolved `workflow` tier **first**:

- **`minimal`** (the default — `modes.rigor` defaults to `minimal`) runs the
  **Lean Brief flow**: 2–3 one-line concepts, one pick, the brief fields filled
  conversationally, and a one-page `design/game-brief.md` written after
  "Brief is ready. May I write it to `design/game-brief.md`?". No director gates
  run and no `game-concept.md` is written.
- **`standard` / `full`** run the full flow: Creative Discovery, 3 distinct
  concepts, core loop, pillars, player types, scope, then
  `design/gdd/game-concept.md` after "Game concept is ready. May I write it to
  `design/gdd/game-concept.md`?".

In the full flow, director gates run at three points, not together: CD-PILLARS
(creative-director) and AD-CONCEPT-VISUAL (art-director) in parallel once
pillars are agreed (Phase 4); TD-FEASIBILITY (technical-director) after technical
risks are identified and before scope tiers (Phase 6); PR-SCOPE (producer) after
scope tiers are defined. Review mode comes from the resolved config
(`--review` overrides it); `lean` and `solo` skip all four with a named note each.
Both flows end with `Verdict: **COMPLETE**`.

---

## Static Assertions (Structural)

Checked against the SKILL.md by `/skill-test spec` — no fixture needed.

- [ ] Has required frontmatter fields: `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`
- [ ] Has ≥2 phase headings
- [ ] Contains verdict keyword: COMPLETE (in both the Lean Brief flow and the full flow)
- [ ] Contains "May I write" language for both `design/game-brief.md` and `design/gdd/game-concept.md`
- [ ] Has a next-step handoff at the end (`/map-systems` in the full flow's Path A; `/create-stories` in the Lean Brief flow)
- [ ] Documents 4 director gates in full mode: CD-PILLARS, AD-CONCEPT-VISUAL, TD-FEASIBILITY, PR-SCOPE
- [ ] Documents a named skip note for each gate in lean and solo modes

---

## Director Gate Checks

Full flow only (`workflow: standard` or `full`):

- **Full review mode**: CD-PILLARS + AD-CONCEPT-VISUAL spawn in parallel after
  pillars are agreed; TD-FEASIBILITY spawns after technical risks are identified;
  PR-SCOPE spawns after scope tiers are defined.
- **Lean review mode**: all 4 skipped (none is a PHASE-GATE). Notes read
  "CD-PILLARS skipped — Lean mode.", "AD-CONCEPT-VISUAL skipped — Lean mode.",
  "TD-FEASIBILITY skipped — Lean mode.", "PR-SCOPE skipped — Lean mode."
- **Solo review mode**: all 4 skipped, same notes with "Solo mode".

`workflow: minimal` (Lean Brief flow): no director gate is spawned at all.

---

## Test Cases

### Case 1: Happy Path — Full mode, 3 concepts, gates at their three points

**Fixture:**
- `project.yaml` sets `modes.rigor: full` (`workflow` → `full`, `review_mode` → `full`)
- No existing `design/gdd/game-concept.md`
- CD-PILLARS returns APPROVE; TD-FEASIBILITY returns VIABLE and PR-SCOPE returns REALISTIC (each gate's own verdict words)

**Input:** `/brainstorm`

**Expected behavior:**
1. Tier branch: `full` → full flow
2. Phase 1 asks discovery questions (favourite games as plain text; the
   Experience / Timeline / Dev level multi-tab `AskUserQuestion`)
3. Phase 2 presents 3 concepts, then a plain-list `AskUserQuestion` (no tabs) to pick
4. After pillars are locked, CD-PILLARS and AD-CONCEPT-VISUAL are spawned in
   parallel; their results are presented in a two-tab (Pillars / Visual anchor) `AskUserQuestion`
5. Phase 6 asks for platform and engine (the engine question always prompts);
   TD-FEASIBILITY spawns after risks are identified, before scope tiers
6. PR-SCOPE spawns after scope tiers are defined
7. Skill asks "Game concept is ready. May I write it to `design/gdd/game-concept.md`?"
8. Written after approval with a Visual Identity Anchor section; Path A next steps include `/map-systems`
9. Verdict is COMPLETE

**Assertions:**
- [ ] Exactly 3 concept options are presented
- [ ] CD-PILLARS and AD-CONCEPT-VISUAL are issued as simultaneous `Agent` calls
- [ ] TD-FEASIBILITY spawns before scope tiers are defined; PR-SCOPE after
- [ ] "May I write it to `design/gdd/game-concept.md`?" is asked before writing
- [ ] The concept document includes a Visual Identity Anchor section
- [ ] Next-step handoff lists `/map-systems`
- [ ] Verdict is COMPLETE

---

### Case 2: Failure Path — CD-PILLARS returns REJECT

**Fixture:**
- `project.yaml` sets `modes.rigor: full`
- Pillars and anti-pillars have been agreed with the user
- CD-PILLARS returns REJECT: "The pillars do not carry weight — none forces a design choice"
- AD-CONCEPT-VISUAL returns 3 named visual directions

**Input:** `/brainstorm`

**Expected behavior:**
1. Both gates were spawned in parallel; the skill collects both results
2. Because CD-PILLARS returned REJECT, the two-tab question is **not** used: the
   creative-director's feedback is presented in a Pillars question on its own,
   with options `Lock in as-is` / `Revise [specific pillar]` / `Discuss further`
3. Pillar issues are resolved first; only then is the Visual anchor question
   asked, on its own, with the art-director's 3 directions
4. The skill does not move on to document generation or the write ask while the pillar issue is open

**Assertions:**
- [ ] CD-PILLARS feedback is shown to the user
- [ ] User is offered `Revise [specific pillar]` and `Discuss further` (and may `Lock in as-is`)
- [ ] The first question after the REJECT has no Visual anchor tab
- [ ] Visual anchor selection is not requested until the pillar issue is resolved
- [ ] `design/gdd/game-concept.md` is not written at this point

---

### Case 3: Lean Mode — All 4 gates skipped with named notes

**Fixture:**
- `project.yaml` sets `modes.rigor: standard` (`workflow` → `standard`, `review_mode` → `lean`)
- No existing game concept

**Input:** `/brainstorm`

**Expected behavior:**
1. Tier branch: `standard` → full flow
2. At Phase 4: "CD-PILLARS skipped — Lean mode. AD-CONCEPT-VISUAL skipped — Lean mode."
3. At Phase 6: "TD-FEASIBILITY skipped — Lean mode." then "PR-SCOPE skipped — Lean mode."
4. No director agents are spawned
5. "Game concept is ready. May I write it to `design/gdd/game-concept.md`?" is asked
6. Written after approval; Verdict is COMPLETE

**Assertions:**
- [ ] All 4 skip notes appear, each naming its gate and "Lean mode"
- [ ] No `Agent` call is made for any director
- [ ] "May I write" is still asked before writing
- [ ] Verdict is COMPLETE

---

### Case 4: Solo Default — Minimal tier runs the Lean Brief flow

**Fixture:**
- `project.yaml` has `engine.name` set and no `modes` block (`modes.rigor`
  defaults to `minimal`: `workflow` → `minimal`, `review_mode` → `solo`)
- No `design/game-brief.md`, no `design/gdd/game-concept.md`

**Input:** `/brainstorm roguelike`

**Expected behavior:**
1. Tier branch: `minimal` → Lean Brief flow; Phases 1–5 are skipped
2. From the hint, proposes 2–3 one-line concepts and asks one `AskUserQuestion` to pick or combine
3. Fills the brief fields conversationally (pitch, core loop, player goal & fail
   state, MVP, out of scope, build order) and presents the brief for one confirmation
4. Asks "Brief is ready. May I write it to `design/game-brief.md`?" with
   `[A] Yes — write it` / `[B] Revise a field first`
5. Next steps: `/create-stories`, then `/dev-story`; `/setup-engine` is NOT listed
   because `engine.name` is set
6. Verdict is COMPLETE

**Assertions:**
- [ ] Output file is `design/game-brief.md`; `design/gdd/game-concept.md` is not written
- [ ] 2–3 one-line concepts are proposed (not the full 9-field concept cards)
- [ ] No director agent is spawned
- [ ] Next steps list `/create-stories` and `/dev-story`, not `/map-systems` or `/setup-engine`
- [ ] Verdict is COMPLETE

---

### Case 5: Director Gate — PR-SCOPE returns UNREALISTIC

**Fixture:**
- `project.yaml` sets `modes.rigor: full`
- Concept, pillars and scope tiers are defined
- PR-SCOPE returns UNREALISTIC: "The MVP would take 18+ months for a solo developer"
- The user cuts the MVP to the adjusted tiers the skill offers, then answers
  `[A] Yes — write it` to the write ask

**Input:** `/brainstorm`

**Expected behavior:**
1. PR-SCOPE spawns after scope tiers are defined
2. Skill presents the producer's assessment to the user
3. Because the verdict is UNREALISTIC, the skill offers to adjust the MVP
   definition or scope tiers before writing the document
4. The write ask comes only after that offer is resolved; the user decides
5. After the user approves the write, `design/gdd/game-concept.md` is written

**Assertions:**
- [ ] PR-SCOPE assessment is shown to the user before the "May I write" ask
- [ ] Skill offers to adjust the MVP definition or scope tiers
- [ ] Skill does NOT discard or auto-reject the concept — the user decides
- [ ] The concept is written only after the user approves the write
- [ ] "Estimated Scope" in the written concept matches the Scope Tiers timeline (e.g. "Large (X–Y months, solo)")

---

### Case 6: Solo Review on the Full Flow — All 4 gates skipped with Solo-mode notes

**Fixture:**
- `project.yaml` sets `modes.rigor: standard` (`workflow` → `standard`)
- No existing game concept

**Input:** `/brainstorm --review solo`

**Expected behavior:**
1. Tier branch: `standard` → full flow; `--review solo` overrides the resolved
   `review_mode` for this run
2. At Phase 4: "CD-PILLARS skipped — Solo mode. AD-CONCEPT-VISUAL skipped — Solo mode."
3. At Phase 6: "TD-FEASIBILITY skipped — Solo mode." then "PR-SCOPE skipped — Solo mode."
4. No director agents are spawned
5. "Game concept is ready. May I write it to `design/gdd/game-concept.md`?" is
   asked, and the concept is written after approval; Verdict is COMPLETE

**Assertions:**
- [ ] All 4 skip notes appear, each naming its gate and "Solo mode" (not "Lean mode")
- [ ] No `Agent` call is made for any director
- [ ] The concept is written only after the user's approval
- [ ] Verdict is COMPLETE

---

## Protocol Compliance

- [ ] Checks `workflow` before anything else and runs exactly one flow
- [ ] Full flow presents 3 concepts before the user commits; Lean Brief flow presents 2–3 one-liners
- [ ] Concept selection always asks, regardless of `modes.automation`
- [ ] Gates spawn at their own points in full mode (CD-PILLARS + AD-CONCEPT-VISUAL together; TD-FEASIBILITY; PR-SCOPE)
- [ ] In the full flow (`workflow: standard` / `full`), all 4 gates are skipped in lean and solo modes, each noted by name; the Lean Brief flow spawns no gate at all
- [ ] Asks "May I write" before writing `design/game-brief.md` or `design/gdd/game-concept.md`
- [ ] Ends with Verdict COMPLETE and the tier's next-step handoff

---

## Coverage Notes

- TD-FEASIBILITY returning HIGH RISK (offer to revisit scope) is not separately tested.
- A gate answering NOT ASSESSED (it lacked an input) is never an approval — the
  missing input is named and the gate re-run, or the result recorded as not
  assessed; not separately tested.
- The concept refinement loop ("Generate fresh directions") is not fixture-tested.
- Resuming an existing `design/game-brief.md` or `design/gdd/game-concept.md` is not separately tested.
- `guided` / `autonomous` automation behaviour for the pillar and write loops is not tested here.
