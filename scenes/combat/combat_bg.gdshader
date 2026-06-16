shader_type canvas_item;

uniform float vignette_radius : hint_range(0.0, 1.0) = 0.35;
uniform float vignette_softness : hint_range(0.0, 1.0) = 0.45;
uniform float vignette_darkness : hint_range(0.0, 1.0) = 0.85;
uniform float grain_amount : hint_range(0.0, 0.2) = 0.06;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

void fragment() {
	float noise = hash(UV * 3.0 + vec2(TIME * 0.015)) * grain_amount;
	vec3 base = COLOR.rgb + (noise - grain_amount * 0.5);

	vec2 p = UV - vec2(0.5);
	p.x *= 1.78;
	float d = length(p);
	float vignette = smoothstep(vignette_radius, vignette_radius + vignette_softness, d) * vignette_darkness;
	base *= (1.0 - vignette);

	COLOR = vec4(base, 1.0);
}
