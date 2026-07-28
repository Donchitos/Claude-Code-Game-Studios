// Grass/foliage wind-sway material (Presentation Experience story
// presentation-001 Sub-scope A; art-bible SS6.5: "Cheap -- vertex-shader
// wind"; SS3.2: vegetation is the sanctioned "soft" shape exception).
//
// A SEPARATE ShaderMaterial from res://assets/shaders/terrain_chunk.gdshader
// -- never applied to committed-block terrain (Control Manifest Presentation
// layer Forbidden: "baking any ambient motion ... into committed-block
// materials"; whole-story AC: "the slice-validated static foundation is
// untouched"). This file exists purely so a later vegetation-authoring story
// can assign it to real cross-quad grass/foliage meshes without inventing a
// second wind shader.
//
// Texturing deferred (art-bible SS6.2/SS8.9.4: vegetation atlas has no
// scheduled story yet) -- mirrors terrain_chunk.gdshader's own placeholder
// choice: ALBEDO reads the mesh's per-vertex COLOR rather than sampling an
// atlas that does not exist yet.
//
// Culling deliberately left at Godot's cull_back default (explicit, per this
// project's "never leave culling to an unstated default" convention) rather
// than cull_disabled -- a double-sided cross-quad billboard mesh is a later
// vegetation-mesh-authoring decision (no such mesh exists in this codebase
// yet), not something this wind-sway shader needs to force.
shader_type spatial;

render_mode cull_back, diffuse_lambert, specular_schlick_ggx;

// Sway oscillation speed, cycles roughly per second at wind_strength's peak.
uniform float wind_speed : hint_range(0.0, 5.0) = 1.0;

// Peak horizontal displacement, in the mesh's own local units.
uniform float wind_strength : hint_range(0.0, 1.0) = 0.15;

void vertex() {
	// Phase offset from world position so neighboring instances of the same
	// mesh do not sway in lockstep ("the air is alive," SS6.5) -- read from
	// MODEL_MATRIX's translation column rather than a per-instance uniform,
	// so a single shared ShaderMaterial (art-bible SS8.9.1 canonical
	// contract) still produces varied motion per placement.
	float phase = (MODEL_MATRIX[3].x + MODEL_MATRIX[3].z) * 0.5;
	// VERTEX.y scales the sway so a blade's base (near y=0) stays anchored
	// and its tip sways the most -- the standard grass-wind vertex trick.
	float sway = sin(TIME * wind_speed + phase) * wind_strength * clamp(VERTEX.y, 0.0, 10.0);
	VERTEX.x += sway;
}

void fragment() {
	ALBEDO = COLOR.rgb;
	ROUGHNESS = 1.0;
	METALLIC = 0.0;
	SPECULAR = 0.0;
}
