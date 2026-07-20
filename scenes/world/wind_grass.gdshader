shader_type canvas_item;
// Ilusión de brisa sobre el pasto: desplaza la GEOMETRÍA (vértices) en X según
// el tiempo y la posición. No toca las UV, así que no hay "smear"/chorreo por
// leer píxeles del tile vecino del atlas. Como la onda depende de la posición
// del vértice (no de la UV del tile), los bordes compartidos entre tiles se
// mueven idéntico → sin costuras.
// Pensado para una capa de pasto (NO aplicar a piso de cemento/tierra).

uniform float speed : hint_range(0.0, 5.0) = 1.0;
uniform float strength : hint_range(0.0, 6.0) = 1.5; // en píxeles
uniform float scale : hint_range(0.001, 0.2) = 0.03; // frecuencia espacial

void vertex() {
	float wave = sin(VERTEX.y * scale + TIME * speed)
		+ 0.5 * sin(VERTEX.y * scale * 1.7 + TIME * speed * 0.6 + VERTEX.x * scale * 0.5);
	VERTEX.x += wave * strength;
}
