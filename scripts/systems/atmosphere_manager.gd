extends Node
class_name AtmosphereManager
## Sistema de tensión/atmósfera. La música y los visuales reaccionan al
## peligro cercano, la cordura baja, y el nivel de amenaza del mundo.
##
## Se actualiza cada frame desde GameState._process().
## Lee: nearest enemy distance, sanity, danger level, bleeding.

## Nivel de tensión actual (0.0 = calma, 1.0 = pánico total).
var tension: float = 0.0

## Distancia a la que los enemigos empiezan a subir la tensión.
var tension_range: float = 200.0

func _ready() -> void:
	pass

## Llamar cada frame. Actualiza el nivel de tensión basado en el estado.
func update_tension(player_pos: Vector2, enemies: Array, delta: float) -> void:
	var target_tension := 0.0

	# 1. Enemigos cercanos suben la tensión.
	if not enemies.is_empty():
		var min_dist := INF
		for e in enemies:
			if not is_instance_valid(e):
				continue
			var d: float = player_pos.distance_to(e.global_position)
			if d < min_dist:
				min_dist = d
		if min_dist < tension_range:
			var proximity_t := 1.0 - (min_dist / tension_range)
			target_tension = maxf(target_tension, proximity_t)

	# 2. Cordura baja sube la tensión.
	var sanity_t := 1.0 - (float(GameState.sanity) / float(GameState.SANITY_MAX))
	target_tension = maxf(target_tension, sanity_t * 0.6)

	# 3. Sangrado/vida baja sube la tensión.
	var hp_t := 1.0 - (float(GameState.player_hp) / float(GameState.PLAYER_HP_MAX))
	target_tension = maxf(target_tension, hp_t * 0.4)
	target_tension = maxf(target_tension, clampf(GameState.bleeding * 0.15, 0.0, 0.5))

	# 4. Nivel de peligro general.
	target_tension = maxf(target_tension, clampf(GameState.danger * 0.05, 0.0, 0.3))

	# Suavizar transición.
	tension = lerpf(tension, clampf(target_tension, 0.0, 1.0), delta * 2.0)

## Devuelve un valor 0-1 para modulación de shaders/audio.
func get_tension() -> float:
	return tension

## Devuelve un multiplicador de volumen para música ambiental (-dB).
func get_music_volume_mod() -> float:
	return lerpf(0.0, -8.0, tension)

## Devuelve un multiplicador de pitch para efectos de tensión.
func get_pitch_mod() -> float:
	return lerpf(1.0, 1.15, tension)

## Devuelve un color de tint para la pantalla según la tensión.
func get_tension_tint() -> Color:
	var r := lerpf(0.0, 0.15, tension)
	return Color(r, 0.0, 0.0, lerpf(0.0, 0.2, tension))
