class_name InventoryManager
## Gestiona inventario, items, crafteo y tienda.
## Se instancia dentro de GameState para mantener la API existente.

## ESPACIOS del inventario (ítems distintos; apilar más del mismo no ocupa
## espacio extra, estilo Fear & Hunger: la decisión es QUÉ llevás, no cuánto).
const INVENTORY_MAX := 24

var inventory: Dictionary = {}   # ItemData -> cantidad
var money: int = 0
var shop_items: Array[ItemData] = []
var items_by_id: Dictionary = {}

# --- Recursos de items ---
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

const RECIPE_FOGATA := preload("res://data/recipes/fogota_recipe.tres")
const RECIPE_VENDA_ESTERILIZADA := preload("res://data/recipes/venda_esterilizada_recipe.tres")
var recipes: Array = [RECIPE_FOGATA, RECIPE_VENDA_ESTERILIZADA]

## Mejoras de arma (mesa de crafteo): se fabrican y se MONTAN directo en el arma
## equipada. Los AccessoryData no pasan por el inventario (que es ItemData→cant).
const RECIPE_CORREA := preload("res://data/recipes/correa_recipe.tres")
const RECIPE_TRIPODE := preload("res://data/recipes/tripode_recipe.tres")
const RECIPE_MIRA := preload("res://data/recipes/mira_recipe.tres")
var accessory_recipes: Array = [RECIPE_CORREA, RECIPE_TRIPODE, RECIPE_MIRA]

func setup() -> void:
	items_by_id = {
		"venda": ITEM_VENDA, "racion": ITEM_RACION, "morfina": ITEM_MORFINA,
		"antibioticos": ITEM_ANTIBIOTICOS, "fosforos": ITEM_FOSFOROS, "tablilla": ITEM_TABLILLA,
		"rama": ITEM_RAMA, "alcohol": ITEM_ALCOHOL, "carne_podrida": ITEM_CARNE_PODRIDA,
		"diente": ITEM_DIENTE, "fogata_portatil": ITEM_FOGATA_PORTATIL,
		"venda_esterilizada": ITEM_VENDA_ESTERILIZADA,
		"linterna": ITEM_LINTERNA, "pilas": ITEM_PILAS,
		"kit_limpieza": preload("res://data/items/kit_limpieza.tres"),
		"bidon_gasoil": preload("res://data/items/bidon_gasoil.tres"),
		"medias_secas": preload("res://data/items/medias_secas.tres"),
		"carne_cruda": preload("res://data/items/carne_cruda.tres"),
		"carta_casa": preload("res://data/items/carta_casa.tres"),
		# Armas de fuego.
		"fal": preload("res://data/items/fal.tres"),
		"fap": preload("res://data/items/fap.tres"),
		"fn_mag": preload("res://data/items/fn_mag.tres"),
		"fmk3": preload("res://data/items/fmk3.tres"),
		"browning_hp": preload("res://data/items/browning_hp.tres"),
		"escopeta": preload("res://data/items/escopeta.tres"),
		# Armas cuerpo a cuerpo.
		"cuchillo_trinchera": preload("res://data/items/cuchillo_trinchera.tres"),
		"palo_filo": preload("res://data/items/palo_filo.tres"),
		"cuchillo_combate": preload("res://data/items/cuchillo_combate.tres"),
		"bayoneta": preload("res://data/items/bayoneta.tres"),
		# Libros de habilidades.
		"informe_medico": preload("res://data/items/informe_medico.tres"),
		"manual_sigilo": preload("res://data/items/manual_sigilo.tres"),
		"manual_asalto": preload("res://data/items/manual_asalto.tres"),
		"orden_del_dia": preload("res://data/items/orden_del_dia.tres"),
		# Munición: balas sueltas + cargadores/cintas (llenos y vacíos).
		"balas_762": preload("res://data/items/balas_762.tres"),
		"balas_9mm": preload("res://data/items/balas_9mm.tres"),
		"cartuchos_12": preload("res://data/items/cartuchos_12.tres"),
		"cargador_762": preload("res://data/items/cargador_762.tres"),
		"cargador_762_vacio": preload("res://data/items/cargador_762_vacio.tres"),
		"cargador_9mm": preload("res://data/items/cargador_9mm.tres"),
		"cargador_9mm_vacio": preload("res://data/items/cargador_9mm_vacio.tres"),
		"cinta_762": preload("res://data/items/cinta_762.tres"),
		"cinta_762_vacia": preload("res://data/items/cinta_762_vacia.tres"),
		# Explosivos y artillería.
		"granada_f1": preload("res://data/items/granada_f1.tres"),
		"c4": preload("res://data/items/c4.tres"),
		"claymore": preload("res://data/items/claymore.tres"),
		"coordenadas_artilleria": preload("res://data/items/coordenadas_artilleria.tres"),
	}
	shop_items = [ITEM_VENDA, ITEM_RACION, ITEM_MORFINA, ITEM_ANTIBIOTICOS, ITEM_FOSFOROS, ITEM_TABLILLA, ITEM_RAMA, ITEM_ALCOHOL, ITEM_LINTERNA, ITEM_PILAS,
		items_by_id["balas_762"], items_by_id["balas_9mm"], items_by_id["cartuchos_12"]]

