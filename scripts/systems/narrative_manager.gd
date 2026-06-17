extends Node
class_name NarrativeManager
## Sistema de consecuencias narrativas. Registra decisiones del jugador
## y las reutiliza en diálogos, eventos y finales.
##
## Cada decisión tiene un id, un peso, y efectos. Se guarda/carga con la partida.

## Estructura: { "decision_id": { "weight": int, "effects": Dictionary } }
var consequences: Dictionary = {}

## Registra una decisión. weight = importancia (para comparar).
func make_decision(id: String, weight: int = 1, effects: Dictionary = {}) -> void:
	if not consequences.has(id):
		consequences[id] = {"weight": 0, "effects": {}}
	consequences[id]["weight"] += weight
	for key in effects.keys():
		consequences[id]["effects"][key] = effects[key]
	# También setea flags para que los diálogos puedan leer.
	GameState.set_flag("decision_" + id)

## Devuelve el peso acumulado de una decisión.
func get_weight(id: String) -> int:
	if consequences.has(id):
		return consequences[id]["weight"]
	return 0

## Devuelve true si se tomó una decisión.
func has_decision(id: String) -> bool:
	return consequences.has(id)

## Devuelve el efecto de una decisión (o default_value).
func get_effect(id: String, effect_key: String, default_value = null):
	if consequences.has(id) and consequences[id]["effects"].has(effect_key):
		return consequences[id]["effects"][effect_key]
	return default_value

## Devuelve todas las decisiones tomadas con peso > threshold.
func get_major_decisions(threshold: int = 1) -> Array:
	var result := []
	for id in consequences.keys():
		if consequences[id]["weight"] >= threshold:
			result.append(id)
	return result

## Serializar para guardado.
func serialize() -> Dictionary:
	return {"consequences": consequences}

## Deserializar desde guardado.
func deserialize(data: Dictionary) -> void:
	var c = data.get("consequences", {})
	if typeof(c) == TYPE_DICTIONARY:
		consequences = c

## Resetear para partida nueva.
func reset() -> void:
	consequences.clear()
