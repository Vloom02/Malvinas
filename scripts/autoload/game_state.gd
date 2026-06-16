extends Node
## Singleton (autoload) con el estado global de la partida.
## Vive entre escenas. SIN HUD: estos valores se reflejan en pantalla/cuerpo
## de forma diegética (ver scenes/ui/darkness.gd), no en barras.

# --- Señales (las usan los efectos diegéticos y el combate) ---
signal hunger_changed(value: int)
signal sanity_changed(value: int)
signal player_hp_changed(value: int)
signal body_changed          # sangrado/frío/infección cambió
signal body_part_broken(part: String)  # se te rompió un miembro
signal inventory_changed     # se agregó/usó un item
signal money_changed         # cambió la plata (cigarrillos)
signal player_died
signal sanity_depleted
signal hallucination(type: String)  # "whisper", "shadow", "screen"

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

# --- Estado persistente del mundo ---
## Flags arbitrarios que recuerdan cosas: enemigos muertos, items agarrados,
## palancas, decisiones de diálogo. Se guardan/cargan. Ej: flags["dead_x"] = true.
var flags: Dictionary = {}
## Id del enemigo que estás peleando (para marcarlo muerto si ganás).
var pending_kill_id: String = ""
## Evita disparar game over más de una vez.
var _dead: bool = false

## "Peligro": sube con el tiempo (descansar, pelear). Los enemigos pegan más.
var danger: int = 0

func advance_danger(n: int = 1) -> void:
	danger += n

## Diario: entradas de lore que vas juntando (se ven con J).
var journal: Array = []

func add_journal(entry: String) -> void:
	if entry != "" and not journal.has(entry):
		journal.append(entry)

func set_flag(id: String) -> void:
	flags[id] = true

func has_flag(id: String) -> bool:
	return flags.get(id, false)

# --- Cuerpo: heridas persistentes (pilar de diseño) ---
var bleeding: int = 0   # cantidad de heridas sangrando; drena vida con el tiempo
var cold: int = 0       # hipotermia (0-100), la sube el ambiente helado
var infection: int = 0  # infección (0-100) de heridas sin tratar

## Miembros del jugador: "ok" o "roto". Roto = consecuencia PERMANENTE (hasta
## que lo entablilles). Brazo roto = peor pulso; pierna rota = caminás lento.
var body_parts_state: Dictionary = {
	"brazo_izq": "ok", "brazo_der": "ok",
	"pierna_izq": "ok", "pierna_der": "ok",
}

const BLEED_INTERVAL := 1.5   # cada cuántos segundos drena el sangrado
var _bleed_timer: float = 0.0
var _body_timer: float = 0.0  # tick lento para frío/infección

# --- Inventario ---
const ITEM_VENDA := preload("res://data/items/venda.tres")
const ITEM_RACION := preload("res://data/items/racion.tres")
const ITEM_MORFINA := preload("res://data/items/morfina.tres")
const ITEM_ANTIBIOTICOS := preload("res://data/items/antibioticos.tres")
const ITEM_FOSFOROS := preload("res://data/items/fosforos.tres")
const ITEM_TABLILLA := preload("res://data/items/tablilla.tres")
const ITEM_RAMA := preload("res://data/items/rama.tres")
const ITEM_ALCOHOL := preload("res://data/items/alcohol.tres")
const ITEM_CARNE_PODRIDA := preload("res://data/items/carne_podrida.tres")
const ITEM_DIENTE := preload("res://data/items/diente.tres")
const ITEM_FOGATA_PORTATIL := preload("res://data/items/fogata_portatil.tres")
const ITEM_VENDA_ESTERILIZADA := preload("res://data/items/venda_esterilizada.tres")
const ITEM_LINTERNA := preload("res://data/items/linterna.tres")
const ITEM_PILAS := preload("res://data/items/pilas.tres")

