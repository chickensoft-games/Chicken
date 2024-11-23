shader_type spatial;
render_mode depth_prepass_alpha, cull_back, unshaded;

uniform sampler2D noise_sampler : filter_linear_mipmap, repeat_enable;
uniform sampler2D gradient_sampler : repeat_disable, source_color;
uniform sampler2D height_fade : repeat_disable;
uniform float noise_scale = 0.2;
uniform float edge : hint_range(0.0, 1.0, 0.01) = 0.5;
uniform float smoothness : hint_range(0.0, 1.0, 0.01) = 0.1;
uniform float energy = 1.4;
varying vec4 custom;

void vertex() {
	custom = INSTANCE_CUSTOM;
	// Billboard Mode: Particles
	mat4 mat_world = mat4(
			normalize(INV_VIEW_MATRIX[0]),
			normalize(INV_VIEW_MATRIX[1]),
			normalize(INV_VIEW_MATRIX[2]),
			MODEL_MATRIX[3]);
	mat_world = mat_world * mat4(
			vec4(cos(INSTANCE_CUSTOM.x), -sin(INSTANCE_CUSTOM.x), 0.0, 0.0),
			vec4(sin(INSTANCE_CUSTOM.x), cos(INSTANCE_CUSTOM.x), 0.0, 0.0),
			vec4(0.0, 0.0, 1.0, 0.0),
			vec4(0.0, 0.0, 0.0, 1.0));
	MODELVIEW_MATRIX = VIEW_MATRIX * mat_world;

	// Billboard Keep Scale: Enabled
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(
			vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0),
			vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0),
			vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0),
			vec4(0.0, 0.0, 0.0, 1.0));

	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}

void fragment() {
	float noise = clamp(texture(noise_sampler, UV * noise_scale + custom.z).x - custom.g, 0.0, 1.0);
	float dist = smoothstep(0.5, 1.0, distance(UV, vec2(0.5)) * 2.0);
	float mask = clamp(noise - dist, 0.0, 1.0);
	vec3 color = texture(gradient_sampler, vec2(mask, 0.0)).rgb;
	ALBEDO = color * energy;
	ALPHA *= smoothstep(max(0.0, edge - smoothness), min(1.0, edge + smoothness), mask) * COLOR.a;
	ALPHA *= texture(height_fade, vec2(UV.y, 0.0)).x;
}