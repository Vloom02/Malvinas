extends Node
class_name MapManager
## Sistema de conexión de mapas. Define qué salas existen, cómo se conectan,
## y la dificultad de cada zona.
##
## Se usa para generar transiciones dinámicas y escalar dificultad.

## Nivel actual (sube al avanzar).
var current_level: int = 1
## Teatro/zona actual.
var current_zone: String = "infanteria"

## Zonas del juego y su dificultad base.
const ZONES := {
	"infanteria": {
		"name": "Infantería",
		"difficulty": 1,
		"maps": [
			"res://scenes/maps/nivel1_trinchera.tscn",
			"res://scenes/maps/nivel1_campo.tscn",
			"res://scenes/maps/nivel1_pozo.tscn",
		],
		"enemy_tier": 1,
	},
	"naval": {
		"name": "Naval",
		"difficulty": 2,
		"maps": ["res://scenes/maps/naval_barco.tscn"],
		"enemy_tier": 2,
	},
}

## Devuelve la dificultad de la zona actual.
func get_zone_difficulty() -> int:
	return ZONES.get(current_zone, {}).get("difficulty", 1)

## Devuelve el tier de enemigos de la zona actual.
func get_enemy_tier() -> int:
	return ZONES.get(current_zone, {}).get("enemy_tier", 1)

## Devuelve el nombre de la zona actual.
func get_zone_name() -> String:
	return ZONES.get(current_zone, {}).get("name", "Desconocido")

## Avanza a la siguiente zona. Devuelve true si hay zona siguiente.
func advance_zone() -> bool:
	var zone_keys := ZONES.keys()
	var idx := zone_keys.find(current_zone)
	if idx < 0 or idx >= zone_keys.size() - 1:
		return false
	current_zone = zone_keys[idx + 1]
	current_level += 1
	return true

## Selecciona un enemigo al azar según el tier de la zona.
func get_random_enemy_path() -> String:
	var tier := get_enemy_tier()
	var pool: Array[String] = []
	match tier:
		1:
			pool = ["res://data/enemies/ghoul.tres", "res://data/enemies/soldado.tres"]
		2:
			pool = ["res://data/enemies/soldado.tres", "res://data/enemies/pesadilla.tres", "res://data/enemies/perro.tres"]
		3:
			pool = ["res://data/enemies/pesadilla.tres"]
	return pool[randi() % pool.size()]

## Serializar para guardado.
func serialize() -> Dictionary:
	return {"current_level": current_level, "current_zone": current_zone}

## Deserializar.
func deserialize(data: Dictionary) -> void:
	current_level = int(data.get("current_level", 1))
	current_zone = str(data.get("current_zone", "infanteria"))

## Resetear.
func reset() -> void:
	current_level = 1
	current_zone = "infanteria"
