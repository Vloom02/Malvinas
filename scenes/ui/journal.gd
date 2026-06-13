extends CanvasLayer
## Diario (autoload "Journal"). Se abre/cierra con J. Muestra las entradas de
## lore que fuiste juntando. Pausa el juego mientras está abierto.

@onready var list: VBoxContainer = $Panel/Scroll/List

func _ready() -> void:
	visible = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("journal"):
		_toggle()
		get_viewport().set_input_as_handled()
	elif visible and event.is_action_pressed("ui_cancel"):
		_close()
		get_viewport().set_input_as_handled()

func _toggle() -> void:
	if visible:
		_close()
	else:
		_open()

func _open() -> void:
	visible = true
	get_tree().paused = true
	_refresh()

func _close() -> void:
	visible = false
	get_tree().paused = false

func _refresh() -> void:
	for c in list.get_children():
		c.queue_free()
	if GameState.journal.is_empty():
		var l := Label.new()
		l.text = "(El diario está vacío. Vas juntando recuerdos por el camino.)"
		l.autowrap_mode = TextServer.AUTOWRAP_WORD
		list.add_child(l)
		return
	for entry in GameState.journal:
		var l := Label.new()
		l.text = "• " + str(entry)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD
		l.custom_minimum_size = Vector2(360, 0)
		list.add_child(l)
