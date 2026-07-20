extends Control
## Menú de título. Consagración: tirada de dado al iniciar (solo ambientación;
## ya no define dificultad — siempre se juega en modo normal).

const NIVEL_INICIO := "res://scenes/maps/sandbox.tscn"

@onready var continue_btn: Button = $Center/VBox/Continuar
@onready var vbox: VBoxContainer = $Center/VBox
@onready var consagracion_label: Label = $Center/VBox/ConsagracionLabel
## Cursores de selección: el FAL con la mano gore flanquea al botón enfocado
## desde los dos lados, con los caños apuntándolo.
@onready var cursor: TextureRect = $Cursor
@onready var cursor_der: TextureRect = $CursorDer
## Foco: esquineras de retícula (como una mira enmarcando el blanco) que laten.
var _foco: Control

var _menu_buttons: Array[Button] = []

func _ready() -> void:
	# Al volver al menú: despausar, ocultar el menú de pausa (es autoload y
	# persiste entre escenas) y cortar la música del juego.
	get_tree().paused = false
	PauseMenu.visible = false
	AudioManager.stop_music()
	# Diálogos/eventos que quedaron colgados de la partida mueren acá:
	# el menú arranca limpio.
	Dialogue.clear()
	_apply_saved_fullscreen()

	continue_btn.disabled = not GameState.has_save()
	$Center/VBox/Nueva.pressed.connect(_on_new)
	continue_btn.pressed.connect(_on_continue)
	$Center/VBox/Opciones.pressed.connect(_on_opciones)
	$Center/VBox/Logros.pressed.connect(_on_logros)
	$Center/VBox/Salir.pressed.connect(_on_quit)
	consagracion_label.visible = false

	_menu_buttons = [$Center/VBox/Nueva, continue_btn, $Center/VBox/Opciones, $Center/VBox/Logros, $Center/VBox/Salir]
	for b in _menu_buttons:
		b.focus_entered.connect(_on_button_focus.bind(b))

	_foco = Control.new()
	_foco.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_foco.draw.connect(_draw_foco)
	add_child(_foco)

	# Esperar a que el VBoxContainer termine de calcular posiciones antes de
	# enfocar el primer botón, para que el cursor aparezca ya alineado.
	await get_tree().process_frame
	$Center/VBox/Nueva.grab_focus()

## Marca qué botón tiene el foco: lo deja en brillo normal, atenúa el resto,
## y mueve el cursor a su lado — el "indicio de dónde está la persona".
func _on_button_focus(b: Button) -> void:
	var cy := b.size.y * 0.5 - cursor.size.y * 0.5
	cursor.global_position = b.global_position + Vector2(-cursor.size.x - 6.0, cy)
	cursor_der.global_position = b.global_position + Vector2(b.size.x + 6.0, cy)
	_foco.global_position = b.global_position - Vector2(6, 4)
	_foco.size = b.size + Vector2(12, 8)
	_foco.queue_redraw()
	for other in _menu_buttons:
		other.modulate = Color(1, 1, 1) if other == b else Color(0.55, 0.55, 0.55)

## Latido de las esquineras (respiración suave de opacidad).
func _process(_delta: float) -> void:
	if _foco != null:
		_foco.modulate.a = 0.7 + 0.3 * sin(Time.get_ticks_msec() / 1000.0 * 3.5)

## Cuatro esquineras estilo retícula de mira: nada de rectángulo completo.
func _draw_foco() -> void:
	var w := _foco.size.x
	var h := _foco.size.y
	var l := 9.0    # largo de cada brazo
	var t := 2.0    # grosor
	var col := Color(0.80, 0.18, 0.10)
	# Superior izquierda / derecha
	_foco.draw_line(Vector2(0, 1), Vector2(l, 1), col, t)
	_foco.draw_line(Vector2(1, 0), Vector2(1, l), col, t)
	_foco.draw_line(Vector2(w - l, 1), Vector2(w, 1), col, t)
	_foco.draw_line(Vector2(w - 1, 0), Vector2(w - 1, l), col, t)
	# Inferior izquierda / derecha
	_foco.draw_line(Vector2(0, h - 1), Vector2(l, h - 1), col, t)
	_foco.draw_line(Vector2(1, h - l), Vector2(1, h), col, t)
	_foco.draw_line(Vector2(w - l, h - 1), Vector2(w, h - 1), col, t)
	_foco.draw_line(Vector2(w - 1, h - l), Vector2(w - 1, h), col, t)

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

# La "Consagración" con dado quedó afuera por ahora (quizás vuelva como modo).
func _on_new() -> void:
	GameState.set_game_mode("cabeza")
	GameState.new_game()
	AudioManager.play_music("res://assets/audio/ambient.ogg", -10.0)
	# Entrar por Transition: el mapa aparece con el melt inverso estilo Doom.
	Transition.change(NIVEL_INICIO, "")

func _on_continue() -> void:
	if not GameState.load_game():
		AudioManager.play_music("res://assets/audio/ambient.ogg", -10.0)
		Transition.change(NIVEL_INICIO, "")

func _on_opciones() -> void:
	var settings := preload("res://scenes/ui/settings_menu.tscn").instantiate()
	get_tree().root.add_child(settings)
	settings.open()
	await settings.tree_exited

## Logros todavía no existen como sistema — placeholder honesto en vez de un
## botón muerto que no hace nada al apretarlo.
func _on_logros() -> void:
	for c in vbox.get_children():
		if c != consagracion_label:
			c.visible = false
	consagracion_label.visible = true
	consagracion_label.text = "LOGROS\n\nPróximamente."
	await get_tree().create_timer(1.2).timeout
	consagracion_label.visible = false
	for c in vbox.get_children():
		if c != consagracion_label:
			c.visible = true

func _on_quit() -> void:
	get_tree().quit()
