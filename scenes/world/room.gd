extends Node2D
## Script base de una sala. Al cargar, si venís de otra sala, deja al jugador
## en el punto de aparición correcto (un Marker2D cuyo nombre guardó la puerta).

func _ready() -> void:
	if GameState.next_spawn == "":
		return
	var spawn := find_child(GameState.next_spawn, true, false)
	var player := get_tree().get_first_node_in_group("player")
	if spawn != null and player != null:
		player.global_position = spawn.global_position
	GameState.next_spawn = ""
