extends CanvasLayer
## Menú del sargento (autoload "NpcMenu"). Te reportás (guardar), comprás
## provisiones y hablás. Cualquier NPC lo abre con NpcMenu.open("Nombre").
## Pausa el juego mientras está abierto; se cierra con Esc o "Irte".

@onready var title: Label = $Panel/Title
@onready var list: VBoxContainer = $Panel/List
@onready var info: Label = $Panel/Info

var _npc_name: String = "Sargento"

func _ready() -> void:
	visible = false

func open(npc_name: String = "Sargento") -> void:
	_npc_name = npc_name
	visible = true
	get_tree().paused = true
	_show_main()

func close() -> void:
	visible = false
	get_tree().paused = false

func _show_main() -> void:
	title.text = _npc_name
	_set_options([
		["Reportarte (guardar)", _do_save],
		["Volver al último reporte (cargar)", _do_load],
		["Comprar provisiones", _show_shop],
		["Descansar", _do_rest],
		["Hablar", _do_talk],
		["Irte", Callable(self, "close")],
	])
	_info("«Reportate cuando quieras, soldado.»")

func _show_shop() -> void:
	title.text = "Provisiones"
	var opts: Array = []
	for item in GameState.shop_items:
		opts.append(["%s  —  %d cig." % [item.display_name, item.price], _buy.bind(item)])
	opts.append(["Volver", _show_main])
	_set_options(opts)
	_info("¿Qué llevás?")

func _set_options(opts: Array) -> void:
	for c in list.get_children():
		c.queue_free()
	for o in opts:
		var b := Button.new()
		b.text = o[0]
		b.pressed.connect(o[1])
		list.add_child(b)

func _info(msg: String) -> void:
	info.text = "%s\n\nCigarrillos: %d" % [msg, GameState.money]

func _do_save() -> void:
	GameState.save_game()
	_info("Te reportás. Partida guardada.")

func _do_load() -> void:
	if GameState.has_save():
		close()
		GameState.load_game()
	else:
		_info("No hay ningún reporte previo.")

func _buy(item: ItemData) -> void:
	if GameState.buy_item(item):
		_info("Comprás: %s." % item.display_name)
	else:
		_info("No te alcanzan los cigarrillos.")

func _do_rest() -> void:
	GameState.player_hp += 30
	GameState.cold = 0
	GameState.hunger = maxi(0, GameState.hunger - 12)
	GameState.advance_danger(1)   # mientras dormís, el peligro avanza
	GameState.body_changed.emit()
	_info("Te tirás a dormir un rato. Recomponés el cuerpo... pero el hambre aprieta\ny algo, afuera, se acerca.")

func _do_talk() -> void:
	_info("«Aguantá, pibe. El frío y el miedo matan más que el inglés.»")

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()
