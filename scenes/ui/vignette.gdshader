shader_type canvas_item;
// Viñeta opresiva estilo Fear & Hunger: el centro de la pantalla queda
// visible y los bordes se funden a negro. Como la cámara sigue al jugador,
// el círculo de luz queda siempre alrededor de él.

// radius: qué tan grande es la zona visible (más bajo = más cerrado/opresivo).
uniform float radius : hint_range(0.0, 1.0) = 0.26;
// softness: qué tan difuso es el borde de la oscuridad.
uniform float softness : hint_range(0.0, 1.0) = 0.32;
// darkness: opacidad máxima del negro en los bordes (1.0 = negro total).
uniform float darkness : hint_range(0.0, 1.0) = 0.96;

void fragment() {
	// Corrijo la relación de aspecto para que el círculo no quede ovalado feo.
	vec2 p = UV - vec2(0.5);
	p.x *= 1.78; // ~16:9
	float d = length(p);
	float a = smoothstep(radius, radius + softness, d) * darkness;
	COLOR = vec4(0.0, 0.0, 0.0, a);
}
