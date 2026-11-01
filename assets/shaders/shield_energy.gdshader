shader_type spatial;
render_mode blend_add, depth_draw_opaque, cull_disabled;

uniform vec4 shield_color : source_color = vec4(0.2, 0.65, 1.0, 0.85);
uniform vec4 rim_color : source_color = vec4(0.6, 0.9, 1.0, 1.0);
uniform float rim_power : hint_range(0.5, 8.0) = 2.8;
uniform float scanline_frequency = 25.0;
uniform float scanline_speed = 3.5;
uniform float hit_flash : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	// Fresnel rim calculation
	float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), rim_power);

	// Animated scrolling energy lines
	float scanline = sin((UV.y + UV.x * 0.2) * scanline_frequency - TIME * scanline_speed) * 0.5 + 0.5;
	scanline = pow(scanline, 3.0) * 0.35;

	vec4 base = mix(shield_color, rim_color, fresnel);
	base += scanline * rim_color;

	// Hit flash intensity
	base = mix(base, vec4(1.0, 1.0, 1.0, 1.0), hit_flash * 0.85);

	ALBEDO = base.rgb;
	EMISSION = base.rgb * (1.2 + fresnel * 2.0 + hit_flash * 3.0);
	ALPHA = clamp(base.a * (0.35 + fresnel * 0.65 + scanline + hit_flash), 0.0, 1.0);
}
