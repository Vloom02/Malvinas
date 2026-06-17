extends CanvasLayer
## Menú de opciones (pausa). Zoom de cámara, resolución, volumen.
## Se abre desde el menú de pausa o con una tecla dedicada.

@onready var zoom_slider: HSlider = $Panel/VBox/ZoomRow/ZoomSlider
@onready var zoom_label: Label = $Panel/VBox/ZoomRow/ZoomLabel
@onready var res_option: OptionButton = $Panel/VBox/ResRow/ResOption
@onready var master_slider: HSlider = $Panel/VBox/MasterRow/MasterSlider
@onready var music_slider: HSlider = $Panel/VBox/MusicRow/MusicSlider
@onready var fullscreen_check: CheckBox = $Panel/VBox/FullscreenRow/FullscreenCheck
@onready var close_btn: Button = $Panel/VBox/CloseBtn

## Resoluciones disponibles: [ancho, alto, etiqueta].
const RESOLUTIONS := [
	[480, 270, "480x270"],
	[640, 360, "640x360 (original)"],
	[960, 540, "960x540"],
	[1280, 720, "1280x720"],
	[1600, 900, "1600x900"],
	[1920, 1080, "1920x1080"],
]

func _ready() -> void:
	visible = false
	_setup_zoom()
	_setup_resolutions()
	_setup_audio()
	close_btn.pressed.connect(_close)
	_load_settings()

func _setup_zoom() -> void:
	zoom_slider.min_value = 0.5
	zoom_slider.max_value = 3.0
	zoom_slider.step = 0.1
	zoom_slider.value = 1.0
	zoom_slider.value_changed.connect(_on_zoom_changed)

func _setup_resolutions() -> void:
	res_option.clear()
	for r in RESOLUTIONS:
		res_option.add_item(r[2])
	res_option.item_selected.connect(_on_res_changed)

func _setup_audio() -> void:
	master_slider.min_value = -40.0
	master_slider.max_value = 0.0
	master_slider.step = 1.0
	master_slider.value = 0.0
	master_slider.value_changed.connect(_on_master_changed)

	music_slider.min_value = -40.0
	music_slider.max_value = 0.0
	music_slider.step = 1.0
	music_slider.value = -6.0
	music_slider.value_changed.connect(_on_music_changed)

	fullscreen_check.toggled.connect(_on_fullscreen_toggled)

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		_close()
		get_viewport().set_input_as_handled()

func open() -> void:
	visible = true
	get_tree().paused = true
	_load_settings()
	res_option.call_deferred("grab_focus")

func _close() -> void:
	visible = false
	if is_inside_tree():
		get_tree().paused = false
	_save_settings()
	queue_free()

func _on_zoom_changed(value: float) -> void:
	zoom_label.text = "x%.1f" % value
	GameState.camera_zoom = value
	# Aplicar zoom al Camera2D del jugador si existe.
	var cam := get_viewport().get_camera_2d()
	if cam != null:
		cam.zoom = Vector2(value, value)

func _on_res_changed(index: int) -> void:
	# Si elegís una resolución estando en pantalla completa, salimos a ventana.
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		fullscreen_check.button_pressed = false
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	_apply_resolution(index)

## Aplica el tamaño/centrado de la ventana. No hace nada en pantalla completa.
func _apply_resolution(index: int) -> void:
	if index < 0 or index >= RESOLUTIONS.size():
		return
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		return
	var r: Array = RESOLUTIONS[index]
	var window_size := Vector2i(r[0], r[1])
	DisplayServer.window_set_size(window_size)
	# Centrar ventana (división entera intencional: posición en píxeles).
	var screen_size := DisplayServer.screen_get_size()
	@warning_ignore("integer_division")
	var pos := Vector2i(screen_size.x - window_size.x, screen_size.y - window_size.y) / 2
	DisplayServer.window_set_position(pos)

func _on_master_changed(value: float) -> void:
	AudioManager.set_master_volume(value)

func _on_music_changed(value: float) -> void:
	AudioManager.set_music_volume(value)

func _on_fullscreen_toggled(pressed: bool) -> void:
	if pressed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		# Al volver a ventana, re-aplicar la resolución elegida para no quedar
		# con un tamaño raro.
		_apply_resolution(res_option.selected)

func _save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("settings", "zoom", zoom_slider.value)
	config.set_value("settings", "resolution_index", res_option.selected)
	config.set_value("settings", "master_volume", master_slider.value)
	config.set_value("settings", "music_volume", music_slider.value)
	config.set_value("settings", "fullscreen", fullscreen_check.button_pressed)
	config.save("user://settings.cfg")

func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load("user://settings.cfg") != OK:
		return
	zoom_slider.value = config.get_value("settings", "zoom", 1.0)
	var res_idx: int = config.get_value("settings", "resolution_index", 1)
	if res_idx >= 0 and res_idx < RESOLUTIONS.size():
		res_option.selected = res_idx
	master_slider.value = config.get_value("settings", "master_volume", 0.0)
	music_slider.value = config.get_value("settings", "music_volume", -6.0)
	_on_zoom_changed(zoom_slider.value)
	_on_master_changed(master_slider.value)
	_on_music_changed(music_slider.value)
	# Aplicar el modo de ventana al final y de forma explícita: setear
	# button_pressed por código NO emite la señal `toggled`, así que el modo
	# hay que aplicarlo a mano para que no quede desincronizado.
	var want_fullscreen: bool = config.get_value("settings", "fullscreen", true)
	fullscreen_check.button_pressed = want_fullscreen
	if want_fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		_apply_resolution(res_option.selected)
