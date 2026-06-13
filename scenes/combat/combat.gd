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
@onready var parts_list: VBoxContainer = $PartsList
@onready var actions: VBoxContainer = $Actions
@onready var log_label: Label = $Log
@onready var player_info: Label = $PlayerInfo
@onready var madness_tint: ColorRect = $MadnessTint

# --- Tuning ---
const PLAYER_DMG := 11      # daño con pulso firme (determinista)
const PULSE_MOD := 2        # modificador de la tirada de pulso
const PULSE_DC := 11        # dificultad de mantener el pulso estando herido
const DODGE_MOD := 3        # modificador para esquivar poderes de jefe
const WOUNDED_HP := 35      # debajo de esto, te tiembla el pulso

var enemy: EnemyData
var parts_hp: Dictionary = {}
var part_labels: Dictionary = {}
var is_player_turn: bool = true
var combat_over: bool = false
var _pending_dodge: bool = false   # esperando que esquives un poder
var _power_cooldown: bool = false  # el jefe no encadena poderes
var _enemy_staggered: bool = false # le destruiste una parte: pierde el turno

func _ready() -> void:
	var path := GameState.pending_enemy_path
	if path == "":
		path = "res://data/enemies/ghoul.tres"
	enemy = load(path) as EnemyData
	parts_hp = enemy.body_parts.duplicate()

	enemy_name_label.text = enemy.display_name
	_build_parts_display()
	_build_action_buttons()
	_refresh_player_info()
	_log("Te enfrentás a: %s." % enemy.display_name)

	GameState.player_died.connect(_on_player_died)

	if path.contains("madness"):
		_begin_madness()

func _process(_delta: float) -> void:
	if not combat_over:
		_refresh_player_info()  # la vida puede bajar en vivo si sangrás

func _on_player_died() -> void:
	if not combat_over:
		_lose()

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

func _build_action_buttons() -> void:
	_clear_actions()
	for part in parts_hp.keys():
		var b := Button.new()
		b.text = "Atacar %s" % part
		b.pressed.connect(_on_attack_part.bind(part))
		actions.add_child(b)
	var risky := Button.new()
	risky.text = "Ataque arriesgado (dados)"
	risky.pressed.connect(_on_risky_attack)
	actions.add_child(risky)
	var heal := Button.new()
	heal.text = "Vendarte"
	heal.pressed.connect(_on_bandage)
	actions.add_child(heal)
	var flee := Button.new()
	flee.text = "Huir (dado)"
	flee.pressed.connect(_on_flee)
	actions.add_child(flee)

func _clear_actions() -> void:
	for c in actions.get_children():
		c.queue_free()

## Lugares donde el enemigo te puede pegar (los miembros son quebrables).
const TARGETS := [
	{"key": "cabeza", "name": "la cabeza"},
	{"key": "torso", "name": "el torso"},
	{"key": "brazo_izq", "name": "el brazo izquierdo"},
	{"key": "brazo_der", "name": "el brazo derecho"},
	{"key": "pierna_izq", "name": "la pierna izquierda"},
	{"key": "pierna_der", "name": "la pierna derecha"},
]

## Estás "herido": te tiembla el pulso (sangrando, con poca vida o brazo roto).
func _is_wounded() -> bool:
	return GameState.bleeding > 0 or GameState.player_hp < WOUNDED_HP or GameState.broken_arms() > 0

