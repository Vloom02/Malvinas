extends Node
## Singleton (autoload) con el estado global de la partida.
## Vive entre escenas. SIN HUD: estos valores se reflejan en pantalla/cuerpo
## de forma diegética (ver scenes/ui/darkness.gd), no en barras.
##
## Estructura interna:
##   - _inv: InventoryManager (inventario, items, crafteo, tienda)
##   - _save: SaveManager (guardar/cargar con validación)
##   - El resto del estado vive directamente acá.

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
signal companion_changed           # se reclutó o perdió un companion
signal status_effect_changed       # efecto de estado cambió
signal weapon_changed              # se equipó/desequipó un arma

# --- Topes ---
const HUNGER_MAX := 100
const SANITY_MAX := 100
var PLAYER_HP_MAX: int = 100

# --- Módulos internos ---
var _inv: InventoryManager
var _save: SaveManager

# --- Stats del jugador ---
var player_attack: int = 18

# --- Arma equipada ---
var equipped_weapon: WeaponData = null
var _base_damage: int = 11  ## Daño sin arma (puños).

# --- Habilidades desbloqueadas por libros ---
## Mods permanentes ganados al leer informes/libros.
var skill_mods: Dictionary = {
	"pulse": 0, "dodge": 0, "force": 0,
	"perception": 0, "stealth": 0, "damage": 0,
}
var bonus_hp: int = 0  ## HP máximo bonus por libros.

## Devuelve el daño actual del jugador (base + arma + mods).
## Si roll_variance = true, aplica ±variance del arma al resultado.
func get_player_damage(roll_variance: bool = false) -> int:
	var dmg: int = _base_damage + int(skill_mods.get("damage", 0))
	var var_range: int = 0
	if equipped_weapon != null:
		dmg = equipped_weapon.damage + int(skill_mods.get("damage", 0))
		var_range = equipped_weapon.variance
	if roll_variance and var_range > 0:
		dmg += randi_range(-var_range, var_range)
		dmg = maxi(1, dmg)
	return dmg

## Devuelve mod de pulso actual (arma + skills).
func get_pulse_mod() -> int:
	var mod := 0
	if equipped_weapon != null:
		mod += equipped_weapon.pulse_mod
	mod += int(skill_mods.get("pulse", 0))
	return mod

## Devuelve mod de esquiva actual (arma + skills).
func get_dodge_mod() -> int:
	var mod := 0
	if equipped_weapon != null:
		mod += equipped_weapon.dodge_mod
	mod += int(skill_mods.get("dodge", 0))
	return mod

## Devuelve mod de fuerza actual.
func get_force_mod() -> int:
	var mod := 0
	if equipped_weapon != null:
		mod += equipped_weapon.force_mod
	mod += int(skill_mods.get("force", 0))
	return mod

## Devuelve mod de percepción actual.
func get_perception_mod() -> int:
	var mod := 0
	if equipped_weapon != null:
		mod += equipped_weapon.perception_mod
	mod += int(skill_mods.get("perception", 0))
	return mod

## Devuelve mod de sigilo actual.
func get_stealth_mod() -> int:
	return int(skill_mods.get("stealth", 0))

## Devuelve mod de defensa (quemaduras reducen defensa).
func get_defense_mod() -> int:
	var mod := 0
	if burns > 0:
		mod -= burns * 2
	return mod

## Devuelve multiplicador de daño recibido (infección de herida lo aumenta).
func get_damage_taken_mult() -> float:
	if wound_infection > 0:
		return 1.5
	return 1.0

## Equipa un arma. Devuelve el arma anterior (o null).
func equip_weapon(weapon: WeaponData) -> WeaponData:
	var old := equipped_weapon
	equipped_weapon = weapon
	weapon_changed.emit()
	return old

## Aplica un libro/informe. Devuelve true si se aplicó.
func apply_skill_book(book: SkillBook) -> bool:
	if book.read_flag != "" and has_flag(book.read_flag):
		return false  # ya leído
	if book.read_flag != "":
		set_flag(book.read_flag)
	match book.skill_type:
		SkillBook.SkillType.MOD_PULSE: skill_mods["pulse"] += book.skill_value
		SkillBook.SkillType.MOD_DODGE: skill_mods["dodge"] += book.skill_value
		SkillBook.SkillType.MOD_FORCE: skill_mods["force"] += book.skill_value
		SkillBook.SkillType.MOD_PERCEPTION: skill_mods["perception"] += book.skill_value
		SkillBook.SkillType.MOD_STEALTH: skill_mods["stealth"] += book.skill_value
		SkillBook.SkillType.BONUS_HP:
			bonus_hp += book.skill_value
			PLAYER_HP_MAX += book.skill_value
		SkillBook.SkillType.BONUS_DAMAGE: skill_mods["damage"] += book.skill_value
	return true

