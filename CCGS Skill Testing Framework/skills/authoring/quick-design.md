# Skill Test Spec: $quick-design

## Skill Summary

`$quick-design` produces a lightweight design spec for features too small to
warrant a full 8-section GDD. The target scope is under 4 hours of design time
for a single-system feature. Instead of the full 8-section GDD format, the
quick-design spec uses a streamlined 3-section format: Overview, Rules, and
Acceptance Criteria.

The skill has no director gates — adding gate overhead would defeat the purpose
of a lightweight design tool. The skill asks "May I write" before writing the
design note to `design/quick-notes/[name].md`. If the feature scope is too large
for a quick-design, the skill redirects to `$design-system` instead.

---

## Static Assertions (Structural)

Verified automatically by `$skill-test static` — no fixture needed.

- [ ] Has non-empty `name` and `description`; `agents/openai.yaml` has non-empty display name and short description
- [ ] Has ≥2 phase headings
- [ ] Contains verdict keywords: CREATED, BLOCKED, REDIRECTED
- [ ] Contains "May I write" collaborative protocol language (for quick-note file)
- [ ] Has a next-step handoff at the end
- [ ] Explicitly notes: no director gates (lightweight skill by design)
- [ ] Mentions scope check: redirects to `$design-system` if scope exceeds sub-4h threshold

---

## Director Gate Checks

No director gates — this skill spawns no director gate agents. The lightweight
nature of quick-design means director gate overhead is intentionally absent.
Full GDD review is not needed for sub-4-hour single-system features.

---

## Test Cases

### Case 1: Happy Path — Small UI change produces a 3-section spec

**Fixture:**
- No existing quick-note for the target feature
- Feature is clearly scoped: a single UI element change with no cross-system impact

**Input:** `$quick-design [feature-name]`

**Expected behavior:**
1. Skill asks scoping questions: what system, what change, what is the acceptance signal
2. Skill determines scope is within the sub-4h threshold
3. Skill drafts a 3-section spec: Overview, Rules, Acceptance Criteria
4. Draft is shown to user
5. "May I write `design/quick-notes/[name].md`?" is asked
6. File is written after approval

**Assertions:**
- [ ] Spec contains exactly 3 sections: Overview, Rules, Acceptance Criteria
- [ ] Draft is shown to user before "May I write" ask
- [ ] "May I write `design/quick-notes/[name].md`?" is asked before writing
- [ ] File is written to the correct path: `design/quick-notes/[name].md`
- [ ] Verdict is CREATED after successful write

---

### Case 2: Failure Path — Scope check fails; redirected to $design-system

**Fixture:**
- Feature described spans multiple systems or would take more than 4 hours of design time
  (e.g., "redesign the entire combat system" or "new progression mechanic affecting all classes")

**Input:** `$quick-design [large-feature]`

**Expected behavior:**
1. Skill asks scoping questions
2. Skill determines scope exceeds the sub-4h / single-system threshold
3. Skill outputs: "This feature is too large for a quick-design. Use `$design-system [name]` for a full GDD."
4. Skill does NOT write a quick-note file
5. Verdict is REDIRECTED

**Assertions:**
- [ ] Skill detects the scope excess and stops before drafting
- [ ] Message explicitly names `$design-system` as the correct alternative
- [ ] No quick-note file is written
- [ ] Verdict is REDIRECTED (not CREATED or BLOCKED)

---

### Case 3: Edge Case — File already exists; offered to update

**Fixture:**
- `design/quick-notes/[name].md` already exists from a previous session

**Input:** `$quick-design [name]`

**Expected behavior:**
1. Skill detects existing quick-note file and reads its current content
2. Skill asks: "[name].md already exists. Update it, or create a new version?"
3. User selects update
4. Skill shows the existing spec and asks which section to revise
5. Updated spec is shown, "May I write?" asked, file updated after approval

**Assertions:**
- [ ] Skill detects and reads the existing file before offering to update
- [ ] User is offered update or create-new options — not auto-overwritten
- [ ] Only the revised section is updated (or the whole spec if user chooses full rewrite)
- [ ] "May I write" is asked before overwriting the existing file

---

### Case 4: Edge Case — No argument provided

**Fixture:**
- `design/quick-notes/` directory may or may not exist

**Input:** `$quick-design` (no argument)

**Expected behavior:**
1. Skill detects no argument is provided
2. Skill outputs a usage error: "No feature name specified. Usage: $quick-design [feature-name]"
3. Skill provides an example: `$quick-design pause-menu-settings`
4. No file is created

**Assertions:**
- [ ] Skill outputs a usage error when no argument is given
- [ ] A usage example is shown with the correct format
- [ ] No quick-note file is written
- [ ] Skill does NOT silently pick a feature name or default to any action

---

### Case 5: Director Gate — No gate spawned; explicitly noted for sub-4h features

**Fixture:**
- Feature is within scope for quick-design
- `production/session-state/review-mode.txt` exists with `full`

**Input:** `$quick-design [feature-name]`

**Expected behavior:**
1. Skill asks scoping questions and determines scope is within threshold
2. Skill does NOT read `production/session-state/review-mode.txt`
3. Skill does NOT spawn any director gate agent
4. Spec is drafted, "May I write" asked, file written after approval
5. Output explicitly notes: "No director gate review — quick-design is for sub-4h features"

**Assertions:**
- [ ] No director gate agents are spawned (no CD-, TD-, PR-, AD- prefixed gates)
- [ ] Skill does NOT read `production/session-state/review-mode.txt`
- [ ] Output contains a note explaining why no gate review is needed
- [ ] Review mode has no effect on this skill's behavior
- [ ] Full GDD review path (`$design-system`) is mentioned as the alternative for larger features

---

## Protocol Compliance

- [ ] Scope check runs before drafting (redirects to `$design-system` if scope too large)
- [ ] 3-section format used (Overview, Rules, Acceptance Criteria) — NOT the 8-section GDD format
- [ ] Draft shown to user before "May I write" ask
- [ ] "May I write `design/quick-notes/[name].md`?" asked before writing
- [ ] No director gates — no review-mode.txt read
- [ ] Ends with next-step handoff (e.g., proceed to implementation or `$dev-story`)

---

## Coverage Notes

- The scope threshold heuristic (sub-4h, single-system) is a judgment call —
  the skill's internal check is the authoritative definition and is not
  independently tested by counting hours.
- The `design/quick-notes/` directory is created automatically if it does not
  exist — this filesystem behavior is not independently tested here.
- Integration with the story pipeline (can a quick-design generate a story
  directly?) is out of scope for this spec — quick-designs are standalone.
