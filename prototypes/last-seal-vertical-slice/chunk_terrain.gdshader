// VERTICAL SLICE - NOT FOR PRODUCTION
// Chunk terrain/block shader (2026-07-22, BUILD UX PACKAGE feature 2: SLICE VIEW).
//
// Replicates the previous StandardMaterial3D look used by every chunk mesh
// (see voxel_world.gd _rebuild_chunk_mesh / _append_face):
//   - vertex color is a pure AO/shade multiplier (never a hue) that modulates
//     the atlas texture underneath (vertex_color_use_as_albedo equivalent)
//   - faces draw double-sided (cull_disabled — see the CCW/CW winding note
//     in voxel_world.gd _ready())
//   - matte: roughness 1.0, no specular/metallic (metallic_specular = 0.0
//     equivalent)
//
// Adds exactly ONE new thing over the old material: a y_cut plane. Fragments
// whose world-space Y is above y_cut are discarded (open cut, no cap faces —
// acceptable per task spec, since the mesher never emits a top face for a
// covered cell regardless of the visual cut).
//
// Chunk MeshInstance3D nodes are added at the scene-tree origin with no
// position/rotation/scale set (see voxel_world.gd _rebuild_chunk_mesh), so
// object-space VERTEX.y IS world-space Y here — no MODEL_MATRIX transform
// needed to recover world Y.
shader_type spatial;
render_mode cull_disabled, diffuse_lambert, specular_schlick_ggx;

uniform sampler2D albedo_texture : source_color, filter_nearest;
uniform float y_cut = 999.0;

varying float v_world_y;

void vertex() {
	v_world_y = VERTEX.y;
}

void fragment() {
	if (v_world_y > y_cut) {
		discard;
	}
	vec4 tex_color = texture(albedo_texture, UV);
	ALBEDO = tex_color.rgb * COLOR.rgb;
	ROUGHNESS = 1.0;
	METALLIC = 0.0;
	SPECULAR = 0.0;
}
