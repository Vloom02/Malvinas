extends Control
## Menú de título. "Continuar" solo se habilita si hay una partida guardada.

const NIVEL_INICIO := "res://scenes/maps/nivel1_trinchera.tscn"

@onready var continue_btn: Button = $Center/VBox/Continuar

func _ready() -> void:
	continue_btn.disabled = not GameState.has_save()
	$Center/VBox/Nueva.pressed.connect(_on_new)
	continue_btn.pressed.connect(_on_continue)
	$Center/VBox/Salir.pressed.connect(_on_quit)
	$Center/VBox/Nueva.grab_focus()

func _on_new() -> void:
	GameState.new_game()
	AudioManager.play_music("res://assets/audio/ambient.ogg", -10.0)
	get_tree().change_scene_to_file(NIVEL_INICIO)

func _on_continue() -> void:
	if not GameState.load_game():
		AudioManager.play_music("res://assets/audio/ambient.ogg", -10.0)
		get_tree().change_scene_to_file(NIVEL_INICIO)

func _on_quit() -> void:
	get_tree().quit()