# --- Estado de combate ---
var pending_enemy_path: String = ""
var return_scene_path: String = "res://scenes/maps/nivel1_trinchera.tscn"
var _madness_triggered: bool = false
## True mientras estás peleando: congela eventos del mundo, alucinaciones y
## sangrado (que solo avanza al caminar). Evita que aparezcan peleas encima
## de otra pelea.
var in_combat: bool = false

# --- Navegación entre salas ---
var next_spawn: String = ""

# --- Estado persistente del mundo ---
var flags: Dictionary = {}
var pending_kill_id: String = ""
var _dead: bool = false
var danger: int = 0

func advance_danger(n: int = 1) -> void:
	danger += n

var journal: Array = []

func add_journal(entry: String) -> void:
	if entry != "" and not journal.has(entry):
		journal.append(entry)

func set_flag(id: String) -> void:
	flags[id] = true

func has_flag(id: String) -> bool:
	return flags.get(id, false)

# --- Cuerpo: heridas persistentes ---
var bleeding: int = 0
var cold: int = 0
var infection: int = 0

var body_parts_state: Dictionary = {
	"brazo_izq": "ok", "brazo_der": "ok",
	"pierna_izq": "ok", "pierna_der": "ok",
}

## Cada cuántos pasos caminados perdés sangre (el sangrado ya no avanza por
## tiempo, solo al moverte).
const BLEED_STEP_INTERVAL := 3
var _bleed_steps: int = 0
var _body_timer: float = 0.0

# --- Efectos de estado adicionales ---
## Veneno: drena HP cada segundo. Sube por enemigos/objeto específicos.
var poison: int = 0
## Parálisis: si > 0, el jugador no puede atacar un turno en combate.
var paralysis: int = 0
## Ceguera: si > 0, tiradas con desventaja y no podés usar linterna.
var blind: int = 0
## Conmoción cerebral: si > 0, -2 percepción y -1 pulso.
var concussion: int = 0
## Choque de artillería: si > 0, no puede actuar (similar a parálisis pero temática).
var shell_shock: int = 0
## Quemaduras: si > 0, -20% defensa y 1 HP/seg (requiere tablilla+venda).
var burns: int = 0
## Infección de herida: si > 0, +50% daño recibido y 2 HP/seg (requiere antibióticos).
var wound_infection: int = 0

## Artillería: una sola llamada por zona de mapa.
var artillery_used: bool = false

var _poison_timer: float = 0.0

# --- Luz ambiental por mapa ---
const AMBIENT_LIGHT_MAP: Dictionary = {
	"res://scenes/maps/test_room.tscn": 80,
	"res://scenes/maps/room2.tscn": 60,
	"res://scenes/maps/nivel1_trinchera.tscn": 80,
	"res://scenes/maps/nivel1_pozo.tscn": 30,
	"res://scenes/maps/nivel1_campo.tscn": 90,
	"res://scenes/maps/naval_barco.tscn": 20,
}

# --- Propiedades de luz ---
var can_save: bool = false
var game_mode: String = "cabeza"
var ambient_light: int = 80
var linterna_on: bool = false
var light_battery: float = 100.0
var _hallu_timer: float = 0.0

## Zoom de cámara (persistido en settings).
var camera_zoom: float = 1.0

## Módulos de sistema.
var _atmosphere: AtmosphereManager
var _world_events: WorldEvents
var _narrative: NarrativeManager
var _map_manager: MapManager

func effective_light() -> int:
	if linterna_on and light_battery > 0:
		return maxi(ambient_light, 40)
	return ambient_light

# --- Setters con señales ---
var hunger: int = HUNGER_MAX:
	set(value):
		hunger = clampi(value, 0, HUNGER_MAX)
		hunger_changed.emit(hunger)

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

# --- API pública de inventario (delega a _inv) ---

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

const INVENTORY_MAX := InventoryManager.INVENTORY_MAX

var inventory: Dictionary:
	get: return _inv.inventory if _inv else {}
var money: int:
	get: return _inv.money if _inv else 0
	set(value): if _inv: _inv.money = value
var shop_items: Array[ItemData]:
	get: return _inv.shop_items if _inv else []
