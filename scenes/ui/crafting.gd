extends CanvasLayer
## Mesa de crafteo: recetas de items + mejoras del arma equipada (se fabrican
## y se montan acá mismo) + limpieza del arma con el kit.

@onready var panel: Panel = $Panel
@onready var list: VBoxContainer = $Panel/Scroll/List
@onready var info: Label = $Panel/Info
@onready var cerrar_btn: Button = $Panel/CerrarBtn

func _ready() -> void:
	visible = false
	cerrar_btn.pressed.connect(_close)

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("inventory") or event.is_action_pressed("ui_cancel"):
		_close()
		get_viewport().set_input_as_handled()

func open() -> void:
	visible = true
	get_tree().paused = true
	_refresh()
	cerrar_btn.call_deferred("grab_focus")

func _close() -> void:
	visible = false
	get_tree().paused = false

func _ingredients_text(recipe: CraftRecipe) -> String:
	var out := ""
	var first := true
	for ing_id in recipe.ingredients.keys():
		var item: ItemData = GameState.items_by_id.get(str(ing_id))
		if not first:
			out += ", "
		first = false
		var iname: String = item.display_name if item != null else str(ing_id)
		out += "%s x%d" % [iname, recipe.ingredients[ing_id]]
	return out

func _add_header(text: String) -> void:
	var l := Label.new()
	l.text = text
	list.add_child(l)

func _refresh() -> void:
	for c in list.get_children():
		c.queue_free()

	# --- Recetas de items ---
	var avail := GameState.get_available_recipes()
	if avail.is_empty():
		_add_header("(No tenés materiales para craftear items.)")
	else:
		for recipe in avail:
			var b := Button.new()
			b.text = "%s  ←  %s" % [recipe.result_name, _ingredients_text(recipe)]
			b.pressed.connect(_craft.bind(recipe))
			list.add_child(b)

	# --- Mejoras del arma equipada (se fabrican y montan acá) ---
	var w: WeaponData = GameState.equipped_weapon
	if w == null:
		_add_header("— Equipá un arma para fabricarle mejoras. —")
		info.text = ""
		return
	_add_header("— Mejoras para la %s —" % w.display_name)
	var alguna := false
	for recipe in GameState.get_accessory_recipes():
		var status: String = GameState.accessory_recipe_status(recipe)
		if status == "slot" or status == "sin_arma":
			continue  # esta arma no acepta esa mejora
		alguna = true
		var b := Button.new()
		match status:
			"puesto":
				b.text = "%s (ya montada)" % recipe.result_name
				b.disabled = true
			"faltan":
				b.text = "%s  ←  %s (faltan materiales)" % [recipe.result_name, _ingredients_text(recipe)]
				b.disabled = true
			_:
				b.text = "Montar %s  ←  %s" % [recipe.result_name, _ingredients_text(recipe)]
				b.pressed.connect(_craft_accessory.bind(recipe))
		list.add_child(b)
	if not alguna:
		_add_header("(La %s no admite mejoras de esta mesa.)" % w.display_name)

	# --- Limpieza del arma (kit de limpieza) ---
	var kit: ItemData = GameState.items_by_id.get("kit_limpieza")
	if kit != null and int(GameState.inventory.get(kit, 0)) > 0:
		var st: Dictionary = GameState.equipped_weapon_state()
		var sucia: bool = not st.is_empty() and (int(st["mud"]) > 0 or int(st["wet"]) > 0 or int(st["condition"]) < 100)
		var b := Button.new()
		if sucia:
			b.text = "Limpiar y engrasar la %s (usa el kit)" % w.display_name
			b.pressed.connect(_clean_weapon.bind(kit))
		else:
			b.text = "La %s está limpia." % w.display_name
			b.disabled = true
		list.add_child(b)

func _craft(recipe: CraftRecipe) -> void:
	if GameState.craft(recipe):
		_refresh()
		info.text = "Crafteaste: %s." % recipe.result_name
	else:
		info.text = "No tenés los materiales."

func _craft_accessory(recipe: CraftRecipe) -> void:
	if GameState.craft_accessory(recipe):
		_refresh()
		info.text = "Montás la %s en el arma." % recipe.result_name
	else:
		info.text = "No se pudo montar."

func _clean_weapon(kit: ItemData) -> void:
	if GameState.use_item(kit):
		_refresh()
		info.text = "Arma limpia y engrasada. No se va a trabar tan fácil."
	else:
		info.text = "No hace falta limpiarla."
