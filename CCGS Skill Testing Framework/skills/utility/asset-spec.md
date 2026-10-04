# Skill Test Spec: /asset-spec

## Skill Summary

`/asset-spec` turns one target's visual needs into asset specs with AI generation
prompts. The argument names a target — `system:<name>`, `level:<name>` or
`character:<name>` (an `entity:` entry from the inventory is read like a
character) — plus an optional `--review full|lean|solo`. It reads the art bible
at `design/art/art-bible.md` (and stops if it is missing, unless the minimal-path
exception applies), `performance.*` and `naming.*` from `project.yaml`, and the
target's source doc. It confirms the identified asset list with the user, drafts
one `ASSET-NNN` block per asset, and after approval writes **one file per target**
to `design/assets/specs/[target-name]-assets.md`, then updates
`design/assets/asset-manifest.md`. Asset IDs run sequentially across the whole
project. A re-run for a target whose spec file exists updates that file in place
(existing blocks and IDs kept, new assets appended) after "May I update".

The resolved review mode decides who drafts: `full` spawns `art-director` and
`technical-artist` in parallel, `lean` spawns `art-director` only, `solo` (the
default, via `modes.rigor: minimal`) spawns no agents; `full` is also what
`modes.rigor: full` resolves to. Every skipped agent is announced by name in
the output. These are drafting consultations, not gates. The skill produces an
artifact, not a judgement, so it has no run verdict; it closes with an
`AskUserQuestion` offering the next target or `/asset-audit`.

---

## Static Assertions (Structural)

Checked against the SKILL.md by `/skill-test spec` — no fixture needed.

- [ ] Has required frontmatter fields: `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`
- [ ] Has ≥2 phase headings
- [ ] Check 3 passes on the `BLOCKED` keyword of its Error Recovery Protocol; the skill has no run verdict by design (artifact producer), and the run closes with "Asset specs complete for **[target]**. What's next?"
- [ ] Contains "May I write" language for the spec file and "May I update" for the manifest
- [ ] Has a next-step handoff (`/asset-spec [next-context]`, `/asset-audit`)

---

## Director Gate Checks

No gate IDs and no `/gate-check`. The review mode controls drafting agents only:

- **Full mode** (what `modes.rigor: full` resolves to): `art-director` and
  `technical-artist` spawned in parallel
- **Lean mode**: `art-director` only; the output says "technical-artist skipped —
  Lean mode: technical constraints not validated."
- **Solo mode** (default at `modes.rigor: minimal`): no agents; the main session
  derives specs from the art bible, and the output names both skipped agents and
  says technical constraints were not validated

---

## Test Cases

### Case 1: Happy Path — Character spec in lean mode

**Fixture:**
- `project.yaml` sets `modes.rigor: standard` (review mode resolves to `lean`) and
  has `performance.*` and `naming.*` values
- `design/art/art-bible.md` exists with Shape Language, Color System and Section 8 Asset Standards
- `design/narrative/characters/goblin-enemy.md` exists with a visual description
- No `design/assets/asset-manifest.md`

**Input:** `/asset-spec character:goblin-enemy`

**Expected behavior:**
1. Skill reads the art bible, project config and the character doc before asking anything
2. Skill presents the context summary ("Asset Spec: Character — goblin-enemy")
3. Phase 2 identifies the character's assets (sprite sheets such as idle, walk,
   attack, death; portrait; ability VFX; UI icon), shows them grouped by category,
   and asks via `AskUserQuestion` before speccing
4. Lean mode: spawns `art-director` only, and says so: "technical-artist skipped —
   Lean mode: technical constraints not validated."
5. Phase 4 presents one `ASSET-NNN` block per asset with the field table
   (Category, Dimensions, Format, Naming, Polycount, Texture Res), Visual
   Description, Art Bible Anchors citing sections, Generation Prompt, and `Status: Needed`
6. After approval asks "May I write the spec to `design/assets/specs/goblin-enemy-assets.md`?"
7. Creates the manifest after asking "May I update `design/assets/asset-manifest.md`?";
   IDs start at `ASSET-001`
8. Phase 6 `AskUserQuestion` offers another target or `/asset-audit`