var items_by_id: Dictionary:
	get: return _inv.items_by_id if _inv else {}

func inventory_total() -> int:
	return _inv.inventory_total() if _inv else 0

func add_item(item: ItemData, qty: int = 1) -> bool:
	var ok := _inv.add_item(item, qty) if _inv else false
	if ok:
		inventory_changed.emit()
	return ok

func use_item(item: ItemData) -> bool:
	var ok := _inv.use_item(item, self) if _inv else false
	if ok:
		inventory_changed.emit()
	return ok

## Prende/apaga la linterna desde el menú. Devuelve un texto de estado.
## No consume la linterna: es un toggle perpetuo mientras tengas batería.
func toggle_linterna() -> String:
	if not inventory.has(ITEM_LINTERNA):
		return "No tenés linterna."
	if blind > 0:
		return "No ves nada, la linterna no ayuda ahora."
	if not linterna_on and light_battery <= 0:
		return "La linterna no tiene batería."
	linterna_on = not linterna_on
	inventory_changed.emit()
	return "Linterna encendida." if linterna_on else "Linterna apagada."

func process_loot(loot_table: Array) -> Array:
	var gained := _inv.process_loot(loot_table) if _inv else []
	if not gained.is_empty():
		inventory_changed.emit()
	return gained

func get_available_recipes() -> Array:
	return _inv.get_available_recipes() if _inv else []

func craft(recipe: CraftRecipe) -> bool:
	var ok := _inv.craft(recipe) if _inv else false
	if ok:
		inventory_changed.emit()
	return ok

func buy_item(item: ItemData) -> bool:
	var ok := _inv.buy_item(item) if _inv else false
	if ok:
		inventory_changed.emit()
		money_changed.emit()
	return ok

# --- Init ---

func _ready() -> void:
	_inv = InventoryManager.new()
	_inv.setup()
	_save = SaveManager.new()
	# Atmosphere manager.
	_atmosphere = load("res://scripts/systems/atmosphere_manager.gd").new()
	add_child(_atmosphere)
	# World events.
	_world_events = load("res://scripts/systems/world_events.gd").new()
	add_child(_world_events)
	# Narrative.
	_narrative = load("res://scripts/systems/narrative_manager.gd").new()
	add_child(_narrative)
	# Map manager.
	_map_manager = load("res://scripts/systems/map_manager.gd").new()
	add_child(_map_manager)
	player_died.connect(_on_player_died_global)
	_inv.give_starting_items(game_mode)

func _on_player_died_global() -> void:
	if _dead:
		return
	var cur := get_tree().current_scene
	if cur != null and cur.scene_file_path.contains("combat"):
		return
	_dead = true
	game_over()

# --- Tick del cuerpo ---

func _process(delta: float) -> void:
	if get_tree().paused:
		return
	# Solo correr la lógica de juego dentro de una partida (mapa o combate).
	# En el título / game over no debe pasar nada (evita eventos del mundo,
	# alucinaciones, etc. apareciendo antes de empezar a jugar).
	if not _in_gameplay():
		return

	# El frío/infección/hambre siguen pasando factura aunque pelees.
	_body_timer += delta
	while _body_timer >= 1.0:
		_body_timer -= 1.0
		_tick_status()

	if linterna_on and light_battery > 0:
		light_battery = maxf(0.0, light_battery - delta * 0.5)
		if light_battery <= 0:
			linterna_on = false

	# Lo que NO debe ocurrir mientras peleás: alucinaciones por cordura,
	# eventos del mundo (incluidas emboscadas) ni veneno.
	# (El sangrado avanza al caminar, ver spend_step.)
	if in_combat:
		return

	if sanity > 0 and sanity < SANITY_MAX:
		_hallu_timer += delta
		var interval := 3.0 + (float(sanity) / float(SANITY_MAX)) * 12.0
		if _hallu_timer >= interval:
			_hallu_timer = 0.0
			_trigger_hallucination()

	# Tick de veneno.
	_tick_poison(delta)

	# Tick de eventos del mundo.
	if _world_events != null:
		_world_events.process(delta)

