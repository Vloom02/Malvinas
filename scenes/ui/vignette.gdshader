shader_type canvas_item;
// Viñeta reusable: el centro queda visible y los bordes se funden a un color.
// Se usa dos veces: en negro (oscuridad por cordura) y en rojo (sangre/herida).

// radius: tamaño de la zona visible (más bajo = más cerrado/opresivo).
uniform float radius : hint_range(0.0, 1.0) = 0.26;
// softness: qué tan difuso es el borde.
uniform float softness : hint_range(0.0, 1.0) = 0.32;
// darkness: opacidad máxima del color en los bordes (1.0 = sólido).
uniform float darkness : hint_range(0.0, 1.0) = 0.96;
// tint: color de la viñeta (negro = oscuridad, rojo = sangre).
uniform vec3 tint = vec3(0.0);

void fragment() {
	vec2 p = UV - vec2(0.5);
	p.x *= 1.78; // corrige el aspecto 16:9 para que el círculo no quede ovalado
	float d = length(p);
	float a = smoothstep(radius, radius + softness, d) * darkness;
	COLOR = vec4(tint, a);
}
