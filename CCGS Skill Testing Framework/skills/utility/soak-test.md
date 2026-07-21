# Skill Test Spec: $soak-test

## Skill Summary

`$soak-test` generates a structured soak test protocol — an extended runtime
test plan designed to surface memory leaks, performance drift, and stability
issues that only appear under sustained gameplay. The skill produces a document
specifying the test duration, system under test, monitoring checkpoints (e.g.,
memory sample every 30 minutes), pass/fail thresholds, and conditions for early
termination.

The skill asks "May I write to `production/qa/soak-[slug]-[date].md`?" before
persisting. If a previous soak test for the same system exists, the skill offers
to extend the duration or add new conditions. No director gates apply. The verdict
is COMPLETE when the soak test protocol is written.

---

## Static Assertions (Structural)

Verified automatically by `$skill-test static` — no fixture needed.

- [ ] Has non-empty `name` and `description`; `agents/openai.yaml` has non-empty display name and short description
- [ ] Has ≥2 phase headings
- [ ] Contains verdict keyword: COMPLETE
- [ ] Contains "May I write" collaborative protocol language before writing the protocol
- [ ] Has a next-step handoff (e.g., `$regression-suite` or `$release-checklist`)

---

## Director Gate Checks

None. `$soak-test` is a QA planning utility. No director gates apply.

---

## Test Cases

### Case 1: Happy Path — Online gameplay feature, 2-hour soak protocol

**Fixture:**
- User specifies: system = "online multiplayer lobby", duration = "2 hours"
- `technical-preferences.md` has engine configured

**Input:** `$soak-test online-lobby 2h`

**Expected behavior:**
1. Skill generates a 2-hour soak test protocol for the online lobby system
2. Protocol includes: monitoring checkpoints every 30 minutes, metrics to track
   (memory usage, connection count, packet loss), pass thresholds, early termination
   conditions (crash or >20% memory growth)
3. Networking-specific checks are included (session drop rate, reconnect handling)
4. Skill asks "May I write to `production/qa/soak-online-lobby-2026-04-06.md`?"
5. File is written on approval; verdict is COMPLETE

**Assertions:**
- [ ] Protocol duration matches the requested 2 hours
- [ ] Monitoring checkpoints are at reasonable intervals (e.g., every 30 minutes)
- [ ] Network-specific checks are included (not just generic memory checks)
- [ ] "May I write" is asked with the correct file path
- [ ] Verdict is COMPLETE

---

### Case 2: No Target Defined — Prompts for system, duration, and conditions

**Fixture:**
- No arguments provided
- No soak test config in session state

**Input:** `$soak-test`

**Expected behavior:**
1. Skill detects no target system or duration specified
2. Skill asks: "What system or feature should be soak-tested?"
3. After user responds with system: Skill asks: "What duration? (e.g., 1h, 4h, 8h)"
4. After user responds with duration: Skill asks for specific conditions or
   uses defaults (normal gameplay loop, default player count)
5. Skill generates protocol from collected inputs and asks "May I write"

**Assertions:**
- [ ] At minimum 2 follow-up questions are asked (system + duration)
- [ ] Default conditions are applied when user doesn't specify custom ones
- [ ] Protocol is not generated until system and duration are known
- [ ] Verdict is COMPLETE after file is written

---

### Case 3: Previous Soak Test Exists — Offers to extend or add conditions

**Fixture:**
- `production/qa/soak-online-lobby-2026-03-15.md` exists with a 1-hour protocol
- User wants to extend to 4 hours with new memory threshold conditions

**Input:** `$soak-test online-lobby 4h`

**Expected behavior:**
1. Skill finds existing soak test for online-lobby
2. Skill reports: "Previous soak test found: soak-online-lobby-2026-03-15.md (1h)"
3. Skill presents options: create new protocol (4h standalone), or extend the
   existing protocol to 4h and add new conditions
4. User selects extend; existing checkpoints are preserved, new ones added
5. Skill asks "May I write to `production/qa/soak-online-lobby-2026-04-06.md`?"
   (new file, not overwriting old one)

**Assertions:**
- [ ] Existing soak test is surfaced and referenced
- [ ] User is offered extend vs. new options
- [ ] New file is created (old file is not overwritten)
- [ ] Extended protocol includes both old and new checkpoints
- [ ] Verdict is COMPLETE

---

### Case 4: Mobile Target Platform — Memory-specific checkpoints added

**Fixture:**
- `technical-preferences.md` specifies target platform: Mobile
- User requests soak test for "gameplay session" at 30 minutes

**Input:** `$soak-test gameplay 30m`

**Expected behavior:**
1. Skill reads `technical-preferences.md` and detects mobile target platform
2. Soak test protocol includes mobile-specific memory checkpoints:
   - Check heap memory growth vs. device baseline
   - Check texture memory at checkpoint intervals
   - Add warning threshold at 300MB (mobile ceiling)
3. Protocol also includes thermal/battery drain advisory notes
4. Skill asks "May I write?" and writes on approval; verdict is COMPLETE

**Assertions:**
- [ ] Mobile platform is detected from technical-preferences.md
- [ ] Memory checkpoints include mobile-appropriate thresholds (not desktop)
- [ ] Thermal/battery notes are present in the protocol
- [ ] Verdict is COMPLETE

---

### Case 5: Director Gate Check — No gate; soak-test is a planning utility

**Fixture:**
- Valid system and duration provided

**Input:** `$soak-test combat 1h`

**Expected behavior:**
1. Skill generates and writes the soak test protocol
2. No director agents are spawned
3. No gate IDs appear in output

**Assertions:**
- [ ] No director gate is invoked
- [ ] No gate skip messages appear
- [ ] Skill reaches COMPLETE without any gate check

---

## Protocol Compliance

- [ ] Collects system, duration, and conditions before generating protocol
- [ ] Includes monitoring checkpoints at regular intervals
- [ ] Includes pass/fail thresholds and early termination conditions
- [ ] Adapts checkpoints to target platform (mobile vs. desktop)
- [ ] Asks "May I write" before creating the protocol file
- [ ] Verdict is COMPLETE when file is written

---

## Coverage Notes

- Soak tests for specific engine subsystems (rendering pipeline, physics
  simulation) follow the same protocol structure and are not separately tested.
- The case where the user provides a duration shorter than the minimum useful
  soak period (e.g., 5 minutes) is not tested; the skill would note this is
  too short for meaningful results.
- Automated execution of the soak test protocol is outside this skill's scope —
  this skill generates the plan, not the runner.
