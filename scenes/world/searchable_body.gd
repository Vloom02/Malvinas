extends Interactable
class_name SearchableBody
## Cadáver u objeto del mundo que se puede buscar con un dado.
## Tirada de Percepción: éxito = item, fallo = nada o peligro.

## DC de la búsqueda.
@export var search_dc: int = 10
## Items que puede contener (se elige uno al azar).
@export var possible_items: Array[ItemData] = []
## Si fallás, puede pasar algo malo.
@export var fail_effect: String = ""  ## "bleed", "cold", "sanity", ""
## Cuánto sangrado/frío/cordura si fallás.
@export var fail_amount: int = 1
## Mensaje si no queda nada.
@export var empty_message: String = "Ya no hay nada que buscar acá."
## Flag para recordar que ya se buscó.
@export var search_id: String = ""

var _searched: bool = false

func _ready() -> void:
	super._ready()
	if search_id != "" and GameState.has_flag("searched_" + search_id):
		_searched = true
	# Sobreescribir el message base.
	if _searched:
		message = empty_message

func _unhandled_input(event: InputEvent) -> void:
	if _player_inside and event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		if _searched:
			Dialogue.say(empty_message)
			return
		_do_search()

func _do_search() -> void:
	var r := Dice.check(GameState.get_perception_mod(), search_dc)
	var text := "Revisás los restos...\n[d20 %d+%d=%d vs %d]\n\n" % [
		r["die"], r["modifier"], r["total"], search_dc]

	if r["success"]:
		_searched = true
		if search_id != "":
			GameState.set_flag("searched_" + search_id)
		if possible_items.is_empty():
			text += "No encontrás nada de utilidad."
		else:
			var item: ItemData = possible_items[randi() % possible_items.size()]
			if GameState.add_item(item):
				text += "Encontrás: %s." % item.display_name
			else:
				text += "Encontrás %s, pero no te cabe en el inventario." % item.display_name
	else:
		text += "No encontrás nada."
		if r["fumble"]:
			text += "\n¡Pifia! Algo te lastimás."
			_apply_fail_effect()
		elif fail_effect != "" and Dice.chance(0.4):
			text += "\n" + _apply_fail_effect()

	if journal_entry != "":
		GameState.add_journal(journal_entry)
	Dialogue.say(text)
	interacted.emit()

func _apply_fail_effect() -> String:
	match fail_effect:
		"bleed":
			GameState.apply_bleeding(fail_amount)
			return "El filo te corta: empezás a SANGRAR."
		"cold":
			GameState.cold = clampi(GameState.cold + fail_amount * 10, 0, 100)
			GameState.body_changed.emit()
			return "El frío te cala los huesos."
		"sanity":
			GameState.drain_sanity(fail_amount * 5)
			return "Lo que ves te horroriza. Perdés cordura."
		_:
			return ""
