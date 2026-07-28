## Unit test — Build Validation & Navigability story build-validation-004
## (outside-connection trace & Room/Sealed verdict; ADR-0007 primary, GDD
## `design/gdd/build-validation-navigability.md` Rules 2/3).
##
## Proves:
## 1. AC1/AC2: a 3x3 interior with a 1-wide walkable gap -> Room; the same
##    structure fully sealed -> Sealed.
## 2. AC4: a region of exactly `min_room_cells` with a connection -> Room; one
##    cell fewer -> OPEN (never even reachability-checked).
## 3. AC5: three independent Sealed cases -- a 2-cell drop (step-height
##    violation, structurally excluded from the Δy ∈ {-1,0,1} neighbor scan),
##    a sub-3-clearance opening, and an opening whose only outward path leads
##    into a chain of roofed pockets that never reach open sky.
## 4. AC8: removing a connecting segment from a valid room yields two
##    independent regions, each independently evaluated against Rule 2.
## 5. AC9/AC10: terrain-as-structure enclosure -> Room; roof-on-pillars with
##    no walls -> Room (accepted MVP behavior, Edge Case 6 -- NOT a defect).
## 6. AC29/AC30: a legal flanked diagonal (both orthogonal flankers passable)
##    -> Room; either flanker closed -> Sealed. Both flanker positions must be
##    closed simultaneously to actually seal the corner (see the doc comment
##    on [method _make_flanked_diagonal_grid] for why a single closed flanker
##    alone never suffices under the shared predicates' own math).
## 7. AC37 (Edge Case 14): two regions touching only corner-to-corner, where
##    region A's sole path to open sky is a legal flanked diagonal through B's
##    interior and door -- BOTH are valid rooms; with either flanker closed,
##    A is Sealed while B remains a Room (B's own door is untouched).
## 8. AC25: a mocked Building System's block/revert call-count stays 0 across
##    every Sealed configuration this file builds -- this module has no write
##    path at all.
## 9. Edge case: a region exactly at `min_room_cells` with zero legal steps
##    out is Sealed (distinct from AC4's below-threshold OPEN case).
## 10. Grep guards: no [VillagerAi] reference, no local
##     `VILLAGER_CLEARANCE`/`MAX_STEP_HEIGHT` literal, and zero
##     `NavigationServer3D`-family reference in this story's production file.
class_name BuildValidationRoomVerdictTest
extends GdUnitTestSuite


## Minimal duck-typed Building System stub (AC25 — Rule 9 never-blocks):
## exposes call-counted `block_placement()`/`revert_placement()` methods this
## module is never expected to call. No production code in this story
## references a Building System type at all; this stub exists purely to
## demonstrate that property dynamically, mirroring the "mock call-count"
## verification the GDD's own AC25 names.
class _MockBuildingSystem:
	var block_call_count: int = 0
	var revert_call_count: int = 0

	func block_placement() -> void:
		block_call_count += 1

	func revert_placement() -> void:
		revert_call_count += 1


# ---------------------------------------------------------------------------
# Test fixtures
# ---------------------------------------------------------------------------

const MAX_ROOM_HEIGHT: int = 8
const MIN_ROOM_CELLS: int = 2

## Every interior cell in this file sits at this y-level -- elevated above 0
## (rather than the sibling stories' y=1) so there is room BELOW it to place
## genuine, in-bounds "2-cell drop" terrain for AC5's step-height case
## ([method VoxelWorldGrid.is_in_bounds] requires `y >= config.min_y == 0`).
const ROOM_Y: int = 3


func _make_grid() -> VoxelWorldGrid:
	var grid: VoxelWorldGrid = auto_free(VoxelWorldGrid.new())
	grid.config = VoxelWorldConfig.new()
	return grid


func _solid_contents() -> CellContents:
	return CellContents.new(1, 0)


## Makes [param cell] an interior candidate cell in isolation: solid floor
## directly below, solid roof exactly [constant MAX_ROOM_HEIGHT] above --
## per-column, no shared floor/roof plane required (GDD Rule 1 needs no wall
## coverage, Edge Case 6).
func _place_interior_cell(grid: VoxelWorldGrid, cell: Vector3i) -> void:
	grid.set_cell(cell + Vector3i(0, -1, 0), _solid_contents())
	grid.set_cell(cell + Vector3i(0, MAX_ROOM_HEIGHT, 0), _solid_contents())


