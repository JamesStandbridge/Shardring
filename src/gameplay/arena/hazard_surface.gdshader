shader_type spatial;
render_mode cull_disabled, diffuse_lambert, specular_schlick_ggx;

uniform vec4 base_color : source_color = vec4(1.0, 0.45, 0.08, 1.0);
uniform sampler2D effect_texture : source_color, repeat_enable;
uniform bool use_effect_texture = false;
uniform int effect_mode = 0;
uniform float effect_strength = 0.45;
uniform float effect_tile_meters = 3.0;
uniform float pulse_speed = 2.0;
uniform float emission_energy = 0.0;
uniform float roughness_value = 0.72;

varying vec3 world_position;

float hash21(vec2 point) {
	return fract(sin(dot(point, vec2(269.5, 183.3))) * 43758.5453123);
}

float value_noise(vec2 point) {
	vec2 cell = floor(point);
	vec2 local = fract(point);
	local = local * local * (3.0 - 2.0 * local);
	float a = hash21(cell);
	float b = hash21(cell + vec2(1.0, 0.0));
	float c = hash21(cell + vec2(0.0, 1.0));
	float d = hash21(cell + vec2(1.0, 1.0));
	return mix(mix(a, b, local.x), mix(c, d, local.x), local.y);
}

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 uv = world_position.xz / max(effect_tile_meters, 0.01);
	if (effect_mode == 1) {
		uv += vec2(TIME * 0.05, TIME * 0.11);
	} else if (effect_mode == 2) {
		uv += vec2(sin(TIME * 0.9), cos(TIME * 0.7)) * 0.025;
	} else if (effect_mode == 3) {
		uv += vec2(0.0, TIME * 0.08);
	}

	vec3 effect_color = base_color.rgb;
	float mask = value_noise(uv * 3.0);
	if (use_effect_texture) {
		vec4 sampled = texture(effect_texture, uv);
		effect_color = sampled.rgb;
		mask = max(max(sampled.r, sampled.g), sampled.b);
	}

	float pulse = 0.65 + 0.35 * sin(TIME * pulse_speed + mask * 6.28318);
	vec3 color = mix(base_color.rgb, effect_color, effect_strength);
	color *= 0.92 + pulse * 0.13;

	ALBEDO = color;
	EMISSION = color * emission_energy * (0.5 + pulse * 0.5);
	ROUGHNESS = roughness_value;
	SPECULAR = 0.12;
}
