extends CanvasLayer
## Menú principal estilo Fear & Hunger / RPG Maker.
## Se abre con Escape o con un botón. Pausa el juego.
## Pestañas: Estado, Equipar, Compañero, Habilidades, Objetos.

@onready var panel: Panel = $Panel
@onready var tabs: HBoxContainer = $Panel/Margin/VBox/Tabs
@onready var content: MarginContainer = $Panel/Margin/VBox/ContentScroll/Content

# Botones de pestañas.
@onready var btn_status: Button = $Panel/Margin/VBox/Tabs/BtnStatus
@onready var btn_equip: Button = $Panel/Margin/VBox/Tabs/BtnEquip
@onready var btn_companion: Button = $Panel/Margin/VBox/Tabs/BtnCompanion
@onready var btn_skills: Button = $Panel/Margin/VBox/Tabs/BtnSkills
@onready var btn_items: Button = $Panel/Margin/VBox/Tabs/BtnItems
@onready var btn_close: Button = $Panel/Margin/VBox/Tabs/BtnClose

# Paneles de contenido.
@onready var status_panel: VBoxContainer = $Panel/Margin/VBox/ContentScroll/Content/StatusPanel
@onready var equip_panel: VBoxContainer = $Panel/Margin/VBox/ContentScroll/Content/EquipPanel
@onready var companion_panel: VBoxContainer = $Panel/Margin/VBox/ContentScroll/Content/CompanionPanel
@onready var skills_panel: VBoxContainer = $Panel/Margin/VBox/ContentScroll/Content/SkillsPanel
@onready var items_panel: VBoxContainer = $Panel/Margin/VBox/ContentScroll/Content/ItemsPanel

var _current_panel: Control = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	btn_status.pressed.connect(_show_status)
	btn_equip.pressed.connect(_show_equip)
	btn_companion.pressed.connect(_show_companion)
	btn_skills.pressed.connect(_show_skills)
	btn_items.pressed.connect(_show_items)
	btn_close.pressed.connect(_close)
	# Conectar señales de GameState para actualizar si hay cambios.
	GameState.inventory_changed.connect(_on_data_changed)
	GameState.weapon_changed.connect(_on_data_changed)
	GameState.companion_changed.connect(_on_data_changed)
	GameState.player_hp_changed.connect(_on_data_changed)
	GameState.hunger_changed.connect(_on_data_changed)
	GameState.sanity_changed.connect(_on_data_changed)
	GameState.body_changed.connect(_on_data_changed)
	GameState.status_effect_changed.connect(_on_data_changed)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if visible:
			_close()
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed("inventory"):
		if visible:
			_close()
		else:
			_open()
		get_viewport().set_input_as_handled()

func _open() -> void:
	visible = true
	get_tree().paused = true
	_show_status()
	btn_status.call_deferred("grab_focus")

func _close() -> void:
	visible = false
	if is_inside_tree():
		get_tree().paused = false
	# Se libera al cerrar: así no quedan instancias colgadas en la raíz entre
	# escenas y el `await tree_exited` del menú de pausa se resuelve bien.
	queue_free()

## Acepta un argumento opcional porque está conectado tanto a señales sin
## parámetros (inventory_changed) como a otras que emiten un valor
## (hunger_changed, sanity_changed, player_hp_changed).
func _on_data_changed(_value = null) -> void:
	if visible and _current_panel != null:
		_refresh_current()

func _refresh_current() -> void:
	if _current_panel == status_panel:
		_show_status()
	elif _current_panel == equip_panel:
		_show_equip()
	elif _current_panel == companion_panel:
		_show_companion()
	elif _current_panel == skills_panel:
		_show_skills()
	elif _current_panel == items_panel:
		_show_items()

func _hide_all() -> void:
	status_panel.visible = false
	equip_panel.visible = false
	companion_panel.visible = false
	skills_panel.visible = false
	items_panel.visible = false

func _show_panel(panel_node: Control) -> void:
	_hide_all()
	panel_node.visible = true
	_current_panel = panel_node

