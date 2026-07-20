extends Control
## Combate por turnos con desmembramiento (estilo Fear & Hunger).
##
## El combate normal es DETERMINISTA (atacás → pegás; el enemigo pega). El DADO
## NO resuelve cada ataque: aparece solo en dos momentos de tensión:
##   1) PULSO: si estás herido/sangrando, te tiembla la mano. Al atacar tirás un
##      dado para firmar el pulso; si lo aguantás, pegás bien; si no, flojo o errás.
##   2) ESQUIVAR: si el enemigo es un JEFE, a veces carga un PODER y tenés que
##      tirar para esquivarlo (éxito = lo evitás, fallo = te come y te abre herida).
## Ganás destruyendo cabeza o torso. Perdés si tu vida llega a 0.

@onready var enemy_name_label: Label = $EnemyName
@onready var enemy_sprite: TextureRect = $EnemySprite
@onready var player_sprite: TextureRect = $PlayerSprite
@onready var parts_list: VBoxContainer = $PartsList
@onready var actions: VBoxContainer = $ActionsPanel/ActionsScroll/Actions
@onready var log_label: Label = $LogPanel/Log
@onready var player_info: Label = $PlayerInfo
@onready var madness_tint: ColorRect = $MadnessTint
@onready var companion_info: Label = $CompanionInfo if has_node("CompanionInfo") else null

const PLAYER_TEXTURE := preload("res://assets/sprites/conscripto/rotations/south.png")

## Rutas de audio (dejar vacío = silencio hasta tener los .ogg).
const SFX_HIT := "res://assets/audio/hit.wav"
const SFX_PLAYER_ATTACK := "res://assets/audio/player_attack.wav"
const SFX_BANDAGE := "res://assets/audio/bandage.wav"
const SFX_DODGE := "res://assets/audio/dodge.wav"
const SFX_VICTORY := "res://assets/audio/victory.wav"
const SFX_DEATH := "res://assets/audio/death.wav"
const MUSIC_COMBAT := "res://assets/audio/combat.ogg"

const PULSE_DC := 11
const WOUNDED_HP := 35

var enemy: EnemyData
var parts_hp: Dictionary = {}
var part_labels: Dictionary = {}
var is_player_turn: bool = true
var combat_over: bool = false
var _pending_dodge: bool = false
var _enemy_staggered: bool = false
var _resolved: bool = false
var _guard_active: bool = false
var _enemy_destroyed_parts: Dictionary = {}
var _enemy_skip_turn: bool = false
var _enemy_stun_turns: int = 0
var _enemy_bleed: int = 0
var _enemy_burn: int = 0
var _enemy_poison: int = 0
var _enemy_max_hp: int = 0
var _companion_turn_used: bool = false
var _rest_position: Vector2 = Vector2.ZERO
## El arma de fuego puede trabarse en pleno combate (barro/humedad/frío/desgaste,
## misma tirada que el disparo con F en el mapa). Trabada = hay que gastar un
## turno en destrabarla desde el menú Pelear.
var _weapon_jammed: bool = false

## Menú jerárquico (estilo RPG Maker / F&H): "main", "attack", "items", "companion".
var _menu: String = "main"

## --- Ataque especial con aviso (telegraph) ---
## Cuando el enemigo "carga" un golpe fuerte, lo avisa este turno y lo descarga
## el turno siguiente. _special_cd evita que lo spamee.
var _enemy_charging: bool = false
var _special_cd: int = 2
const SPECIAL_CHANCE_COMMON := 0.25
var _last_log_lines: Array[String] = []
const LOG_MAX_LINES := 4

func _ready() -> void:
	var path := GameState.pending_enemy_path
	if path == "":
		path = "res://data/enemies/ghoul.tres"
	var loaded := load(path) as EnemyData
	if loaded == null:
		push_error("combat: no se pudo cargar enemigo: %s" % path)
		loaded = load("res://data/enemies/ghoul.tres") as EnemyData
	enemy = loaded.duplicate() as EnemyData
	parts_hp = enemy.body_parts.duplicate()
	_enemy_max_hp = _total_parts_hp()
	# Modo Cruz: enemigos más duros
	if GameState.game_mode == "cruz":
		for part in parts_hp.keys():
			parts_hp[part] = int(parts_hp[part] * 1.3)
		enemy.attack += 3

	# Daño pre-combate por dispararle en el mapa: resta del torso (sin matarlo)
	# y arranca sangrando. Lo aplicamos antes de dibujar las partes.
	var pre_dmg := GameState.pending_pre_damage
	var pre_bleed := GameState.pending_enemy_bleed
	GameState.pending_pre_damage = 0
	GameState.pending_enemy_bleed = 0
	if pre_dmg > 0 and parts_hp.has("torso"):
		parts_hp["torso"] = maxi(1, parts_hp["torso"] - pre_dmg)
	if pre_bleed > 0:
		_enemy_bleed += pre_bleed

	enemy_name_label.text = enemy.display_name
	if enemy.sprite != null:
		enemy_sprite.texture = enemy.sprite
		_begin_enemy_breathing()
	player_sprite.texture = PLAYER_TEXTURE
	_style_ui()
	_build_parts_display()
	_build_action_buttons()
	_refresh_player_info()
	_log("Te enfrentás a: %s." % enemy.display_name)
	if pre_dmg > 0 or pre_bleed > 0:
		_log("Ya venía herido de tus disparos.")

	_rest_position = position
	GameState.player_died.connect(_on_player_died)

	if path.contains("madness"):
		_begin_madness()
	AudioManager.play_music(MUSIC_COMBAT, -8.0)

func _exit_tree() -> void:
	if GameState.player_died.is_connected(_on_player_died):
		GameState.player_died.disconnect(_on_player_died)

func _process(_delta: float) -> void:
	if not combat_over:
		_refresh_player_info()

func _on_player_died() -> void:
	if not combat_over:
		_lose()

func _begin_enemy_breathing() -> void:
	var tw: Tween = create_tween().set_loops()
	tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_method(func(v: float): enemy_sprite.scale = Vector2(v, v), 1.0, 1.03, 2.0)
	tw.tween_method(func(v: float): enemy_sprite.scale = Vector2(v, v), 1.03, 1.0, 2.0)

