extends CanvasLayer
## Ventana de diálogos (caja de texto abajo, estilo Fear & Hunger).
##   Dialogue.say("...")            → mensaje simple (avanzás con E).
##   Dialogue.ask("...", [op1,op2]) → muestra opciones; await Dialogue.chosen da el índice.
##   Dialogue.play_data(res)        → reproduce un DataDialogue con opciones y ramas.
## Pausa el mundo mientras está abierta. Es autoload global.

signal finished
signal chosen(index: int)

@onready var text_label: Label = $Panel/Text
@onready var options_box: VBoxContainer = $Panel/Options

var _queue: Array[String] = []
var _active: bool = false
var _choosing: bool = false

func _ready() -> void:
	visible = false

## Muestra un mensaje (o lo encola).
func say(text: String) -> void:
	_queue.append(text)
	if not _active and not _choosing:
		_advance()

## Muestra texto + botones de opción. El índice elegido sale por la señal `chosen`.
func ask(text: String, options: Array) -> void:
	_active = false
	_choosing = true
	visible = true
	get_tree().paused = true
	text_label.text = text
	for c in options_box.get_children():
		c.queue_free()
	for i in options.size():
		var b := Button.new()
		b.text = str(options[i])
		b.pressed.connect(_on_choice.bind(i))
		options_box.add_child(b)

## Reproduce un DataDialogue: muestra el texto y, si tiene opciones,
## permite elegir. Las opciones pueden encadenar a otros DataDialogue.
func play_data(data: DataDialogue) -> void:
	if data == null:
		return
	_queue.clear()
	_active = false
	_choosing = true
	visible = true
	get_tree().paused = true
	text_label.text = data.text
	for c in options_box.get_children():
		c.queue_free()
	if data.options.is_empty():
		var b := Button.new()
		b.text = "Continuar"
		b.pressed.connect(_finish_data)
		options_box.add_child(b)
		return
	for opt in data.options:
		var b := Button.new()
		b.text = str(opt.get("text", ""))
		var next_path := str(opt.get("next_path", ""))
		var set_flag := str(opt.get("set_flag", ""))
		var journal := str(opt.get("journal_entry", ""))
		var sanity := int(opt.get("sanity_cost", 0))
		b.pressed.connect(_on_data_choice.bind(next_path, set_flag, journal, sanity))
		options_box.add_child(b)

func _finish_data() -> void:
	_choosing = false
	for c in options_box.get_children():
		c.queue_free()
	visible = false
	get_tree().paused = false
	finished.emit()

func _on_data_choice(next_path: String, set_flag: String, journal: String, sanity: int) -> void:
	_choosing = false
	for c in options_box.get_children():
		c.queue_free()
	visible = false
	get_tree().paused = false
	if set_flag != "":
		GameState.set_flag(set_flag)
	if journal != "":
		GameState.add_journal(journal)
	if sanity > 0:
		GameState.drain_sanity(sanity)
	chosen.emit(0)
	if next_path != "":
		var next := load(next_path) as DataDialogue
		if next != null:
			play_data(next)
			return
	finished.emit()

func _on_choice(index: int) -> void:
	_choosing = false
	for c in options_box.get_children():
		c.queue_free()
	visible = false
	get_tree().paused = false
	chosen.emit(index)

func _advance() -> void:
	if _queue.is_empty():
		_close()
		return
	_active = true
	visible = true
	get_tree().paused = true
	text_label.text = _queue.pop_front()

func _close() -> void:
	_active = false
	visible = false
	get_tree().paused = false
	finished.emit()

func _unhandled_input(event: InputEvent) -> void:
	if _active and not _choosing and (event.is_action_pressed("interact") or event.is_action_pressed("ui_accept")):
		get_viewport().set_input_as_handled()
		_advance()