# --- Luz ambiental por mapa ---
const AMBIENT_LIGHT_MAP: Dictionary = {
	"res://scenes/maps/test_room.tscn": 80,
	"res://scenes/maps/room2.tscn": 60,
	"res://scenes/maps/nivel1_trinchera.tscn": 80,
	"res://scenes/maps/nivel1_pozo.tscn": 30,
	"res://scenes/maps/nivel1_campo.tscn": 90,
	"res://scenes/maps/naval_barco.tscn": 20,
}
var inventory: Dictionary = {}   # ItemData -> cantidad

# --- Dinero / tienda / guardado ---
const SAVE_PATH := "user://save.json"
## Moneda de trueque: cigarrillos (lo que se usaba entre soldados).
var money: int = 0
## Items que vende el sargento.
var shop_items: Array[ItemData] = []
## id -> ItemData (para reconstruir el inventario al cargar).
var items_by_id: Dictionary = {}
## Guardado limitado: solo se puede guardar en refugios/trincheras.
var can_save: bool = false
## Modo de juego definido por la Consagración al inicio.
var game_mode: String = "cabeza"  # "cabeza" (normal) o "cruz" (duro)
## Luz ambiental del mapa actual (0-100).
var ambient_light: int = 80
var linterna_on: bool = false
var light_battery: float = 100.0
var _hallu_timer: float = 0.0

func effective_light() -> int:
	if linterna_on and light_battery > 0:
		return maxi(ambient_light, 40)
	return ambient_light

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
	items_by_id = {
		"venda": ITEM_VENDA, "racion": ITEM_RACION, "morfina": ITEM_MORFINA,
		"antibioticos": ITEM_ANTIBIOTICOS, "fosforos": ITEM_FOSFOROS, "tablilla": ITEM_TABLILLA,
		"rama": ITEM_RAMA, "alcohol": ITEM_ALCOHOL, "carne_podrida": ITEM_CARNE_PODRIDA,
		"diente": ITEM_DIENTE, "fogata_portatil": ITEM_FOGATA_PORTATIL,
		"venda_esterilizada": ITEM_VENDA_ESTERILIZADA,
		"linterna": ITEM_LINTERNA, "pilas": ITEM_PILAS,
	}
	shop_items = [ITEM_VENDA, ITEM_RACION, ITEM_MORFINA, ITEM_ANTIBIOTICOS, ITEM_FOSFOROS, ITEM_TABLILLA, ITEM_RAMA, ITEM_ALCOHOL, ITEM_LINTERNA, ITEM_PILAS]
	player_died.connect(_on_player_died_global)
	_give_starting_items()

## Muerte (hambre/sangrado/etc.). En el MUNDO dispara el game over; en COMBATE
## lo maneja la propia pantalla de combate (para mostrar "Has muerto").
func _on_player_died_global() -> void:
	if _dead:
		return
	var cur := get_tree().current_scene
	if cur != null and cur.scene_file_path.contains("combat"):
		return
	_dead = true
	game_over()

# --- Tick del cuerpo: sangrado (rápido) + frío/infección (lento) ---
func _process(delta: float) -> void:
	if get_tree().paused:
		return
	if bleeding > 0 and player_hp > 0:
		_bleed_timer += delta
		while _bleed_timer >= BLEED_INTERVAL:
			_bleed_timer -= BLEED_INTERVAL
			player_hp -= bleeding

	_body_timer += delta
	while _body_timer >= 1.0:
		_body_timer -= 1.0
		_tick_status()

	if sanity > 0 and sanity < SANITY_MAX:
		_hallu_timer += delta
		var interval := 3.0 + (float(sanity) / float(SANITY_MAX)) * 12.0
		if _hallu_timer >= interval:
			_hallu_timer = 0.0
			_trigger_hallucination()

	if linterna_on and light_battery > 0:
		light_battery = maxf(0.0, light_battery - delta * 2.0)
		if light_battery <= 0:
			linterna_on = false

