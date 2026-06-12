extends Area2D
class_name Npc
## NPC con el que te "reportás": acercate y apretá E para abrir su menú
## (guardar, comprar, hablar). Reutilizable: cada NPC tiene su nombre.

@export var npc_name: String = "Sargento"

var _inside: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_inside = true

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		_inside = false

func _unhandled_input(event: InputEvent) -> void:
	if _inside and event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		NpcMenu.open(npc_name)
