extends CanvasLayer
## Menú de inventario. Se abre/cierra con la tecla I (acción "inventory").
## Pausa el juego mientras está abierto (como F&H). No es un HUD: es un menú
## que abrís a propósito. Usás items haciendo clic.

@onready var panel: Panel = $Panel
@onready var list: VBoxContainer = $Panel/List

func _ready() -> void:
	visible = false
	GameState.inventory_changed.connect(_refresh)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory"):
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

func _refresh(_a = null) -> void:
	for c in list.get_children():
		c.queue_free()

	if GameState.inventory.is_empty():
		var empty := Label.new()
		empty.text = "(vacío)"
		list.add_child(empty)
		return

	for item in GameState.inventory.keys():
		var count: int = GameState.inventory[item]
		var b := Button.new()
		b.text = "%s  x%d   —   %s" % [item.display_name, count, item.description]
		b.pressed.connect(_use.bind(item))
		list.add_child(b)

func _use(item: ItemData) -> void:
	var ok := GameState.use_item(item)
	if not ok:
		print("[Inventario] No tiene sentido usar %s ahora." % item.display_name)
