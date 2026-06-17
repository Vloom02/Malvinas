extends Control
## Menú de título. Consagración: tirada de dado al iniciar (solo ambientación;
## ya no define dificultad — siempre se juega en modo normal).

const NIVEL_INICIO := "res://scenes/maps/nivel1_trinchera.tscn"

@onready var continue_btn: Button = $Center/VBox/Continuar
@onready var vbox: VBoxContainer = $Center/VBox
@onready var consagracion_label: Label = $Center/VBox/ConsagracionLabel

func _ready() -> void:
	# Al volver al menú: despausar, ocultar el menú de pausa (es autoload y
	# persiste entre escenas) y cortar la música del juego.
	get_tree().paused = false
	PauseMenu.visible = false
	AudioManager.stop_music()
	_apply_saved_fullscreen()

	continue_btn.disabled = not GameState.has_save()
	$Center/VBox/Nueva.pressed.connect(_on_new_prompt)
	continue_btn.pressed.connect(_on_continue)
	$Center/VBox/Opciones.pressed.connect(_on_opciones)
	$Center/VBox/Salir.pressed.connect(_on_quit)
	$Center/VBox/Nueva.grab_focus()
	consagracion_label.visible = false

## Aplica la preferencia de pantalla completa guardada. Por defecto: fullscreen.
func _apply_saved_fullscreen() -> void:
	var want_fullscreen := true
	var cfg := ConfigFile.new()
	if cfg.load("user://settings.cfg") == OK:
		want_fullscreen = bool(cfg.get_value("settings", "fullscreen", true))
	if want_fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _on_new_prompt() -> void:
	for c in vbox.get_children():
		if c != consagracion_label:
			c.visible = false
	consagracion_label.visible = true
	consagracion_label.text = "CONSAGRACIÓN\n\nTirá el dado para sellar tu destino..."
	await get_tree().create_timer(1.0).timeout
	_roll_consagracion()

func _roll_consagracion() -> void:
	var die := Dice.roll(20)
	consagracion_label.text = "CONSAGRACIÓN\n\n[ d20 ]   =   %d\n\nEl destino queda echado." % die
	await get_tree().create_timer(1.5).timeout
	GameState.set_game_mode("cabeza")
	_on_new()

func _on_new() -> void:
	GameState.new_game()
	AudioManager.play_music("res://assets/audio/ambient.ogg", -10.0)
	get_tree().change_scene_to_file(NIVEL_INICIO)

func _on_continue() -> void:
	if not GameState.load_game():
		AudioManager.play_music("res://assets/audio/ambient.ogg", -10.0)
		get_tree().change_scene_to_file(NIVEL_INICIO)

func _on_opciones() -> void:
	var settings := preload("res://scenes/ui/settings_menu.tscn").instantiate()
	get_tree().root.add_child(settings)
	settings.open()
	await settings.tree_exited

func _on_quit() -> void:
	get_tree().quit()