# --- ESTADO ---
func _show_status() -> void:
	_show_panel(status_panel)
	_clear(status_panel)

	# Header del jugador.
	_add_header(status_panel, "=== SOLDADO ===")
	_add_stat(status_panel, "HP: %d/%d" % [GameState.player_hp, GameState.PLAYER_HP_MAX])
	_add_stat(status_panel, "Hambre: %d/100" % GameState.hunger)
	_add_stat(status_panel, "Cordura: %d/100" % GameState.sanity)
	var hh := int(GameState.time_hours)
	var mm := int((GameState.time_hours - hh) * 60.0)
	_add_stat(status_panel, "Hora: %02d:%02d%s" % [hh, mm, "  (noche)" if GameState.is_night() else ""])
	_add_stat(status_panel, "Día: %d de junio  (la guerra termina el %d)" % [
		mini(GameState.day, GameState.CAMPAIGN_DAYS), GameState.CAMPAIGN_DAYS])
	_add_stat(status_panel, "Reputación con el batallón: %d/100" % GameState.reputation)

	# Efectos de estado.
	var effects: Array[String] = []
	if GameState.bleeding > 0:
		effects.append("Sangrado x%d" % GameState.bleeding)
	if GameState.trench_foot >= 20:
		effects.append("Pie de trinchera %d%%" % GameState.trench_foot)
	if GameState.cold > 0:
		effects.append("Frío %d" % GameState.cold)
	if GameState.infection > 0:
		effects.append("Infección %d" % GameState.infection)
	if GameState.poison > 0:
		effects.append("Veneno x%d" % GameState.poison)
	if GameState.paralysis > 0:
		effects.append("Parálisis")
	if GameState.blind > 0:
		effects.append("Ceguera")
	if not effects.is_empty():
		_add_stat(status_panel, "Efectos: " + ", ".join(effects))

	# Cuerpo.
	var rotos: Array[String] = []
	for part in GameState.body_parts_state.keys():
		if GameState.body_parts_state[part] == "roto":
			rotos.append(part)
	if not rotos.is_empty():
		_add_stat(status_panel, "Roto: " + ", ".join(rotos))

	# Compañero.
	_separator(status_panel)
	if GameState.companion != null:
		_add_header(status_panel, "=== COMPAÑERO ===")
		_add_stat(status_panel, "%s" % GameState.companion.display_name)
		_add_stat(status_panel, "HP: %d/%d" % [GameState.companion_hp, GameState.companion_hp_max])
		_add_stat(status_panel, "Ataque: %d | Defensa: %d" % [GameState.companion.attack, GameState.companion.defense])
	else:
		_add_header(status_panel, "=== COMPAÑERO ===")
		_add_stat(status_panel, "(ninguno)")

# --- EQUIPAR ---
func _show_equip() -> void:
	_show_panel(equip_panel)
	_clear(equip_panel)

	_add_header(equip_panel, "=== EQUIPAMIENTO ===")

	# Arma actual.
	_add_header(equip_panel, "Arma:")
	if GameState.equipped_weapon != null:
		var w := GameState.equipped_weapon
		_add_stat(equip_panel, "%s" % w.display_name)
		_add_stat(equip_panel, "Daño: %d | Pulso: %+d | Esquivar: %+d" % [w.damage, w.pulse_mod, w.dodge_mod])
		_add_stat(equip_panel, "Fuerza: %+d | Percepción: %+d" % [w.force_mod, w.perception_mod])
	else:
		_add_stat(equip_panel, "(sin arma — puños)")

	_separator(equip_panel)

	# Desequipar (pelear con puños).
	if GameState.equipped_weapon != null:
		var unequip := Button.new()
		unequip.text = "Desequipar (pelear con puños)"
		unequip.pressed.connect(_unequip_weapon)
		_add(equip_panel, unequip)

	_separator(equip_panel)

	# Armas disponibles en inventario.
	_add_header(equip_panel, "Cambiar arma:")
	var weapons_found := false
	for item in GameState.inventory.keys():
		if item is WeaponData:
			weapons_found = true
			var w: WeaponData = item
			var btn := Button.new()
			var is_equipped := (GameState.equipped_weapon == w)
			btn.text = "%s (Daño: %d)%s" % [w.display_name, w.damage, " [EQUIPADA]" if is_equipped else ""]
			if not is_equipped:
				btn.pressed.connect(_equip_weapon.bind(w))
			_add(equip_panel, btn)
	if not weapons_found:
		_add_stat(equip_panel, "(no tenés otras armas)")

