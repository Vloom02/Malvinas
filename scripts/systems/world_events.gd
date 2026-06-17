extends Node
class_name WorldEvents
## Eventos aleatorios del mundo. Se disparan mientras el jugador camina
## por las salas. Crea tensión y sensación de que algo te acecha.
##
## Integrado con GameState._process(). Se instancia como autoload.

## Intervalo mínimo entre eventos (segundos).
var min_interval: float = 30.0
## Intervalo máximo entre eventos.
var max_interval: float = 90.0

var _timer: float = 0.0
var _next_event: float = 0.0
var _event_cooldown: bool = false

## Pool de eventos posibles.
var _events: Array[Dictionary] = []

func _ready() -> void:
	_next_event = randf_range(min_interval, max_interval)
	_build_event_pool()

func _build_event_pool() -> void:
	_events = [
		{"type": "whisper", "weight": 3, "sanity_cost": 0},
		{"type": "footsteps", "weight": 4, "sanity_cost": 0},
		{"type": "shadow_move", "weight": 2, "sanity_cost": 3},
		{"type": "cold_draft", "weight": 3, "cold": 10},
		{"type": "find_item", "weight": 1, "item_id": ""},
		{"type": "ambush", "weight": 1, "enemy_path": ""},
		{"type": "radio_static", "weight": 2, "sanity_cost": 2},
		{"type": "blood_trail", "weight": 2, "sanity_cost": 5},
	]

func process(delta: float) -> void:
	if _event_cooldown:
		return
	_timer += delta
	if _timer >= _next_event:
		_timer = 0.0
		_next_event = randf_range(min_interval, max_interval)
		_trigger_random_event()

func _trigger_random_event() -> void:
	var total_weight := 0
	for e in _events:
		total_weight += e["weight"]

	var roll := randi() % total_weight
	var cumulative := 0
	for e in _events:
		cumulative += e["weight"]
		if roll < cumulative:
			_execute_event(e)
			return

func _execute_event(event: Dictionary) -> void:
	_event_cooldown = true
	match event["type"]:
		"whisper":
			_do_whisper()
		"footsteps":
			_do_footsteps()
		"shadow_move":
			_do_shadow_move(event["sanity_cost"])
		"cold_draft":
			_do_cold_draft(event["cold"])
		"find_item":
			_do_find_item()
		"ambush":
			_do_ambush(event["enemy_path"])
		"radio_static":
			_do_radio_static(event["sanity_cost"])
		"blood_trail":
			_do_blood_trail(event["sanity_cost"])
	# Cooldown después del evento.
	await get_tree().create_timer(randf_range(5.0, 15.0)).timeout
	_event_cooldown = false

func _do_whisper() -> void:
	GameState.hallucination.emit("whisper")

func _do_footsteps() -> void:
	Dialogue.say("Escuchás pasos detrás tuyo... pero cuando te girás, no hay nadie.")

func _do_shadow_move(cost: int) -> void:
	GameState.hallucination.emit("shadow")
	if cost > 0:
		GameState.drain_sanity(cost)

func _do_cold_draft(amount: int) -> void:
	GameState.cold = clampi(GameState.cold + amount, 0, 100)
	GameState.body_changed.emit()
	Dialogue.say("Una ráfaga helada te cala los huesos. El frío se te mete adentro.")

func _do_find_item() -> void:
	# 85% chance de item básico, 10% arma, 5% libro.
	var roll := randf()
	if roll < 0.85:
		# Item básico.
		var items: Array[ItemData] = [
			GameState.ITEM_VENDA,
			GameState.ITEM_RACION,
			GameState.ITEM_FOSFOROS,
			GameState.ITEM_RAMA,
		]
		var item := items[randi() % items.size()]
		if GameState.add_item(item):
			Dialogue.say("Encontrás algo entre los escombros: %s." % item.display_name)
		else:
			Dialogue.say("Encontrás algo, pero no te cabe en el inventario.")
	elif roll < 0.95:
		# Arma (rara).
		var weapons := [
			preload("res://data/items/cuchillo_trinchera.tres"),
			preload("res://data/items/palo_filo.tres"),
		]
		var weapon: WeaponData = weapons[randi() % weapons.size()]
		var text := weapon.find_text if weapon.find_text != "" else "Encontrás un arma: %s." % weapon.display_name
		Dialogue.say(text)
		GameState.equip_weapon(weapon)
	else:
		# Libro (muy raro).
		var books := [
			preload("res://data/items/informe_medico.tres"),
			preload("res://data/items/manual_sigilo.tres"),
			preload("res://data/items/orden_del_dia.tres"),
		]
		var book: SkillBook = books[randi() % books.size()]
		if book.read_flag != "" and GameState.has_flag(book.read_flag):
			# Ya lo leyó, dar item básico en su lugar.
			var item := GameState.ITEM_VENDA
			GameState.add_item(item)
			Dialogue.say("Encontrás algo entre los escombros: %s." % item.display_name)
		else:
			GameState.apply_skill_book(book)
			Dialogue.say(book.read_text)

func _do_ambush(enemy_path: String) -> void:
	if enemy_path == "":
		enemy_path = "res://data/enemies/ghoul.tres"
	Dialogue.say("¡Algo salta de la oscuridad!")
	var from_scene := ""
	if get_tree().current_scene != null:
		from_scene = get_tree().current_scene.scene_file_path
	GameState.start_combat(enemy_path, from_scene)

func _do_radio_static(cost: int) -> void:
	GameState.hallucination.emit("screen")
	if cost > 0:
		GameState.drain_sanity(cost)
	Dialogue.say("La radio emite estática... voces que no deberían estar ahí.")

func _do_blood_trail(cost: int) -> void:
	GameState.hallucination.emit("shadow")
	if cost > 0:
		GameState.drain_sanity(cost)
	Dialogue.say("Ves una senda de sangre que se adentra en la oscuridad. No sabés si seguirla.")
