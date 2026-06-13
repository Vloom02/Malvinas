extends Node2D
## Script base de una sala. Al cargar: ubica al jugador en el spawn correcto y,
## si la sala tiene chance de emboscada, puede tirarte a un combate al entrar.

## Probabilidad (0-1) de una emboscada al entrar a la sala. 0 = nunca.
@export var encounter_chance: float = 0.0
## Enemigo de la emboscada.
@export_file("*.tres") var encounter_enemy: String = "res://data/enemies/ghoul.tres"

func _ready() -> void:
	if GameState.next_spawn != "":
		var spawn := find_child(GameState.next_spawn, true, false)
		var player := get_tree().get_first_node_in_group("player")
		if spawn != null and player != null:
			player.global_position = spawn.global_position
		GameState.next_spawn = ""

	if encounter_chance > 0.0 and Dice.chance(encounter_chance):
		call_deferred("_ambush")

func _ambush() -> void:
	var scene := get_tree().current_scene
	var from := scene.scene_file_path if scene != null else ""
	GameState.pending_kill_id = ""
	Dialogue.say("¡Emboscada! Algo te cae encima.")
	await Dialogue.finished
	GameState.start_combat(encounter_enemy, from)