## True solo cuando hay una partida activa (mapa o combate). Falso en el título,
## game over o si no hay escena cargada.
func _in_gameplay() -> bool:
	var scene := get_tree().current_scene
	if scene == null:
		return false
	var path := scene.scene_file_path
	if path.ends_with("title.tscn") or path.ends_with("game_over.tscn"):
		return false
	return true

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
	# Parálisis, ceguera y conmoción se reducen con el tiempo.
	if paralysis > 0:
		paralysis -= 1
		changed = true
	if blind > 0:
		blind -= 1
		changed = true
	if concussion > 0:
		concussion -= 1
		changed = true
	if shell_shock > 0:
		shell_shock -= 1
		changed = true
	# Quemaduras e infección de herida NO se reducen solos (requieren tratamiento).
	# Quemaduras drenan HP.
	if burns > 0 and player_hp > 0:
		player_hp -= 1
	# Infección de herida drena HP.
	if wound_infection > 0 and player_hp > 0:
		player_hp -= 2
	# Daño por estados críticos.
	if cold >= 90 and player_hp > 0:
		player_hp -= 1
	if infection >= 90 and player_hp > 0:
		player_hp -= 1
	if hunger <= 0 and player_hp > 0:
		player_hp -= 1
	if changed:
		body_changed.emit()
		status_effect_changed.emit()

# --- Acciones ---

func spend_step() -> void:
	hunger -= 1
	# El sangrado solo te desangra mientras caminás (cada BLEED_STEP_INTERVAL pasos).
	if bleeding > 0 and player_hp > 0:
		_bleed_steps += 1
		if _bleed_steps >= BLEED_STEP_INTERVAL:
			_bleed_steps = 0
			player_hp -= bleeding

func drain_sanity(amount: int) -> void:
	sanity -= amount

func sanity_save(dc: int = 12, sanity_loss: int = 10, mod: int = 0) -> Dictionary:
	var r := Dice.check(mod, dc)
	if not r["success"]:
		drain_sanity(sanity_loss)
	return r

func damage_player(amount: int) -> void:
	player_hp -= amount

func apply_bleeding(stacks: int) -> void:
	bleeding = clampi(bleeding + stacks, 0, 10)
	body_changed.emit()

func bandage() -> void:
	bleeding = 0
	body_changed.emit()
	print("[Cuerpo] Te vendás. El sangrado se detiene.")

# --- Miembros ---

func break_part(part: String) -> bool:
	if body_parts_state.get(part, "roto") == "ok":
		body_parts_state[part] = "roto"
		body_part_broken.emit(part)
		body_changed.emit()
		return true
	return false

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

# --- Compañeros (party) ---
var companion: CompanionData = null
var companion_hp: int = 0
var companion_hp_max: int = 0

## Agrega un companion. Devuelve false si ya tenés uno.
func add_companion(data: CompanionData) -> bool:
	if companion != null:
		return false
	companion = data
	companion_hp = data.hp
	companion_hp_max = data.hp_max
	companion_changed.emit()
	print("[Party] Reclutaste a %s." % data.display_name)
	return true

## Remueve el companion actual (muerto o lo mandás de vuelta).
func remove_companion() -> void:
	if companion != null:
		print("[Party] %s se va." % companion.display_name)
		companion = null
		companion_hp = 0
		companion_hp_max = 0
		companion_changed.emit()

## Daño al companion. Devuelve true si murió.
func damage_companion(amount: int) -> bool:
	if companion == null:
		return false
	companion_hp = maxi(0, companion_hp - amount)
	if companion_hp <= 0:
		print("[Party] %s ha muerto." % companion.display_name)
		remove_companion()
		return true
	return false

## Cura al companion.
func heal_companion(amount: int) -> void:
	if companion == null:
		return
	companion_hp = mini(companion_hp_max, companion_hp + amount)

# --- Efectos de estado: veneno/parálisis/ceguera ---

func apply_poison(stacks: int) -> void:
	poison = clampi(poison + stacks, 0, 10)
	status_effect_changed.emit()

func apply_paralysis(turns: int) -> void:
	paralysis = clampi(paralysis + turns, 0, 5)
	status_effect_changed.emit()

func apply_blind(turns: int) -> void:
	blind = clampi(blind + turns, 0, 5)
	status_effect_changed.emit()

func apply_concussion(stacks: int) -> void:
	concussion = clampi(concussion + stacks, 0, 3)
	status_effect_changed.emit()

func apply_shell_shock(turns: int) -> void:
	shell_shock = clampi(shell_shock + turns, 0, 1)
	status_effect_changed.emit()

func apply_burns(stacks: int) -> void:
	burns = clampi(burns + stacks, 0, 5)
	status_effect_changed.emit()

func apply_wound_infection(stacks: int) -> void:
	wound_infection = clampi(wound_infection + stacks, 0, 3)
	status_effect_changed.emit()

func clear_poison() -> void:
	poison = 0
	status_effect_changed.emit()

