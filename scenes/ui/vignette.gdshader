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
// beam_dir: dirección hacia la que apunta la linterna (en espacio de pantalla, y hacia abajo).
uniform vec2 beam_dir = vec2(0.0, 1.0);
// beam_len: alcance del haz (0 = linterna apagada).
uniform float beam_len : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec2 p = UV - vec2(0.5);
	p.x *= 1.78; // corrige el aspecto 16:9 para que el círculo no quede ovalado
	float d = length(p);

	// Haz de linterna: en la dirección a la que mirás, la zona visible se alarga
	// formando un cono hacia adelante (no un círculo simétrico).
	if (beam_len > 0.0) {
		vec2 dir = normalize(vec2(beam_dir.x * 1.78, beam_dir.y));
		float proj = dot(p, dir);  // qué tan adelante (en la dirección del haz) está el pixel
		if (proj > 0.0) {
			// Reducir la distancia efectiva hacia adelante = revela más en esa dirección.
			d = max(0.0, d - proj * beam_len);
		}
	}

	float a = smoothstep(radius, radius + softness, d) * darkness;
	COLOR = vec4(tint, a);
}
