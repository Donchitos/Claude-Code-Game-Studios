# Skill Test Spec: $team-live-ops

## Skill Summary

Orchestrates the live-ops team through a 7-phase planning pipeline to produce a
season or event plan. Coordinates live-ops-designer, economy-designer,
analytics-engineer, community-manager, narrative-director, and writer. Phases 3
and 4 (economy design and analytics) run simultaneously. Ends with a consolidated
season plan requiring user approval before handoff to production.

---

## Static Assertions (Structural)

- [ ] Has non-empty `name` and `description`; `agents/openai.yaml` has non-empty display name and short description
- [ ] Has ≥2 phase headings
- [ ] Contains verdict keywords: COMPLETE, BLOCKED
- [ ] Contains "May I write" language in the File Write Protocol section (delegated to sub-agents)
- [ ] Has a File Write Protocol section stating that the orchestrator does not write files directly
- [ ] Has a next-step handoff at the end referencing `$design-review`, `$sprint-plan`, and `$team-release`
- [ ] Uses `AskUserQuestion` at phase transitions to capture user approval before proceeding
- [ ] States explicitly that Phases 3 and 4 can run simultaneously (parallel spawning)
- [ ] Error recovery section present (or implied through BLOCKED handling)
- [ ] Output documents section specifies paths under `design/live-ops/seasons/`

---

## Test Cases

### Case 1: Happy Path — All 7 phases complete, season plan produced

**Fixture:**
- `design/live-ops/economy-rules.md` exists with current economy configuration
- `design/live-ops/ethics-policy.md` exists with the project ethics policy
- Game concept document exists at its standard path
- No existing season documents for the new season name being planned

**Input:** `$team-live-ops "Season 2: The Frozen Wastes"`

**Expected behavior:**
1. Phase 1: Spawns `live-ops-designer` via Task; receives season brief with scope, content list, and retention mechanic; presents to user
2. AskUserQuestion: user approves Phase 1 output before Phase 2 begins
3. Phase 2: Spawns `narrative-director` via Task; reads the Phase 1 season brief; produces narrative framing document (theme, story hook, lore connections); presents to user
4. Phase 3 and 4 (parallel): Spawns `economy-designer` and `analytics-engineer` simultaneously via two Task calls before waiting for either result; economy-designer reads `design/live-ops/economy-rules.md`
5. Phase 5: Spawns `narrative-director` and `writer` in parallel to produce in-game narrative text and player-facing copy; both read Phase 2 narrative framing doc
6. Phase 6: Spawns `community-manager` via Task; reads season brief, economy design, and narrative framing; produces communication calendar with draft copy
7. Phase 7: Collects all phase outputs; presents consolidated season plan summary including economy health check, analytics readiness, ethics review, and open questions
8. AskUserQuestion: user approves the full season plan
9. Sub-agents ask "May I write to `design/live-ops/seasons/S2_The_Frozen_Wastes.md`?", `...analytics.md`, and `...comms.md` before writing
10. Verdict: COMPLETE — season plan produced and handed off for production

**Assertions:**
- [ ] All 7 phases execute in order; Phase 3 and 4 are issued as parallel Task calls
- [ ] Phase 7 consolidated summary includes all six sections (season brief, narrative framing, economy design, analytics plan, content inventory, communication calendar)
- [ ] Ethics review section in Phase 7 explicitly references `design/live-ops/ethics-policy.md`
- [ ] Three output documents written to `design/live-ops/seasons/` with correct naming convention
- [ ] File writes are delegated to sub-agents — orchestrator does not write directly
- [ ] Verdict: COMPLETE appears in final output
- [ ] Next steps reference `$design-review`, `$sprint-plan`, and `$team-release`

---

### Case 2: Ethics Violation Found — Reward element violates ethics policy

**Fixture:**
- All standard live-ops fixtures present (economy-rules.md, ethics-policy.md)
- `design/live-ops/ethics-policy.md` explicitly prohibits loot boxes targeting players under 18
- economy-designer (Phase 3) proposes a "Mystery Chest" mechanic with randomized premium rewards and no pity timer

**Input:** `$team-live-ops "Season 3: Shadow Tournament"`

**Expected behavior:**
1. Phases 1–4 proceed normally; economy-designer proposes Mystery Chest mechanic
2. Phase 7: Orchestrator reviews Phase 3 output against ethics policy; identifies Mystery Chest as a violation of the "no untransparent random premium rewards" rule in the ethics policy
3. Ethics review section of the Phase 7 summary flags the violation explicitly: "ETHICS FLAG: Mystery Chest mechanic in Phase 3 economy design violates [policy rule]. Approval is blocked until this is resolved."
4. AskUserQuestion presented with resolution options before season plan approval is offered
5. Skill does NOT issue a COMPLETE verdict or write output documents until the ethics violation is resolved or explicitly waived by the user

**Assertions:**
- [ ] Phase 7 ethics review section explicitly names the violating element and the policy rule it breaks
- [ ] Skill does not auto-approve the season plan when an ethics violation is present
- [ ] AskUserQuestion is used to surface the violation and offer resolution options (revise economy design, override with documented rationale, cancel)
- [ ] Output documents are NOT written while the violation is unresolved
- [ ] If user chooses to revise: skill re-spawns economy-designer to produce a corrected design before returning to Phase 7 review
- [ ] Verdict: COMPLETE is only issued after the ethics flag is cleared