func _on_attack_part(part: String) -> void:
	if combat_over or not is_player_turn or _pending_dodge:
		return
	if parts_hp[part] <= 0:
		_log("%s ya está destruida." % part)
		return

	is_player_turn = false
	var dmg := PLAYER_DMG

	if _is_wounded():
		# Pulso tembloroso: el dado decide si firmás el tiro.
		var r := Dice.check(PULSE_MOD, PULSE_DC)
		if r["fumble"]:
			dmg = 0
			_log("Te tiembla el pulso y errás del todo  [d20 %d]" % r["die"])
		elif r["success"]:
			if r["crit"]:
				dmg = PLAYER_DMG * 2
				_log("¡Pulso de acero! (20 natural)")
			else:
				_log("Aguantás el pulso  [d20 %d+%d=%d vs %d]" % [
					r["die"], r["modifier"], r["total"], PULSE_DC])
		else:
			dmg = int(PLAYER_DMG / 2.0)
			_log("El brazo herido te falla, pegás flojo  [d20 %d+%d=%d vs %d]" % [
				r["die"], r["modifier"], r["total"], PULSE_DC])

	if dmg > 0:
		parts_hp[part] = maxi(0, parts_hp[part] - dmg)
		_log("Golpeás %s: %d de daño." % [part, dmg])
		_update_part_label(part)
		if parts_hp[part] == 0:
			_log("¡Destruiste %s! Queda tambaleándose." % part)
			_enemy_staggered = true

	if _enemy_dead():
		_win()
		return

	await get_tree().create_timer(0.6).timeout
	_enemy_turn()

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
	_log("Te vendás a las apuradas. El sangrado se detiene.")
	await get_tree().create_timer(0.6).timeout
	_enemy_turn()

func _enemy_turn() -> void:
	if combat_over:
		return

	# Si le destruiste una parte, está aturdido: pierde el turno.
	if _enemy_staggered:
		_enemy_staggered = false
		_log("%s se tambalea y pierde el turno." % enemy.display_name)
		is_player_turn = true
		return

	# ¿El jefe carga un poder? → telegrafía y tenés que esquivar (tu turno).
	if enemy.is_boss and enemy.power_name != "" and not _power_cooldown and Dice.chance(enemy.power_chance):
		_power_cooldown = true
		_pending_dodge = true
		_log("%s prepara «%s». ¡ESQUIVÁ!" % [enemy.display_name, enemy.power_name])
		_show_dodge_action()
		is_player_turn = true
		return

	# Ataque normal: determinista, sin dado.
	_power_cooldown = false
	var dmg := maxi(1, enemy.attack)
	var t := TARGETS[randi() % TARGETS.size()]
	GameState.damage_player(dmg)
	_log("%s te golpea en %s: -%d de vida." % [enemy.display_name, t["name"], dmg])
	# Si pega un miembro, puede quebrártelo (permanente).
	if GameState.body_parts_state.has(t["key"]) and Dice.chance(0.22):
		if GameState.break_part(t["key"]):
			_log("¡CRAC! Te quiebra %s. Queda roto." % t["name"])
	elif Dice.chance(0.3):
		GameState.apply_bleeding(1)
		_log("¡Te abre una herida! Empezás a SANGRAR.")
	_refresh_player_info()
	if GameState.player_hp <= 0:
		_lose()
		return
	is_player_turn = true

func _show_dodge_action() -> void:
	_clear_actions()
	var b := Button.new()
	b.text = "Esquivar  (tirar dado)"
	b.pressed.connect(_on_dodge)
	actions.add_child(b)

func _on_dodge() -> void:
	if combat_over or not _pending_dodge:
		return
	_pending_dodge = false
	var r := Dice.check(DODGE_MOD, enemy.power_dc)

	if r["success"]:
		if r["crit"]:
			_log("¡Esquive perfecto! (20 natural) Ni te roza.")
		else:
			_log("¡Esquivás «%s»!  [d20 %d+%d=%d vs %d]" % [
				enemy.power_name, r["die"], r["modifier"], r["total"], enemy.power_dc])
	else:
		var dmg := maxi(1, enemy.power_damage)
		GameState.damage_player(dmg)
		GameState.apply_bleeding(1)
		_log("«%s» te da de lleno: -%d de vida y te abre una herida  [d20 %d+%d=%d vs %d]" % [
			enemy.power_name, dmg, r["die"], r["modifier"], r["total"], enemy.power_dc])
		_refresh_player_info()

	_build_action_buttons()  # vuelven las acciones normales
	if GameState.player_hp <= 0:
		_lose()
		return
	await get_tree().create_timer(0.7).timeout
	_enemy_turn()