func _style_ui() -> void:
	var font_path := "res://assets/fonts/GrenzeGotisch.ttf"
	var fnt := load(font_path) as FontFile
	if fnt == null:
		return
	var combat_theme := Theme.new()
	combat_theme.set_default_font(fnt)
	combat_theme.set_font("font", "Label", fnt)
	combat_theme.set_font("font", "Button", fnt)
	combat_theme.set_font_size("font_size", "Label", 14)
	combat_theme.set_font_size("font_size", "Button", 18)
	combat_theme.set_color("font_color", "Label", Color(0.75, 0.7, 0.65))
	combat_theme.set_color("font_color", "Button", Color(0.8, 0.75, 0.7))
	combat_theme.set_color("font_hover_color", "Button", Color(1.0, 0.9, 0.8))
	combat_theme.set_stylebox("panel", "Panel", null)
	combat_theme.set_constant("h_separation", "Button", 4)
	for c in [enemy_name_label, log_label, player_info, parts_list, actions]:
		c.theme = combat_theme

func _begin_madness() -> void:
	_log("La cordura te abandona. Algo sin rostro se arrastra hacia vos.")
	madness_tint.color = Color(0.5, 0.0, 0.0, 0.0)
	var tw := create_tween()
	tw.tween_property(madness_tint, "color:a", 0.35, 0.8)

func _build_parts_display() -> void:
	for part in parts_hp.keys():
		var l := Label.new()
		l.text = "%s: %d" % [part, parts_hp[part]]
		parts_list.add_child(l)
		part_labels[part] = l

## Compatibilidad: arranca el menú en la raíz.
func _build_action_buttons() -> void:
	_show_menu("main")

## Empieza el turno del jugador: resetea el menú a la raíz.
func _start_player_turn() -> void:
	is_player_turn = true
	_companion_turn_used = false
	_show_menu("main")

## Helper para agregar un botón de acción.
func _add_action(text: String, cb: Callable) -> void:
	var b := Button.new()
	b.text = text
	b.pressed.connect(cb)
	actions.add_child(b)

## Pone el foco en el primer botón de acción (para jugar con teclado).
func _focus_first_action() -> void:
	if actions.get_child_count() > 0:
		var first := actions.get_child(0)
		if first is Button:
			(first as Button).call_deferred("grab_focus")

## Dibuja el menú según el estado. Jerárquico: Pelear / Objetos / Huir.
func _show_menu(menu: String) -> void:
	_menu = menu
	_clear_actions()

	# Parálisis: solo podés esperar.
	if menu == "main" and GameState.paralysis > 0:
		_add_action("Esperar (paralizado)", _on_paralyzed_wait)
		_focus_first_action()
		return

	match menu:
		"main":
			_add_action("Pelear", _show_attack_menu)
			if enemy.talk_type != "":
				_add_action("Hablar", _show_talk_menu)
			_add_action("Objetos", _show_items_menu)
			if GameState.companion != null:
				_add_action("Compañero", _show_companion_menu)
			_add_action("Huir", _on_flee)
		"talk":
			match enemy.talk_type:
				"britanico":
					_add_action("Rendirte (te capturan)", _on_surrender)
					_add_action("Intimidar (d20 Fuerza)", _on_intimidate)
				"desertor":
					_add_action("Calmarlo (d20)", _on_calm)
			_add_action("« Volver", _show_main_menu)
		"attack":
			# Arma trabada: primero hay que destrabarla (cuesta el turno).
			if _weapon_jammed:
				var w: WeaponData = GameState.equipped_weapon
				var wname: String = w.display_name if w != null else "arma"
				_add_action("Destrabar la %s" % wname, _on_unjam)
				_add_action("Guardia", _on_guard)
				_add_action("« Volver", _show_main_menu)
				_focus_first_action()
				return
			if GameState.blind > 0:
				_log("No ves bien. Las tiradas tienen desventaja.")
			# Arma de fuego sin balas: ofrecer recargar (cuesta el turno). Los
			# ataques siguen disponibles pero pegan a culatazo (medio daño).
			var wf: WeaponData = GameState.equipped_weapon
			if wf != null and wf.is_firearm() and GameState.weapon_ammo() <= 0 \
					and GameState.ammo_reserve_count() > 0:
				_add_action("Recargar la %s" % wf.display_name, _on_combat_reload)
			for part in parts_hp.keys():
				var estado := "" if parts_hp[part] > 0 else " (destruida)"
				_add_action("Atacar %s%s" % [part, estado], _on_attack_part.bind(part))
			_add_action("Ataque arriesgado (dados)", _on_risky_attack)
			_add_action("Guardia", _on_guard)
			_add_action("« Volver", _show_main_menu)
		"items":
			_add_action("Vendarte", _on_bandage)
			for item in GameState.inventory.keys():
				if not (item is ItemData):
					continue
				if item == GameState.ITEM_VENDA or item == GameState.ITEM_LINTERNA or item == GameState.ITEM_PILAS:
					continue
				var count: int = GameState.inventory[item]
				_add_action("Usar %s x%d" % [item.display_name, count], _on_use_combat_item.bind(item))
			_add_action("« Volver", _show_main_menu)
		"companion":
			if GameState.companion != null:
				if GameState.companion.can_heal:
					_add_action("%s cura" % GameState.companion.display_name, _on_companion_heal)
				if GameState.companion.can_force:
					_add_action("%s ayuda a golpear" % GameState.companion.display_name, _on_companion_attack)
			_add_action("« Volver", _show_main_menu)

	_focus_first_action()

func _show_main_menu() -> void:
	_show_menu("main")

func _show_attack_menu() -> void:
	_show_menu("attack")

func _show_items_menu() -> void:
	_show_menu("items")

func _show_talk_menu() -> void:
	_show_menu("talk")

func _show_companion_menu() -> void:
	_show_menu("companion")

func _clear_actions() -> void:
	for c in actions.get_children():
		c.queue_free()

