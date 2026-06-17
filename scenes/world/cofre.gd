extends Area2D
class_name Cofre
## Cofre que contiene múltiples items (WeaponData, SkillBook, ItemData).
## Al interactuar, entrega todos los items y se marca como abierto.

## Items que contiene el cofre ( WeaponData, SkillBook o ItemData).
@export var items: Array[Resource] = []
## Texto al abrir el cofre.
@export var open_text: String = "Abrís el cofre y encontrás:"
## Texto cuando ya está vacío.
@export var empty_text: String = "El cofre ya está vacío."
## Id único para persistencia (flag taken_<id>).
@export var pickup_id: String = ""

var _player_inside: bool = false
var _opened: bool = false

func _ready() -> void:
	if pickup_id != "" and GameState.has_flag("taken_" + pickup_id):
		_opened = true
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_player_inside = true

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		_player_inside = false

func _unhandled_input(event: InputEvent) -> void:
	if not _player_inside or not event.is_action_pressed("interact"):
		return
	get_viewport().set_input_as_handled()

	if _opened:
		Dialogue.say(empty_text)
		return

	var lines: PackedStringArray = [open_text]
	var any_item := false

	for res in items:
		if res is WeaponData:
			var w: WeaponData = res
			GameState.equip_weapon(w)
			lines.append("• %s (Daño: %d) — equipada." % [w.display_name, w.damage])
			any_item = true
		elif res is SkillBook:
			var b: SkillBook = res
			if b.read_flag == "" or not GameState.has_flag(b.read_flag):
				GameState.apply_skill_book(b)
				lines.append("• %s — %s" % [b.display_name, b.read_text])
				any_item = true
		elif res is ItemData:
			var item: ItemData = res
			if GameState.add_item(item, 1):
				lines.append("• %s" % item.display_name)
				any_item = true

	if not any_item:
		lines.append("(no encontrás nada útil)")

	_opened = true
	if pickup_id != "":
		GameState.set_flag("taken_" + pickup_id)
	Dialogue.say("\n".join(lines))