## Opción de tirar los dados en combate: tirada ENFRENTADA (vos vs enemigo).
## Los dos dados son aleatorios. El resultado se muestra en la ventana de diálogos.
func _on_risky_attack() -> void:
	if combat_over or not is_player_turn or _pending_dodge:
		return
	is_player_turn = false

	var v := Dice.versus(2, enemy.defense)
	var text := "ATAQUE ARRIESGADO\n\nVos:  [ d20 %d + 2 = %d ]\n%s:  [ d20 %d + %d = %d ]\n\n" % [
		v["player_die"], v["player_total"],
		enemy.display_name, v["enemy_die"], enemy.defense, v["enemy_total"]]

	if v["player_wins"]:
		var part := _strongest_part()
		var dmg := PLAYER_DMG * 2
		parts_hp[part] = maxi(0, parts_hp[part] - dmg)
		_update_part_label(part)
		text += "¡Ganás el intercambio! Golpe brutal a %s: %d de daño." % [part, dmg]
		if parts_hp[part] == 0:
			text += "\n¡Destruiste %s!" % part
	elif v["tie"]:
		text += "Empate: los golpes chocan, nadie cede."
	else:
		var dmg := enemy.attack + 4
		GameState.damage_player(dmg)
		GameState.apply_bleeding(1)
		text += "%s te lee el movimiento: -%d de vida y te abre una herida." % [enemy.display_name, dmg]

	_log(text)
	Dialogue.say(text)
	await Dialogue.finished

	if _enemy_dead():
		_win()
		return
	if GameState.player_hp <= 0:
		_lose()
		return
	_enemy_turn()

## Huir: tirada de reflejos. Si sale, escapás (el enemigo queda vivo). Si no,
## te alcanza y juega su turno.
func _on_flee() -> void:
	if combat_over or not is_player_turn or _pending_dodge:
		return
	is_player_turn = false
	var r := Dice.check(3, 12)
	var text := "Intentás huir...\n[ d20 %d + 3 = %d ]  vs  12\n\n" % [r["die"], r["total"]]
	if r["success"]:
		combat_over = true
		text += "¡Escapás! (%s sigue al acecho)" % enemy.display_name
		Dialogue.say(text)
		await Dialogue.finished
		GameState.flee_combat()
	else:
		text += "No llegás. %s te alcanza." % enemy.display_name
		Dialogue.say(text)
		await Dialogue.finished
		_enemy_turn()

## Devuelve la parte viva con más HP (el "ataque arriesgado" pega a la más dura).
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
	else:
		part_labels[part].text = "%s: %d" % [part, parts_hp[part]]

func _enemy_dead() -> bool:
	return parts_hp.get("cabeza", 1) <= 0 or parts_hp.get("torso", 1) <= 0

func _random_player_part() -> String:
	var parts := ["la cabeza", "el torso", "el brazo", "la pierna"]
	return parts[randi() % parts.size()]

func _refresh_player_info() -> void:
	var s := "Tu vida: %d/%d" % [GameState.player_hp, GameState.PLAYER_HP_MAX]
	if GameState.bleeding > 0:
		s += "    (SANGRANDO x%d)" % GameState.bleeding
	var roto: Array = []
	for part in GameState.body_parts_state.keys():
		if GameState.body_parts_state[part] == "roto":
			roto.append(part)
	if not roto.is_empty():
		s += "\nRoto: " + ", ".join(roto)
	player_info.text = s

func _win() -> void:
	combat_over = true
	_log("Derrotaste a %s." % enemy.display_name)
	if enemy.reward > 0:
		GameState.money += enemy.reward
		GameState.money_changed.emit()
		_log("Le revisás los bolsillos: +%d cigarrillos." % enemy.reward)
	if GameState.pending_enemy_path.contains("madness"):
		GameState.recover_from_madness()
		_log("Recuperás algo de cordura...")
	await get_tree().create_timer(1.5).timeout
	GameState.end_combat()

func _lose() -> void:
	combat_over = true
	_log("Has muerto.")
	await get_tree().create_timer(1.5).timeout
	GameState.game_over()

func _log(msg: String) -> void:
	log_label.text += msg + "\n"
