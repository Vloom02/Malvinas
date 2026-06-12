extends CanvasLayer
## Ventana de diálogos / mensajes (caja de texto abajo, estilo Fear & Hunger).
## Cualquier script muestra texto con  Dialogue.say("...")  — es autoload global.
## Pausa el mundo mientras se lee; avanzás/cerrás con E o Enter. Encola mensajes.

signal finished

@onready var text_label: Label = $Panel/Text

var _queue: Array[String] = []
var _active: bool = false

func _ready() -> void:
	visible = false

## Muestra un mensaje (o lo agrega a la cola si ya hay uno abierto).
func say(text: String) -> void:
	_queue.append(text)
	if not _active:
		_advance()

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
	if _active and (event.is_action_pressed("interact") or event.is_action_pressed("ui_accept")):
		get_viewport().set_input_as_handled()
		_advance()
