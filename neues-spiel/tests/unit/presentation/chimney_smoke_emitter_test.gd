## Unit test — [ChimneySmokeEmitter] (Presentation Experience story
## presentation-001 Sub-scope A; art-bible SS6.5 "smoke absence = nobody
## home" + SS8.9.5 particle budget).
##
## Covers:
## 1. headless setup() with no rendering.
## 2. default state is NOT emitting ("nobody home" until told otherwise).
## 3. set_occupied_lit toggles emitting on/off, both directions.
## 4. the particle count never exceeds the SS8.9.5 <=50 ambient-emitter
##    budget, even with an out-of-range config (AmbientLifeConfig clamps it
##    before ChimneySmokeEmitter ever reads it).
##
## NOTE (accumulated pitfall): [GPUParticles3D] instantiates fine headless
## (no viewport/window needed to construct/configure it); only an actual
## RENDERED frame needs a window, which this unit test never asks for.
class_name ChimneySmokeEmitterTest
extends GdUnitTestSuite


func test_setup_headless_completes_and_starts_not_emitting() -> void:
	var emitter: ChimneySmokeEmitter = auto_free(ChimneySmokeEmitter.new())
	emitter.config = AmbientLifeConfig.new()
	assert_bool(emitter.is_set_up()).is_false()

	emitter.setup()

	assert_bool(emitter.is_set_up()).is_true()
	assert_bool(emitter.is_emitting_smoke()).is_false()


func test_set_occupied_lit_true_starts_emitting() -> void:
	var emitter: ChimneySmokeEmitter = auto_free(ChimneySmokeEmitter.new())
	emitter.config = AmbientLifeConfig.new()
	emitter.setup()

	emitter.set_occupied_lit(true)

	assert_bool(emitter.is_emitting_smoke()).is_true()
	assert_bool(emitter.get_particles().emitting).is_true()


func test_set_occupied_lit_false_after_true_stops_emitting() -> void:
	var emitter: ChimneySmokeEmitter = auto_free(ChimneySmokeEmitter.new())
	emitter.config = AmbientLifeConfig.new()
	emitter.setup()
	emitter.set_occupied_lit(true)

	emitter.set_occupied_lit(false)

	assert_bool(emitter.is_emitting_smoke()).is_false()


func test_particle_amount_never_exceeds_ambient_vfx_budget() -> void:
	var config := AmbientLifeConfig.new()
	config.chimney_smoke_particle_amount = 9999
	config.validate()  # the sanctioned clamp path a real setup() call always runs first

	var emitter: ChimneySmokeEmitter = auto_free(ChimneySmokeEmitter.new())
	emitter.config = config
	emitter.setup()

	assert_int(emitter.get_particles().amount).is_less_equal(
		AmbientLifeConfig.CHIMNEY_SMOKE_PARTICLE_AMOUNT_MAX
	)


func test_draw_pass_mesh_is_assigned_never_left_default_missing() -> void:
	var emitter: ChimneySmokeEmitter = auto_free(ChimneySmokeEmitter.new())
	emitter.config = AmbientLifeConfig.new()

	emitter.setup()

	assert_object(emitter.get_particles().draw_pass_1).is_not_null()
