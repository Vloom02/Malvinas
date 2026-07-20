shader_type canvas_item;
// Melt inverso estilo Doom: la imagen del mapa "cae" en columnas verticales
// con retardos aleatorios hasta encajar en su lugar. Donde todavía no llegó,
// se ve negro. progress: 0 = todo negro, 1 = imagen completa.

uniform float progress : hint_range(0.0, 1.0) = 1.0;
uniform float columns = 80.0;
// false = entrada (el mapa nuevo cae hasta armarse). true = salida (melt
// clásico Doom: la pantalla vieja se derrite hacia abajo dejando negro).
uniform bool salida = false;
uniform sampler2D screen_tex : hint_screen_texture, filter_nearest;

float hash(float n) {
	return fract(sin(n * 127.1) * 43758.5453);
}

void fragment() {
	float col = floor(SCREEN_UV.x * columns);
	float delay = hash(col) * 0.35;
	float p = clamp((progress - delay) / 0.65, 0.0, 1.0);
	p = p * p * (3.0 - 2.0 * p); // suavizar la caída
	if (salida) {
		// progress: 0 = imagen completa, 1 = todo negro (cada columna cayó).
		vec2 uv = vec2(SCREEN_UV.x, SCREEN_UV.y - p);
		COLOR = uv.y < 0.0 ? vec4(0.0, 0.0, 0.0, 1.0) : texture(screen_tex, uv);
	} else {
		// progress: 0 = todo negro, 1 = imagen completa.
		vec2 uv = vec2(SCREEN_UV.x, SCREEN_UV.y + (1.0 - p));
		COLOR = uv.y > 1.0 ? vec4(0.0, 0.0, 0.0, 1.0) : texture(screen_tex, uv);
	}
}