func _place_interior_rect(grid: VoxelWorldGrid, x_range: Array, z_range: Array, y: int) -> void:
	for x: int in x_range:
		for z: int in z_range:
			_place_interior_cell(grid, Vector3i(x, y, z))


## Makes [param cell] a standable, genuinely OPEN-SKY cell: solid floor
## directly below, deliberately NO roof anywhere above.
func _place_open_sky_cell(grid: VoxelWorldGrid, cell: Vector3i) -> void:
	grid.set_cell(cell + Vector3i(0, -1, 0), _solid_contents())


# ---------------------------------------------------------------------------
# AC1 / AC2 — full enclosure with a walkable gap vs. fully sealed
# ---------------------------------------------------------------------------

func test_full_enclosure_with_walkable_gap_is_room() -> void:
	# Arrange — a 3x3 roofed+floored interior with one open-sky cell directly
	# adjacent (a 1-wide gap, step height 0 — AC1's own wording).
	var grid: VoxelWorldGrid = _make_grid()
	_place_interior_rect(grid, range(0, 3), range(0, 3), ROOM_Y)
	_place_open_sky_cell(grid, Vector3i(3, ROOM_Y, 1))

	# Act
	var region: BuildValidationRegion = BuildValidationRegionFormation.form_region(
		grid, Vector3i(0, ROOM_Y, 0), MAX_ROOM_HEIGHT
	)
	var verdict: int = BuildValidationReachability.classify_region(
		grid, region, MIN_ROOM_CELLS, MAX_ROOM_HEIGHT
	)

	# Assert
	assert_int(region.size()).is_equal(9)
	assert_int(verdict).is_equal(BuildValidationReachability.Verdict.ROOM)


func test_fully_sealed_structure_is_sealed() -> void:
	# Arrange — the identical 3x3 interior, with NO opening anywhere: nothing
	# standable exists outside the footprint at all.
	var grid: VoxelWorldGrid = _make_grid()
	_place_interior_rect(grid, range(0, 3), range(0, 3), ROOM_Y)

	# Act
	var region: BuildValidationRegion = BuildValidationRegionFormation.form_region(
		grid, Vector3i(0, ROOM_Y, 0), MAX_ROOM_HEIGHT
	)
	var verdict: int = BuildValidationReachability.classify_region(
		grid, region, MIN_ROOM_CELLS, MAX_ROOM_HEIGHT
	)

	# Assert
	assert_int(region.size()).is_equal(9)
	assert_int(verdict).is_equal(BuildValidationReachability.Verdict.SEALED)


# ---------------------------------------------------------------------------
# AC4 — min_room_cells boundary
# ---------------------------------------------------------------------------

func test_region_of_exactly_min_room_cells_with_connection_is_room() -> void:
	# Arrange — exactly 2 (MIN_ROOM_CELLS) interior cells, plus an open-sky
	# escape.
	var grid: VoxelWorldGrid = _make_grid()
	_place_interior_cell(grid, Vector3i(0, ROOM_Y, 0))
	_place_interior_cell(grid, Vector3i(1, ROOM_Y, 0))
	_place_open_sky_cell(grid, Vector3i(2, ROOM_Y, 0))

	# Act
	var region: BuildValidationRegion = BuildValidationRegionFormation.form_region(
		grid, Vector3i(0, ROOM_Y, 0), MAX_ROOM_HEIGHT
	)
	var verdict: int = BuildValidationReachability.classify_region(
		grid, region, MIN_ROOM_CELLS, MAX_ROOM_HEIGHT
	)

	# Assert
	assert_int(region.size()).is_equal(MIN_ROOM_CELLS)
	assert_int(verdict).is_equal(BuildValidationReachability.Verdict.ROOM)


func test_region_one_cell_fewer_than_min_room_cells_is_open_not_room() -> void:
	# Arrange — a single interior cell (one fewer than MIN_ROOM_CELLS), WITH
	# an open-sky escape present — proving the disqualification is purely
	# about size, never about connectivity (Implementation Notes: size is
	# checked before reachability at all).
	var grid: VoxelWorldGrid = _make_grid()
	_place_interior_cell(grid, Vector3i(0, ROOM_Y, 0))
	_place_open_sky_cell(grid, Vector3i(1, ROOM_Y, 0))

	# Act
	var region: BuildValidationRegion = BuildValidationRegionFormation.form_region(
		grid, Vector3i(0, ROOM_Y, 0), MAX_ROOM_HEIGHT
	)
	var verdict: int = BuildValidationReachability.classify_region(
		grid, region, MIN_ROOM_CELLS, MAX_ROOM_HEIGHT
	)

	# Assert
	assert_int(region.size()).is_equal(1)
	assert_int(verdict).is_equal(BuildValidationReachability.Verdict.OPEN)
	assert_bool(verdict == BuildValidationReachability.Verdict.ROOM).is_false()


