shader_type spatial;
render_mode blend_add, depth_draw_opaque, cull_disabled;

uniform vec4 beam_color : source_color = vec4(1.0, 0.25, 0.25, 0.8);
uniform float core_brightness : hint_range(1.0, 5.0) = 2.5;

void fragment() {
	// Distance from center axis of the beam (UV.x or UV.y)
	float dist_from_center = abs(UV.x - 0.5) * 2.0;
	float core = pow(1.0 - clamp(dist_from_center, 0.0, 1.0), 4.0) * core_brightness;
	float glow = pow(1.0 - clamp(dist_from_center, 0.0, 1.0), 1.5) * 0.6;

	vec3 final_color = mix(beam_color.rgb, vec3(1.0, 1.0, 1.0), core * 0.7);
	ALBEDO = final_color;
	EMISSION = final_color * (beam_color.a * (core + glow) * 2.2);
	ALPHA = clamp(beam_color.a * (core + glow), 0.0, 1.0);
}
