## Chimney/hearth smoke wisp emitter (Presentation Experience story
## presentation-001 Sub-scope A; art-bible SS6.5). Renders as a small
## [GPUParticles3D] (art-bible SS8.9.5 "Cheap -- small GPUParticles3D" cost
## class), gated on an externally-supplied occupied/lit state via [method
## set_occupied_lit] rather than any state this class computes itself --
## "smoke absence = nobody home" (Principle 1) is a readable signal ABOUT a
## building's occupancy, not a simulation of it.
##
## Presentation-only, no new simulation (Control Manifest Presentation layer
## Required: "ambient motion is presentation-only, added on top of the
## static foundation"): this class holds zero building/occupancy logic of
## its own. The real occupied/lit signal source (a fixture's lit state, a
## project's DONE-and-inhabited state, ...) does not exist yet anywhere in
## this codebase as of this story -- exactly like [LoopPayoffSignalSurface]
## stood in for its own real emitters with test stubs, THIS class exposes
## the seam ([method set_occupied_lit]) a later Building-System/fixture
## wiring story calls into; it is never called from here.
##
## Placeholder VFX material (art-bible SS6 Texturing note: "VFX textures ...
## deferred until real assets exist"): a small unlit, alpha-blended
## billboard quad in a neutral warm-grey, mirroring [VoxelWorldMesher]'s own
## "flat placeholder color, never a missing/blocking asset" precedent
## ([constant VoxelWorldMesher.DEBUG_BLOCK_COLORS]) -- never left as an
## unassigned/default-white particle material.
class_name ChimneySmokeEmitter
extends Node3D

## Tuning-config dependency (ADR-0001 injected-tier / ADR-0002). Wired via a
## scene file's Inspector in production, or assigned directly in a headless
## test/tool -- never read inside `_ready()` (see [method setup]).
@export var config: AmbientLifeConfig

## The wrapped [GPUParticles3D] -- constructed once, at this node's own
## construction (mirrors [VoxelWorldMesher._material]'s "constructed exactly
## once" field-initializer precedent), never rebuilt per-toggle. [method
## set_occupied_lit] only flips [member GPUParticles3D.emitting]; it never
## reconstructs the particle system.
var _particles: GPUParticles3D = GPUParticles3D.new()

## True once [method setup] has completed.
var _is_set_up: bool = false


## Explicitly-callable wiring entry point (ADR-0001). Parents [member
## _particles] immediately here -- NEVER deferred to `_ready()` (which only
## fires once THIS node itself enters a live [SceneTree], and this
## codebase's established headless-test convention, ADR-0001, instantiates
## via `Node.new()` + `auto_free()` without ever adding the instance to a
## tree -- `_ready()` would simply never run, leaking [member _particles] as
## an unparented orphan node with nothing left to free it. Mirrors
## [VoxelWorldMesher]'s identical "add_child from the explicit method call,
## independent of the owner's own tree membership" precedent
## ([method VoxelWorldMesher._get_or_create_chunk_node]).) Asserts [member
## config] is wired, then builds the particle system's process material/draw
## pass from its tuning knobs. [member GPUParticles3D.emitting] starts
## `false` -- "nobody home" is the default until a caller (the eventual
## occupied/lit data source) calls [method set_occupied_lit].
func setup() -> void:
	assert(config != null, "ChimneySmokeEmitter.config not wired")
	if _particles.get_parent() == null:
		add_child(_particles)
	_particles.amount = config.chimney_smoke_particle_amount
	_particles.lifetime = config.chimney_smoke_lifetime_seconds
	_particles.process_material = _build_process_material()
	_particles.draw_pass_1 = _build_draw_mesh()
	_particles.emitting = false
	_is_set_up = true


## Returns whether [method setup] has completed.
func is_set_up() -> bool:
	return _is_set_up


## Sets whether the hearth/chimney this instance represents is currently
## occupied AND lit -- the ONE gating input this class reacts to (class doc
## comment). Toggling this does not rebuild the particle system, only its
## [member GPUParticles3D.emitting] flag -- cheap, called as rarely as the
## underlying occupancy/lit state itself changes, never per-frame.
func set_occupied_lit(is_occupied_lit: bool) -> void:
	_particles.emitting = is_occupied_lit


## Returns whether this emitter is CURRENTLY emitting smoke -- test-facing
## and equivalent to "is this building presenting as occupied/lit right now."
func is_emitting_smoke() -> bool:
	return _particles.emitting


## Returns the wrapped [GPUParticles3D] -- exposed read-only for tests/tools
## that need to inspect budget-relevant fields (`amount`, draw-pass mesh).
func get_particles() -> GPUParticles3D:
	return _particles


## Builds the upward-drifting wisp [ParticleProcessMaterial] from
## [member config]'s tuning knobs -- a soft cone spread, gentle upward
## velocity, and a fade-out-while-rising alpha curve so wisps dissipate
## rather than hard-cutting at end of life.
func _build_process_material() -> ParticleProcessMaterial:
	var material := ParticleProcessMaterial.new()
	material.direction = Vector3(0.0, 1.0, 0.0)
	material.spread = config.chimney_smoke_spread_degrees
	material.initial_velocity_min = config.chimney_smoke_rise_speed
	material.initial_velocity_max = config.chimney_smoke_rise_speed * 1.5
	material.gravity = Vector3(0.0, 0.15, 0.0)
	material.scale_min = 0.3
	material.scale_max = 0.6
	var fade_curve := Curve.new()
	fade_curve.add_point(Vector2(0.0, 0.0))
	fade_curve.add_point(Vector2(0.2, 1.0))
	fade_curve.add_point(Vector2(1.0, 0.0))
	var alpha_curve_texture := CurveTexture.new()
	alpha_curve_texture.curve = fade_curve
	material.alpha_curve = alpha_curve_texture
	return material


## Builds the placeholder unlit billboard quad draw pass -- class doc
## comment's "flat placeholder color, never a missing/blocking asset" note.
func _build_draw_mesh() -> QuadMesh:
	var mesh := QuadMesh.new()
	mesh.size = Vector2(0.5, 0.5)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	material.albedo_color = Color(0.72, 0.70, 0.68, 0.55)
	mesh.material = material
	return mesh
