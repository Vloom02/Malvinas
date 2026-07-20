extends Node2D
## Mesa de crafteo. Acercate y apretá E: abre la UI de crafteo, donde también
## se fabrican/montan mejoras del arma equipada y se la limpia con el kit.

const CRAFTING_SCENE := preload("res://scenes/ui/crafting.tscn")

var _inside: bool = false
var _ui: CanvasLayer = null

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
		if _ui == null:
			_ui = CRAFTING_SCENE.instantiate()
			add_child(_ui)
		_ui.open()
