extends Control
## Menú de título. Consagración: tirada de dado al iniciar.
## Cabeza (11+) = normal, Cruz (10-) = duro.

const NIVEL_INICIO := "res://scenes/maps/nivel1_trinchera.tscn"

@onready var continue_btn: Button = $Center/VBox/Continuar
@onready var vbox: VBoxContainer = $Center/VBox
@onready var consagracion_label: Label = $Center/VBox/ConsagracionLabel

func _ready() -> void:
	continue_btn.disabled = not GameState.has_save()
	$Center/VBox/Nueva.pressed.connect(_on_new_prompt)
	continue_btn.pressed.connect(_on_continue)
	$Center/VBox/Salir.pressed.connect(_on_quit)
	$Center/VBox/Nueva.grab_focus()
	consagracion_label.visible = false

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
	var mode := "cabeza" if die >= 11 else "cruz"
	var label := "CABEZA" if die >= 11 else "CRUZ"
	var desc := "Juego normal." if die >= 11 else "Modo duro: menos recursos, enemigos más fuertes."
	consagracion_label.text = "CONSAGRACIÓN\n\n[d20]   =   %d\n\n%s\n%s" % [die, label, desc]
	await get_tree().create_timer(1.5).timeout
	GameState.set_game_mode(mode)
	_on_new()

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
