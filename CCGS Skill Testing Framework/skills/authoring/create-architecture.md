# Skill Test Spec: $create-architecture

## Skill Summary

`$create-architecture` guides the user through section-by-section authoring of a
technical architecture document. It uses a skeleton-first approach — the file is
created with all required section headers before any content is filled. Each
section is discussed, drafted, and written individually after user approval. If an
architecture document already exists, the skill offers retrofit mode to update
specific sections.

In `full` review mode, TD-ARCHITECTURE (technical-director) and LP-FEASIBILITY
(lead-programmer) spawn after the complete draft is finished. In `lean` or `solo`
mode, both gates are skipped. The skill writes to `docs/architecture/architecture.md`.

---

## Static Assertions (Structural)

Verified automatically by `$skill-test static` — no fixture needed.

- [ ] Has non-empty `name` and `description`; `agents/openai.yaml` has non-empty display name and short description
- [ ] Has ≥2 phase headings
- [ ] Contains verdict keywords: APPROVED, NEEDS REVISION, MAJOR REVISION NEEDED
- [ ] Contains "May I write" collaborative protocol language (per-section approval)
- [ ] Has a next-step handoff at the end (`$architecture-review` or `$create-control-manifest`)
- [ ] Documents skeleton-first approach
- [ ] Documents gate behavior: TD-ARCHITECTURE + LP-FEASIBILITY in full mode; skipped in lean/solo
- [ ] Documents retrofit mode for existing architecture documents

---

## Director Gate Checks

In `full` mode: TD-ARCHITECTURE (technical-director) and LP-FEASIBILITY
(lead-programmer) spawn in parallel after all sections are drafted and before
any final approval write.

In `lean` mode: both gates are skipped. Output notes:
"TD-ARCHITECTURE skipped — lean mode" and "LP-FEASIBILITY skipped — lean mode".

In `solo` mode: both gates are skipped with equivalent notes.

---

## Test Cases

### Case 1: Happy Path — New architecture doc, skeleton-first, full mode gates approve

**Fixture:**
- No existing `docs/architecture/architecture.md`
- `docs/architecture/` contains Accepted ADRs for reference
- `production/session-state/review-mode.txt` contains `full`

**Input:** `$create-architecture`

**Expected behavior:**
1. Skill creates skeleton `docs/architecture/architecture.md` with all required section headers
2. For each section: drafts content, shows draft, asks "May I write [section]?", writes after approval
3. After all sections are drafted: TD-ARCHITECTURE and LP-FEASIBILITY spawn in parallel
4. Both gates return APPROVED
5. Final "May I confirm architecture is complete?" asked
6. Session state updated

**Assertions:**
- [ ] Skeleton file is created with all section headers before any content is written
- [ ] "May I write [section]?" asked per section during authoring
- [ ] TD-ARCHITECTURE and LP-FEASIBILITY spawn in parallel (not sequentially)
- [ ] Both gates complete before the final completion confirmation
- [ ] Verdict is APPROVED when both gates return APPROVED
- [ ] Next-step handoff to `$architecture-review` or `$create-control-manifest` is present

---

### Case 2: Failure Path — TD-ARCHITECTURE returns MAJOR REVISION

**Fixture:**
- Architecture doc is fully drafted (all sections)
- `production/session-state/review-mode.txt` contains `full`
- TD-ARCHITECTURE gate returns MAJOR REVISION: "[specific structural issue]"

**Input:** `$create-architecture`

**Expected behavior:**
1. All sections are drafted and written
2. TD-ARCHITECTURE gate runs and returns MAJOR REVISION with specific feedback
3. Skill surfaces the feedback to the user
4. Architecture is NOT marked as finalized
5. User is asked: revise the flagged sections, or accept the document as a draft

**Assertions:**
- [ ] Architecture is NOT marked finalized when TD-ARCHITECTURE returns MAJOR REVISION
- [ ] Gate feedback is shown to the user with specific issue descriptions
- [ ] User is given the option to revise specific sections
- [ ] Skill does NOT auto-finalize despite MAJOR REVISION feedback

---

### Case 3: Lean Mode — Both gates skipped; architecture written with user approval only

**Fixture:**
- No existing architecture doc
- `production/session-state/review-mode.txt` contains `lean`

**Input:** `$create-architecture`

**Expected behavior:**
1. Skeleton file is created
2. All sections are authored and written per-section with user approval
3. After completion: TD-ARCHITECTURE and LP-FEASIBILITY are skipped
4. Output notes: "TD-ARCHITECTURE skipped — lean mode" and "LP-FEASIBILITY skipped — lean mode"
5. Architecture is considered complete based on user approval alone

**Assertions:**
- [ ] Both gate skip notes appear in output
- [ ] Architecture document is written with only user approval in lean mode
- [ ] Skill does NOT block completion because gates were skipped
- [ ] Next-step handoff is still present

---

### Case 4: Retrofit Mode — Existing architecture doc, user updates a section

**Fixture:**
- `docs/architecture/architecture.md` already exists with all sections populated

**Input:** `$create-architecture`

**Expected behavior:**
1. Skill detects existing architecture doc and reads its current content
2. Skill offers retrofit mode: "Architecture doc already exists. Which section would you like to update?"
3. User selects a section
4. Skill authors only that section, asks "May I write [section]?"
5. Only the selected section is updated — other sections unchanged

**Assertions:**
- [ ] Skill detects and reads the existing architecture doc before offering retrofit
- [ ] User is asked which section to update — not asked to rewrite the whole document
- [ ] Only the selected section is updated
- [ ] Other sections are not modified during a retrofit session

---

### Case 5: Director Gate — Architecture references a Proposed ADR; flagged as risk

**Fixture:**
- Architecture doc is being authored
- One section references or depends on an ADR that has `Status: Proposed`
- `production/session-state/review-mode.txt` contains `full`

**Input:** `$create-architecture`

**Expected behavior:**
1. Skill authors all sections
2. During authoring, skill detects a reference to a Proposed ADR
3. Skill flags: "Note: [section] references ADR-NNN which is Proposed — this is a risk until the ADR is accepted"
4. Risk flag is embedded in the relevant section's content
5. TD-ARCHITECTURE and LP-FEASIBILITY still run — they are informed of the Proposed ADR risk

**Assertions:**
- [ ] Proposed ADR reference is detected and flagged during section authoring
- [ ] Risk note is embedded in the architecture document section
- [ ] TD-ARCHITECTURE and LP-FEASIBILITY still spawn (the risk does not block the gates)
- [ ] Risk flag names the specific ADR number and title

---

## Protocol Compliance

- [ ] Skeleton file created with all section headers before any content is written
- [ ] "May I write [section]?" asked per section during authoring
- [ ] TD-ARCHITECTURE and LP-FEASIBILITY spawn in parallel in full mode
- [ ] Skipped gates noted by name and mode in lean/solo output
- [ ] Proposed ADR references flagged as risks in the document
- [ ] Ends with next-step handoff: `$architecture-review` or `$create-control-manifest`

---

## Coverage Notes

- The required section list for architecture documents is defined in the skill
  body and in the `$architecture-review` skill — not re-enumerated here.
- Engine version stamping in the architecture doc (parallel to ADR stamping)
  is part of the authoring workflow — tested implicitly via Case 1.
- The retrofit mode for updating multiple sections in one session follows the
  same per-section approval pattern — not independently tested for multi-section
  retrofits.
