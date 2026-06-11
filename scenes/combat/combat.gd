extends Control
## Pantalla de combate por turnos con desmembramiento (estilo Fear & Hunger).
##
## Flujo: es TU turno -> elegís qué parte del cuerpo atacar -> el enemigo
## recibe daño en esa parte -> si no murió, te contraataca -> repetir.
## Ganás si destruís su cabeza o su torso. Perdés si tu vida llega a 0.
##
## El enemigo a pelear lo decide GameState.pending_enemy_path (lo setea quien
## inicia el combate). Si la cordura llegó a 0, viene la pesadilla y la
## pantalla se tiñe de sangre.

@onready var enemy_name_label: Label = $EnemyName
@onready var parts_list: VBoxContainer = $PartsList
@onready var actions: VBoxContainer = $Actions
@onready var log_label: Label = $Log
@onready var player_info: Label = $PlayerInfo
@onready var madness_tint: ColorRect = $MadnessTint

var enemy: EnemyData
var parts_hp: Dictionary = {}          # parte -> HP vivo (copia, no toca el .tres)
var part_labels: Dictionary = {}       # parte -> Label que muestra su HP
var is_player_turn: bool = true
var combat_over: bool = false

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

	if path.contains("madness"):
		_begin_madness()

## Efecto de pesadilla: la pantalla se tiñe de rojo y un texto inquietante.
func _begin_madness() -> void:
	_log("La cordura te abandona. Algo sin rostro se arrastra hacia vos.")
	madness_tint.color = Color(0.5, 0.0, 0.0, 0.0)
	var tw := create_tween()
	tw.tween_property(madness_tint, "color:a", 0.35, 0.8)

## Crea una etiqueta por cada parte del cuerpo, mostrando su HP.
func _build_parts_display() -> void:
	for part in parts_hp.keys():
		var l := Label.new()
		l.text = "%s: %d" % [part, parts_hp[part]]
		parts_list.add_child(l)
		part_labels[part] = l

## Crea un botón "Atacar <parte>" por cada parte. Esto es el menú de combate.
func _build_action_buttons() -> void:
	for part in parts_hp.keys():
		var b := Button.new()
		b.text = "Atacar %s" % part
		b.pressed.connect(_on_attack_part.bind(part))
		actions.add_child(b)

func _on_attack_part(part: String) -> void:
	if combat_over or not is_player_turn:
		return
	if parts_hp[part] <= 0:
		_log("%s ya está destruida." % part)
		return

	is_player_turn = false
	var dmg := GameState.player_attack
	parts_hp[part] = maxi(0, parts_hp[part] - dmg)
	_log("Golpeás %s: -%d." % [part, dmg])
	_update_part_label(part)
	if parts_hp[part] == 0:
		_log("¡Destruiste %s!" % part)

	if _enemy_dead():
		_win()
		return

	# Pequeña pausa y contraataca el enemigo.
	await get_tree().create_timer(0.6).timeout
	_enemy_turn()

func _update_part_label(part: String) -> void:
	if parts_hp[part] <= 0:
		part_labels[part].text = "%s: DESTRUIDA" % part
	else:
		part_labels[part].text = "%s: %d" % [part, parts_hp[part]]

## El enemigo muere si pierde la cabeza o el torso.
func _enemy_dead() -> bool:
	return parts_hp.get("cabeza", 1) <= 0 or parts_hp.get("torso", 1) <= 0

func _enemy_turn() -> void:
	if combat_over:
		return
	var dmg := maxi(1, enemy.attack)
	GameState.damage_player(dmg)
	_log("%s te ataca: -%d de vida." % [enemy.display_name, dmg])
	_refresh_player_info()
	if GameState.player_hp <= 0:
		_lose()
		return
	is_player_turn = true

func _refresh_player_info() -> void:
	player_info.text = "Tu vida: %d/%d" % [GameState.player_hp, GameState.PLAYER_HP_MAX]

func _win() -> void:
	combat_over = true
	_log("Derrotaste a %s." % enemy.display_name)
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