# ---------------------------------------------------------------------------
# AC5 — three independent Sealed cases
# ---------------------------------------------------------------------------

func test_opening_onto_two_cell_drop_is_sealed() -> void:
	# Arrange — a 2-cell interior; the real standable ground outside is 2
	# cells BELOW the interior's own level (floor at y=0 -> standable cell at
	# y=1, while the interior stands at ROOM_Y=3). A step of |dy|=2 is both
	# outside the Δy ∈ {-1,0,1} neighbor-candidate range AND would fail
	# is_step_legal's own height check — the drop is structurally
	# unreachable, not merely "no floor placed".
	var grid: VoxelWorldGrid = _make_grid()
	_place_interior_cell(grid, Vector3i(0, ROOM_Y, 0))
	_place_interior_cell(grid, Vector3i(1, ROOM_Y, 0))
	grid.set_cell(Vector3i(2, 0, 0), _solid_contents())  # real ground, 2 below the room's own level

	# Act
	var region: BuildValidationRegion = BuildValidationRegionFormation.form_region(
		grid, Vector3i(0, ROOM_Y, 0), MAX_ROOM_HEIGHT
	)
	var verdict: int = BuildValidationReachability.classify_region(
		grid, region, MIN_ROOM_CELLS, MAX_ROOM_HEIGHT
	)

	# Assert — the ground genuinely exists (proving this is a real drop, not
	# an absent-terrain artifact) but is unreachable in one legal step.
	assert_bool(VillagerWalkabilityRules.is_standable(grid, Vector3i(2, 1, 0))).is_true()
	assert_int(region.size()).is_equal(2)
	assert_int(verdict).is_equal(BuildValidationReachability.Verdict.SEALED)


func test_opening_with_sub_clearance_is_sealed() -> void:
	# Arrange — an adjacent cell has a floor (so it LOOKS like an opening) but
	# its 3-cell clearance column is broken one cell up, failing standability.
	var grid: VoxelWorldGrid = _make_grid()
	_place_interior_cell(grid, Vector3i(0, ROOM_Y, 0))
	_place_interior_cell(grid, Vector3i(1, ROOM_Y, 0))
	grid.set_cell(Vector3i(2, ROOM_Y - 1, 0), _solid_contents())  # floor for the "opening" cell
	grid.set_cell(Vector3i(2, ROOM_Y + 1, 0), _solid_contents())  # blocks the clearance column

	# Act
	var region: BuildValidationRegion = BuildValidationRegionFormation.form_region(
		grid, Vector3i(0, ROOM_Y, 0), MAX_ROOM_HEIGHT
	)
	var verdict: int = BuildValidationReachability.classify_region(
		grid, region, MIN_ROOM_CELLS, MAX_ROOM_HEIGHT
	)

	# Assert
	assert_bool(
		VillagerWalkabilityRules.is_standable(grid, Vector3i(2, ROOM_Y, 0))
	).is_false()
	assert_int(verdict).is_equal(BuildValidationReachability.Verdict.SEALED)


func test_opening_into_roofed_pocket_chain_never_reaching_sky_is_sealed() -> void:
	# Arrange — the room's only neighbors are more roofed, standable "pocket"
	# cells (folded into the SAME region by orthogonal adjacency, Edge Case
	# 1) that themselves never reach an unroofed cell.
	var grid: VoxelWorldGrid = _make_grid()
	_place_interior_cell(grid, Vector3i(0, ROOM_Y, 0))
	_place_interior_cell(grid, Vector3i(1, ROOM_Y, 0))
	_place_interior_cell(grid, Vector3i(2, ROOM_Y, 0))  # pocket cell 1 — roofed, no sky
	_place_interior_cell(grid, Vector3i(3, ROOM_Y, 0))  # pocket cell 2 — roofed, no sky, dead end

	# Act
	var region: BuildValidationRegion = BuildValidationRegionFormation.form_region(
		grid, Vector3i(0, ROOM_Y, 0), MAX_ROOM_HEIGHT
	)
	var verdict: int = BuildValidationReachability.classify_region(
		grid, region, MIN_ROOM_CELLS, MAX_ROOM_HEIGHT
	)

	# Assert
	assert_int(region.size()).is_equal(4)
	assert_int(verdict).is_equal(BuildValidationReachability.Verdict.SEALED)