## Usa un consumible en combate (cuesta el turno).
func _on_use_combat_item(item: ItemData) -> void:
	if combat_over or not is_player_turn or _pending_dodge:
		return
	# Verificar artillería antes de consumir.
	if item.effect == "artillery" and GameState.artillery_used:
		_log("Ya usaste artillería en esta zona. Las coordenadas no sirven.")
		return
	var ok := GameState.use_item(item)
	if not ok:
		_log("No podés usar %s ahora." % item.display_name)
		return
	is_player_turn = false
	_log("Usás %s." % item.display_name)

	match item.effect:
		"grenade":
			_log("¡La granada estalla en el enemigo!")
			for part in parts_hp.keys():
				if parts_hp[part] > 0:
					var dmg := 15
					if part in ["torso", "cabeza"]:
						dmg = 20
					parts_hp[part] = maxi(0, parts_hp[part] - dmg)
					_update_part_label(part)
					_log("%s recibe %d de daño por la metralla." % [part, dmg])
			if _enemy_dead():
				_win()
				_refresh_player_info()
				AudioManager.play_sfx(SFX_HIT, -6.0)
				_shake(10.0, 0.5)
				return
		"c4":
			_log("¡El C4 detona! Una explosión masiva sacude el área.")
			var dmg := 50
			if parts_hp.get("torso", 0) > 0:
				parts_hp["torso"] = maxi(0, parts_hp["torso"] - dmg)
				_update_part_label("torso")
				_log("El torso recibe %d de daño." % dmg)
			# Daño secundario a otras partes.
			for part in parts_hp.keys():
				if part != "torso" and parts_hp[part] > 0:
					parts_hp[part] = maxi(0, parts_hp[part] - 15)
					_update_part_label(part)
			_enemy_burn += 5
			_log("El enemigo arde en llamas.")
			if _enemy_dead():
				_win()
				_refresh_player_info()
				AudioManager.play_sfx(SFX_HIT, -6.0)
				_shake(10.0, 0.5)
				return
		"claymore":
			_log("¡La Claymore dispara una lluvia de metralla a las piernas!")
			var dmg := 25
			for p in ["pierna_izq", "pierna_der"]:
				if parts_hp.get(p, 0) > 0:
					parts_hp[p] = maxi(0, parts_hp[p] - dmg)
					_update_part_label(p)
					_log("%s recibe %d de daño." % [p, dmg])
			_enemy_bleed += 4
			_log("El enemigo sangra profusamente.")
			if _enemy_dead():
				_win()
				_refresh_player_info()
				AudioManager.play_sfx(SFX_HIT, -6.0)
				_shake(8.0, 0.4)
				return
		"artillery":
			GameState.artillery_used = true
			_log("¡Llamás a la artillería! El cielo truena y el infierno cae sobre %s." % enemy.display_name)
			for part in parts_hp.keys():
				if parts_hp[part] > 0:
					var dmg := 35
					parts_hp[part] = maxi(0, parts_hp[part] - dmg)
					_update_part_label(part)
					_log("%s: -%d por metralla de artillería." % [part, dmg])
			_enemy_stun_turns = maxi(_enemy_stun_turns, 2)
			_enemy_burn += 5
			if _enemy_dead():
				_win()
				_refresh_player_info()
				AudioManager.play_sfx(SFX_HIT, -8.0)
				_shake(12.0, 0.6)
				AudioManager.play_sfx("res://assets/audio/explosion.wav", -4.0)
				return

	_refresh_player_info()
	await get_tree().create_timer(0.8).timeout
	_enemy_turn()

const TARGETS := [
	{"key": "cabeza", "name": "la cabeza"},
	{"key": "torso", "name": "el torso"},
	{"key": "brazo_izq", "name": "el brazo izquierdo"},
	{"key": "brazo_der", "name": "el brazo derecho"},
	{"key": "pierna_izq", "name": "la pierna izquierda"},
	{"key": "pierna_der", "name": "la pierna derecha"},
]

func _is_wounded() -> bool:
	return GameState.bleeding > 0 or GameState.player_hp < WOUNDED_HP or GameState.broken_arms() > 0

func _on_attack_part(part: String) -> void:
	if combat_over or not is_player_turn or _pending_dodge:
		return
	if parts_hp[part] <= 0:
		_log("%s ya está destruida." % part)
		return

	# ¿Se traba el arma de fuego? (misma tirada que el disparo con F en el mapa)
	if await _roll_combat_jam():
		return

	# Munición: cada disparo gasta una bala (aunque el enemigo esquive).
	# Sin balas, el ataque es a culatazo: medio daño.
	var culata := _spend_combat_bullet()

	# Evasión de cabeza (30%).
	if part == "cabeza" and Dice.chance(0.3):
		is_player_turn = false
		_companion_turn_used = false
		_log("%s esquiva el ataque a la cabeza. ¡Es rápido!" % enemy.display_name)
		await get_tree().create_timer(0.6).timeout
		_enemy_turn()
		return

	is_player_turn = false
	_companion_turn_used = false
	var dmg := GameState.get_player_damage()
	var weapon := GameState.equipped_weapon

	# Aplicar varianza del arma al daño base
	if weapon != null and weapon.variance > 0:
		dmg = maxi(1, dmg + randi_range(-weapon.variance, weapon.variance))
	if culata:
		dmg = maxi(1, int(dmg / 2.0))
		_log("Sin balas: golpeás con la culata.")
	var base_dmg := dmg

	if _is_wounded():
		var r: Dictionary = Dice.check(GameState.get_pulse_mod(), PULSE_DC)
		if r["fumble"]:
			dmg = 0
			_log("Te tiembla el pulso y errás del todo  [d20 %d]" % r["die"])
		elif r["success"]:
			if r["crit"]:
				dmg = base_dmg * 2
				_log("¡Pulso de acero! (20 natural)")
			else:
				dmg = base_dmg
				_log("Aguantás el pulso  [d20 %d+%d=%d vs %d]" % [
					r["die"], r["modifier"], r["total"], PULSE_DC])
		else:
			dmg = maxi(1, int(base_dmg / 2.0))
			_log("El brazo herido te falla, pegás flojo  [d20 %d+%d=%d vs %d]" % [
				r["die"], r["modifier"], r["total"], PULSE_DC])

	if dmg > 0:
		parts_hp[part] = maxi(0, parts_hp[part] - dmg)
		var atk_text := "Golpeás %s: %d de daño."
		if weapon != null and weapon.attack_text != "":
			atk_text = weapon.attack_text + " (%d de daño)"
		_log(atk_text % [part, dmg])
		AudioManager.play_sfx(SFX_PLAYER_ATTACK, -3.0)
		_update_part_label(part)

		# Aplicar efecto de estado del arma.
		if weapon != null and weapon.status_effect != "" and weapon.status_chance > 0.0:
			if Dice.chance(weapon.status_chance):
				match weapon.status_effect:
					"bleed":
						_enemy_bleed += 3
						_log("¡El arma abre una herida profunda! (Sangrado x3)")
					"burn":
						_enemy_burn += 5
						_log("¡El impacto quema al enemigo! (Quemadura x5)")
					"stun":
						_enemy_stun_turns = maxi(_enemy_stun_turns, 1)
						_log("¡El golpe aturde al enemigo!")
					"poison":
						_enemy_poison += 3
						_log("¡Veneno entra en la herida! (Veneno x3)")

		if dmg > 0 and Dice.chance(0.15):
			GameState.apply_bleeding(1)
			_log("La sangre salpica. También te manchás vos.")

		if parts_hp[part] == 0:
			_enemy_destroyed_parts[part] = true
			_log("¡Destruiste %s!" % part)
			if part in ["pierna_izq", "pierna_der"]:
				_enemy_skip_turn = true
				_log("%s pierde una pata y se arrastra." % enemy.display_name)
			elif part in ["brazo_izq", "brazo_der"]:
				_log("%s perdió un brazo, pega más débil." % enemy.display_name)
			else:
				_enemy_staggered = true

	if _enemy_dead():
		_win()
		return

	await get_tree().create_timer(0.6).timeout
	_enemy_turn()