## Cada segundo: el frío se va yendo (te calentás); la infección sube si tenés
## heridas abiertas y baja si no. Frío o infección al máximo = drenan vida.
func _tick_status() -> void:
	var changed := false
	if cold > 0:
		cold -= 1
		changed = true
	if bleeding > 0 and infection < 100:
		infection += 1
		changed = true
	elif bleeding == 0 and infection > 0:
		infection -= 1
		changed = true
	if cold >= 90 and player_hp > 0:
		player_hp -= 1
	if infection >= 90 and player_hp > 0:
		player_hp -= 1
	if hunger <= 0 and player_hp > 0:
		player_hp -= 1   # inanición: el hambre en 0 te mata de a poco
	if changed:
		body_changed.emit()

# --- Acciones ---

## Hambre/frío que baja al caminar.
func spend_step() -> void:
	hunger -= 1

## Baja la cordura (altar, sustos, oscuridad...).
func drain_sanity(amount: int) -> void:
	sanity -= amount

## Save de cordura: tirá un d20 + modificador contra una dificultad.
## Si fallás, perdés `sanity_loss` puntos de cordura.
## Usalo para eventos perturbadores (ver un muerto, entrar a una sala oscura, etc.).
func sanity_save(dc: int = 12, sanity_loss: int = 10, mod: int = 0) -> Dictionary:
	var r := Dice.check(mod, dc)
	if not r["success"]:
		drain_sanity(sanity_loss)
	return r

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

# --- Miembros / consecuencias permanentes ---

## Rompe un miembro (permanente). Devuelve true si recién se rompió.
func break_part(part: String) -> bool:
	if body_parts_state.get(part, "roto") == "ok":
		body_parts_state[part] = "roto"
		body_part_broken.emit(part)
		body_changed.emit()
		return true
	return false

## Entablilla (repara) un miembro roto. Devuelve true si reparó alguno.
func splint() -> bool:
	for part in body_parts_state.keys():
		if body_parts_state[part] == "roto":
			body_parts_state[part] = "ok"
			body_changed.emit()
			return true
	return false

func broken_arms() -> int:
	return int(body_parts_state["brazo_izq"] == "roto") + int(body_parts_state["brazo_der"] == "roto")

func broken_legs() -> int:
	return int(body_parts_state["pierna_izq"] == "roto") + int(body_parts_state["pierna_der"] == "roto")

# --- Inventario ---

## Cuántos items podés cargar en total (escasez estilo F&H).
const INVENTORY_MAX := 12

func inventory_total() -> int:
	var t := 0
	for c in inventory.values():
		t += c
	return t

## Agrega items. Devuelve false si no entran (inventario lleno).
func add_item(item: ItemData, qty: int = 1) -> bool:
	if item == null:
		return false
	if inventory_total() + qty > INVENTORY_MAX:
		return false
	inventory[item] = int(inventory.get(item, 0)) + qty
	inventory_changed.emit()
	print("[Inventario] +%d %s" % [qty, item.display_name])
	return true

## Usa un item: aplica su efecto y descuenta uno si se consumió.
## Devuelve true si se usó, false si no tenía sentido (no se gasta).
func use_item(item: ItemData) -> bool:
	if int(inventory.get(item, 0)) <= 0:
		return false
	var result := _apply_item_effect(item)
	match result:
		"consumed":
			inventory[item] -= 1
			if inventory[item] <= 0:
				inventory.erase(item)
			inventory_changed.emit()
			return true
		"used":
			return true
		_:
			return false

