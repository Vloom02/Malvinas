extends Node
## Singleton (autoload) con el estado global de la partida.
## Vive entre escenas. SIN HUD: estos valores se reflejan en pantalla/cuerpo
## de forma diegética (ver scenes/ui/darkness.gd), no en barras.

# --- Señales (las usan los efectos diegéticos y el combate) ---
signal hunger_changed(value: int)
signal sanity_changed(value: int)
signal player_hp_changed(value: int)
signal body_changed          # sangrado/frío/infección cambió
signal inventory_changed     # se agregó/usó un item
signal money_changed         # cambió la plata (cigarrillos)
signal player_died
signal sanity_depleted

# --- Topes ---
const HUNGER_MAX := 100
const SANITY_MAX := 100
const PLAYER_HP_MAX := 100

# --- Stats del jugador ---
var player_attack: int = 18

# --- Estado de combate (a qué enemigo pelear y a dónde volver) ---
var pending_enemy_path: String = ""
var return_scene_path: String = "res://scenes/maps/nivel1_trinchera.tscn"
var _madness_triggered: bool = false

# --- Navegación entre salas ---
## Nombre del punto de aparición (Marker2D) donde dejar al jugador al entrar
## a la próxima sala. "" = usar la posición por defecto de la escena.
var next_spawn: String = ""

# --- Cuerpo: heridas persistentes (pilar de diseño) ---
var bleeding: int = 0   # cantidad de heridas sangrando; drena vida con el tiempo
var cold: int = 0       # hipotermia (0-100), la sube el ambiente helado
var infection: int = 0  # infección (0-100) de heridas sin tratar

const BLEED_INTERVAL := 1.5   # cada cuántos segundos drena el sangrado
var _bleed_timer: float = 0.0

# --- Inventario ---
const ITEM_VENDA := preload("res://data/items/venda.tres")
const ITEM_RACION := preload("res://data/items/racion.tres")
var inventory: Dictionary = {}   # ItemData -> cantidad

# --- Dinero / tienda / guardado ---
const SAVE_PATH := "user://save.json"
## Moneda de trueque: cigarrillos (lo que se usaba entre soldados).
var money: int = 0
## Items que vende el sargento.
var shop_items: Array[ItemData] = [ITEM_VENDA, ITEM_RACION]
## id -> ItemData (para reconstruir el inventario al cargar).
var items_by_id: Dictionary = {}

# --- Recursos con setter (avisan por señal y respetan límites) ---
var hunger: int = HUNGER_MAX:
	set(value):
		hunger = clampi(value, 0, HUNGER_MAX)
		hunger_changed.emit(hunger)
		if hunger <= 0:
			player_died.emit()

var sanity: int = SANITY_MAX:
	set(value):
		sanity = clampi(value, 0, SANITY_MAX)
		sanity_changed.emit(sanity)
		if sanity <= 0 and not _madness_triggered:
			_madness_triggered = true
			sanity_depleted.emit()
			_trigger_madness()
		elif sanity > 0:
			_madness_triggered = false

var player_hp: int = PLAYER_HP_MAX:
	set(value):
		player_hp = clampi(value, 0, PLAYER_HP_MAX)
		player_hp_changed.emit(player_hp)
		if player_hp <= 0:
			player_died.emit()

func _ready() -> void:
	items_by_id = {"venda": ITEM_VENDA, "racion": ITEM_RACION}
	_give_starting_items()

# --- Tick del cuerpo: el sangrado drena vida con el tiempo ---
func _process(delta: float) -> void:
	if bleeding > 0 and player_hp > 0:
		_bleed_timer += delta
		while _bleed_timer >= BLEED_INTERVAL:
			_bleed_timer -= BLEED_INTERVAL
			player_hp -= bleeding   # cada herida sangrante = 1 de daño por tick

# --- Acciones ---

## Hambre/frío que baja al caminar.
func spend_step() -> void:
	hunger -= 1

## Baja la cordura (altar, sustos, oscuridad...).
func drain_sanity(amount: int) -> void:
	sanity -= amount

## Daño directo al jugador (combate).
func damage_player(amount: int) -> void:
	player_hp -= amount

## Agrega heridas sangrantes (lo usan los peligros tipo enredadera).
func apply_bleeding(stacks: int) -> void:
	bleeding = clampi(bleeding + stacks, 0, 10)
	body_changed.emit()

