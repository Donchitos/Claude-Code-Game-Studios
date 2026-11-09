# Lens: technical art (Section 8 only)

Read at Section 8, after drafting its art side. It is what the
`technical-artist` agent checked there: the hard limits the art wishes must fit.

## Inputs

`performance.*` and `engine.name` from `project.yaml` (Phase 0 read them; absent
keys fall back to `.claude/docs/technical-preferences.md`) and `platform.*`.
Use the numbers the project states, never ones you substitute. With no budget
stated, say so in the section ("no texture memory budget set") instead of
inventing one.

## Checks

Per asset category, the constraint side of:

- poly or vertex budget, draw calls per frame
- texture resolution and texture memory
- material slots, shader instruction limits
- particle counts and overdraw for VFX
- importer and format constraints of the pinned engine. For engine specifics,
  read `docs/engine-reference/<engine>/VERSION.md`; what the reference does not
  cover is marked unverified, not asserted from memory.

Tie each limit to the budget it serves, and name any choice that helps one
budget at another's cost (merged meshes cut draw calls but can defeat
occlusion).

## Output

Write the technical view as its own block, separate from the art view. Where an
art preference breaks a limit (4K textures against a 2K mobile budget), state the
ideal standard, the constrained standard and the trade-off; never resolve it
yourself.

## Limits

No aesthetic choices (no palette values, no style); no gameplay code; no engine
architecture.