## Tira encasquillamiento antes de un ataque. Solo armas de fuego. Si se traba,
## el turno se pierde y el arma queda trabada hasta usar "Destrabar".
## Devuelve true si se trabó (el caller debe cortar su ataque).
func _roll_combat_jam() -> bool:
	var w: WeaponData = GameState.equipped_weapon
	if w == null:
		return false
	if not w.is_firearm():
		# Las armas blancas no se traban, pero se MELLAN con el uso
		# (la condición baja el daño: ver get_player_damage).
		var stm := GameState.equipped_weapon_state()
		if not stm.is_empty() and randf() < 0.15:
			stm["condition"] = clampi(int(stm["condition"]) - 1, 0, 100)
			if int(stm["condition"]) == 20:
				_log("El filo de la %s está hecho pedazos." % w.display_name)
		return false
	if not GameState.roll_weapon_jam():
		return false
	_weapon_jammed = true
	is_player_turn = false
	var grime := GameState.weapon_grime_state()
	var reason := "el barro"
	if grime == "mojado":
		reason = "la humedad"
	elif grime != "barro":
		reason = "el frío y el desgaste"
	AudioManager.play_sfx("res://assets/audio/disparo.wav", -18.0)  # "click" seco
	_log("¡CLICK! La %s se traba (%s)." % [w.display_name, reason])
	await get_tree().create_timer(0.8).timeout
	_enemy_turn()
	return true

## Gasta una bala del arma equipada si es de fuego y tiene. Devuelve true si
## NO había balas (el ataque sale a culatazo, medio daño).
func _spend_combat_bullet() -> bool:
	var w: WeaponData = GameState.equipped_weapon
	if w == null or not w.is_firearm():
		return false
	if GameState.weapon_ammo() <= 0:
		return true
	GameState.spend_bullet()
	return false

## Recargar en combate cuesta el turno (si la recarga falla, no lo perdés).
func _on_combat_reload() -> void:
	if combat_over or not is_player_turn or _pending_dodge:
		return
	var msg := GameState.reload_weapon()
	if msg != "":
		_log(msg)
		return
	is_player_turn = false
	AudioManager.play_sfx("res://assets/audio/disparo.wav", -24.0)  # "clac" de recarga
	_log("Metés munición nueva en el arma.")
	await get_tree().create_timer(0.6).timeout
	_enemy_turn()

## Destrabar el arma cuesta el turno.
func _on_unjam() -> void:
	if combat_over or not is_player_turn or _pending_dodge:
		return
	is_player_turn = false
	_weapon_jammed = false
	var w: WeaponData = GameState.equipped_weapon
	var wname: String = w.display_name if w != null else "arma"
	_log("Manoteás la corredera y expulsás el cartucho trabado de la %s." % wname)
	await get_tree().create_timer(0.6).timeout
	_enemy_turn()

func _on_guard() -> void:
	if combat_over or not is_player_turn or _pending_dodge:
		return
	_guard_active = true
	is_player_turn = false
	_log("Te ponés en guardia.")
	_enemy_turn()

func _enemy_damage_mod() -> int:
	var mod := 0
	if _enemy_destroyed_parts.get("brazo_izq", false) and _enemy_destroyed_parts.get("brazo_der", false):
		mod -= 4
	return mod

func _on_bandage() -> void:
	if combat_over or not is_player_turn or _pending_dodge:
		return
	if GameState.bleeding <= 0:
		_log("No estás sangrando.")
		return
	if int(GameState.inventory.get(GameState.ITEM_VENDA, 0)) <= 0:
		_log("No te quedan vendas.")
		return

	is_player_turn = false
	GameState.use_item(GameState.ITEM_VENDA)
	AudioManager.play_sfx(SFX_BANDAGE, -2.0)
	_log("Te vendás a las apuradas. El sangrado se detiene.")
	await get_tree().create_timer(0.6).timeout
	_enemy_turn()

func _on_paralyzed_wait() -> void:
	if combat_over or not is_player_turn:
		return
	is_player_turn = false
	_companion_turn_used = false
	_log("Los músculos no responden. Perdés el turno.")
	await get_tree().create_timer(0.6).timeout
	_enemy_turn()

func _select_ai_action() -> String:
	var ratio := _enemy_hp_ratio()
	if ratio < 0.25 and Dice.chance(enemy.ai_chance_desperate):
		return enemy.ai_desperate
	if ratio < 0.5 and Dice.chance(enemy.ai_chance_hurt):
		return enemy.ai_hurt
	return enemy.ai_normal