---

### Case 3: No Argument — Usage guidance shown

**Fixture:**
- Any project state

**Input:** `$team-live-ops` (no argument)

**Expected behavior:**
1. Phase 1: No argument detected
2. Outputs: "Usage: `$team-live-ops [season name or event description]` — Provide the name or description of the season or live event to plan."
3. Skill exits immediately without spawning any subagents

**Assertions:**
- [ ] Skill does NOT guess a season name or fabricate a scope
- [ ] Error message includes the correct usage format with the canonical invocation syntax
- [ ] No Task calls are issued before the argument check fails
- [ ] No files are read or written

---

### Case 4: Parallel Phase Validation — Phases 3 and 4 run simultaneously

**Fixture:**
- All standard live-ops fixtures present
- Phase 1 (season brief) and Phase 2 (narrative framing) already approved
- Phase 3 (economy-designer) and Phase 4 (analytics-engineer) inputs are independent of each other

**Input:** `$team-live-ops "Season 1: The First Thaw"` (observed at Phase 3/4 transition)

**Expected behavior:**
1. After Phase 2 is approved by the user, the orchestrator issues both Task calls (economy-designer and analytics-engineer) before awaiting either result
2. Both agents receive the season brief as context; analytics-engineer does NOT wait for economy-designer output to begin
3. Economy-designer output and analytics-engineer output are collected together before Phase 5 begins
4. If one of the two parallel agents blocks, the other continues; a partial result is reported

**Assertions:**
- [ ] Both Task calls for Phase 3 and Phase 4 are issued before either result is awaited — they are not sequential
- [ ] Analytics-engineer prompt does NOT include economy-designer output as a required input (the inputs are independent)
- [ ] If economy-designer blocks but analytics-engineer succeeds, analytics output is preserved and the block is surfaced via AskUserQuestion
- [ ] Phase 5 does not begin until BOTH Phase 3 and Phase 4 results are collected
- [ ] Skill documentation explicitly states "Phases 3 and 4 can run simultaneously"

---

### Case 5: Missing Ethics Policy — `design/live-ops/ethics-policy.md` does not exist

**Fixture:**
- `design/live-ops/economy-rules.md` exists
- `design/live-ops/ethics-policy.md` does NOT exist
- All other fixtures are present

**Input:** `$team-live-ops "Season 4: Desert Heat"`

**Expected behavior:**
1. Phases 1–4 proceed; economy-designer and analytics-engineer are given the ethics policy path but it is absent
2. Phase 7: Orchestrator attempts to run ethics review; detects that `design/live-ops/ethics-policy.md` is missing
3. Phase 7 summary includes a gap flag: "ETHICS REVIEW SKIPPED: `design/live-ops/ethics-policy.md` not found. Economy design was not reviewed against an ethics policy. Recommend creating one before production begins."
4. Skill still completes the season plan and reaches COMPLETE verdict, but the gap is prominently flagged in the output and in the season design document
5. Next steps include a recommendation to create the ethics policy document

**Assertions:**
- [ ] Skill does NOT error out when the ethics policy file is missing
- [ ] Skill does NOT fabricate ethics policy rules in the absence of the file
- [ ] Phase 7 summary explicitly notes that ethics review was skipped and why
- [ ] Verdict: COMPLETE is still reachable despite the missing file
- [ ] Gap flag appears in the season design output document (not just in conversation)
- [ ] Next steps recommend creating `design/live-ops/ethics-policy.md`

---

## Protocol Compliance

- [ ] `AskUserQuestion` used at every phase transition — user approves before the next phase begins
- [ ] Phases 3 and 4 are always spawned in parallel, not sequentially
- [ ] File Write Protocol: orchestrator never calls Write/Edit directly — all writes are delegated to sub-agents
- [ ] Each output document gets its own "May I write to [path]?" ask from the relevant sub-agent
- [ ] Ethics review in Phase 7 always references the ethics policy file path explicitly
- [ ] Error recovery: any BLOCKED agent is surfaced immediately with AskUserQuestion options (skip / retry / stop)
- [ ] Partial reports are produced if any phase blocks — work is never discarded
- [ ] Verdict: COMPLETE only after user approves the consolidated season plan; BLOCKED if any unresolved ethics violation exists
- [ ] Next steps always include `$design-review`, `$sprint-plan`, and `$team-release`

---

## Coverage Notes

- Phase 5 parallel spawning (narrative-director + writer) follows the same pattern as Phases 3/4 but is not separately tested here — it uses the same parallel Task protocol validated in Case 4.
- The "economy-rules.md absent" edge case is not separately tested — it would surface as a BLOCKED result from economy-designer and follow the standard error recovery path tested implicitly in Case 4.
- The full content writing pipeline (Phase 5 output validation) is validated implicitly by the Case 1 happy path consolidated summary check.
- Community manager communication calendar format (pre-launch, launch day, mid-season, final week) is validated implicitly by Case 1; no separate edge case is needed.