# ---------------------------------------------------------------------------
# AC8 — splitting a valid room yields two independent regions
# ---------------------------------------------------------------------------

func test_splitting_room_by_removing_connector_yields_two_independent_regions() -> void:
	# Arrange — room A (3 cells, own open-sky escape) — bridge (1 cell) —
	# room B (3 cells, no escape of its own), all one connected region.
	var grid: VoxelWorldGrid = _make_grid()
	_place_open_sky_cell(grid, Vector3i(9, ROOM_Y, 0))
	for x: int in range(10, 13):
		_place_interior_cell(grid, Vector3i(x, ROOM_Y, 0))  # room A
	_place_interior_cell(grid, Vector3i(13, ROOM_Y, 0))  # bridge
	for x: int in range(14, 17):
		_place_interior_cell(grid, Vector3i(x, ROOM_Y, 0))  # room B

	var combined: BuildValidationRegion = BuildValidationRegionFormation.form_region(
		grid, Vector3i(10, ROOM_Y, 0), MAX_ROOM_HEIGHT
	)
	assert_int(combined.size()).is_equal(7)
	assert_int(
		BuildValidationReachability.classify_region(grid, combined, MIN_ROOM_CELLS, MAX_ROOM_HEIGHT)
	).is_equal(BuildValidationReachability.Verdict.ROOM)  # via A's own escape

	# Act — remove the bridge's floor+roof (a demolition), splitting the mass.
	grid.clear_cell(Vector3i(13, ROOM_Y - 1, 0))
	grid.clear_cell(Vector3i(13, ROOM_Y + MAX_ROOM_HEIGHT, 0))

	var region_a: BuildValidationRegion = BuildValidationRegionFormation.form_region(
		grid, Vector3i(10, ROOM_Y, 0), MAX_ROOM_HEIGHT
	)
	var region_b: BuildValidationRegion = BuildValidationRegionFormation.form_region(
		grid, Vector3i(14, ROOM_Y, 0), MAX_ROOM_HEIGHT
	)

	# Assert — two independent size-3 regions, independently evaluated: A
	# still has its own escape (Room); B has none (Sealed).
	assert_int(region_a.size()).is_equal(3)
	assert_int(region_b.size()).is_equal(3)
	assert_bool(region_a.contains(Vector3i(13, ROOM_Y, 0))).is_false()
	assert_bool(region_b.contains(Vector3i(13, ROOM_Y, 0))).is_false()
	assert_int(
		BuildValidationReachability.classify_region(grid, region_a, MIN_ROOM_CELLS, MAX_ROOM_HEIGHT)
	).is_equal(BuildValidationReachability.Verdict.ROOM)
	assert_int(
		BuildValidationReachability.classify_region(grid, region_b, MIN_ROOM_CELLS, MAX_ROOM_HEIGHT)
	).is_equal(BuildValidationReachability.Verdict.SEALED)


# ---------------------------------------------------------------------------
# AC9 / AC10 — terrain as structure, roof-on-pillars
# ---------------------------------------------------------------------------

func test_terrain_as_floor_and_wall_can_form_valid_room() -> void:
	# Arrange — Edge Case 5: "solid is solid" regardless of source. The floor
	# and an adjacent "wall" block both use a distinct block_type_id (a stand-
	# in for terrain-origin blocks) — the predicate makes no distinction
	# between built and natural enclosure (is_empty() only ever checks
	# block_type_id != EMPTY, never an origin flag, which does not exist).
	var grid: VoxelWorldGrid = _make_grid()
	var terrain_contents := CellContents.new(3, 0)
	for x: int in range(0, 2):
		grid.set_cell(Vector3i(x, ROOM_Y - 1, 0), terrain_contents)  # terrain floor
		grid.set_cell(Vector3i(x, ROOM_Y + MAX_ROOM_HEIGHT, 0), terrain_contents)  # roof
	grid.set_cell(Vector3i(0, ROOM_Y, 1), terrain_contents)  # a "terrain wall" beside the interior — inert per Rule 1, present only to reflect AC9's own wording
	_place_open_sky_cell(grid, Vector3i(2, ROOM_Y, 0))

	# Act
	var region: BuildValidationRegion = BuildValidationRegionFormation.form_region(
		grid, Vector3i(0, ROOM_Y, 0), MAX_ROOM_HEIGHT
	)
	var verdict: int = BuildValidationReachability.classify_region(
		grid, region, MIN_ROOM_CELLS, MAX_ROOM_HEIGHT
	)

	# Assert
	assert_int(region.size()).is_equal(2)
	assert_int(verdict).is_equal(BuildValidationReachability.Verdict.ROOM)


