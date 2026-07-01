extends Node2D
## Script base de una sala. Al cargar: ubica al jugador en el spawn correcto y,
## si la sala tiene chance de emboscada, puede tirarte a un combate al entrar.

## Probabilidad (0-1) de una emboscada al entrar a la sala. 0 = nunca.
@export var encounter_chance: float = 0.0
## Enemigo de la emboscada.
@export_file("*.tres") var encounter_enemy: String = "res://data/enemies/ghoul.tres"
## DC para notar la emboscada antes de que ocurra (0 = sin chance de evitarla).
@export var stealth_dc: int = 0

## Decoraciones que NO bloquean el paso (pasto, arbustos, cráteres, charcos):
## se las reconoce por el prefijo del nombre del nodo.
const WALKABLE_DECALS := ["Tussock", "Gorse", "Crater", "Charco", "Pasto"]

func _ready() -> void:
	_add_prop_collisions()

	if GameState.next_spawn != "":
		var spawn := find_child(GameState.next_spawn, true, false)
		var player := get_tree().get_first_node_in_group("player")
		if spawn != null and player != null:
			player.global_position = spawn.global_position
		GameState.next_spawn = ""

	_onboarding()

	if encounter_chance > 0.0 and Dice.chance(encounter_chance):
		if stealth_dc > 0:
			call_deferred("_stealth_check")
		else:
			call_deferred("_ambush")

func _onboarding() -> void:
	if GameState.has_flag("intro_shown"):
		return
	var path := get_tree().current_scene.scene_file_path if get_tree().current_scene != null else ""
	if not path.ends_with("sandbox.tscn"):
		return
	GameState.set_flag("intro_shown")
	GameState.add_journal("Malvinas, 1982. La brigada está diezmada. Hay que llegar al pozo de la zona sur y pedir ayuda por radio.")
	GameState.add_journal("Controles: WASD = moverte, E = interactuar, I = menú/equipo, J = diario, R = tirar dado, Esc = pausa.")
	await get_tree().create_timer(0.5).timeout
	var scene := get_tree().current_scene
	if scene != null:
		Dialogue.say("Despertás en la trinchera.\nTenés que llegar al pozo de la zona sur y pedir ayuda por radio.\n\nWASD = moverte, E = usar, I = inventario, J = diario")
		await Dialogue.finished

## Le da colisión a los props decorativos (sacos, barriles, cruces, rocas) que
## están como Sprite2D plano dentro del nodo "Deco". Los props que ya son
## prop.tscn (StaticBody2D) no se tocan. Los decals pisables se saltean.
func _add_prop_collisions() -> void:
	var deco := get_node_or_null("Deco")
	if deco == null:
		return
	for child in deco.get_children():
		if not (child is Sprite2D):
			continue
		var spr := child as Sprite2D
		if spr.texture == null:
			continue
		var skip := false
		for prefix in WALKABLE_DECALS:
			if spr.name.begins_with(prefix):
				skip = true
				break
		if skip:
			continue
		if spr.get_node_or_null("AutoCollision") != null:
			continue
		var tex_size := spr.texture.get_size()
		var body := StaticBody2D.new()
		body.name = "AutoCollision"
		var col := CollisionShape2D.new()
		var shape := RectangleShape2D.new()
		# Cubre la base del prop (no todo el alto) para poder solaparte por arriba.
		shape.size = Vector2(tex_size.x * 0.8, tex_size.y * 0.5)
		col.shape = shape
		col.position = Vector2(0, tex_size.y * 0.2)  # bajar a la base (sprite centrado)
		body.add_child(col)
		spr.add_child(body)

func _stealth_check() -> void:
	var r := Dice.check(2, stealth_dc)
	if r["success"]:
		Dialogue.say("Algo se mueve en las sombras. Te agazapás a tiempo.\n[Percepción: d20 %d+2=%d vs %d]" % [r["die"], r["total"], stealth_dc])
		await Dialogue.finished
		return
	Dialogue.say("No viste venir lo que te esperaba.\n[Percepción: d20 %d+2=%d vs %d — fallaste]" % [r["die"], r["total"], stealth_dc])
	await Dialogue.finished
	_ambush()

func _ambush() -> void:
	var scene := get_tree().current_scene
	var from := scene.scene_file_path if scene != null else ""
	GameState.pending_kill_id = ""
	Dialogue.say("¡Emboscada! Algo te cae encima.")
	await Dialogue.finished
	GameState.start_combat(encounter_enemy, from)
