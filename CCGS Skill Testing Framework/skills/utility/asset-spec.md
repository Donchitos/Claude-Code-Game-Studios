# Skill Test Spec: $asset-spec

## Skill Summary

`$asset-spec` generates per-asset visual specification documents from design
requirements. It reads the relevant GDD, art bible, and design system to produce
a structured asset spec sheet that defines: dimensions, animation states (if
applicable), color palette reference, style notes, technical constraints
(format, file size budget), and deliverable checklist.

Spec sheets are written to `assets/specs/[asset-name]-spec.md` after a "May I write"
ask. If a spec already exists, the skill offers to update it. When multiple assets
are requested in a single invocation, a "May I write" ask is made per asset. No
director gates apply. The verdict is COMPLETE when all requested specs are written.

---

## Static Assertions (Structural)

Verified automatically by `$skill-test static` — no fixture needed.

- [ ] Has non-empty `name` and `description`; `agents/openai.yaml` has non-empty display name and short description
- [ ] Has ≥2 phase headings
- [ ] Contains verdict keyword: COMPLETE
- [ ] Contains "May I write" collaborative protocol language (per asset)
- [ ] Has a next-step handoff (e.g., assign to an artist, or `$asset-audit` later)

---

## Director Gate Checks

None. `$asset-spec` is a design documentation utility. Technical artists may
review specs separately but this is not a gate within this skill.

---

## Test Cases

### Case 1: Happy Path — Enemy sprite spec with full GDD and art bible

**Fixture:**
- `design/gdd/enemies.md` exists with enemy variants defined
- `design/art-bible.md` exists with color palette and style notes
- No existing asset spec for "goblin-enemy"

**Input:** `$asset-spec goblin-enemy`

**Expected behavior:**
1. Skill reads enemies GDD and art bible
2. Skill generates a spec for the goblin enemy sprite:
   - Dimensions: inferred from engine defaults or explicitly from GDD
   - Animation states: idle, walk, attack, hurt, death
   - Color palette reference: links to art-bible palette section
   - Style notes: from art bible character design rules
   - Technical constraints: format (PNG), size budget
   - Deliverable checklist
3. Skill asks "May I write to `assets/specs/goblin-enemy-spec.md`?"
4. File written on approval; verdict is COMPLETE

**Assertions:**
- [ ] All 6 spec components are present (dimensions, animations, palette, style, tech, checklist)
- [ ] Color palette reference links to art bible (not duplicated)
- [ ] Animation states are drawn from GDD (not invented)
- [ ] "May I write" is asked with the correct path
- [ ] Verdict is COMPLETE

---

### Case 2: No Art Bible Found — Spec with Placeholder Style Notes, Dependency Flagged

**Fixture:**
- `design/gdd/player.md` exists
- `design/art-bible.md` does NOT exist

**Input:** `$asset-spec player-sprite`

**Expected behavior:**
1. Skill reads player GDD but cannot find the art bible
2. Skill generates spec with placeholder style notes: "DEPENDENCY GAP: art bible
   not found — style notes are placeholders"
3. Color palette section uses: "TBD — see art bible when created"
4. Skill asks "May I write to `assets/specs/player-sprite-spec.md`?"
5. File written with placeholders and dependency flag; verdict is COMPLETE with advisory

**Assertions:**
- [ ] DEPENDENCY GAP is flagged for the missing art bible
- [ ] Spec is still generated (not blocked)
- [ ] Style notes contain placeholder markers, not invented styles
- [ ] Verdict is COMPLETE with advisory note

---

### Case 3: Asset Spec Already Exists — Offers to Update

**Fixture:**
- `assets/specs/goblin-enemy-spec.md` already exists
- GDD has been updated since the spec was written (new attack animation added)

**Input:** `$asset-spec goblin-enemy`

**Expected behavior:**
1. Skill detects existing spec file
2. Skill reports: "Asset spec already exists for goblin-enemy — checking for updates"
3. Skill diffs GDD against existing spec and identifies: new "charge-attack" animation
   state added in GDD but not in spec
4. Skill presents the diff: "1 new animation state found — offering to update spec"
5. Skill asks "May I update `assets/specs/goblin-enemy-spec.md`?" (not overwrite)
6. Spec is updated; verdict is COMPLETE

**Assertions:**
- [ ] Existing spec is detected and "update" path is offered
- [ ] Diff between GDD and existing spec is shown
- [ ] "May I update" language is used (not "May I write")
- [ ] Existing spec content is preserved; only the diff is applied
- [ ] Verdict is COMPLETE

---

### Case 4: Multiple Assets Requested — May-I-Write Per Asset

**Fixture:**
- GDD and art bible exist
- User requests specs for 3 assets: goblin-enemy, orc-enemy, treasure-chest

**Input:** `$asset-spec goblin-enemy orc-enemy treasure-chest`

**Expected behavior:**
1. Skill generates all 3 specs in sequence
2. For each asset, skill shows the draft and asks "May I write to
   `assets/specs/[name]-spec.md`?" individually
3. User can approve all 3 or skip individual assets
4. All approved specs are written; verdict is COMPLETE

**Assertions:**
- [ ] "May I write" is asked 3 times (once per asset), not once for all
- [ ] User can decline one asset without blocking the others
- [ ] All 3 spec files are written for approved assets
- [ ] Verdict is COMPLETE when all approved specs are written

---

### Case 5: Director Gate Check — No gate; asset-spec is a design utility

**Fixture:**
- GDD and art bible exist

**Input:** `$asset-spec goblin-enemy`

**Expected behavior:**
1. Skill generates and writes the asset spec
2. No director agents are spawned
3. No gate IDs appear in output

**Assertions:**
- [ ] No director gate is invoked
- [ ] No gate skip messages appear
- [ ] Verdict is COMPLETE without any gate check

---

## Protocol Compliance

- [ ] Reads GDD, art bible, and design system before generating spec
- [ ] Includes all 6 spec components (dimensions, animations, palette, style, tech, checklist)
- [ ] Flags missing dependencies (art bible, GDD) with DEPENDENCY GAP notes
- [ ] Asks "May I write" (or "May I update") per asset
- [ ] Handles multiple assets with individual write confirmations
- [ ] Verdict is COMPLETE when all approved specs are written

---

## Coverage Notes

- Audio asset specs (sound effects, music) follow the same structure with
  different fields (duration, sample rate, looping) and are not separately tested.
- UI asset specs (icons, button states) follow the same flow with interaction
  state requirements aligned to the UX spec.
- The case where GDD is also missing (neither GDD nor art bible exists) is not
  separately tested; spec would be generated with both dependency gaps flagged.
