extends CanvasLayer
## Menú de pausa (autoload "PauseMenu"). Se abre con Esc durante la exploración
## (cuando hay un jugador en la sala). Reanudar, opciones o salir al título.

func _ready() -> void:
	visible = false
	$Center/VBox/Reanudar.pressed.connect(_close)
	$Center/VBox/Menu.pressed.connect(_open_game_menu)
	$Center/VBox/Opciones.pressed.connect(_open_settings)
	$Center/VBox/Titulo.pressed.connect(_to_title)

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	# No interferir si el game_menu está abierto.
	var game_menu := get_tree().root.find_child("GameMenu", true, false)
	if game_menu != null and game_menu.visible:
		return
	if visible:
		_close()
		get_viewport().set_input_as_handled()
	elif not get_tree().paused and get_tree().get_first_node_in_group("player") != null:
		_open()
		get_viewport().set_input_as_handled()

func _open() -> void:
	visible = true
	get_tree().paused = true
	$Center/VBox/Reanudar.grab_focus()

func _close() -> void:
	visible = false
	get_tree().paused = false

func _open_game_menu() -> void:
	visible = false
	get_tree().paused = false
	var game_menu := preload("res://scenes/ui/game_menu.tscn").instantiate()
	get_tree().root.add_child(game_menu)
	game_menu._open()
	await game_menu.tree_exited
	# Cuando se cierra el game_menu, volver a la pausa.
	get_tree().paused = true
	visible = true

func _open_settings() -> void:
	visible = false
	var settings := preload("res://scenes/ui/settings_menu.tscn").instantiate()
	get_tree().root.add_child(settings)
	settings.open()
	await settings.tree_exited
	# settings._close() despausa; volvemos a la pausa.
	get_tree().paused = true
	visible = true

func _to_title() -> void:
	visible = false
	get_tree().paused = false
	AudioManager.stop_music()
	get_tree().change_scene_to_file("res://scenes/ui/title.tscn")