## Venda: corta TODO el sangrado (item de curación).
func bandage() -> void:
	bleeding = 0
	body_changed.emit()
	print("[Cuerpo] Te vendás. El sangrado se detiene.")

# --- Inventario ---

## Agrega `qty` unidades de un item al inventario.
func add_item(item: ItemData, qty: int = 1) -> void:
	if item == null:
		return
	inventory[item] = int(inventory.get(item, 0)) + qty
	inventory_changed.emit()
	print("[Inventario] +%d %s" % [qty, item.display_name])

## Usa un item: aplica su efecto y descuenta uno si se consumió.
## Devuelve true si se usó, false si no tenía sentido (no se gasta).
func use_item(item: ItemData) -> bool:
	if int(inventory.get(item, 0)) <= 0:
		return false
	var consumed := _apply_item_effect(item)
	if consumed:
		inventory[item] -= 1
		if inventory[item] <= 0:
			inventory.erase(item)
		inventory_changed.emit()
	return consumed

func _apply_item_effect(item: ItemData) -> bool:
	match item.effect:
		"bandage":
			if bleeding <= 0:
				return false  # no gastar venda si no estás sangrando
			bandage()
			return true
		"ration":
			hunger += item.amount
			print("[Inventario] Comés. Hambre: %d/%d" % [hunger, HUNGER_MAX])
			return true
		_:
			return false

## Items y plata con los que arrancás la partida.
func _give_starting_items() -> void:
	add_item(ITEM_VENDA, 1)
	add_item(ITEM_RACION, 1)
	money = 10
	money_changed.emit()

# --- Tienda ---

## Compra un item si te alcanza la plata. Devuelve true si se compró.
func buy_item(item: ItemData) -> bool:
	if item == null or item.price <= 0 or money < item.price:
		return false
	money -= item.price
	money_changed.emit()
	add_item(item, 1)
	return true

# --- Guardar / cargar (te reportás al sargento para guardar) ---

func save_game() -> void:
	var inv := {}
	for item in inventory.keys():
		inv[item.id] = inventory[item]
	var data := {
		"scene": get_tree().current_scene.scene_file_path,
		"hp": player_hp, "hunger": hunger, "sanity": sanity,
		"bleeding": bleeding, "cold": cold, "infection": infection,
		"money": money, "inventory": inv,
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	f.store_string(JSON.stringify(data))
	f.close()

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func load_game() -> bool:
	if not has_save():
		return false
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var data = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(data) != TYPE_DICTIONARY:
		return false
	_madness_triggered = false
	bleeding = int(data.get("bleeding", 0))
	cold = int(data.get("cold", 0))
	infection = int(data.get("infection", 0))
	hunger = int(data.get("hunger", HUNGER_MAX))
	sanity = int(data.get("sanity", SANITY_MAX))
	player_hp = int(data.get("hp", PLAYER_HP_MAX))
	money = int(data.get("money", 0))
	money_changed.emit()
	inventory.clear()
	var inv = data.get("inventory", {})
	for id in inv.keys():
		if items_by_id.has(id):
			inventory[items_by_id[id]] = int(inv[id])
	inventory_changed.emit()
	next_spawn = ""
	_change_scene(str(data.get("scene", "res://scenes/maps/test_room.tscn")))
	return true

## Reinicia todo para una partida nueva.
func new_game() -> void:
	_madness_triggered = false
	bleeding = 0
	cold = 0
	infection = 0
	hunger = HUNGER_MAX
	sanity = SANITY_MAX
	player_hp = PLAYER_HP_MAX
	inventory.clear()
	_give_starting_items()

# --- Puente de combate (combate es otra escena) ---

func start_combat(enemy_path: String, from_scene: String) -> void:
	pending_enemy_path = enemy_path
	return_scene_path = from_scene
	_change_scene("res://scenes/combat/combat.tscn")

func end_combat() -> void:
	_change_scene(return_scene_path)

func game_over() -> void:
	new_game()
	_change_scene("res://scenes/maps/nivel1_trinchera.tscn")

func _trigger_madness() -> void:
	pending_enemy_path = "res://data/enemies/madness.tres"
	# Volvés a la sala donde estabas cuando se te quebró la cordura.
	var cur := get_tree().current_scene
	if cur != null:
		return_scene_path = cur.scene_file_path
	_change_scene("res://scenes/combat/combat.tscn")

func recover_from_madness() -> void:
	sanity = int(SANITY_MAX / 2.0)

func _change_scene(path: String) -> void:
	get_tree().call_deferred("change_scene_to_file", path)