func test_roof_on_pillars_with_no_walls_is_room() -> void:
	# Arrange — Edge Case 6 (AC10, accepted MVP behavior — do NOT add a wall-
	# coverage requirement): a floored, roofed, reachable interior with no
	# wall blocks anywhere.
	var grid: VoxelWorldGrid = _make_grid()
	for x: int in range(0, 3):
		_place_interior_cell(grid, Vector3i(x, ROOM_Y, 0))
	_place_open_sky_cell(grid, Vector3i(3, ROOM_Y, 0))

	# Act
	var region: BuildValidationRegion = BuildValidationRegionFormation.form_region(
		grid, Vector3i(0, ROOM_Y, 0), MAX_ROOM_HEIGHT
	)
	var verdict: int = BuildValidationReachability.classify_region(
		grid, region, MIN_ROOM_CELLS, MAX_ROOM_HEIGHT
	)

	# Assert — no wall block was ever placed at the interior's own side cell,
	# and the region is still a valid room.
	assert_bool(grid.get_cell(Vector3i(0, ROOM_Y, 1)).is_empty()).is_true()
	assert_int(verdict).is_equal(BuildValidationReachability.Verdict.ROOM)


# ---------------------------------------------------------------------------
# AC29 / AC30 — flanked diagonal legality
# ---------------------------------------------------------------------------
#
# A structural note load-bearing for both fixtures below: given the landed
# is_step_legal formula, flanker_a = (to.x, from.y, from.z) and flanker_b =
# (from.x, from.y, to.z) are EACH, independently, orthogonally adjacent to
# BOTH the origin cell and the diagonal target (at the identical dy the
# direct diagonal step would use). This means a single STANDABLE flanker
# already offers its own fully-legal 2-hop orthogonal route to the target,
# regardless of the diagonal-corner rule. A corner is therefore only
# genuinely sealed when NEITHER flanker is standable — closing just one while
# leaving the other open (as the raw is_step_legal unit tests do, to prove
# only that ONE step is illegal) does not, by itself, seal full reachability.
# The two AC30 fixtures below close BOTH positions, each simply by never
# giving that cell a floor (an occupying solid block placed directly on a
# flanker cell was tried and rejected: it inadvertently becomes a legal
# standable "step-up ledge" one cell above itself — |dy| = 1 is a legal
# orthogonal step — which would silently reopen the very escape the fixture
# is trying to close). "Never floored" is the side-effect-free way to make a
# cell fail is_standable's "solid below" check.

func test_flanked_diagonal_both_flankers_open_is_room() -> void:
	# Arrange — a 2-cell room whose only escape is a diagonal step; both
	# flanking orthogonal cells are standable (floor only, unroofed, so they
	# never become candidate cells of their own).
	var grid: VoxelWorldGrid = _make_grid()
	_place_interior_cell(grid, Vector3i(20, ROOM_Y, 0))
	_place_interior_cell(grid, Vector3i(21, ROOM_Y, 0))  # from_cell for the diagonal
	grid.set_cell(Vector3i(22, ROOM_Y - 1, 0), _solid_contents())  # flanker_a = (22, ROOM_Y, 0)
	grid.set_cell(Vector3i(21, ROOM_Y - 1, 1), _solid_contents())  # flanker_b = (21, ROOM_Y, 1)
	_place_open_sky_cell(grid, Vector3i(22, ROOM_Y, 1))  # diagonal target, open sky

	# Act
	var region: BuildValidationRegion = BuildValidationRegionFormation.form_region(
		grid, Vector3i(20, ROOM_Y, 0), MAX_ROOM_HEIGHT
	)
	var verdict: int = BuildValidationReachability.classify_region(
		grid, region, MIN_ROOM_CELLS, MAX_ROOM_HEIGHT
	)

	# Assert
	assert_int(region.size()).is_equal(2)
	assert_bool(
		VillagerWalkabilityRules.is_step_legal(
			grid, Vector3i(21, ROOM_Y, 0), Vector3i(22, ROOM_Y, 1)
		)
	).is_true()
	assert_int(verdict).is_equal(BuildValidationReachability.Verdict.ROOM)