## Arma de prueba: el FAL arranca en el inventario para poder equiparla y probar
## el disparo. (Las armas se guardan en el dict de inventario como WeaponData.)
const WEAPON_FAL := preload("res://data/items/fal.tres")

func give_starting_items(game_mode: String) -> void:
	add_item(ITEM_VENDA, 1)
	add_item(ITEM_RACION, 1)
	add_item(ITEM_RAMA, 2)
	inventory[WEAPON_FAL] = 1
	# Munición inicial: un cargador listo, uno vacío y balas para probar el ciclo
	# completo (llenar cargador en el inventario → R para recargar).
	# El resto del arsenal se consigue con el cheat F10 o en el cofre de pruebas.
	add_item(items_by_id["cargador_762"], 1)
	add_item(items_by_id["cargador_762_vacio"], 1)
	add_item(items_by_id["balas_762"], 20)
	if game_mode == "cabeza":
		money = 10
		add_item(ITEM_LINTERNA, 1)
	else:
		money = 4

## Espacios ocupados (ítems distintos, no unidades).
func inventory_total() -> int:
	return inventory.size()

func add_item(item: ItemData, qty: int = 1) -> bool:
	if item == null:
		return false
	if not inventory.has(item) and inventory.size() >= INVENTORY_MAX:
		print("[Inventario] Lleno (%d espacios). Hay que soltar algo." % INVENTORY_MAX)
		return false
	inventory[item] = int(inventory.get(item, 0)) + qty
	print("[Inventario] +%d %s" % [qty, item.display_name])
	return true

func use_item(item: ItemData, state: Node) -> bool:
	if int(inventory.get(item, 0)) <= 0:
		return false
	var result := _apply_item_effect(item, state)
	match result:
		"consumed":
			inventory[item] -= 1
			if inventory[item] <= 0:
				inventory.erase(item)
			return true
		"used":
			return true
		_:
			return false

func _apply_item_effect(item: ItemData, state: Node) -> String:
	match item.effect:
		"bandage":
			if state.bleeding <= 0:
				return ""
			state.bleeding = 0
			state.body_changed.emit()
			print("[Cuerpo] Te vendás. El sangrado se detiene.")
			return "consumed"
		"ration":
			state.hunger += item.amount
			print("[Inventario] Comés. Hambre: %d/%d" % [state.hunger, state.HUNGER_MAX])
			if item.id == "carne_podrida" and Dice.chance(0.45):
				state.infection = clampi(state.infection + 15, 0, 100)
				state.body_changed.emit()
				print("[Inventario] La carne podrida te hizo mal. Infección sube.")
			elif item.id == "carne_cruda" and Dice.chance(0.25):
				state.infection = clampi(state.infection + 8, 0, 100)
				state.body_changed.emit()
				print("[Inventario] La carne cruda te cae pesada. Mejor asarla.")
			return "consumed"
		"dry_feet":
			if state.trench_foot <= 0:
				return ""
			state.trench_foot = 0
			state._tf_warned = false
			state.body_changed.emit()
			print("[Cuerpo] Medias secas. Los pies vuelven a la vida.")
			return "consumed"
		"letter":
			state.sanity = mini(state.SANITY_MAX, state.sanity + item.amount)
			print("[Cordura] Leés la carta una vez más. Todavía hay un afuera.")
			return "consumed"
		"morphine":
			state.player_hp += item.amount
			return "consumed"
		"antibiotic":
			if state.infection <= 0:
				return ""
			state.infection = 0
			state.body_changed.emit()
			return "consumed"
		"clean_weapon":
			if state.equipped_weapon == null:
				print("[Arma] No tenés arma para limpiar.")
				return ""
			state.clean_weapon()
			print("[Arma] Limpiás y engrasás el arma. Barro y humedad afuera.")
			return "consumed"
		"warm":
			if state.cold <= 0:
				return ""
			state.cold = maxi(0, state.cold - item.amount)
			state.body_changed.emit()
			return "consumed"
		"alcohol":
			state.cold = maxi(0, state.cold - item.amount)
			state.sanity = mini(state.SANITY_MAX, state.sanity + 20)
			state.body_changed.emit()
			state.sanity_changed.emit(state.sanity)
			print("[Inventario] Tomás alcohol. Frío baja, cordura +20.")
			return "consumed"
		"grenade", "c4", "claymore", "artillery":
			# El efecto en combate lo maneja combat.gd.
			# Aquí solo consumimos el item cuando se usa.
			return "consumed"
		"splint":
			return "consumed" if state.splint() else ""
		"bandage_sterile":
			if state.bleeding <= 0 and state.infection <= 0:
				return ""
			state.bleeding = 0
			state.infection = 0
			state.body_changed.emit()
			return "consumed"
		"light":
			if state.light_battery <= 0:
				return ""
			state.linterna_on = not state.linterna_on
			return "used"
		"battery":
			if state.light_battery >= 100:
				return ""
			state.light_battery = mini(100, state.light_battery + item.amount)
			return "consumed"
		"load_mag":
			# Cargador/cinta VACÍO: usarlo lo llena con balas sueltas del
			# inventario (item.amount balas) y lo convierte en el item lleno.
			var full_id: String = item.id.trim_suffix("_vacio").trim_suffix("_vacia")
			var bullets_id := "balas_762" if item.id.contains("762") else "balas_9mm"
			var bullets: ItemData = items_by_id.get(bullets_id)
			var have := int(inventory.get(bullets, 0))
			if have < item.amount:
				print("[Munición] Necesitás %d balas y tenés %d." % [item.amount, have])
				return ""
			inventory[bullets] -= item.amount
			if inventory[bullets] <= 0:
				inventory.erase(bullets)
			add_item(items_by_id[full_id], 1)
			return "consumed"
		_:
			return ""

