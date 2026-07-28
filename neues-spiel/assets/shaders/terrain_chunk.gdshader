// Voxel World terrain chunk material (Story vox-007, ADR-0014 Decision
// Section 2 + art-bible SS8.9.1's "exactly one ShaderMaterial for all
// terrain" canonical contract). ONE compiled instance of this shader is
// wrapped in ONE ShaderMaterial (VoxelWorldMesher._material) and shared by
// EVERY chunk's ArrayMesh surface -- never a per-chunk or per-material-id
// ShaderMaterial (art-bible SS8.9.11 Reject-If gate #1).
//
// Scope note (vox-007): this story's job is CORRECT WINDING + CULLING, not
// texturing. Atlas sampling (art-bible SS8.9.1's "atlas" clause) has no
// scheduled story yet anywhere in production/epics/voxel-world/ as of this
// story -- deferred. Vertex-AO and the vertical slice's y_cut slice-view
// uniform (prototypes/last-seal-vertical-slice/chunk_terrain.gdshader) are
// ALSO deferred -- neither is required by this story's acceptance criteria.
// This shader stubs texturing with the mesh's own per-vertex COLOR (a flat
// per-block-type placeholder assigned by VoxelWorldMesher -- see that
// script's DEBUG_BLOCK_COLORS) as plain unlit-texture ALBEDO, so this SAME
// material/shader file is the one atlas/AO/y_cut stories extend in place
// later, never replaced with a second ShaderMaterial.
shader_type spatial;

// Explicit per the sprint QA smoke item (TR-voxel-world-052): backface
// culling is Godot's default even without this line, but it is stated
// explicitly here so this committed-block material's culling behavior is
// never ambiguous or silently dependent on an unstated engine default.
// CULL_DISABLED must NEVER appear on this material or anywhere else in this
// system -- the vertical slice's now-EXPIRED mitigation
// (prototypes/last-seal-vertical-slice/chunk_terrain.gdshader's
// `render_mode cull_disabled, ...`) is exactly what this story exists to
// retire. Grep-guarded by
// tests/unit/voxel_world/mesher_material_contract_test.gd.
render_mode cull_back, diffuse_lambert, specular_schlick_ggx;

void fragment() {
	ALBEDO = COLOR.rgb;
	ROUGHNESS = 1.0;
	METALLIC = 0.0;
	SPECULAR = 0.0;
}