func _execute_ai_action(action: String) -> void:
	match action:
		"attack":
			_execute_ai_attack()
		"scream":
			_log("%s emite un alarido que te perfora los oídos." % enemy.display_name)
			GameState.sanity = maxi(0, GameState.sanity - 10)
			GameState.apply_paralysis(1)
			_log("El alarido te paraliza de miedo.")
			_start_player_turn()
		"embrace":
			_log("%s se abalanza sobre vos en un abrazo mortal." % enemy.display_name)
			var dmg := maxi(1, enemy.attack + 6 + GameState.danger)
			dmg = maxi(1, int(dmg * GameState.get_damage_taken_mult()))
			dmg = maxi(1, dmg - GameState.get_defense_mod())
			_companion_take_hit(dmg)
			GameState.apply_bleeding(2)
			AudioManager.play_sfx(SFX_HIT, -2.0)
			_log("Te aprieta: -%d de vida y sangrado." % dmg)
			_shake(6.0, 0.3)
			_refresh_player_info()
			if GameState.player_hp <= 0:
				_lose()
			else:
				_start_player_turn()
		"burst":
			_log("%s descarga una ráfaga de disparos." % enemy.display_name)
			var dmg := maxi(1, int(enemy.attack * 0.6) + GameState.danger)
			dmg = maxi(1, int(dmg * GameState.get_damage_taken_mult()))
			dmg = maxi(1, dmg - GameState.get_defense_mod())
			_companion_take_hit(dmg)
			GameState.apply_bleeding(1)
			AudioManager.play_sfx(SFX_HIT, -2.0)
			_log("La ráfaga impacta: -%d de vida y sangrado." % dmg)
			_shake(5.0, 0.3)
			_refresh_player_info()
			if GameState.player_hp <= 0:
				_lose()
			else:
				_start_player_turn()
		"grenade":
			_log("%s tira una granada. ¡Agachate!" % enemy.display_name)
			var dmg := maxi(1, enemy.attack + 8 + GameState.danger)
			if _guard_active:
				dmg = maxi(1, int(dmg * 0.5))
				_guard_active = false
				_log("Bloqueás parte de la metralla con la guardia.")
			dmg = maxi(1, int(dmg * GameState.get_damage_taken_mult()))
			dmg = maxi(1, dmg - GameState.get_defense_mod())
			_companion_take_hit(dmg)
			AudioManager.play_sfx(SFX_HIT, -4.0)
			_log("La metralla te alcanza: -%d de vida." % dmg)
			_shake(8.0, 0.4)
			_refresh_player_info()
			if GameState.player_hp <= 0:
				_lose()
			else:
				_start_player_turn()
		"bite":
			_log("%s te clava los dientes." % enemy.display_name)
			var dmg := maxi(1, enemy.attack + 4 + GameState.danger)
			dmg = maxi(1, int(dmg * GameState.get_damage_taken_mult()))
			dmg = maxi(1, dmg - GameState.get_defense_mod())
			_companion_take_hit(dmg)
			GameState.apply_bleeding(2)
			AudioManager.play_sfx(SFX_HIT, -2.0)
			_log("La mordida te desgarra: -%d de vida y sangrado profundo." % dmg)
			_shake(5.0, 0.3)
			_refresh_player_info()
			if GameState.player_hp <= 0:
				_lose()
			else:
				_start_player_turn()
		"kamikaze":
			_log("%s se abalanza sobre vos con furia suicida." % enemy.display_name)
			var dmg := maxi(1, int(enemy.attack * 1.8) + GameState.danger)
			dmg = maxi(1, int(dmg * GameState.get_damage_taken_mult()))
			dmg = maxi(1, dmg - GameState.get_defense_mod())
			_companion_take_hit(dmg)
			AudioManager.play_sfx(SFX_HIT, -2.0)
			_log("El ataque te revuelca: -%d de vida." % dmg)
			_shake(10.0, 0.5)
			for part in parts_hp.keys():
				if parts_hp[part] > 0:
					parts_hp[part] = maxi(0, parts_hp[part] - 8)
					_update_part_label(part)
			_log("%s se hiere a sí mismo en el ataque." % enemy.display_name)
			_refresh_player_info()
			if _enemy_dead():
				_win()
				return
			if GameState.player_hp <= 0:
				_lose()
			else:
				_start_player_turn()
		"whisper":
			_log("Un susurro helado llena tu mente.")
			GameState.sanity = maxi(0, GameState.sanity - 15)
			GameState.apply_paralysis(1)
			_log("El susurro te paraliza. Cordura -15.")
			_start_player_turn()
		"distort":
			_log("La realidad se distorsiona frente a tus ojos.")
			GameState.apply_blind(2)
			GameState.sanity = maxi(0, GameState.sanity - 8)
			_log("La distorsión te ciega. Ceguera x2, cordura -8.")
			_start_player_turn()
		"power":
			if _special_cd <= 0:
				_enemy_charging = true
				_special_cd = 3
				_log("%s se prepara para un GOLPE FUERTE. ¡Anticipate!" % enemy.display_name)
				_telegraph_flash()
				_start_player_turn()
			else:
				_execute_ai_attack()
		"rest":
			var heal := 10 + (GameState.danger * 2)
			for part in parts_hp.keys():
				if parts_hp[part] > 0 and parts_hp[part] < enemy.body_parts[part]:
					parts_hp[part] = mini(enemy.body_parts[part], parts_hp[part] + heal)
				_update_part_label(part)
			_log("%s se retira un momento y se recupera." % enemy.display_name)
			_start_player_turn()
		_:
			_execute_ai_attack()

func _execute_ai_attack() -> void:
	var dmg := maxi(1, enemy.attack + GameState.danger)
	dmg = maxi(1, int(dmg * GameState.get_damage_taken_mult()))
	dmg = maxi(1, dmg - GameState.get_defense_mod())
	dmg = maxi(1, dmg + _enemy_damage_mod())
	var t: Dictionary = TARGETS[randi() % TARGETS.size()]

	if _guard_active:
		dmg = maxi(1, int(dmg * 0.5))
		_guard_active = false
		_log("Bloqueás parte del golpe con la guardia.")

	_companion_take_hit(dmg)
	AudioManager.play_sfx(SFX_HIT, -2.0)
	_log("%s te golpea en %s: -%d de vida." % [enemy.display_name, t["name"], dmg])
	_shake(4.0, 0.25)
	_spawn_blood(Vector2(randf_range(470, 560), randf_range(50, 150)))

	if GameState.body_parts_state.has(t["key"]) and Dice.chance(0.22):
		if GameState.break_part(t["key"]):
			_log("¡CRAC! Te quiebra %s. Queda roto." % t["name"])
	elif Dice.chance(0.3):
		GameState.apply_bleeding(1)
		_log("¡Te abre una herida! Empezás a SANGRAR.")

func _tick_enemy_status() -> void:
	var status_log: Array[String] = []
	if _enemy_bleed > 0:
		var bleed_dmg := _enemy_bleed
		# Aplicar a torso como daño directo
		if parts_hp.get("torso", 0) > 0:
			parts_hp["torso"] = maxi(0, parts_hp["torso"] - bleed_dmg)
			_update_part_label("torso")
		_enemy_bleed = maxi(0, _enemy_bleed - 1)
		status_log.append("sangrado -%d" % bleed_dmg)
	if _enemy_burn > 0:
		var burn_dmg := _enemy_burn
		var target := "torso"
		for p in ["brazo_izq", "brazo_der", "pierna_izq", "pierna_der"]:
			if parts_hp.get(p, 0) > 0:
				target = p
				break
		if parts_hp.get(target, 0) > 0:
			parts_hp[target] = maxi(0, parts_hp[target] - burn_dmg)
			_update_part_label(target)
		_enemy_burn = maxi(0, _enemy_burn - 1)
		status_log.append("quemadura -%d" % burn_dmg)
	if _enemy_poison > 0:
		if parts_hp.get("torso", 0) > 0:
			parts_hp["torso"] = maxi(0, parts_hp["torso"] - 2)
			_update_part_label("torso")
		_enemy_poison = maxi(0, _enemy_poison - 1)
		status_log.append("veneno -2")
	if _enemy_stun_turns > 0:
		status_log.append("aturdido")
	if not status_log.is_empty():
		_log("[Estado enemigo: %s]" % ", ".join(status_log))

