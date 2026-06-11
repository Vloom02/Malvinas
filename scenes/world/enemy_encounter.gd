extends Area2D
class_name EnemyEncounter
## Enemigo en el mundo. Cuando el jugador lo toca, arranca el combate contra
## el enemigo indicado en `enemy_path`. Al ganar, GameState te trae de vuelta.
##
## Reutilizable: poné varios en el mapa, cada uno con su .tres de enemigo.

## Ruta al recurso de datos del enemigo (un EnemyData .tres).
@export var enemy_path: String = "res://data/enemies/ghoul.tres"

var _triggered: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if _triggered:
		return
	if body.is_in_group("player"):
		_triggered = true
		var from_scene := get_tree().current_scene.scene_file_path
		GameState.start_combat(enemy_path, from_scene)