**Assertions:**
- [ ] Asset list is confirmed with `AskUserQuestion` before any spec is generated
- [ ] Only `art-director` is spawned (no `technical-artist` in lean mode)
- [ ] The output names `technical-artist` as skipped and says technical constraints were not validated
- [ ] Each asset block has the field table, Art Bible Anchors (by section), a Generation Prompt and `Status: Needed`
- [ ] "May I write" names `design/assets/specs/goblin-enemy-assets.md`
- [ ] Manifest is created with a Progress Summary and IDs starting at `ASSET-001`
- [ ] Phase 6 offers `/asset-audit` among the next steps

---

### Case 2: No Art Bible — Skill stops before speccing

**Fixture:**
- `project.yaml` sets `modes.rigor: standard`
- `design/gdd/combat.md` exists with a Visual/Audio Requirements section
- `design/art/art-bible.md` does NOT exist
- `design/game-brief.md` does NOT exist

**Input:** `/asset-spec system:combat`

**Expected behavior:**
1. Phase 1 reads for `design/art/art-bible.md` and finds nothing
2. The minimal-path exception does not apply (no game brief)
3. Skill stops with: "No art bible found. Run `/art-bible` first — asset specs are
   anchored to the art bible's visual rules and asset standards."
4. No asset identification, no agents, no files

**Assertions:**
- [ ] The "No art bible found. Run `/art-bible` first" message is shown
- [ ] No asset list is presented and no `Agent` call is made
- [ ] No spec file or manifest is written
- [ ] Specs are not generated with invented style rules

---

### Case 3: Manifest Already Exists — IDs continue and shared assets are reused

**Fixture:**
- `project.yaml` sets `modes.rigor: standard`; art bible exists
- `design/assets/asset-manifest.md` exists; the highest ID is `ASSET-014`, and
  `ASSET-012` (Generic Hit Spark) is specced for the Combat system in
  `design/assets/specs/combat-assets.md`
- `design/gdd/tower-defense.md` Visual/Audio section lists a hit spark and a tower-build VFX

**Input:** `/asset-spec system:tower-defense`

**Expected behavior:**
1. Skill reads the manifest and globs `design/assets/specs/*.md` for shareable assets
2. Context summary lists the shared asset found in another spec
3. The hit spark reuses `ASSET-012` instead of creating a duplicate, with a note like
   "ASSET-012 (Generic Hit Spark) already specced for Combat system. Reusing for Tower Defense"
4. The new tower-build VFX is numbered `ASSET-015`
5. After "May I write" for `design/assets/specs/tower-defense-assets.md`, the skill asks
   "May I update `design/assets/asset-manifest.md`?", appends a Tower Defense context
   block, and updates the Progress Summary counts

**Assertions:**
- [ ] The hit spark references `ASSET-012`; no duplicate hit-spark spec is created
- [ ] The new asset's ID is `ASSET-015` (project-wide sequence, not restarted per target)
- [ ] The manifest is appended to, not recreated, after a "May I update" ask
- [ ] Progress Summary counts are updated

---

### Case 4: Several Assets in One Target — One file, per-asset revision before write

**Fixture:**
- `project.yaml` sets `modes.rigor: standard`; art bible exists; no manifest
- `design/gdd/combat.md` Visual/Audio section names a hit-spark VFX, a floating
  damage number (UI) and a hit sound (audio)

**Input:** `/asset-spec system:combat`

**Expected behavior:**
1. Phase 2 lists all three assets grouped under VFX, UI and Audio and asks the user to confirm
2. Phase 4 presents `ASSET-001` to `ASSET-003`; the audio asset carries a
   description of its sonic character and no image generation prompt
3. User picks `[B] Revise a specific asset` for the damage number; the skill revises
   it inline and re-presents without re-spawning agents
4. User approves all; the skill asks "May I write" **once**, for
   `design/assets/specs/combat-assets.md`, which holds all three assets

**Assertions:**
- [ ] One "May I write" ask covers all three assets in one file (not one ask or file per asset)
- [ ] The audio asset has no image generation prompt
- [ ] The minor revision does not re-spawn `art-director`
- [ ] All three `ASSET-NNN` blocks are in `design/assets/specs/combat-assets.md`