func _enemy_turn() -> void:
	if combat_over:
		return

	if _enemy_staggered:
		_enemy_staggered = false
		_log("%s se tambalea y pierde el turno." % enemy.display_name)
		_tick_enemy_status()
		if _enemy_dead():
			_win()
			return
		_start_player_turn()
		return

	if _enemy_skip_turn:
		_enemy_skip_turn = false
		_log("%s se arrastra sin poder alcanzarte." % enemy.display_name)
		_tick_enemy_status()
		if _enemy_dead():
			_win()
			return
		_start_player_turn()
		return

	# Aturdido: no hace nada.
	if _enemy_stun_turns > 0:
		_enemy_stun_turns -= 1
		_log("%s está aturdido y no puede moverse." % enemy.display_name)
		_tick_enemy_status()
		if _enemy_dead():
			_win()
			return
		_start_player_turn()
		return

	# Tic de estados del enemigo.
	_tick_enemy_status()
	if _enemy_dead():
		_win()
		return

	# Si venía cargando un golpe fuerte, lo descarga AHORA.
	if _enemy_charging:
		_execute_special()
		return

	# Selección de IA según HP.
	var ai_action := _select_ai_action()

	# ¿Empieza a cargar un golpe especial? Solo si la IA no lo hizo ya.
	if _special_cd <= 0 and Dice.chance(_special_chance()) and ai_action != "power":
		_enemy_charging = true
		_special_cd = 3
		_log("%s se prepara para un GOLPE FUERTE. ¡Anticipate! (Guardia o curarte)" % enemy.display_name)
		_telegraph_flash()
		_start_player_turn()
		return
	if _special_cd > 0:
		_special_cd -= 1

	_execute_ai_action(ai_action)
	_refresh_player_info()
	if GameState.player_hp <= 0:
		_lose()
		return
	_start_player_turn()

## Probabilidad de que el enemigo cargue un golpe especial este turno.
func _special_chance() -> float:
	if enemy.is_boss and enemy.power_chance > 0.0:
		return enemy.power_chance
	return SPECIAL_CHANCE_COMMON

## Tiñe al enemigo de rojo un instante para avisar que está cargando.
func _telegraph_flash() -> void:
	enemy_sprite.modulate = Color(1, 1, 1, 1)
	var tw := create_tween().set_loops(3)
	tw.tween_property(enemy_sprite, "modulate", Color(1.6, 0.5, 0.5, 1), 0.25)
	tw.tween_property(enemy_sprite, "modulate", Color(1, 1, 1, 1), 0.25)

## Descarga el golpe fuerte cargado el turno anterior. Podés esquivarlo (dado)
## o aguantarlo con guardia.
func _execute_special() -> void:
	_enemy_charging = false
	enemy_sprite.modulate = Color(1, 1, 1, 1)
	var pname: String = enemy.power_name if (enemy.is_boss and enemy.power_name != "") else "Embestida brutal"
	var dmg := maxi(1, (enemy.attack + GameState.danger) * 2)
	dmg = maxi(1, int(dmg * GameState.get_damage_taken_mult()))
	dmg = maxi(1, dmg - GameState.get_defense_mod())
	if enemy.is_boss and enemy.power_damage > 0:
		dmg = maxi(dmg, enemy.power_damage)
	var dc: int = enemy.power_dc if (enemy.is_boss and enemy.power_dc > 0) else 12
	var r := Dice.check(GameState.get_dodge_mod(), dc)

	if r["success"]:
		AudioManager.play_sfx(SFX_DODGE, -4.0)
		_log("¡Esquivás «%s»!  [d20 %d+%d=%d vs %d]" % [
			pname, r["die"], r["modifier"], r["total"], dc])
	else:
		if _guard_active:
			dmg = maxi(1, int(dmg * 0.5))
			_guard_active = false
			_log("Aguantás «%s» con la guardia." % pname)
		_companion_take_hit(dmg)
		GameState.apply_bleeding(1)
		AudioManager.play_sfx(SFX_HIT, -2.0)
		_log("«%s» te revienta: -%d de vida y herida abierta.  [d20 %d+%d=%d vs %d]" % [
			pname, dmg, r["die"], r["modifier"], r["total"], dc])
		_shake(8.0, 0.4)
		_spawn_blood(Vector2(randf_range(470, 560), randf_range(50, 150)))

	_refresh_player_info()
	if GameState.player_hp <= 0:
		_lose()
		return
	_start_player_turn()

func _on_risky_attack() -> void:
	if combat_over or not is_player_turn or _pending_dodge:
		return
	if await _roll_combat_jam():
		return
	var culata := _spend_combat_bullet()
	is_player_turn = false

	var v := Dice.versus(GameState.get_pulse_mod(), enemy.defense)
	_log("Arriesgado: vos [d20 %d+%d=%d] vs %s [%d+%d=%d]" % [
		v["player_die"], GameState.get_pulse_mod(), v["player_total"],
		enemy.display_name, v["enemy_die"], enemy.defense, v["enemy_total"]])

	if v["player_wins"]:
		var part := _strongest_part()
		var dmg: int = GameState.get_player_damage()
		var weapon_r: WeaponData = GameState.equipped_weapon
		if weapon_r != null and weapon_r.variance > 0:
			dmg = maxi(1, dmg + randi_range(-weapon_r.variance, weapon_r.variance))
		if culata:
			dmg = maxi(1, int(dmg / 2.0))
			_log("Sin balas: es a culatazo limpio.")
		dmg *= 2
		parts_hp[part] = maxi(0, parts_hp[part] - dmg)
		_update_part_label(part)
		_log("¡Ganás! Golpe brutal a %s: %d de daño." % [part, dmg])
		# Aplicar efecto del arma en risky attack.
		var weapon := GameState.equipped_weapon
		if weapon != null and weapon.status_effect != "" and Dice.chance(weapon.status_chance):
			match weapon.status_effect:
				"bleed":
					_enemy_bleed += 5
					_log("La herida es profunda y sangra copiosamente.")
				"burn":
					_enemy_burn += 5
					_log("El impacto deja el cuerpo humeante.")
				"stun":
					_enemy_stun_turns = maxi(_enemy_stun_turns, 2)
					_log("El enemigo queda aturdido por el golpe.")
				"poison":
					_enemy_poison += 5
					_log("El veneno corre por las venas del enemigo.")
		if parts_hp[part] == 0:
			_log("¡Destruiste %s!" % part)
	elif v["tie"]:
		_log("Empate: los golpes chocan, nadie cede.")
	else:
		var dmg := maxi(1, enemy.attack + 4)
		dmg = maxi(1, int(dmg * GameState.get_damage_taken_mult()))
		dmg = maxi(1, dmg - GameState.get_defense_mod())
		GameState.damage_player(dmg)
		GameState.apply_bleeding(1)
		_log("%s te lee el movimiento: -%d y herida abierta." % [enemy.display_name, dmg])
		_shake(5.0, 0.3)
		_spawn_blood(Vector2(randf_range(470, 560), randf_range(50, 150)))

	_refresh_player_info()
	await get_tree().create_timer(0.8).timeout

	if _enemy_dead():
		_win()
		return
	if GameState.player_hp <= 0:
		_lose()
		return
	_enemy_turn()