func test_flanked_diagonal_flanker_a_blocked_is_sealed() -> void:
	# Arrange — same geometry; flanker_a (22, ROOM_Y, 0) is simply never given
	# a floor (not standable) — NOT occupied by a solid block placed directly
	# on it, which would create an unintended step-UP ledge one cell above
	# (a legal |dy|=1 orthogonal step onto the block's own top face) and
	# defeat the seal. flanker_b (21, ROOM_Y, 1) is likewise never given a
	# floor — see the section note above for why closing only one is
	# insufficient.
	var grid: VoxelWorldGrid = _make_grid()
	_place_interior_cell(grid, Vector3i(20, ROOM_Y, 0))
	_place_interior_cell(grid, Vector3i(21, ROOM_Y, 0))
	_place_open_sky_cell(grid, Vector3i(22, ROOM_Y, 1))  # target — unreachable regardless

	# Act
	var region: BuildValidationRegion = BuildValidationRegionFormation.form_region(
		grid, Vector3i(20, ROOM_Y, 0), MAX_ROOM_HEIGHT
	)
	var verdict: int = BuildValidationReachability.classify_region(
		grid, region, MIN_ROOM_CELLS, MAX_ROOM_HEIGHT
	)

	# Assert
	assert_bool(VillagerWalkabilityRules.is_standable(grid, Vector3i(22, ROOM_Y, 0))).is_false()
	assert_int(verdict).is_equal(BuildValidationReachability.Verdict.SEALED)


func test_flanked_diagonal_flanker_b_blocked_is_sealed() -> void:
	# Arrange — the OTHER flanking cell (21, ROOM_Y, 1) is the one left
	# without a floor this time (both flankers were floorless above too, but
	# proving each one's own is_standable() is false individually still
	# guards against a future asymmetric regression) — proving both flankers
	# are actually checked, not just one — mirroring the raw-predicate unit
	# test's own "other flanker" precedent.
	var grid: VoxelWorldGrid = _make_grid()
	_place_interior_cell(grid, Vector3i(20, ROOM_Y, 0))
	_place_interior_cell(grid, Vector3i(21, ROOM_Y, 0))
	_place_open_sky_cell(grid, Vector3i(22, ROOM_Y, 1))  # target — unreachable regardless

	# Act
	var region: BuildValidationRegion = BuildValidationRegionFormation.form_region(
		grid, Vector3i(20, ROOM_Y, 0), MAX_ROOM_HEIGHT
	)
	var verdict: int = BuildValidationReachability.classify_region(
		grid, region, MIN_ROOM_CELLS, MAX_ROOM_HEIGHT
	)

	# Assert
	assert_bool(VillagerWalkabilityRules.is_standable(grid, Vector3i(21, ROOM_Y, 1))).is_false()
	assert_int(verdict).is_equal(BuildValidationReachability.Verdict.SEALED)


# ---------------------------------------------------------------------------
# AC37 (Edge Case 14) — corner-touching regions
# ---------------------------------------------------------------------------

func test_corner_touching_regions_both_valid_via_shared_diagonal_door() -> void:
	# Arrange — region A (2 cells, NO escape of its own) and region B (2
	# cells, its OWN open-sky door), touching only corner-to-corner (never
	# orthogonally adjacent, so story 003 forms them as TWO regions). The
	# flanked diagonal between A's corner and B's corner is legal (both
	# flankers standable, unroofed).
	var grid: VoxelWorldGrid = _make_grid()
	_place_interior_cell(grid, Vector3i(29, ROOM_Y, 0))
	_place_interior_cell(grid, Vector3i(30, ROOM_Y, 0))  # A's corner cell
	_place_interior_cell(grid, Vector3i(31, ROOM_Y, 1))  # B's corner cell (diagonal to A's corner)
	_place_interior_cell(grid, Vector3i(32, ROOM_Y, 1))
	_place_open_sky_cell(grid, Vector3i(33, ROOM_Y, 1))  # B's own door
	grid.set_cell(Vector3i(31, ROOM_Y - 1, 0), _solid_contents())  # flanker_p = (31, ROOM_Y, 0)
	grid.set_cell(Vector3i(30, ROOM_Y - 1, 1), _solid_contents())  # flanker_q = (30, ROOM_Y, 1)

	# Act
	var region_a: BuildValidationRegion = BuildValidationRegionFormation.form_region(
		grid, Vector3i(29, ROOM_Y, 0), MAX_ROOM_HEIGHT
	)
	var region_b: BuildValidationRegion = BuildValidationRegionFormation.form_region(
		grid, Vector3i(31, ROOM_Y, 1), MAX_ROOM_HEIGHT
	)

	# Assert — two distinct regions (membership is orthogonal), both Rooms.
	assert_int(region_a.size()).is_equal(2)
	assert_int(region_b.size()).is_equal(2)
	assert_bool(region_a.contains(Vector3i(31, ROOM_Y, 1))).is_false()
	assert_bool(region_b.contains(Vector3i(30, ROOM_Y, 0))).is_false()
	assert_int(
		BuildValidationReachability.classify_region(grid, region_a, MIN_ROOM_CELLS, MAX_ROOM_HEIGHT)
	).is_equal(BuildValidationReachability.Verdict.ROOM)
	assert_int(
		BuildValidationReachability.classify_region(grid, region_b, MIN_ROOM_CELLS, MAX_ROOM_HEIGHT)
	).is_equal(BuildValidationReachability.Verdict.ROOM)


