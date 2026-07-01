extends Node2D
## Tienda de campaña. Cuando entrás y apretás E, abrís el menú del Sargento
## (guardar, comprar provisiones, descansar, hablar).

var _inside: bool = false

func _ready() -> void:
	$Area2D.body_entered.connect(_on_enter)
	$Area2D.body_exited.connect(_on_exit)
	$InteractHint.visible = false

func _on_enter(body: Node) -> void:
	if body.is_in_group("player"):
		_inside = true
		$InteractHint.visible = true

func _on_exit(body: Node) -> void:
	if body.is_in_group("player"):
		_inside = false
		$InteractHint.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if _inside and event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		NpcMenu.open("Sargento")
