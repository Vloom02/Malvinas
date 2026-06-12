shader_type canvas_item;
// Niebla que se desplaza (dos capas de ruido a distinta velocidad). Sutil, para
// dar el clima húmedo y opresivo de Malvinas sin tapar el juego.

uniform sampler2D noise : repeat_enable;
uniform float speed = 0.015;
uniform float density : hint_range(0.0, 1.0) = 0.22;
uniform vec3 fog_color : source_color = vec3(0.7, 0.72, 0.75);

void fragment() {
	vec2 uv1 = UV * 2.0 + vec2(TIME * speed, TIME * speed * 0.5);
	vec2 uv2 = UV * 3.0 - vec2(TIME * speed * 0.7, TIME * speed * 0.4);
	float n = (texture(noise, uv1).r + texture(noise, uv2).r) * 0.5;
	float a = smoothstep(0.45, 0.85, n) * density;
	COLOR = vec4(fog_color, a);
}