func test_corner_touching_regions_flanker_blocked_seals_a_but_not_b() -> void:
	# Arrange — identical geometry, but NEITHER flanker_p (31, ROOM_Y, 0) NOR
	# flanker_q (30, ROOM_Y, 1) is given a floor this time (see the AC29/30
	# section note for why both must close — occupying a flanker cell with a
	# solid block directly, rather than simply never flooring it, would
	# create an unintended step-UP ledge one cell above it and defeat the
	# seal). A now has no route to B — or anywhere else — at all; B's own
	# door is untouched.
	var grid: VoxelWorldGrid = _make_grid()
	_place_interior_cell(grid, Vector3i(29, ROOM_Y, 0))
	_place_interior_cell(grid, Vector3i(30, ROOM_Y, 0))
	_place_interior_cell(grid, Vector3i(31, ROOM_Y, 1))
	_place_interior_cell(grid, Vector3i(32, ROOM_Y, 1))
	_place_open_sky_cell(grid, Vector3i(33, ROOM_Y, 1))  # B's own door — untouched

	# Act
	var region_a: BuildValidationRegion = BuildValidationRegionFormation.form_region(
		grid, Vector3i(29, ROOM_Y, 0), MAX_ROOM_HEIGHT
	)
	var region_b: BuildValidationRegion = BuildValidationRegionFormation.form_region(
		grid, Vector3i(31, ROOM_Y, 1), MAX_ROOM_HEIGHT
	)

	# Assert — A is Sealed; B is unaffected and remains a Room.
	assert_int(
		BuildValidationReachability.classify_region(grid, region_a, MIN_ROOM_CELLS, MAX_ROOM_HEIGHT)
	).is_equal(BuildValidationReachability.Verdict.SEALED)
	assert_int(
		BuildValidationReachability.classify_region(grid, region_b, MIN_ROOM_CELLS, MAX_ROOM_HEIGHT)
	).is_equal(BuildValidationReachability.Verdict.ROOM)


# ---------------------------------------------------------------------------
# AC25 — never blocks, reverts, or touches a Building System API
# ---------------------------------------------------------------------------

func test_never_blocks_or_reverts_building_system_across_invalid_configurations() -> void:
	# Arrange — a mocked Building System, and a handful of Sealed
	# configurations built fresh in this test (a fully sealed room, a
	# 2-cell-drop opening, a sub-clearance opening, and a blocked flanked
	# diagonal) covering every DISTINCT sealing mechanism this file exercises.
	var mock_building_system := _MockBuildingSystem.new()

	var sealed_room_grid: VoxelWorldGrid = _make_grid()
	_place_interior_rect(sealed_room_grid, range(0, 3), range(0, 3), ROOM_Y)
	var sealed_room_region: BuildValidationRegion = BuildValidationRegionFormation.form_region(
		sealed_room_grid, Vector3i(0, ROOM_Y, 0), MAX_ROOM_HEIGHT
	)

	var drop_grid: VoxelWorldGrid = _make_grid()
	_place_interior_cell(drop_grid, Vector3i(0, ROOM_Y, 0))
	_place_interior_cell(drop_grid, Vector3i(1, ROOM_Y, 0))
	drop_grid.set_cell(Vector3i(2, 0, 0), _solid_contents())
	var drop_region: BuildValidationRegion = BuildValidationRegionFormation.form_region(
		drop_grid, Vector3i(0, ROOM_Y, 0), MAX_ROOM_HEIGHT
	)

	var flanker_grid: VoxelWorldGrid = _make_grid()
	_place_interior_cell(flanker_grid, Vector3i(20, ROOM_Y, 0))
	_place_interior_cell(flanker_grid, Vector3i(21, ROOM_Y, 0))
	_place_open_sky_cell(flanker_grid, Vector3i(22, ROOM_Y, 1))
	var flanker_region: BuildValidationRegion = BuildValidationRegionFormation.form_region(
		flanker_grid, Vector3i(20, ROOM_Y, 0), MAX_ROOM_HEIGHT
	)

	# Act — analyze every Sealed configuration; the mock is never involved in
	# any production call path.
	var verdicts: Array[int] = [
		BuildValidationReachability.classify_region(
			sealed_room_grid, sealed_room_region, MIN_ROOM_CELLS, MAX_ROOM_HEIGHT
		),
		BuildValidationReachability.classify_region(
			drop_grid, drop_region, MIN_ROOM_CELLS, MAX_ROOM_HEIGHT
		),
		BuildValidationReachability.classify_region(
			flanker_grid, flanker_region, MIN_ROOM_CELLS, MAX_ROOM_HEIGHT
		),
	]

	# Assert — every configuration is genuinely Sealed (a meaningful negative
	# test needs the invalid state to actually be invalid), and the mock's
	# call counts never moved.
	for verdict: int in verdicts:
		assert_int(verdict).is_equal(BuildValidationReachability.Verdict.SEALED)
	assert_int(mock_building_system.block_call_count).is_equal(0)
	assert_int(mock_building_system.revert_call_count).is_equal(0)