# --- Loot ---

func process_loot(loot_table: Array) -> Array:
	var gained: Array = []
	for id in loot_table:
		var item = items_by_id.get(str(id))
		if item == null:
			continue
		if item is WeaponData:
			# Arma: se equipa directamente.
			GameState.equip_weapon(item)
			gained.append(item.display_name)
		elif item is SkillBook:
			# Libro: se aprende directamente.
			GameState.apply_skill_book(item)
			gained.append(item.display_name)
		elif item is ItemData:
			if add_item(item, 1):
				gained.append(item.display_name)
	return gained

# --- Crafteo ---

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
	return true

# --- Mejoras de arma (mesa de crafteo) ---

func _load_accessory_res(acc_id: String) -> Resource:
	var path := "res://data/items/%s.tres" % acc_id
	return load(path) if ResourceLoader.exists(path) else null

## Estado de una receta de mejora respecto del arma equipada:
## "ok" (se puede fabricar y montar), "sin_arma", "slot" (el arma no acepta esa
## ranura), "puesto" (ya está montada) o "faltan" (sin ingredientes).
func accessory_recipe_status(recipe: CraftRecipe, state: Node) -> String:
	if state.equipped_weapon == null:
		return "sin_arma"
	var acc := _load_accessory_res(recipe.result_id)
	if acc == null or not state.equipped_weapon.accepted_slots.has(acc.slot_type):
		return "slot"
	var st: Dictionary = state.equipped_weapon_state()
	if str(st["accessories"].get(acc.slot_type, "")) != "":
		return "puesto"
	if not _has_ingredients(recipe):
		return "faltan"
	return "ok"

## Fabrica la mejora consumiendo ingredientes y la monta en el arma equipada.
func craft_accessory(recipe: CraftRecipe, state: Node) -> bool:
	if accessory_recipe_status(recipe, state) != "ok":
		return false
	for ing_id in recipe.ingredients.keys():
		var item: ItemData = items_by_id.get(str(ing_id))
		var needed: int = recipe.ingredients[ing_id]
		inventory[item] -= needed
		if inventory[item] <= 0:
			inventory.erase(item)
	return state.attach_accessory(_load_accessory_res(recipe.result_id))

# --- Tienda ---

func buy_item(item: ItemData, price_mult: float = 1.0) -> bool:
	if item == null or item.price <= 0:
		return false
	var cost := maxi(1, int(ceil(item.price * price_mult)))
	if money < cost:
		return false
	if not inventory.has(item) and inventory.size() >= INVENTORY_MAX:
		return false
	money -= cost
	add_item(item, 1)
	return true

# --- Serialización para guardado ---

func serialize() -> Dictionary:
	var inv := {}
	for item in inventory.keys():
		inv[item.id] = inventory[item]
	return {"inventory": inv, "money": money}

func deserialize(data: Dictionary, state: Node) -> void:
	inventory.clear()
	var inv = data.get("inventory", {})
	for id in inv.keys():
		if items_by_id.has(id):
			inventory[items_by_id[id]] = int(inv[id])
	money = int(data.get("money", 0))
	state.money_changed.emit()
	state.inventory_changed.emit()