func _on_flee() -> void:
	if combat_over or not is_player_turn or _pending_dodge:
		return
	is_player_turn = false
	var r := Dice.check(3 + GameState.get_force_mod(), 12)
	_log("Intentás huir: [d20 %d+%d=%d] vs 12" % [r["die"], 3 + GameState.get_force_mod(), r["total"]])
	if r["success"]:
		combat_over = true
		_log("¡Escapás! (%s sigue al acecho)" % enemy.display_name)
		await get_tree().create_timer(0.9).timeout
		GameState.flee_combat()
	else:
		_log("No llegás. %s te alcanza." % enemy.display_name)
		await get_tree().create_timer(0.8).timeout
		_enemy_turn()

func _strongest_part() -> String:
	var best := ""
	var best_hp := -1
	for part in parts_hp.keys():
		if parts_hp[part] > best_hp:
			best_hp = parts_hp[part]
			best = part
	return best

func _update_part_label(part: String) -> void:
	if parts_hp[part] <= 0:
		part_labels[part].text = "%s: DESTRUIDA" % part
		_apply_dismember_sprite(part)
	else:
		part_labels[part].text = "%s: %d" % [part, parts_hp[part]]

## Cambia el sprite del enemigo al destruir un miembro, SI existe una variante
## dibujada. Convención: <sprite_base>_<parte>.png en la misma carpeta.
## Ej: soldado_combat.png + brazo_der → soldado_combat_brazo_der.png
## Si no existe el archivo, no pasa nada (se queda el sprite actual).
func _apply_dismember_sprite(part: String) -> void:
	if enemy == null or enemy.sprite == null:
		return
	var base: String = enemy.sprite.resource_path
	if not base.ends_with(".png"):
		return
	var variant := base.trim_suffix(".png") + "_" + part + ".png"
	if ResourceLoader.exists(variant):
		var tex := load(variant) as Texture2D
		if tex != null:
			enemy_sprite.texture = tex

func _total_parts_hp() -> int:
	var t := 0
	for p in parts_hp.values():
		t += p
	return t

func _enemy_hp_ratio() -> float:
	var current := _total_parts_hp()
	if _enemy_max_hp <= 0:
		return 1.0
	return float(current) / float(_enemy_max_hp)

func _enemy_dead() -> bool:
	return parts_hp.get("cabeza", 1) <= 0 or parts_hp.get("torso", 1) <= 0

func _refresh_player_info() -> void:
	var s := "Tu vida: %d/%d" % [GameState.player_hp, GameState.PLAYER_HP_MAX]
	var winfo: WeaponData = GameState.equipped_weapon
	if winfo != null and winfo.is_firearm():
		s += "\nMunición: %d/%d  (repuestos x%d)" % [
			GameState.weapon_ammo(), winfo.mag_size, GameState.ammo_reserve_count()]
	if GameState.bleeding > 0:
		s += "    (SANGRANDO x%d)" % GameState.bleeding
	if GameState.poison > 0:
		s += "    (VENENO x%d)" % GameState.poison
	if GameState.paralysis > 0:
		s += "    (PARÁLISIS)"
	if GameState.blind > 0:
		s += "    (CEGUERA)"
	if GameState.concussion > 0:
		s += "    (CONMOCIÓN)"
	if GameState.shell_shock > 0:
		s += "    (SHOCK DE BATALLA)"
	if GameState.burns > 0:
		s += "    (QUEMADURAS x%d)" % GameState.burns
	if GameState.wound_infection > 0:
		s += "    (INFECCIÓN)"
	if GameState.trench_foot >= 60:
		s += "    (PIE DE TRINCHERA)"
	var enemigo_s := ""
	if _enemy_bleed > 0:
		enemigo_s += " Enemigo:[sangrado x%d]" % _enemy_bleed
	if _enemy_burn > 0:
		enemigo_s += "[quemadura x%d]" % _enemy_burn
	if _enemy_poison > 0:
		enemigo_s += "[veneno x%d]" % _enemy_poison
	var roto: Array = []
	for part in GameState.body_parts_state.keys():
		if GameState.body_parts_state[part] == "roto":
			roto.append(part)
	if not roto.is_empty():
		s += "\nRoto: " + ", ".join(roto)
	if enemigo_s != "":
		s += "\n" + enemigo_s
	player_info.text = s
	# Companion info.
	if companion_info != null and GameState.companion != null:
		companion_info.text = "%s: %d/%d HP" % [
			GameState.companion.display_name, GameState.companion_hp, GameState.companion_hp_max]
		companion_info.visible = true
	elif companion_info != null:
		companion_info.visible = false

func _shake(intensity: float, duration: float) -> void:
	var offset := Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
	var tw: Tween = create_tween().set_trans(Tween.TRANS_QUAD)
	tw.tween_property(self, "position", _rest_position + offset, duration * 0.5)
	tw.tween_property(self, "position", _rest_position, duration * 0.5)

# --- Acciones del companion ---

func _on_companion_heal() -> void:
	if combat_over or not is_player_turn or _pending_dodge or _companion_turn_used:
		return
	if GameState.companion == null or not GameState.companion.can_heal:
		return
	_companion_turn_used = true
	var heal := GameState.companion.heal_power
	if heal <= 0:
		heal = 15
	GameState.heal_companion(heal)
	GameState.player_hp = mini(GameState.PLAYER_HP_MAX, GameState.player_hp + int(heal * 0.5))
	_log("%s te cura. Vos: +%d, Él: +%d" % [GameState.companion.display_name, int(heal * 0.5), heal])
	_refresh_player_info()
	await get_tree().create_timer(0.6).timeout
	_enemy_turn()

func _on_companion_attack() -> void:
	if combat_over or not is_player_turn or _pending_dodge or _companion_turn_used:
		return
	if GameState.companion == null:
		return
	_companion_turn_used = true
	var dmg := GameState.companion.attack
	var part := _strongest_part()
	parts_hp[part] = maxi(0, parts_hp[part] - dmg)
	_update_part_label(part)
	_log("%s ataca %s: %d de daño." % [GameState.companion.display_name, part, dmg])
	AudioManager.play_sfx(SFX_PLAYER_ATTACK, -3.0)
	if parts_hp[part] == 0:
		_enemy_destroyed_parts[part] = true
		_log("¡%s destruye %s!" % [GameState.companion.display_name, part])
		if part in ["pierna_izq", "pierna_der"]:
			_enemy_skip_turn = true
		elif part in ["brazo_izq", "brazo_der"]:
			pass
		else:
			_enemy_staggered = true
	if _enemy_dead():
		_win()
		return
	_refresh_player_info()
	await get_tree().create_timer(0.6).timeout
	_enemy_turn()

