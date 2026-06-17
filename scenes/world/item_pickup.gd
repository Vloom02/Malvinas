extends Area2D
class_name ItemPickup
## Objeto del mundo que puede entregar ItemData, WeaponData o SkillBook.
##
## Soluciona la incompatibilidad de tipos: Interactable solo acepta ItemData,
## pero necesitamos dropear armas y libros en el mapa. Este pickup detecta
## el tipo del Resource y ejecuta la acción correcta.

@export var resource: Resource = null
@export var quantity: int = 1
@export var pickup_id: String = ""
@export var message: String = ""

var _player_inside: bool = false
var _taken: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	if pickup_id != "" and GameState.has_flag("taken_" + pickup_id):
		_taken = true
		visible = false

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_player_inside = true

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		_player_inside = false

func _unhandled_input(event: InputEvent) -> void:
	if _player_inside and event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		if _taken:
			Dialogue.say("Ya agarraste esto.")
			return
		if resource == null:
			Dialogue.say(message if message != "" else "No hay nada aquí.")
			return
		_grab()

func _grab() -> void:
	var text := ""
	if resource is WeaponData:
		var weapon: WeaponData = resource as WeaponData
		GameState.equip_weapon(weapon)
		_taken = true
		if pickup_id != "":
			GameState.set_flag("taken_" + pickup_id)
		text = weapon.find_text if weapon.find_text != "" else "Encontrás: %s" % weapon.display_name
		text += "\n\nEquipás %s." % weapon.display_name
	elif resource is SkillBook:
		var book: SkillBook = resource as SkillBook
		if book.read_flag != "" and GameState.has_flag(book.read_flag):
			Dialogue.say("Ya leíste %s." % book.display_name)
			return
		GameState.apply_skill_book(book)
		_taken = true
		if pickup_id != "":
			GameState.set_flag("taken_" + pickup_id)
		text = book.read_text
	elif resource is ItemData:
		var item: ItemData = resource as ItemData
		if GameState.add_item(item, quantity):
			_taken = true
			if pickup_id != "":
				GameState.set_flag("taken_" + pickup_id)
			text = "Obtenés: %s x%d." % [item.display_name, quantity]
		else:
			text = "No te entra: el inventario está lleno."
	else:
		text = "No sabés qué es esto."
	Dialogue.say(text)
	if _taken:
		visible = false