func clear_paralysis() -> void:
	paralysis = 0
	status_effect_changed.emit()

func clear_blind() -> void:
	blind = 0
	status_effect_changed.emit()

## Tick de veneno: drena 2 HP por stack cada 3 segundos.
func _tick_poison(delta: float) -> void:
	if poison <= 0:
		return
	_poison_timer += delta
	while _poison_timer >= 3.0:
		_poison_timer -= 3.0
		if player_hp > 0:
			player_hp -= poison * 2

# --- Guardar / cargar ---

func set_game_mode(mode: String) -> void:
	game_mode = mode

func allow_save() -> void:
	can_save = true

func disallow_save() -> void:
	can_save = false

func has_save() -> bool:
	return _save.has_save()

func save_game() -> void:
	if not can_save:
		return
	can_save = false
	var inv_data := _inv.serialize() if _inv else {}
	var data := {
		"scene": get_tree().current_scene.scene_file_path,
		"hp": player_hp, "hunger": hunger, "sanity": sanity,
		"bleeding": bleeding, "cold": cold, "infection": infection,
		"poison": poison, "paralysis": paralysis, "blind": blind,
		"concussion": concussion, "shell_shock": shell_shock,
		"burns": burns, "wound_infection": wound_infection,
		"artillery_used": artillery_used,
		"flags": flags, "parts": body_parts_state, "danger": danger,
		"journal": journal, "game_mode": game_mode, "ambient_light": ambient_light,
		"light_battery": light_battery, "camera_zoom": camera_zoom,
		"linterna_on": linterna_on,
		"weapon_id": equipped_weapon.id if equipped_weapon else "",
		"skill_mods": skill_mods, "bonus_hp": bonus_hp,
		"companion": companion.id if companion else "",
		"companion_hp": companion_hp, "companion_hp_max": companion_hp_max,
	}
	data.merge(inv_data)
	# Narrative + map data.
	data.merge(_narrative.serialize())
	data.merge(_map_manager.serialize())
	_save.save_game(data)

func load_game() -> bool:
	var data := _save.load_game()
	if data.is_empty():
		return false
	_madness_triggered = false
	_dead = false
	in_combat = false
	_bleed_steps = 0
	_hallu_timer = 0.0
	bleeding = int(data.get("bleeding", 0))
	cold = int(data.get("cold", 0))
	infection = int(data.get("infection", 0))
	poison = int(data.get("poison", 0))
	paralysis = int(data.get("paralysis", 0))
	blind = int(data.get("blind", 0))
	concussion = int(data.get("concussion", 0))
	shell_shock = int(data.get("shell_shock", 0))
	burns = int(data.get("burns", 0))
	wound_infection = int(data.get("wound_infection", 0))
	artillery_used = bool(data.get("artillery_used", false))
	hunger = int(data.get("hunger", HUNGER_MAX))
	# Prevenir que el setter de sanity dispare _trigger_madness durante la carga.
	var saved_sanity := int(data.get("sanity", SANITY_MAX))
	if saved_sanity <= 0:
		_madness_triggered = true
	sanity = saved_sanity
	# Restaurar bonus_hp/PLAYER_HP_MAX ANTES de player_hp para que el clamp use el max correcto.
	bonus_hp = int(data.get("bonus_hp", 0))
	PLAYER_HP_MAX = 100 + bonus_hp
	player_hp = int(data.get("hp", PLAYER_HP_MAX))
	danger = int(data.get("danger", 0))
	game_mode = str(data.get("game_mode", "cabeza"))
	ambient_light = int(data.get("ambient_light", 80))
	light_battery = float(data.get("light_battery", 100.0))
	camera_zoom = float(data.get("camera_zoom", 1.0))
	linterna_on = bool(data.get("linterna_on", false))
	# Restaurar arma equipada.
	var weapon_id := str(data.get("weapon_id", ""))
	equipped_weapon = null
	if weapon_id != "":
		for item_path in ["cuchillo_trinchera", "fusil_f8", "fal_m1982", "palo_filo", "cuchillo_combate", "bayoneta", "escopeta"]:
			var w: WeaponData = load("res://data/items/%s.tres" % item_path) as WeaponData
			if w != null and w.id == weapon_id:
				equipped_weapon = w
				break
	# Restaurar skills.
	var sm = data.get("skill_mods", {})
	if typeof(sm) == TYPE_DICTIONARY:
		for key in skill_mods.keys():
			if sm.has(key):
				skill_mods[key] = int(sm[key])
	# Restaurar companion.
	var companion_id := str(data.get("companion", ""))
	companion = null
	companion_hp = int(data.get("companion_hp", 0))
	companion_hp_max = int(data.get("companion_hp_max", 0))
	if companion_id != "":
		for c_path in ["cabo_garcia", "medico_rodriguez", "cabo_pascual"]:
			var c: CompanionData = load("res://data/companions/%s.tres" % c_path) as CompanionData
			if c != null and c.id == companion_id:
				companion = c
				break
	var jr = data.get("journal", [])
	journal = jr if typeof(jr) == TYPE_ARRAY else []
	_inv.deserialize(data, self)
	_narrative.deserialize(data)
	_map_manager.deserialize(data)
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

