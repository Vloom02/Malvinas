extends CanvasLayer
## Menú de pausa (autoload "PauseMenu"). Se abre con Esc durante la exploración
## (cuando hay un jugador en la sala). Reanudar o salir al título.

func _ready() -> void:
	visible = false
	$Center/VBox/Reanudar.pressed.connect(_close)
	$Center/VBox/Titulo.pressed.connect(_to_title)

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	if visible:
		_close()
		get_viewport().set_input_as_handled()
	elif not get_tree().paused and get_tree().get_first_node_in_group("player") != null:
		# Solo en exploración (hay jugador) y si no hay otro menú abierto.
		_open()
		get_viewport().set_input_as_handled()

func _open() -> void:
	visible = true
	get_tree().paused = true

func _close() -> void:
	visible = false
	get_tree().paused = false

func _to_title() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/title.tscn")