func _apply_item_effect(item: ItemData) -> String:
	match item.effect:
		"bandage":
			if bleeding <= 0:
				return ""
			bandage()
			return "consumed"
		"ration":
			hunger += item.amount
			print("[Inventario] Comés. Hambre: %d/%d" % [hunger, HUNGER_MAX])
			if item.id == "carne_podrida" and Dice.chance(0.45):
				infection = clampi(infection + 15, 0, 100)
				body_changed.emit()
				print("[Inventario] La carne podrida te hizo mal. Infección sube.")
			return "consumed"
		"morphine":
			player_hp += item.amount
			return "consumed"
		"antibiotic":
			if infection <= 0:
				return ""
			infection = 0
			body_changed.emit()
			return "consumed"
		"warm":
			if cold <= 0:
				return ""
			cold = maxi(0, cold - item.amount)
			body_changed.emit()
			return "consumed"
		"splint":
			return "consumed" if splint() else ""
		"bandage_sterile":
			if bleeding <= 0 and infection <= 0:
				return ""
			bandage()
			infection = 0
			body_changed.emit()
			return "consumed"
		"light":
			if light_battery <= 0:
				return ""
			linterna_on = not linterna_on
			return "used"
		"battery":
			if light_battery >= 100:
				return ""
			light_battery = mini(100, light_battery + item.amount)
			return "consumed"
		_:
			return ""

## Items y plata con los que arrancás la partida.
func _give_starting_items() -> void:
	add_item(ITEM_VENDA, 1)
	add_item(ITEM_RACION, 1)
	add_item(ITEM_RAMA, 2)
	if game_mode == "cabeza":
		money = 10
		add_item(ITEM_LINTERNA, 1)
	else:
		money = 4
	money_changed.emit()

# --- Loot al derrotar enemigos ---

## Procesa un array de IDs de items (loot_table del enemigo) y los mete
## en el inventario si hay lugar. Devuelve una lista de nombres para mostrar.
func process_loot(loot_table: Array) -> Array:
	var gained: Array = []
	for id in loot_table:
		var item: ItemData = items_by_id.get(str(id))
		if item == null:
			continue
		if add_item(item, 1):
			gained.append(item.display_name)
	return gained

# --- Crafteo ---

const RECIPE_FOGATA := preload("res://data/recipes/fogota_recipe.tres")
const RECIPE_VENDA_ESTERILIZADA := preload("res://data/recipes/venda_esterilizada_recipe.tres")
var recipes: Array = [RECIPE_FOGATA, RECIPE_VENDA_ESTERILIZADA]

## Devuelve las recetas que se pueden hacer con el inventario actual.
func get_available_recipes() -> Array:
	var available: Array = []
	for recipe in recipes:
		if _has_ingredients(recipe):
			available.append(recipe)
	return available

func _has_ingredients(recipe: CraftRecipe) -> bool:
	for ing_id in recipe.ingredients.keys():
		var item: ItemData = items_by_id.get(str(ing_id))
		if item == null:
			return false
		var needed: int = recipe.ingredients[ing_id]
		if int(inventory.get(item, 0)) < needed:
			return false
	return true

## Ejecuta una receta. Consume los ingredientes y da el resultado.
## Devuelve true si se pudo craftear.
func craft(recipe: CraftRecipe) -> bool:
	if not _has_ingredients(recipe):
		return false
	for ing_id in recipe.ingredients.keys():
		var item: ItemData = items_by_id.get(str(ing_id))
		if item == null:
			return false
		var needed: int = recipe.ingredients[ing_id]
		inventory[item] -= needed
		if inventory[item] <= 0:
			inventory.erase(item)
	var result: ItemData = items_by_id.get(recipe.result_id)
	if result != null:
		inventory[result] = int(inventory.get(result, 0)) + recipe.result_qty
	inventory_changed.emit()
	return true

# --- Tienda ---

## Compra un item si te alcanza la plata y tenés lugar. Devuelve true si se compró.
func buy_item(item: ItemData) -> bool:
	if item == null or item.price <= 0 or money < item.price:
		return false
	if inventory_total() + 1 > INVENTORY_MAX:
		return false  # inventario lleno
	money -= item.price
	money_changed.emit()
	add_item(item, 1)
	return true

# --- Guardar / cargar (te reportás al sargento para guardar) ---

func set_game_mode(mode: String) -> void:
	game_mode = mode