# --- COMPAÑERO ---
func _show_companion() -> void:
	_show_panel(companion_panel)
	_clear(companion_panel)

	if GameState.companion == null:
		_add_header(companion_panel, "=== COMPAÑERO ===")
		_add_stat(companion_panel, "No tenés ningún compañero.")
		_add_stat(companion_panel, "Buscá NPCs reclutables en el mapa.")
		return

	var c := GameState.companion
	_add_header(companion_panel, "=== %s ===" % c.display_name.to_upper())
	_add_stat(companion_panel, "%s" % c.description)
	_separator(companion_panel)
	_add_stat(companion_panel, "HP: %d/%d" % [GameState.companion_hp, GameState.companion_hp_max])
	_add_stat(companion_panel, "Ataque: %d" % c.attack)
	_add_stat(companion_panel, "Defensa: %d" % c.defense)
	_add_stat(companion_panel, "Poder de cura: %d" % c.heal_power)
	_separator(companion_panel)

	_add_header(companion_panel, "Habilidades:")
	var abilities: Array[String] = []
	if c.can_heal:
		abilities.append("Curar aliados")
	if c.can_scout:
		abilities.append("Detectar enemigos/tesoros")
	if c.can_force:
		abilities.append("Ayudar a forzar puertas")
	if abilities.is_empty():
		_add_stat(companion_panel, "(ninguna habilidad especial)")
	else:
		for ab in abilities:
			_add_stat(companion_panel, "• %s" % ab)

	_separator(companion_panel)
	# Botón para despedir companion.
	var dismiss_btn := Button.new()
	dismiss_btn.text = "Despedir a %s" % c.display_name
	dismiss_btn.pressed.connect(_dismiss_companion)
	_add(companion_panel, dismiss_btn)

# --- HABILIDADES ---
func _show_skills() -> void:
	_show_panel(skills_panel)
	_clear(skills_panel)

	_add_header(skills_panel, "=== HABILIDADES ===")

	_add_header(skills_panel, "Mods permanentes (de libros/informes):")
	var mods := GameState.skill_mods
	_add_stat(skills_panel, "Pulso: %+d" % mods.get("pulse", 0))
	_add_stat(skills_panel, "Esquivar: %+d" % mods.get("dodge", 0))
	_add_stat(skills_panel, "Fuerza: %+d" % mods.get("force", 0))
	_add_stat(skills_panel, "Percepción: %+d" % mods.get("perception", 0))
	_add_stat(skills_panel, "Sigilo: %+d" % mods.get("stealth", 0))
	_add_stat(skills_panel, "Daño bonus: %+d" % mods.get("damage", 0))
	_add_stat(skills_panel, "HP bonus: +%d" % GameState.bonus_hp)

	_separator(skills_panel)
	_add_header(skills_panel, "Libros leídos:")
	var read_books := false
	for flag in GameState.flags.keys():
		if flag.begins_with("read_"):
			var book_name: String = flag.substr(5).replace("_", " ").capitalize()
			_add_stat(skills_panel, "✓ %s" % book_name)
			read_books = true
	if not read_books:
		_add_stat(skills_panel, "(no leíste ningún informe)")

	_separator(skills_panel)
	_add_header(skills_panel, "Arma actual:")
	if GameState.equipped_weapon != null:
		_add_stat(skills_panel, "%s" % GameState.equipped_weapon.display_name)
	else:
		_add_stat(skills_panel, "(puños)")