# --- Partida nueva ---

func new_game() -> void:
	_madness_triggered = false
	_dead = false
	in_combat = false
	_bleed_steps = 0
	can_save = false
	linterna_on = false
	light_battery = 100.0
	ambient_light = 80
	camera_zoom = 1.0
	_hallu_timer = 0.0
	flags.clear()
	pending_kill_id = ""
	danger = 0
	journal.clear()
	bleeding = 0
	cold = 0
	infection = 0
	poison = 0
	paralysis = 0
	blind = 0
	concussion = 0
	shell_shock = 0
	burns = 0
	wound_infection = 0
	artillery_used = false
	companion = null
	companion_hp = 0
	companion_hp_max = 0
	equipped_weapon = null
	skill_mods = {
		"pulse": 0, "dodge": 0, "force": 0,
		"perception": 0, "stealth": 0, "damage": 0,
	}
	bonus_hp = 0
	PLAYER_HP_MAX = 100
	body_parts_state = {
		"brazo_izq": "ok", "brazo_der": "ok",
		"pierna_izq": "ok", "pierna_der": "ok",
	}
	hunger = HUNGER_MAX
	sanity = SANITY_MAX
	player_hp = PLAYER_HP_MAX
	_inv.inventory.clear()
	_inv.give_starting_items(game_mode)
	_narrative.reset()
	_map_manager.reset()

# --- Puente de combate ---

func start_combat(enemy_path: String, from_scene: String) -> void:
	in_combat = true
	pending_enemy_path = enemy_path
	return_scene_path = from_scene
	_change_scene("res://scenes/combat/combat.tscn")

func end_combat() -> void:
	in_combat = false
	if pending_kill_id != "":
		set_flag("dead_" + pending_kill_id)
		pending_kill_id = ""
	advance_danger(1)
	_change_scene(return_scene_path)

func flee_combat() -> void:
	in_combat = false
	pending_kill_id = ""
	_change_scene(return_scene_path)

func game_over() -> void:
	_change_scene("res://scenes/ui/game_over.tscn")

# --- Alucinaciones / locura ---

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
	in_combat = true
	pending_enemy_path = "res://data/enemies/madness.tres"
	var cur := get_tree().current_scene
	if cur != null:
		return_scene_path = cur.scene_file_path
	_change_scene("res://scenes/combat/combat.tscn")

func recover_from_madness() -> void:
	sanity = int(SANITY_MAX / 2.0)

# --- Utilidades ---

func _change_scene(path: String) -> void:
	if path.contains("maps/") or path.contains("test_room"):
		AudioManager.play_music("res://assets/audio/ambient.ogg", -10.0)
		ambient_light = AMBIENT_LIGHT_MAP.get(path, 80)
	get_tree().call_deferred("change_scene_to_file", path)

# --- API de narrativa ---

func make_decision(id: String, weight: int = 1, effects: Dictionary = {}) -> void:
	_narrative.make_decision(id, weight, effects)

func has_decision(id: String) -> bool:
	return _narrative.has_decision(id)

func get_decision_weight(id: String) -> int:
	return _narrative.get_weight(id)

# --- API de mapas ---

func get_zone_name() -> String:
	return _map_manager.get_zone_name()

func get_zone_difficulty() -> int:
	return _map_manager.get_zone_difficulty()

func advance_zone() -> bool:
	return _map_manager.advance_zone()

func get_random_enemy_path() -> String:
	return _map_manager.get_random_enemy_path()

# --- API de atmósfera ---

func update_atmosphere(player_pos: Vector2, enemies: Array, delta: float) -> void:
	if _atmosphere:
		_atmosphere.update_tension(player_pos, enemies, delta)

func get_tension() -> float:
	if _atmosphere:
		return _atmosphere.get_tension()
	return 0.0