func allow_save() -> void:
	can_save = true

func disallow_save() -> void:
	can_save = false

func save_game() -> void:
	if not can_save:
		return
	can_save = false
	var inv := {}
	for item in inventory.keys():
		inv[item.id] = inventory[item]
	var data := {
		"scene": get_tree().current_scene.scene_file_path,
		"hp": player_hp, "hunger": hunger, "sanity": sanity,
		"bleeding": bleeding, "cold": cold, "infection": infection,
		"money": money, "inventory": inv, "flags": flags,
		"parts": body_parts_state, "danger": danger, "journal": journal,
		"game_mode": game_mode, "ambient_light": ambient_light,
		"light_battery": light_battery,
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
	_dead = false
	bleeding = int(data.get("bleeding", 0))
	cold = int(data.get("cold", 0))
	infection = int(data.get("infection", 0))
	hunger = int(data.get("hunger", HUNGER_MAX))
	sanity = int(data.get("sanity", SANITY_MAX))
	player_hp = int(data.get("hp", PLAYER_HP_MAX))
	money = int(data.get("money", 0))
	money_changed.emit()
	danger = int(data.get("danger", 0))
	game_mode = str(data.get("game_mode", "cabeza"))
	ambient_light = int(data.get("ambient_light", 80))
	light_battery = float(data.get("light_battery", 100.0))
	linterna_on = false
	var jr = data.get("journal", [])
	journal = jr if typeof(jr) == TYPE_ARRAY else []
	inventory.clear()
	var inv = data.get("inventory", {})
	for id in inv.keys():
		if items_by_id.has(id):
			inventory[items_by_id[id]] = int(inv[id])
	inventory_changed.emit()
	var fl = data.get("flags", {})
	flags = fl if typeof(fl) == TYPE_DICTIONARY else {}
	var pt = data.get("parts", {})
	if typeof(pt) == TYPE_DICTIONARY:
		for part in body_parts_state.keys():
			if pt.has(part):
				body_parts_state[part] = pt[part]
	next_spawn = ""
	_change_scene(str(data.get("scene", "res://scenes/maps/test_room.tscn")))
	return true

## Reinicia todo para una partida nueva.
func new_game() -> void:
	_madness_triggered = false
	_dead = false
	can_save = false
	linterna_on = false
	light_battery = 100.0
	ambient_light = 80
	_hallu_timer = 0.0
	flags.clear()
	pending_kill_id = ""
	danger = 0
	journal.clear()
	bleeding = 0
	cold = 0
	infection = 0
	body_parts_state = {
		"brazo_izq": "ok", "brazo_der": "ok",
		"pierna_izq": "ok", "pierna_der": "ok",
	}
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
	# Si veníamos de un enemigo del mundo, queda muerto para siempre.
	if pending_kill_id != "":
		set_flag("dead_" + pending_kill_id)
		pending_kill_id = ""
	advance_danger(1)   # cada pelea sube la presión
	_change_scene(return_scene_path)

## Huiste: volvés al mundo pero el enemigo sigue vivo.
func flee_combat() -> void:
	pending_kill_id = ""
	_change_scene(return_scene_path)

func game_over() -> void:
	_change_scene("res://scenes/ui/game_over.tscn")

func _trigger_hallucination() -> void:
	var types: Array[String] = []
	if sanity < 15:
		types = ["whisper", "shadow", "screen"]
	elif sanity < 30:
		types = ["whisper", "shadow"]
	elif sanity < 50:
		types = ["whisper"]
	if types.is_empty():
		return
	var t: String = types[randi() % types.size()]
	hallucination.emit(t)

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
	if path.contains("maps/") or path.contains("test_room"):
		AudioManager.play_music("res://assets/audio/ambient.ogg", -10.0)
		ambient_light = AMBIENT_LIGHT_MAP.get(path, 80)
	get_tree().call_deferred("change_scene_to_file", path)