# --- OBJETOS ---
func _show_items() -> void:
	_show_panel(items_panel)
	_clear(items_panel)

	_add_header(items_panel, "=== INVENTARIO ===")
	_add_stat(items_panel, "Espacios: %d/%d   |   Cigarrillos: %d" % [
		GameState.inventory_total(), GameState.INVENTORY_MAX, GameState.money])

	# Linterna: toggle perpetuo (no se consume). Siempre visible si la tenés.
	if GameState.inventory.has(GameState.ITEM_LINTERNA):
		var estado := "ENCENDIDA" if GameState.linterna_on else "apagada"
		var light_btn := Button.new()
		light_btn.text = "Linterna: %s   (batería %d%%)" % [estado, int(GameState.light_battery)]
		light_btn.pressed.connect(_toggle_light)
		_add(items_panel, light_btn)
	_separator(items_panel)

	if GameState.inventory.is_empty():
		_add_stat(items_panel, "(vacío)")
		return

	# Agrupar por tipo.
	var weapons: Array = []
	var books: Array = []
	var consumables: Array = []

	for item in GameState.inventory.keys():
		var count: int = GameState.inventory[item]
		if item is WeaponData:
			weapons.append({"item": item, "count": count})
		elif item is SkillBook:
			books.append({"item": item, "count": count})
		elif item is ItemData:
			# La linterna tiene su propio botón perpetuo arriba.
			if item == GameState.ITEM_LINTERNA:
				continue
			consumables.append({"item": item, "count": count})

	# Armas.
	if not weapons.is_empty():
		_add_header(items_panel, "Armas:")
		for entry in weapons:
			var w: WeaponData = entry["item"]
			var btn := Button.new()
			var is_eq := (GameState.equipped_weapon == w)
			btn.text = "%s (Daño: %d)%s" % [w.display_name, w.damage, " [E]" if is_eq else ""]
			if not is_eq:
				btn.pressed.connect(_equip_weapon.bind(w))
			_add(items_panel, btn)

	# Libros.
	if not books.is_empty():
		_add_header(items_panel, "Informes/Libros:")
		for entry in books:
			var b: SkillBook = entry["item"]
			var btn := Button.new()
			var read := (b.read_flag != "" and GameState.has_flag(b.read_flag))
			btn.text = "%s%s" % [b.display_name, " [LEÍDO]" if read else ""]
			if not read:
				btn.pressed.connect(_read_book.bind(b))
			_add(items_panel, btn)

	# Consumibles.
	if not consumables.is_empty():
		_add_header(items_panel, "Consumibles:")
		for entry in consumables:
			var item: ItemData = entry["item"]
			var count: int = entry["count"]
			var btn := Button.new()
			btn.text = "%s x%d — %s" % [item.display_name, count, item.description]
			btn.pressed.connect(_use_item.bind(item))
			_add(items_panel, btn)

# --- Acciones ---
func _equip_weapon(weapon: WeaponData) -> void:
	GameState.equip_weapon(weapon)
	_refresh_current()

func _unequip_weapon() -> void:
	GameState.equip_weapon(null)
	_refresh_current()

func _read_book(book: SkillBook) -> void:
	if book.read_flag != "" and GameState.has_flag(book.read_flag):
		Dialogue.say("Ya leíste %s." % book.display_name)
		return
	GameState.apply_skill_book(book)
	if GameState.inventory.has(book):
		GameState.inventory[book] -= 1
		if GameState.inventory[book] <= 0:
			GameState.inventory.erase(book)
	GameState.inventory_changed.emit()
	_refresh_current()

func _use_item(item: ItemData) -> void:
	var ok := GameState.use_item(item)
	if ok:
		_refresh_current()

## Prende/apaga la linterna sin cerrar el menú (botón perpetuo).
func _toggle_light() -> void:
	GameState.toggle_linterna()
	_refresh_current()

func _dismiss_companion() -> void:
	Dialogue.ask("¿Seguro que querés mandar a %s de vuelta?" % GameState.companion.display_name,
		["Sí, me voy solo", "No, quédate"])
	var choice: int = await Dialogue.chosen
	if choice == 0:
		GameState.remove_companion()
		_refresh_current()

# --- Helpers ---
func _add_header(parent: Control, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.6))
	parent.add_child(label)

func _add_stat(parent: Control, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 12)
	parent.add_child(label)

func _add(parent: Control, node: Node) -> void:
	parent.add_child(node)

func _separator(parent: Control) -> void:
	var sep := HSeparator.new()
	parent.add_child(sep)

func _clear(parent: Control) -> void:
	for c in parent.get_children():
		c.queue_free()