## El companion recibe daño en vez del jugador (si está presente).
func _companion_take_hit(dmg: int) -> void:
	if GameState.companion == null:
		GameState.damage_player(dmg)
		return
	# 50% chance de que el companion absorba el golpe.
	if Dice.chance(0.5):
		var cname := GameState.companion.display_name
		var died := GameState.damage_companion(dmg)
		_log("%s recibe el golpe: -%d HP." % [cname, dmg])
		if died:
			_log("%s ha caído." % cname)
			_build_action_buttons()
	else:
		GameState.damage_player(dmg)

func _spawn_blood(at: Vector2) -> void:
	var p := GPUParticles2D.new()
	p.amount = 8
	p.lifetime = 0.6
	p.explosiveness = 0.8
	p.one_shot = true
	p.position = at
	var img := Image.create(4, 4, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	p.texture = ImageTexture.create_from_image(img)
	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, -1, 0)
	mat.spread = 180.0
	mat.initial_velocity_min = 30.0
	mat.initial_velocity_max = 80.0
	mat.gravity = Vector3(0, 120, 0)
	mat.scale_min = 0.5
	mat.scale_max = 1.5
	mat.color = Color(0.6, 0.05, 0.05)
	p.process_material = mat
	add_child(p)
	p.emitting = true
	await get_tree().create_timer(1.0).timeout
	if is_instance_valid(p):
		p.queue_free()

func _win() -> void:
	if _resolved:
		return
	_resolved = true
	combat_over = true
	AudioManager.play_sfx(SFX_VICTORY, -2.0)
	_log("Derrotaste a %s." % enemy.display_name)
	if enemy.reward > 0:
		GameState.money += enemy.reward
		GameState.money_changed.emit()
		_log("Le revisás los bolsillos: +%d cigarrillos." % enemy.reward)
	if not enemy.loot_table.is_empty():
		var gained := GameState.process_loot(enemy.loot_table)
		if gained.is_empty():
			_log("No te entra más nada en el inventario.")
		else:
			_log("Botín: " + ", ".join(gained))
	if GameState.pending_enemy_path.contains("madness"):
		GameState.recover_from_madness()
		_log("Recuperás algo de cordura...")
	await get_tree().create_timer(1.5).timeout
	AudioManager.stop_music()
	GameState.end_combat()

func _lose() -> void:
	if _resolved:
		return
	_resolved = true
	combat_over = true
	# Enemigos humanos que capturan: en vez de morir, despertás prisionero
	# en la celda del mapa (estilo F&H), desarmado y a media vida.
	if enemy.captures:
		await _captured("Un culatazo. Todo se pone negro... pero no morís.")
		return
	AudioManager.play_sfx(SFX_DEATH, -1.0)
	_log("Has muerto.")
	await get_tree().create_timer(1.5).timeout
	GameState.game_over()

## Caída en manos enemigas: desarmado, a media vida, y a la celda del mapa.
## La usan la derrota contra capturadores y la rendición voluntaria.
func _captured(msg: String) -> void:
	_resolved = true
	combat_over = true
	GameState.player_hp = 20
	GameState.bleeding = 0
	GameState.pending_capture = true
	GameState.equip_weapon(null)
	_log(msg)
	await get_tree().create_timer(1.8).timeout
	AudioManager.stop_music()
	GameState.end_combat()

## Rendirse ante los británicos: te toman prisionero (Convención de Ginebra
## mediante). Menos heroico, más vivo.
func _on_surrender() -> void:
	if combat_over or not is_player_turn or _pending_dodge:
		return
	Dialogue.ask("¿Tirás el arma y levantás las manos?", ["Rendirte", "Mejor no"])
	var choice: int = await Dialogue.chosen
	if choice != 0:
		return
	await _captured("—Hands up! Te atan las muñecas. Sos prisionero de guerra.")

## Intimidar: un grito con el arma en alto puede hacer retroceder a un enemigo.
func _on_intimidate() -> void:
	if combat_over or not is_player_turn or _pending_dodge:
		return
	is_player_turn = false
	var mod := GameState.get_force_mod()
	var r := Dice.check(mod, 13)
	if r["success"]:
		combat_over = true
		_resolved = true
		_log("Rugís con el arma en alto. Duda... y retrocede entre la niebla.\n[d20 %d+%d=%d vs 13]" % [r["die"], mod, r["total"]])
		await get_tree().create_timer(1.2).timeout
		GameState.flee_combat()
	else:
		_log("Tu grito suena a miedo. Se te viene encima.\n[d20 %d+%d=%d vs 13]" % [r["die"], mod, r["total"]])
		await get_tree().create_timer(0.6).timeout
		_enemy_turn()

## Calmar a un desertor (estilo Termina): si le hablás bien, baja el arma
## y hasta te deja algo antes de perderse en la turba.
func _on_calm() -> void:
	if combat_over or not is_player_turn or _pending_dodge:
		return
	is_player_turn = false
	var r := Dice.check(0, 12)
	if r["success"]:
		combat_over = true
		_resolved = true
		GameState.add_item(GameState.items_by_id["venda"], 1)
		_log("«Tranquilo, hermano. Somos los dos de acá.»\nBaja el arma. Te deja una venda y se pierde en la niebla.\n[d20 %d vs 12]" % r["die"])
		await get_tree().create_timer(1.4).timeout
		GameState.flee_combat()
	else:
		_log("«¡No te me acerques!» No te escucha.\n[d20 %d vs 12]" % r["die"])
		await get_tree().create_timer(0.6).timeout
		_enemy_turn()

func _log(msg: String) -> void:
	if GameState.sanity < 25 and Dice.chance(0.4):
		msg = _garble(msg)
	# Mantener solo las últimas líneas para que la caja no se desborde.
	_last_log_lines.append(msg)
	while _last_log_lines.size() > LOG_MAX_LINES:
		_last_log_lines.pop_front()
	log_label.text = "\n".join(_last_log_lines)

func _garble(s: String) -> String:
	var garble_chars := "¡¿ãõñáéíóúàèìòùäëïöüâêîôû0123456789"
	var result := ""
	for c in s:
		if Dice.chance(0.25):
			result += "*"
		elif Dice.chance(0.15):
			result += garble_chars[randi() % garble_chars.length()]
		else:
			result += c
	return result