---

### Case 5: Director Gate Check — Solo default, brief instead of art bible

**Fixture:**
- `project.yaml` has no `modes` block (review mode resolves to `solo` via `modes.rigor: minimal`)
- `design/game-brief.md` exists with an Art & audio direction line
- No `design/art/art-bible.md`
- No character profile for `hero` in `design/narrative/` or `design/assets/entity-inventory.md`

**Input:** `/asset-spec character:hero`

**Expected behavior:**
1. The minimal-path exception applies: the skill does not stop, and states at the top
   "Anchored to the brief's one-line art direction; there is no art bible, so colour,
   shape and asset-standard rules below are proposals, not constraints."
2. `/art-bible` is offered once, as optional
3. No profile found → `AskUserQuestion`: "No profile found for **hero**. Describe it
   briefly" with Describe / Skip / Stop options
4. Solo mode: no `Agent` calls; the output announces "art-director and
   technical-artist skipped — Solo mode: specs derived in this session; technical
   constraints not validated."
5. No gate IDs appear and `/gate-check` is not invoked

**Assertions:**
- [ ] Skill continues without an art bible and says the specs are anchored to the brief
- [ ] Missing profile triggers the "Describe it briefly" question rather than a failure
- [ ] No `art-director` or `technical-artist` is spawned
- [ ] Both skipped agents are named in the output, which says technical constraints were not validated
- [ ] If the spec is written, its header names `design/game-brief.md` as the art direction (no `> **Art Bible**:` line), each asset carries a `**Brief anchor:**` line instead of Art Bible Anchors, and no Art Bible section or §8 tier is cited
- [ ] No gate IDs appear — the skip note names agents, not gates

---

### Case 6: Re-run on an Existing Spec — Updated in place, not overwritten

**Fixture:**
- `project.yaml` sets `modes.rigor: standard`; art bible exists
- `design/assets/specs/goblin-enemy-assets.md` exists with `ASSET-001` to
  `ASSET-004` (idle, walk and attack sprites; portrait); the manifest's highest ID
  is `ASSET-009`
- `design/narrative/characters/goblin-enemy.md` has since gained a charge-attack
  ability

**Input:** `/asset-spec character:goblin-enemy`

**Expected behavior:**
1. Phase 1 reads the existing spec file for this target as well as the character doc
2. Phase 2 proposes only what is new — the charge-attack sprite and its VFX — and
   confirms the list with the user
3. The new assets are numbered `ASSET-010` and `ASSET-011` (project-wide sequence)
4. The skill shows what changes, then asks "May I update
   `design/assets/specs/goblin-enemy-assets.md`?" — not "May I write"
5. `ASSET-001` to `ASSET-004` are kept unchanged in the file; the new blocks are appended

**Assertions:**
- [ ] The existing spec file is detected and read before the asset list is proposed
- [ ] The ask is "May I update", naming the existing file
- [ ] Existing blocks and IDs are preserved; the file is not overwritten wholesale
- [ ] New assets continue the project-wide ID sequence (`ASSET-010`, `ASSET-011`)

---

## Protocol Compliance

- [ ] Reads the art bible, project config and source doc before asking the user anything
- [ ] Never specs assets before the user confirms the asset list
- [ ] Spawns agents strictly per the resolved review mode (`--review` overrides for one run), and names every skipped agent in the output
- [ ] Surfaces any art-director / technical-artist conflict instead of silently resolving it
- [ ] Asks "May I write" before a new spec file, "May I update" before changing an existing one, and "May I update" before the manifest
- [ ] Assigns asset IDs sequentially across the project, reading the manifest first

---

## Coverage Notes

- The no-argument flow (pick the next "Needed" item from
  `design/assets/entity-inventory.md`, or build the inventory in Phase 0b) is not
  separately tested.
- `level:` targets and full-mode parallel spawning with a surfaced
  art-director / technical-artist conflict are not separately tested.
- Agent BLOCKED handling (Error Recovery Protocol: always produce a partial spec)
  is not separately tested.