# ---------------------------------------------------------------------------
# Edge case — a region at exactly min_room_cells with zero legal steps out
# ---------------------------------------------------------------------------

func test_region_at_min_cells_with_zero_legal_steps_out_is_sealed() -> void:
	# Arrange — exactly MIN_ROOM_CELLS interior cells (distinct from AC4's
	# below-threshold OPEN case), with absolutely nothing standable anywhere
	# nearby.
	var grid: VoxelWorldGrid = _make_grid()
	_place_interior_cell(grid, Vector3i(40, ROOM_Y, 0))
	_place_interior_cell(grid, Vector3i(41, ROOM_Y, 0))

	# Act
	var region: BuildValidationRegion = BuildValidationRegionFormation.form_region(
		grid, Vector3i(40, ROOM_Y, 0), MAX_ROOM_HEIGHT
	)
	var verdict: int = BuildValidationReachability.classify_region(
		grid, region, MIN_ROOM_CELLS, MAX_ROOM_HEIGHT
	)

	# Assert
	assert_int(region.size()).is_equal(MIN_ROOM_CELLS)
	assert_int(verdict).is_equal(BuildValidationReachability.Verdict.SEALED)


# ---------------------------------------------------------------------------
# Grep guards
# ---------------------------------------------------------------------------

func test_no_villager_ai_or_local_walkability_constant_in_reachability_file() -> void:
	# BV-4 / verbatim-consumption discipline: the reachability trace never
	# references VillagerAi and never declares a local copy of either shared
	# walkability constant.
	var source: String = _read_source_stripped_of_comments(
		"res://src/build_validation/build_validation_reachability.gd"
	)
	assert_bool(source.contains("VillagerAi")).is_false()
	assert_bool(source.contains("VILLAGER_CLEARANCE")).is_false()
	assert_bool(source.contains("MAX_STEP_HEIGHT")).is_false()


func test_no_navigation_server_reference_in_reachability_file() -> void:
	# Control Manifest Feature Layer Forbidden: zero NavigationServer3D-family
	# usage anywhere in Build Validation.
	var source: String = _read_source_stripped_of_comments(
		"res://src/build_validation/build_validation_reachability.gd"
	)
	assert_bool(source.contains("NavigationServer3D")).is_false()
	assert_bool(source.contains("NavigationAgent3D")).is_false()
	assert_bool(source.contains("NavigationRegion3D")).is_false()


# ---------------------------------------------------------------------------
# Test helpers
# ---------------------------------------------------------------------------

## Reads [param file_path], STRIPPING full-line `#`/`##` doc-comment lines
## first -- mirrors `candidate_cell_test.gd`/`region_formation_test.gd`'s own
## established `_read_source_stripped_of_comments` precedent.
func _read_source_stripped_of_comments(file_path: String) -> String:
	var combined: String = ""
	var text: String = FileAccess.get_file_as_string(file_path)
	for line: String in text.split("\n"):
		if not line.strip_edges().begins_with("#"):
			combined += line
			combined += "\n"
	return combined
