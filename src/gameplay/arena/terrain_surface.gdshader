shader_type spatial;
render_mode cull_disabled, diffuse_lambert, specular_schlick_ggx;

uniform vec4 base_color : source_color = vec4(0.34, 0.50, 0.30, 1.0);
uniform vec4 secondary_color : source_color = vec4(0.42, 0.57, 0.34, 1.0);
uniform vec4 accent_color : source_color = vec4(0.52, 0.45, 0.28, 1.0);
uniform sampler2D albedo_texture : source_color, repeat_enable;
uniform sampler2D detail_texture : repeat_enable;
uniform bool use_albedo_texture = false;
uniform bool use_detail_texture = false;
uniform float texture_strength = 0.78;
uniform float texture_tile_meters = 6.5;
uniform float variation_strength = 0.22;
uniform float patch_scale = 10.0;
uniform float detail_texture_strength = 0.16;
uniform float detail_texture_tile_meters = 2.2;
uniform float detail_scale = 2.6;
uniform float detail_strength = 0.07;
uniform float speckle_strength = 0.035;
uniform float roughness_value = 0.86;

varying vec3 world_position;

float hash21(vec2 point) {
	return fract(sin(dot(point, vec2(127.1, 311.7))) * 43758.5453123);
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
	vec2 terrain_uv = world_position.xz;
	float large_patch = value_noise(terrain_uv / max(patch_scale, 0.01));
	float small_detail = value_noise(terrain_uv / max(detail_scale, 0.01));
	float speckle = step(1.0 - speckle_strength, hash21(floor(terrain_uv * 2.7)));
	float texture_detail = small_detail;

	vec3 color = mix(base_color.rgb, secondary_color.rgb, smoothstep(0.24, 0.88, large_patch) * variation_strength);
	if (use_albedo_texture) {
		vec3 texture_color = texture(albedo_texture, terrain_uv / max(texture_tile_meters, 0.01)).rgb;
		color = mix(color, texture_color, texture_strength);
	}
	if (use_detail_texture) {
		texture_detail = texture(detail_texture, terrain_uv / max(detail_texture_tile_meters, 0.01)).r;
	}
	color = mix(color, accent_color.rgb, speckle * 0.18);
	color *= 1.0 + (small_detail - 0.5) * detail_strength;
	color *= 1.0 + (texture_detail - 0.5) * detail_texture_strength;

	ALBEDO = color;
	ROUGHNESS = roughness_value;
	SPECULAR = 0.18;
}
